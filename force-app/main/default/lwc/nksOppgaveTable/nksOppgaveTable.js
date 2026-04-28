import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import USER_NAV_IDENT_FIELD from '@salesforce/schema/User.CRM_NAV_Ident__c';
import getAllOppgaver from '@salesforce/apex/OppgaveManager.getAllOppgaver';
import getOpenOppgaver from '@salesforce/apex/OppgaveManager.getOpenOppgaver';
import getAllAssignedOpenOppgaver from '@salesforce/apex/OppgaveManager.getAllAssignedOpenOppgaver';

export default class NksOppgaveTable extends NavigationMixin(LightningElement) {
	@api numRecords = 25;
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
		if (this.isLoading) {
			return;
		}


		this.isLoading = true;

		try {
			const result = await this.fetchOppgaver();

			const rows = (result || []).map((oppgave) => this.mapOppgaveToRow(oppgave));
			this.allRows = rows.slice(0, this.numRecords);
			this.applyClientFilters();
			this.error = undefined;
		} catch (error) {
			this.allRows = [];
			this.data = [];
			this.error = error;
		} finally {
			this.isLoading = false;
		}
	}

	async fetchOppgaver() {
        console.log('fetchOppgaver er heraaa');
        

        
		if (this.ownedByRunningUser) {
			if (!this.navIdent) {
				return [];
			}
			return getAllAssignedOpenOppgaver({ navIdent: this.navIdent });
		}

		if (this.selectedTaskScope === 'open') {
			return getOpenOppgaver({ personId: this.recordId, offset: this.offset });
		}

        console.log('neste linje! :D ');
        
		console.log(getAllOppgaver({ personId: this.recordId, offset: this.offset }));
		return getAllOppgaver({ personId: this.recordId, offset: this.offset });
	}

	mapOppgaveToRow(oppgave) {
		const externalId = oppgave?.id ? String(oppgave.id) : '';
		//TODO dobbeltsjekk feltnavn
        return {
			id: externalId,
			recordUrl: externalId ? `#${externalId}` : '#', //TODO 
			recordId: externalId,
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
			const status = (row.status || '').toLowerCase();
			return status.includes('open');
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
        return false;
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