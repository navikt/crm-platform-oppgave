import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import USER_NAV_IDENT_FIELD from '@salesforce/schema/User.CRM_NAV_Ident__c';
import getAllOppgaver from '@salesforce/apex/OppgaveManager.getAllOppgaver';
import getOpenOppgaver from '@salesforce/apex/OppgaveManager.getOpenOppgaver';
import getAllAssignedOpenOppgaver from '@salesforce/apex/OppgaveManager.getAllAssignedOpenOppgaver';

export default class NksOppgaveTable extends NavigationMixin(LightningElement) {
	//@api numRecords = 25;
	@api ownedByRunningUser = false;
	@api recordId;

	allRows = [];
	data = [];
	error;
	selectedTaskScope = 'open';
	isRefreshing = false;
	isLoading = false;
	offset = 0;
	navIdent;
    aktorId;

	@wire(getRecord, { recordId: userId, fields: [USER_NAV_IDENT_FIELD] })
	wiredUser({ data }) {
		if (data) {
			this.navIdent = getFieldValue(data, USER_NAV_IDENT_FIELD);
		}
	}

	connectedCallback() {
		this.loadOppgaver();
	}

	async loadOppgaver() {
		// if (this.isLoading) {
		// 	return;
		// }


		// this.isLoading = true;
        console.log('før try-catch');
        

		try {
            console.log('try trigga');
            
			const result = await this.fetchOppgaver();

            console.log('from async load oppgave try. result next line');
            console.log(result);
            
			const rows = (result || []).map((oppgave) => this.mapOppgaveToRow(oppgave))
            console.log('neste jsonStringify');
            
            console.log(JSON.stringify(rows));
            
			this.allRows = rows;
			this.applyClientFilters();
			this.error = undefined;
		} catch (error) {
            console.log('catch trigga');
            
			this.allRows = [];
			this.data = [];
			this.error = error;
		} finally {
            console.log('finally trigga');
            
			this.isLoading = false;
		}
	}

	async fetchOppgaver() {
        console.log('fetchOppgaver er heraaa');
        

        
		// if (this.ownedByRunningUser) {
		// 	if (!this.navIdent) {
		// 		return [];
		// 	}
		// 	return getAllAssignedOpenOppgaver({ navIdent: this.navIdent });
		// }

		// if (this.selectedTaskScope === 'open') {
		// 	return getOpenOppgaver({ personId: this.recordId, offset: this.offset });
		// }

        console.log('neste linje! :D ');
        console.log(this.recordId + ' ' + this.offset);
        
		console.log(getAllOppgaver({ personIdent: '12345678901', offset: this.offset }));
		//return getAllOppgaver({ personId: recordId, offset: offset });
		return getAllOppgaver({ personIdent: '12345678901', offset: this.offset });
	}

	mapOppgaveToRow(oppgave) {
        console.log('mapOppgaveToRow sin oppgave logges på neste');
        
        console.log(oppgave);
        
		const externalId = oppgave?.id ? String(oppgave.id) : '';
		//TODO dobbeltsjekk feltnavn
        return {
			id: externalId,
			recordUrl: externalId ? `#${externalId}` : '#', //TODO 
			oppgavetype: oppgave?.oppgavetype,
			tema: oppgave?.tema,
			gjelder: oppgave?.behandlingstema,
			status: oppgave?.status,
			registrert: this.formatDate(oppgave?.aktivDato),
			frist: this.formatDate(oppgave?.fristFerdigstillelse),
			navEnhet: oppgave?.tildeltEnhetsnr
		};
	}

	handleMineToggle(event) {
		this.ownedByRunningUser = event.target.checked;
		this.loadOppgaver();
	}

	handleScopeChange(event) {
		this.selectedTaskScope = event.target.value;
		this.loadOppgaver();
	}

	async handleRefresh() {
		if (this.isRefreshing) {
			return;
		}

		this.isRefreshing = true;

		try {
			await this.loadOppgaver();
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
			const status = (row.status || '').toString().toLowerCase();
			return status.includes('open') || status.includes('aapen') || status.includes('åpen');
		});
	}

	handleRecordClick(event) {
		event.preventDefault();

		const { recordId } = event.currentTarget.dataset;

		if (!recordId) {
			return;
		}

		this[NavigationMixin.Navigate]({
			type: 'standard__component',
			attributes: {
				componentName: 'c__crmOppgaveRedirect'
			},
			state: {
				c__oppgaveId: recordId
			}
		});

        
	}

	formatDate(value) {
		if (!value) {
			return '';
		}

        //TODO rydd her
		const normalizedValue = String(value).replace(' ', 'T');
		const date = new Date(normalizedValue.includes('T') ? normalizedValue : `${normalizedValue}T00:00:00.000Z`);

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