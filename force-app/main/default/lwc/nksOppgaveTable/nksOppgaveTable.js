import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import userId from '@salesforce/user/Id';
import USER_NAV_IDENT_FIELD from '@salesforce/schema/User.CRM_NAV_Ident__c';
import getAllOppgaver from '@salesforce/apex/OppgaveManager.getAllOppgaver';
import getOpenOppgaver from '@salesforce/apex/OppgaveManager.getOpenOppgaver';
import getAllAssignedOpenOppgaver from '@salesforce/apex/OppgaveManager.getAllAssignedOpenOppgaver';
import OPPGAVE_CREATED_CHANNEL from '@salesforce/messageChannel/oppgaveCreated__c';

const PERSON_FIELDS_BY_OBJECT = {
    Case: ['Case.Account.CRM_Person__r.Name', 'Case.Account.CRM_Person__r.INT_ActorId__c'],
    Account: ['Account.CRM_Person__r.Name', 'Account.CRM_Person__r.INT_ActorId__c']
};

const STATUS_LABELS = {
    OPPRETTET: 'Opprettet',
    AAPNET: 'Åpen',
    UNDER_BEHANDLING: 'Under behandling',
    FERDIGSTILT: 'Ferdigstilt',
    FEILREGISTRERT: 'Feilregistrert'
};

export default class NksOppgaveTable extends NavigationMixin(LightningElement) {
    @api ownedByRunningUser = false;
    @api recordId;
    @api objectApiName;
    @api personIdent;
    @api actorId;

    data = [];
    error;
    selectedTaskScope = 'open';
    isRefreshing = false;
    isLoading = false;
    offset = 0;
    navIdent;
    recordPersonIdent;
    recordActorId;
    oppgaveCreatedSubscription;

    @wire(MessageContext) messageContext;

    @wire(getRecord, { recordId: userId, fields: [USER_NAV_IDENT_FIELD] })
    wiredUser({ data }) {
        if (data) {
            this.navIdent = getFieldValue(data, USER_NAV_IDENT_FIELD);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$personFieldsForRecord' })
    wiredPersonRecord({ data, error }) {
        if (data) {
            const fields = this.personFieldsForRecord;
            if (!fields || fields.length === 0) {
                return;
            }
            this.recordPersonIdent = getFieldValue(data, fields[0]);
            this.recordActorId = getFieldValue(data, fields[1]);
            this.loadOppgaver();
        } else if (error) {
            this.error = error;
        }
    }

    connectedCallback() {
        // No recordid => URL-addressable context
        if (!this.recordId) {
            this.loadOppgaver();
        }
        this.subscribeToOppgaveCreated();
    }

    disconnectedCallback() {
        if (this.oppgaveCreatedSubscription) {
            unsubscribe(this.oppgaveCreatedSubscription);
            this.oppgaveCreatedSubscription = null;
        }
    }

    subscribeToOppgaveCreated() {
        if (this.oppgaveCreatedSubscription) return;
        this.oppgaveCreatedSubscription = subscribe(
            this.messageContext,
            OPPGAVE_CREATED_CHANNEL,
            () => this.loadOppgaver(),
            { scope: APPLICATION_SCOPE }
        );
    }

    async loadOppgaver() {
        if (this.isLoading) {
            return;
        }
        this.isLoading = true;

        try {
            const result = await this.fetchOppgaver();
            const rows = (result || []).map((oppgave) => this.mapOppgaveToRow(oppgave));
            await Promise.all(
                rows.map(async (row) => {
                    row.oppgaveHref = await this[NavigationMixin.GenerateUrl](
                        this.buildOppgavePageReference(row.id, row.oppgavetype)
                    );
                })
            );
            this.data = rows;
            this.error = undefined;
        } catch (error) {
            this.data = [];
            this.error = error;
        } finally {
            this.isLoading = false;
        }
    }

    // TODO: Add caching maybe?
    async fetchOppgaver() {
        if (this.ownedByRunningUser) {
            if (!this.navIdent) {
                return [];
            }
            // TODO: Add apex method which fetches all assigned oppgaver regardless of status?
            return getAllAssignedOpenOppgaver({ navIdent: this.navIdent });
        }

        const ident = this.resolvedActorId || this.resolvedPersonIdent;
        if (!ident) {
            return [];
        }

        if (this.isOpenScope) {
            return getOpenOppgaver({ personIdent: ident, offset: this.offset });
        }

        return getAllOppgaver({ personIdent: ident, offset: this.offset });
    }

    mapOppgaveToRow(oppgave) {
        return {
            id: String(oppgave.id),
            oppgavetype: oppgave?.oppgavetype,
            tema: oppgave?.tema,
            gjelder: oppgave?.behandlingstema, // TODO: Fix gjelder field mapping
            status: STATUS_LABELS[oppgave?.status] ?? oppgave?.status,
            registrert: this.formatDate(oppgave?.aktivDato),
            frist: this.formatDate(oppgave?.fristFerdigstillelse),
            navEnhet: oppgave?.tildeltEnhetsnr
        };
    }

    buildOppgavePageReference(oppgaveId, oppgavetype) {
        return {
            type: 'standard__component',
            attributes: {
                componentName: 'c__crmOppgaveNavigation'
            },
            state: {
                c__oppgaveId: oppgaveId,
                c__oppgavetype: oppgavetype
            }
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

    handleRecordClick(event) {
        event.preventDefault();

        const { oppgaveid, oppgavetype } = event.currentTarget.dataset;

        if (!oppgaveid) {
            return;
        }

        this[NavigationMixin.Navigate](this.buildOppgavePageReference(oppgaveid, oppgavetype));
    }

    formatDate(value) {
        if (!value) {
            return '';
        }

        const normalizedValue = String(value).replace(' ', 'T');
        const date = new Date(normalizedValue.includes('T') ? normalizedValue : `${normalizedValue}T00:00:00.000Z`);

        if (isNaN(date.getTime())) {
            return '';
        }

        return new Intl.DateTimeFormat('nb-NO', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }).format(date);
    }

    get personFieldsForRecord() {
        if (!this.recordId || !this.objectApiName) {
            return undefined;
        }
        return PERSON_FIELDS_BY_OBJECT[this.objectApiName];
    }

    get resolvedPersonIdent() {
        return this.recordPersonIdent || this.personIdent || null;
    }

    get resolvedActorId() {
        return this.recordActorId || this.actorId || null;
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
