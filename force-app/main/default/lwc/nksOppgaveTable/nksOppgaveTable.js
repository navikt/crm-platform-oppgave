import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAV_IDENT_FIELD from '@salesforce/schema/User.CRM_NAV_Ident__c';
import getNavTaskRecords from '@salesforce/apex/CRM_NavTaskListViewCtrl.getRecords';
//import getAllAssignedOpenOppgaver from '@salesforce/apex/OppgaveManager.getAllAssignedOpenOppgaver';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';
import getAllOppgaver from '@salesforce/apex/OppgaveManager.getAllOppgaver';



// const QUERY_FIELDS = [
// 	'Name',
// 	'CRM_Theme__c',
// 	'CRM_SubTheme__c',
// 	'NKS_StatusFormula__c',
// 	'CreatedDate',
// 	'CRM_DueDate__c',
// 	'CRM_NavUnit__r.Name'
// ];

export default class NksOppgaveTable extends NavigationMixin(LightningElement) {
	@api numRecords = 25;
	@api ownedByRunningUser = false;

    userId;
	allRows = [];
	data = [];
	error;
	selectedTaskScope = 'open';
	isRefreshing = false;
	wiredTasksResult;

    isLoading;
    oppgaver = [];
    offset = 0;

    @wire(getRecord, { recordId: USER_ID, fields: [USER_NAV_IDENT_FIELD] })
    wiredUser({ data, error }) {
        if (data) {
            this.navIdent = getFieldValue(data, USER_NAV_IDENT_FIELD) ?? this.navIdent;
            console.log('Fetched user navIdent:', this.navIdent);
            this.loadOppgaver();
        } else if (error) {
            console.error('Error fetching user:', error);
        }
    }

    async loadOppgaver() {
        if(!this.navIdent) return;
        this.isLoading = true;

        try {
            //const result = await getAllAssignedOpenOppgaver({ navIdent: this.navIdent });
            const result = await getAllOppgaver({personId: userId, offset: this.offset});
            console.log('yoyo!');
            console.log(result);

        } catch (error) {
            console.error('Error fetching oppgaver:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
	// wiredTasks(result) {
	// 	this.wiredTasksResult = result;

	// 	const { data, error } = result;

	// 	if (data) {
	// 		this.allRows = data.map((row) => ({
	// 			id: row.Id,
	// 			recordUrl: `/lightning/r/NavTask__c/${row.Id}/view`,
	// 			oppgavetype: row.Name || '',
	// 			tema: row.CRM_Theme__c || '',
	// 			gjelder: row.CRM_SubTheme__c || '',
	// 			status: row.NKS_StatusFormula__c || '',
	// 			registrert: this.formatDate(row.CreatedDate),
	// 			frist: this.formatDate(row.CRM_DueDate__c),
	// 			navEnhet: row.CRM_NavUnit__r?.Name || ''
	// 		}));
	// 		this.applyClientFilters();
	// 		this.error = undefined;
	// 		return;
	// 	}

	// 	this.allRows = [];
	// 	this.data = [];
	// 	this.error = error;
	// }




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
			const status = (row.status || '').toLowerCase();
			return status.includes('open') || status.includes('apen') || status.includes('åpen');
		});
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