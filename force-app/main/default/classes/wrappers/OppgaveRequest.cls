// Invocable wrapper for flows
public class OppgaveRequest {
    @AuraEnabled
    @invocableVariable
    public Integer id;
    @AuraEnabled
    @invocableVariable
    public String tildeltEnhetsnr;
    @AuraEnabled
    @invocableVariable
    public String opprettetAvEnhetsnr;
    @AuraEnabled
    @invocableVariable
    public String journalpostId;
    @AuraEnabled
    @invocableVariable
    public String journalpostkilde;
    @AuraEnabled
    @invocableVariable
    public String behandlesAvApplikasjon;
    @AuraEnabled
    @invocableVariable
    public String tilordnetRessurs;
    @AuraEnabled
    @invocableVariable
    public String endretAvEnhetsnr;
    @AuraEnabled
    @invocableVariable(label='Beskrivelse - Only used for creating tasks, ignored for edits')
    public String beskrivelse;
    @AuraEnabled
    @invocableVariable
    public String saksreferanse;
    @AuraEnabled
    @invocableVariable
    public String tema;
    @AuraEnabled
    @invocableVariable
    public String behandlingstema;
    @AuraEnabled
    @invocableVariable
    public String behandlingstype;
    @AuraEnabled
    @invocableVariable
    public String oppgavetype;
    @AuraEnabled
    @invocableVariable
    public String fristFerdigstillelse;
    @AuraEnabled
    @invocableVariable(label='Prioritet [HOY, NORM, LAV]')
    public String prioritet;
    @AuraEnabled
    @invocableVariable(
        label='Status (only on EDIT requests) [OPPRETTET, AAPNET, UNDER_BEHANDLING, FERDIGSTILT, FEILREGISTRERT]'
    )
    public String status;
    @AuraEnabled
    @invocableVariable
    public Integer versjon;
    @AuraEnabled
    @invocableVariable
    public String personident;
    @AuraEnabled
    @invocableVariable
    public String aktoerId;
    @AuraEnabled
    @invocableVariable
    public String orgnr;
    @AuraEnabled
    @invocableVariable(label='Ekstern henvendelse ID')
    public String eksternHenvendelseId;
    @AuraEnabled
    @invocableVariable
    public String kommentarTekst;
    @AuraEnabled
    @invocableVariable
    public Boolean kommentarAutomatiskGenerert;

    // Request metadata for internal use, not mapped to Oppgave fields
    @AuraEnabled
    @invocableVariable(label='Method type [POST, PATCH]')
    public String methodType;
    @AuraEnabled
    @invocableVariable(label='Force system context for the callout')
    public Boolean POST_AS_SYSTEM = false;
    @AuraEnabled
    @invocableVariable(label='Optional log category override for webhook filtering')
    public String logCategory;

    public Oppgave toOppgave() {
        Oppgave o = new Oppgave();
        o.id = this.id;
        o.tildeltEnhetsnr = this.tildeltEnhetsnr;
        o.opprettetAvEnhetsnr = this.opprettetAvEnhetsnr;
        o.journalpostId = this.journalpostId;
        o.journalpostkilde = this.journalpostkilde;
        o.behandlesAvApplikasjon = this.behandlesAvApplikasjon;
        o.tilordnetRessurs = this.tilordnetRessurs;
        o.endretAvEnhetsnr = this.endretAvEnhetsnr;
        o.beskrivelse = this.beskrivelse;
        o.saksreferanse = this.saksreferanse;
        o.tema = this.tema;
        o.behandlingstema = this.behandlingstema;
        o.oppgavetype = this.oppgavetype;
        o.behandlingstype = this.behandlingstype;
        o.aktivDato = Datetime.now().format('yyyy-MM-dd');
        o.fristFerdigstillelse = String.isNotBlank(this.fristFerdigstillelse)
            ? this.fristFerdigstillelse
            : String.valueOf(CRM_DueDateUtility.setDueDate(this));
        o.prioritet = this.prioritet;
        o.status = String.isNotBlank(this.status) ? this.status : null;
        o.versjon = this.versjon;
        o.personident = this.personident;
        o.aktoerId = this.aktoerId;
        o.orgnr = this.orgnr;
        if (String.isNotBlank(this.eksternHenvendelseId)) {
            o.metadata = new Oppgave.OppgaveMetadata();
            o.metadata.EKSTERN_HENVENDELSE_ID = this.eksternHenvendelseId;
        }
        if (String.isNotBlank(this.kommentarTekst) || this.kommentarAutomatiskGenerert != null) {
            o.kommentar = new Oppgave.Kommentar();
            o.kommentar.tekst = this.kommentarTekst;
            o.kommentar.automatiskGenerert = this.kommentarAutomatiskGenerert;
        }
        return o;
    }
}
