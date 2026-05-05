import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import userId from '@salesforce/user/Id';
import USER_NAV_IDENT_FIELD from '@salesforce/schema/User.CRM_NAV_Ident__c';
import getAllOppgaver from '@salesforce/apex/OppgaveManager.getAllOppgaver';
import getOpenOppgaver from '@salesforce/apex/OppgaveManager.getOpenOppgaver';
import getAllAssignedOpenOppgaver from '@salesforce/apex/OppgaveManager.getAllAssignedOpenOppgaver';
import getGjelderNames from '@salesforce/apex/OppgaveManager.getGjelderNames';
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

const COLUMNS = [
    { field: 'oppgavetype', label: 'Oppgavetype' },
    { field: 'tema', label: 'Tema' },
    { field: 'gjelder', label: 'Gjelder' },
    { field: 'status', label: 'Status' },
    { field: 'registrert', label: 'Registrert' },
    { field: 'frist', label: 'Frist' },
    { field: 'navEnhet', label: 'Nav enhet' }
];

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
    hasLoaded = false;
    offset = 0;
    navIdent;
    recordPersonIdent;
    recordActorId;
    oppgaveCreatedSubscription;
    sortField;
    sortDirection = 'asc';

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
        console.log(this.ownedByRunningUser);
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
            const oppgaver = result || [];
            const gjelderNames = await this.fetchGjelderNames(oppgaver);
            const rows = oppgaver.map((oppgave) => this.mapOppgaveToRow(oppgave, gjelderNames));
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
            this.hasLoaded = true;
        }
    }

    async fetchGjelderNames(oppgaver) {
        const codes = new Set();
        oppgaver.forEach((o) => {
            if (o?.behandlingstema) codes.add(o.behandlingstema);
            if (o?.behandlingstype) codes.add(o.behandlingstype);
        });
        if (codes.size === 0) {
            return {};
        }
        try {
            return await getGjelderNames({ codes: [...codes] });
        } catch (e) {
            return {};
        }
    }

    // TODO: Query nav units og tema og mellomlagre så vi ikke trenger querye alt på nytt ved last mer
    // TODO: Add caching maybe?
    // TODO: Add lazy loading
    async fetchOppgaver() {
        if (this.isAssignedOnlyMode) {
            if (!this.navIdent) {
                return [];
            }
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

    mapOppgaveToRow(oppgave, gjelderNames = {}) {
        return {
            id: String(oppgave.id),
            oppgavetype: oppgave?.oppgavetype,
            tema: oppgave?.tema,
            gjelder: this.buildGjelder(oppgave, gjelderNames),
            status: STATUS_LABELS[oppgave?.status] ?? oppgave?.status,
            registrert: this.formatDate(oppgave?.opprettetTidspunkt),
            frist: this.formatDate(oppgave?.fristFerdigstillelse),
            navEnhet: oppgave?.tildeltEnhetsnr,
            tilordnetRessurs: oppgave?.tilordnetRessurs
        };
    }

    buildGjelder(oppgave, gjelderNames) {
        const temaCode = oppgave?.behandlingstema;
        const typeCode = oppgave?.behandlingstype;
        const temaName = temaCode ? (gjelderNames[temaCode] ?? temaCode) : null;
        const typeName = typeCode ? (gjelderNames[typeCode] ?? typeCode) : null;
        if (temaName && typeName) {
            return `${temaName} - ${typeName}`;
        }
        return temaName || typeName || '';
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

    handleSort(event) {
        const field = event.currentTarget.dataset.field;
        if (!field) {
            return;
        }
        if (this.sortField === field) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortField = field;
            this.sortDirection = 'asc';
        }
    }

    getSortValue(row, field) {
        if (field === 'registrert' || field === 'frist') {
            const value = row[field];
            if (!value) return '';
            const [day, month, year] = value.split('.');
            return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
        }
        const value = row[field];
        return value == null ? '' : String(value).toLowerCase();
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
        return this.hasLoaded && !this.isLoading && !this.error && this.displayData.length === 0;
    }

    get isAssignedOnlyMode() {
        console.log(this.ownedByRunningUser);
        return !this.recordId && this.ownedByRunningUser;
    }

    get showControls() {
        return !this.isAssignedOnlyMode;
    }

    get displayData() {
        let rows = this.data;
        if (this.ownedByRunningUser && !this.isAssignedOnlyMode && this.navIdent) {
            rows = rows.filter((row) => row.tilordnetRessurs === this.navIdent);
        }
        if (!this.sortField) {
            return rows;
        }
        const field = this.sortField;
        const direction = this.sortDirection === 'desc' ? -1 : 1;
        return [...rows].sort((a, b) => {
            const av = this.getSortValue(a, field);
            const bv = this.getSortValue(b, field);
            if (av < bv) return -1 * direction;
            if (av > bv) return 1 * direction;
            return 0;
        });
    }

    get sortableHeaders() {
        return COLUMNS.map((col) => {
            const isSorted = this.sortField === col.field;
            let iconName = 'utility:arrowdown';
            if (isSorted) {
                iconName = this.sortDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
            }
            return {
                ...col,
                iconName,
                buttonClass: isSorted
                    ? 'task-table__sort-button task-table__sort-button_active'
                    : 'task-table__sort-button'
            };
        });
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
