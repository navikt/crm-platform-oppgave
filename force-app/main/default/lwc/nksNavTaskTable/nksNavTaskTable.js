import { api, LightningElement, wire } from 'lwc';
import getNavTaskRecords from '@salesforce/apex/CRM_NavTaskListViewCtrl.getRecords';

const QUERY_FIELDS = [
	'NKS_TaskType__r.Name',
	'NKS_Theme__r.Name',
	'CRM_GjelderFormula__c',
	'NKS_Status__c',
	'NKS_Date_Registered__c',
	'CRM_DueDate__c',
	'CRM_NavUnit__r.Name'
];

const COLUMNS = [
	{ label: 'Oppgavetype', fieldName: 'oppgavetype', type: 'text' },
	{ label: 'Tema', fieldName: 'tema', type: 'text' },
	{ label: 'Gjelder', fieldName: 'gjelder', type: 'text' },
	{ label: 'Status', fieldName: 'status', type: 'text' },
	{
		label: 'Registrert',
		fieldName: 'registrert',
		type: 'date',
		typeAttributes: {
			year: 'numeric',
			month: '2-digit',
			day: '2-digit',
			hour: '2-digit',
			minute: '2-digit'
		}
	},
	{
		label: 'Frist',
		fieldName: 'frist',
		type: 'date',
		typeAttributes: {
			year: 'numeric',
			month: '2-digit',
			day: '2-digit',
			hour: '2-digit',
			minute: '2-digit'
		}
	},
	{ label: 'Nav enhet', fieldName: 'navEnhet', type: 'text' }
];

export default class NksNavTaskTable extends LightningElement {
	@api numRecords = 25;
	@api ownedByRunningUser = false;

	data = [];
	columns = COLUMNS;
	error;

	@wire(getNavTaskRecords, {
		fieldsToQuery: QUERY_FIELDS,
		filterString: '',
		ownedByRunningUser: '$ownedByRunningUser',
		numRecords: '$numRecords'
	})
	wiredTasks({ data, error }) {
		if (data) {
			this.data = data.map((row) => ({
				id: row.Id,
				oppgavetype: row.NKS_TaskType__r?.Name || '',
				tema: row.NKS_Theme__r?.Name || '',
				gjelder: row.CRM_GjelderFormula__c || '',
				status: row.NKS_Status__c || '',
				registrert: this.toDateTimeValue(row.NKS_Date_Registered__c),
				frist: this.toDateTimeValue(row.CRM_DueDate__c),
				navEnhet: row.CRM_NavUnit__r?.Name || ''
			}));
			this.error = undefined;
			return;
		}

		this.data = [];
		this.error = error;
	}

	toDateTimeValue(value) {
		if (!value) {
            console.log('lol');
            
			return null;
		}

		return String(value).includes('T') ? value : `${value}T00:00:00.000Z`;
	}

	get errorMessage() {
		return this.error?.body?.message || this.error?.message || 'Kunne ikke hente oppgaver';
	}
}