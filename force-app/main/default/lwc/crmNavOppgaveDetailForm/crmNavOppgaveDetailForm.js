import { LightningElement, api, wire } from 'lwc';
import getCategorization from '@salesforce/apex/CRM_ThemeUtils.getCategorizationByThemeSet';
import getUserNavUnit from '@salesforce/apex/CRM_NavTaskWorkAllocationController.getUserNavUnit';

const PRIORITET_OPTIONS = [
    { label: 'Høy', value: 'HOY' },
    { label: 'Normal', value: 'NORMAL' },
    { label: 'Lav', value: 'LAV' }
];

export default class CrmNavOppgaveDetailForm extends LightningElement {
    @api isSaving;
    @api errorMessage;

    formData = {};
    prioritetOptions = PRIORITET_OPTIONS;
    navUnitId;
    navUnitDisplayInfo = { additionalFields: ['INT_UnitNumber__c'] };
    navUnitMatchingInfo = {
        primaryField: { fieldPath: 'Name', mode: 'contains' },
        additionalFields: [{ fieldPath: 'INT_UnitNumber__c', mode: 'startsWith' }]
    };
    navUnitFilter = {
        criteria: [{ fieldPath: 'INT_UnitNumber__c', operator: 'ne', value: '4252' }]
    };
    currentThemeId;
    themeMap;
    isEdited = false;
    showForm = true;
    _oppgave;
    unitNumber;

    @wire(getCategorization, { themeSet: 'ARCHIVE_THEMES' })
    wiredCategories({ data }) {
        if (data) {
            this.themeMap = data.themeMap;
            this.getCurrentTheme();
        }
    }

    @wire(getUserNavUnit, { userUnitNumber: '$unitNumber' })
    wiredNavUnit({ data }) {
        if (data) {
            this.navUnitId = data.Id;
        }
    }

    getCurrentTheme() {
        if (!this._oppgave || !this._oppgave.kategorisering?.tema?.kode || !this.themeMap) return;
        const temaCode = this._oppgave.kategorisering.tema.kode;
        for (const themeGroupId of Object.keys(this.themeMap)) {
            const themes = this.themeMap[themeGroupId];
            if (!Array.isArray(themes)) continue;
            const match = themes.find((t) => t.CRM_Code__c === temaCode);
            if (match) {
                this.currentThemeId = match.Id;
                return;
            }
        }
    }

    handleEdited() {
        this.isEdited = true;
    }

    handleReset() {
        this.formData = {
            tema: this._oppgave.kategorisering?.tema?.kode,
            oppgavetype: this._oppgave.kategorisering?.oppgavetype?.kode,
            prioritet: this._oppgave.prioritet,
            tildeltEnhetsnr: this._oppgave.fordeling?.enhet?.nr,
            tilordnetRessurs: this._oppgave.fordeling?.medarbeider?.navident,
            fristDato: this._oppgave.fristDato ? this._oppgave.fristDato.substring(0, 10) : null,
            beskrivelse: this._oppgave.beskrivelse,
            opprettetTidspunkt: this._oppgave.opprettet?.tidspunkt
        };
        this.getCurrentTheme();
        this.isEdited = false;
        this.showForm = false;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.showForm = true;
        }, 0);
    }

    handleFieldChange(event) {
        const field = event.currentTarget.dataset.field;
        const value = event.detail?.recordId ?? event.detail?.value ?? event.target.value;
        this.formData = { ...this.formData, [field]: value };
        this.isEdited = true;
    }

    handleNavUnitChange(event) {
        const recordId = event.detail?.recordId;
        this.navUnitId = recordId;
        const record = event.detail?.record;
        const unitNumber = record?.fields?.INT_UnitNumber__c?.value ?? null;
        this.formData = { ...this.formData, tildeltEnhetsnr: unitNumber };
        this.isEdited = true;
    }

    handleSave() {
        const themeCmp = this.template.querySelector('c-crm-oppgave-theme-categorization');
        const tema = themeCmp && themeCmp.themeCode ? themeCmp.themeCode : null;
        const behandlingstema = themeCmp ? themeCmp.subthemeCode : null;
        const behandlingstype = themeCmp ? themeCmp.subtypeCode : null;
        const taskTypeCmp = this.template.querySelector('c-crm-task-type-picklist');
        const oppgavetype = taskTypeCmp ? taskTypeCmp.selectedTaskType : null;
        this.isEdited = false;
        this.dispatchEvent(
            new CustomEvent('save', {
                detail: {
                    ...this.formData,
                    tema,
                    behandlingstema,
                    behandlingstype,
                    oppgavetype
                }
            })
        );
    }

    @api
    get oppgave() {
        return this._oppgave;
    }
    set oppgave(value) {
        this._oppgave = value;
        if (value) {
            this.unitNumber = value.fordeling?.enhet?.nr ?? null;
            this.formData = {
                tema: value.kategorisering?.tema?.kode,
                oppgavetype: value.kategorisering?.oppgavetype?.kode,
                prioritet: value.prioritet,
                tildeltEnhetsnr: value.fordeling?.enhet?.nr,
                tilordnetRessurs: value.fordeling?.medarbeider?.navident,
                fristDato: value.fristDato ? value.fristDato.substring(0, 10) : null,
                beskrivelse: value.beskrivelse,
                opprettetTidspunkt: value.opprettet?.tidspunkt
            };
            this.isEdited = false;
            this.getCurrentTheme();
        }
    }

    get registrertFormatted() {
        if (!this.formData.opprettetTidspunkt) return null;
        return new Date(this.formData.opprettetTidspunkt).toLocaleString('nb-NO', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    get isCompleted() {
        return this._oppgave?.status === 'FERDIGSTILT';
    }

    get errorText() {
        if (!this.errorMessage) return null;
        const msg = this.errorMessage.errorMessage ?? 'Ukjent feil';
        const base = `Endring av oppgave feilet med feilmelding: ${msg}`;
        if (this.errorMessage.isRetry) {
            return `${base}.\n En utvikler har fått beskjed og vil feilsøke dette.\nOppgaven vil bli automatisk rekjørt på et senere tidspunkt.`;
        }
        return base;
    }

    get isSaveDisabled() {
        return !this.isEdited || this.isSaving || this.isCompleted;
    }
}
