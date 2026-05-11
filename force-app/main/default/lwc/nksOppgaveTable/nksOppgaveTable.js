import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import userId from '@salesforce/user/Id';
import USER_NAV_IDENT_FIELD from '@salesforce/schema/User.CRM_NAV_Ident__c';
import getAllOppgaver from '@salesforce/apex/OppgaveManager.getAllOppgaver';
import getOpenOppgaver from '@salesforce/apex/OppgaveManager.getOpenOppgaver';
import getAllAssignedOpenOppgaver from '@salesforce/apex/OppgaveManager.getAllAssignedOpenOppgaver';
import getCommonCodeNames from '@salesforce/apex/OppgaveManager.getCommonCodeNames';
import getNavUnitNames from '@salesforce/apex/OppgaveManager.getNavUnitNames';
import OPPGAVE_CREATED_CHANNEL from '@salesforce/messageChannel/oppgaveCreated__c';

const PERSON_FIELDS_BY_OBJECT = {
    Case: ['Case.Account.CRM_Person__r.Name', 'Case.Account.CRM_Person__r.INT_ActorId__c'],
    Account: ['Account.CRM_Person__r.Name', 'Account.CRM_Person__r.INT_ActorId__c']
};

const STATUS_LABELS = {
    AVSLUTTET: 'Ferdigstilt',
    OPPRETTET: 'Åpen',
    AAPEN: 'Åpen',
    AAPNET: 'Åpen',
    UNDER_BEHANDLING: 'Under behandling',
    FERDIGSTILT: 'Ferdigstilt',
    FEILREGISTRERT: 'Feilregistrert'
};

const INITIAL_VISIBLE = 10;
const LOAD_MORE_INCREMENT = 50;
const APEX_QUERY_LIMIT = 200;

const COLUMNS = [
    { field: 'oppgavetype', label: 'Type' },
    { field: 'tema', label: 'Tema' },
    { field: 'gjelder', label: 'Gjelder' },
    { field: 'status', label: 'Status' },
    { field: 'registrert', label: 'Registrert' },
    { field: 'frist', label: 'Frist' },
    { field: 'navEnhet', label: 'Enhet' }
];

export default class NksOppgaveTable extends NavigationMixin(LightningElement) {
    @api ownedByRunningUser = false;
    @api recordId;
    @api objectApiName;
    @api ytelser;

    _personIdent;
    _actorId;

    @api
    get personIdent() {
        return this._personIdent;
    }
    set personIdent(value) {
        this._personIdent = value;
        if (!this.recordId && value) {
            this.loadOppgaver();
        }
    }

    @api
    get actorId() {
        return this._actorId;
    }
    set actorId(value) {
        this._actorId = value;
        if (!this.recordId && value) {
            this.loadOppgaver();
        }
    }

    data = [];
    error;
    selectedTaskScope = 'open';
    isRefreshing = false;
    isLoading = false;
    isLoadingMore = false;
    hasLoaded = false;
    offset = 0;
    visibleCount = INITIAL_VISIBLE;
    serverHasMore = false;
    navIdent;
    recordPersonIdent;
    recordActorId;
    oppgaveCreatedSubscription;
    sortField = 'registrert';
    sortDirection = 'desc';
    commonCodeNames = {};
    navUnitNames = {};
    commonCodesReady = new Promise((resolve) => (this.resolveCommonCodes = resolve));
    navUnitsReady = new Promise((resolve) => (this.resolveNavUnits = resolve));

    @wire(MessageContext) messageContext;

    @wire(getCommonCodeNames)
    wiredCommonCodeNames({ data }) {
        if (data) {
            this.commonCodeNames = data;
            this.resolveCommonCodes();
        }
    }

