import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
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

export default class NksNavTaskTable extends NavigationMixin(LightningElement) {
	@api numRecords = 25;
	@api ownedByRunningUser = false;

	data = [];
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
				recordUrl: `/lightning/r/NavTask__c/${row.Id}/view`,
				oppgavetype: row.NKS_TaskType__r?.Name || '',
				tema: row.NKS_Theme__r?.Name || '',
				gjelder: row.CRM_GjelderFormula__c || '',
				status: row.NKS_Status__c || '',
				registrert: this.formatDate(row.NKS_Date_Registered__c),
				frist: this.formatDate(row.CRM_DueDate__c),
				navEnhet: row.CRM_NavUnit__r?.Name || ''
			}));
			this.error = undefined;
			return;
		}

		this.data = [];
		this.error = error;
	}

	handleRecordClick(event) {
		event.preventDefault();

		const { recordId } = event.currentTarget.dataset;

		if (!recordId) {
			return;
		}

		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId,
				actionName: 'view'
			}
		});
	}

	formatDate(value) {
		if (!value) {
			return '';
		}

		const date = new Date(String(value).includes('T') ? value : `${value}T00:00:00.000Z`);

		if (Number.isNaN(date.getTime())) {
			return '';
		}

		return new Intl.DateTimeFormat('nb-NO', {
			year: 'numeric',
			month: '2-digit',
			day: '2-digit'
		}).format(date);
	}

	get hasNoRows() {
		return !this.error && this.data.length === 0;
	}

	get errorMessage() {
		return this.error?.body?.message || this.error?.message || 'Kunne ikke hente oppgaver';
	}
}