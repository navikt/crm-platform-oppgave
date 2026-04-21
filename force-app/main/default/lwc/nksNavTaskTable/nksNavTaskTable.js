import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getNavTaskRecords from '@salesforce/apex/CRM_NavTaskListViewCtrl.getRecords';
import { refreshApex } from '@salesforce/apex';

// const QUERY_FIELDS = [
// 	'NKS_TaskType__r.Name',
// 	'NKS_Theme__r.Name',
// 	'CRM_GjelderFormula__c',
// 	'NKS_Status__c',
// 	'NKS_Date_Registered__c',
// 	'CRM_DueDate__c',
// 	'CRM_NavUnit__r.Name'
// ];

const QUERY_FIELDS = [
	'Name',
	'CRM_Theme__c',
	'CRM_SubTheme__c',
	'NKS_StatusFormula__c',
	'CreatedDate',
	'CRM_DueDate__c',
	'CRM_NavUnit__r.Name'
];

export default class NksNavTaskTable extends NavigationMixin(LightningElement) {
	@api numRecords = 25;
	@api ownedByRunningUser = false;

	allRows = [];
	data = [];
	error;
	selectedTaskScope = 'open';
	isRefreshing = false;
	wiredTasksResult;

	@wire(getNavTaskRecords, {
		fieldsToQuery: QUERY_FIELDS,
		filterString: '',
		ownedByRunningUser: '$ownedByRunningUser',
		numRecords: '$numRecords'
	})
	wiredTasks(result) {
		this.wiredTasksResult = result;

		const { data, error } = result;

		if (data) {
			this.allRows = data.map((row) => ({
					...this.parseStatus(row.NKS_StatusFormula__c),
				id: row.Id,
				recordUrl: `/lightning/r/NavTask__c/${row.Id}/view`,
				oppgavetype: row.Name || '',
				tema: row.CRM_Theme__c || '',
				gjelder: row.CRM_SubTheme__c || '',
				registrert: this.formatDate(row.CreatedDate),
				frist: this.formatDate(row.CRM_DueDate__c),
				navEnhet: row.CRM_NavUnit__r?.Name || ''
			}));
			this.applyClientFilters();
			this.error = undefined;
			return;
		}

		this.allRows = [];
		this.data = [];
		this.error = error;
	}

	handleMineToggle(event) {
		this.ownedByRunningUser = event.target.checked;
	}

	handleScopeChange(event) {
		this.selectedTaskScope = event.target.value;
		this.applyClientFilters();
	}

	async handleRefresh() {
		if (!this.wiredTasksResult || this.isRefreshing) {
			return;
		}

		this.isRefreshing = true;

		try {
			await refreshApex(this.wiredTasksResult);
		} finally {
			this.isRefreshing = false;
		}
	}

	applyClientFilters() {
		if (this.selectedTaskScope === 'all') {
			this.data = this.allRows;
			return;
		}

		this.data = this.allRows.filter((row) => {
			const status = (row.statusText || '').toLowerCase();
			return status.includes('open') || status.includes('apen') || status.includes('åpen');
		});
	}

	parseStatus(statusFormulaValue) {
		const rawStatus = statusFormulaValue || '';
		const srcMatch = rawStatus.match(/src\s*=\s*"([^"]+)"/i);
		const altMatch = rawStatus.match(/alt\s*=\s*"([^"]*)"/i);
		const statusText = this.stripHtml(rawStatus).trim();

		return {
			statusIconUrl: srcMatch ? srcMatch[1] : '',
			statusText: statusText || (altMatch ? altMatch[1] : '')
		};
	}

	stripHtml(value) {
		return String(value || '').replace(/<[^>]*>/g, ' ');
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

	get isOpenScope() {
		return this.selectedTaskScope === 'open';
	}

	get isAllScope() {
		return this.selectedTaskScope === 'all';
	}

	get errorMessage() {
		return this.error?.body?.message || this.error?.message || 'Kunne ikke hente oppgaver';
	}
}