    @wire(getNavUnitNames)
    wiredNavUnitNames({ data }) {
        if (data) {
            this.navUnitNames = data;
            this.resolveNavUnits();
        }
    }

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
        // Skip the load if we're waiting for personIdent/actorId to arrive async; the setters will trigger it.
        if (!this.recordId && (this.isAssignedOnlyMode || this.resolvedPersonIdent || this.resolvedActorId)) {
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
            (message) => {
                if (message?.actorId !== this.resolvedActorId) return;
                this.loadOppgaver();
            },
            { scope: APPLICATION_SCOPE }
        );
    }

    async loadOppgaver() {
        if (this.isLoading) {
            return;
        }
        this.isLoading = true;
        this.offset = 0;
        this.visibleCount = INITIAL_VISIBLE;

        try {
            const oppgaver = (await this.fetchOppgaver()) || [];
            await this.waitForWires();
            this.serverHasMore = this.canPaginate && oppgaver.length === APEX_QUERY_LIMIT;
            this.offset = oppgaver.length;
            this.data = await this.buildRows(oppgaver);
            this.error = undefined;
        } catch (error) {
            this.data = [];
            this.error = error;
            this.serverHasMore = false;
        } finally {
            this.isLoading = false;
            this.hasLoaded = true;
        }
    }

    // Wait for wires before rendering the table so that we have all the common code and nav unit data first
    waitForWires() {
        return Promise.all([this.commonCodesReady, this.navUnitsReady]);
    }

    async loadMoreFromServer() {
        if (this.isLoadingMore || !this.serverHasMore) {
            return;
        }
        this.isLoadingMore = true;
        try {
            const oppgaver = (await this.fetchOppgaver()) || [];
            this.serverHasMore = oppgaver.length === APEX_QUERY_LIMIT;
            this.offset += oppgaver.length;
            const newRows = await this.buildRows(oppgaver);
            this.data = [...this.data, ...newRows];
        } catch (error) {
            this.error = error;
            this.serverHasMore = false;
        } finally {
            this.isLoadingMore = false;
        }
    }

    async buildRows(oppgaver) {
        const rows = oppgaver.map((oppgave) => this.mapOppgaveToRow(oppgave));
        await Promise.all(
            rows.map(async (row) => {
                row.oppgaveHref = await this[NavigationMixin.GenerateUrl](
                    this.buildOppgavePageReference(row.id, row.oppgavetype)
                );
            })
        );
        return rows;
    }

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
            return getOpenOppgaver({ personIdent: ident, offset: this.offset, ytelser: this.ytelserArray });
        }

        return getAllOppgaver({ personIdent: ident, offset: this.offset, ytelser: this.ytelserArray });
    }

    mapOppgaveToRow(oppgave) {
        const oppgavetypeCode = oppgave?.oppgavetype;
        const temaCode = oppgave?.tema;
        const behandlingstemaCode = oppgave?.behandlingstema;
        const behandlingstypeCode = oppgave?.behandlingstype;
        const enhetsnr = oppgave?.tildeltEnhetsnr;
        const enhetName = enhetsnr ? this.navUnitNames[enhetsnr] : null;
        return {
            id: String(oppgave.id),
            oppgavetypeCode,
            oppgavetype: oppgavetypeCode ? (this.commonCodeNames[oppgavetypeCode] ?? oppgavetypeCode) : '',
            tema: temaCode ? (this.commonCodeNames[temaCode] ?? temaCode) : '',
            gjelder: this.buildGjelderFromCodes(behandlingstemaCode, behandlingstypeCode),
            status: STATUS_LABELS[oppgave?.status] ?? oppgave?.status,
            statusIconClass: `task-table__status-dot task-table__status-dot_${oppgave?.status ?? 'AAPNET'}`,
            registrert: this.formatDate(oppgave?.opprettetTidspunkt),
            frist: this.formatDate(oppgave?.fristFerdigstillelse),
            navEnhet: enhetsnr ? (enhetName ? `${enhetsnr} ${enhetName}` : enhetsnr) : '',
            tilordnetRessurs: oppgave?.tilordnetRessurs
        };
    }

    buildGjelderFromCodes(behandlingstemaCode, behandlingstypeCode) {
        const temaName = behandlingstemaCode
            ? (this.commonCodeNames[behandlingstemaCode] ?? behandlingstemaCode)
            : null;
        const typeName = behandlingstypeCode
            ? (this.commonCodeNames[behandlingstypeCode] ?? behandlingstypeCode)
            : null;
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

    async handleLoadMore() {
        const target = this.visibleCount + LOAD_MORE_INCREMENT;
        const filteredLength = this.filteredAndSortedData.length;
        if (target > filteredLength && this.serverHasMore) {
            await this.loadMoreFromServer();
        }
        this.visibleCount = Math.min(target, this.filteredAndSortedData.length);
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

    get ytelserArray() {
        if (!this.ytelser) return null;
        if (Array.isArray(this.ytelser)) {
            return this.ytelser.length ? this.ytelser : null;
        }
        const list = String(this.ytelser)
            .split(',')
            .map((y) => y.trim())
            .filter((y) => y);
        return list.length ? list : null;
    }

    get hasNoRows() {
        return this.hasLoaded && !this.isLoading && !this.error && this.displayData.length === 0;
    }

    get canPaginate() {
        return !this.isAssignedOnlyMode;
    }

    get hasMore() {
        if (!this.hasLoaded) return false;
        if (this.filteredAndSortedData.length === 0) return false; // since "mine" filtering is client-side, it means that if none of the currently loaded oppgaver are assigned to user, the user can't paginate further to look for matches
        return this.serverHasMore || this.filteredAndSortedData.length > this.visibleCount;
    }

    get isLoadMoreDisabled() {
        return this.isLoading || this.isLoadingMore;
    }

    get isAssignedOnlyMode() {
        return !this.hasPersonContext && this.ownedByRunningUser;
    }

    // False if user is on assigned only from home screen
    get hasPersonContext() {
        return Boolean(this.recordId || this.resolvedPersonIdent || this.resolvedActorId);
    }

    get showControls() {
        return !this.isAssignedOnlyMode;
    }

    get filteredAndSortedData() {
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

    get displayData() {
        return this.filteredAndSortedData.slice(0, this.visibleCount);
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
