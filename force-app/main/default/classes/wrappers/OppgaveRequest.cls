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
        o.tildeltEnhetsnr = blankToNull(this.tildeltEnhetsnr);
        o.opprettetAvEnhetsnr = blankToNull(this.opprettetAvEnhetsnr);
        o.journalpostId = blankToNull(this.journalpostId);
        o.journalpostkilde = blankToNull(this.journalpostkilde);
        o.behandlesAvApplikasjon = blankToNull(this.behandlesAvApplikasjon);
        o.tilordnetRessurs = blankToNull(this.tilordnetRessurs);
        o.endretAvEnhetsnr = blankToNull(this.endretAvEnhetsnr);
        o.beskrivelse = blankToNull(this.beskrivelse);
        o.saksreferanse = blankToNull(this.saksreferanse);
        o.tema = blankToNull(this.tema);
        o.behandlingstema = blankToNull(this.behandlingstema);
        o.oppgavetype = blankToNull(this.oppgavetype);
        o.behandlingstype = blankToNull(this.behandlingstype);
        o.aktivDato = Datetime.now().format('yyyy-MM-dd');
        o.fristFerdigstillelse = String.isNotBlank(this.fristFerdigstillelse)
            ? this.fristFerdigstillelse
            : String.valueOf(CRM_DueDateUtility.setDueDate(this));
        o.prioritet = blankToNull(this.prioritet);
        o.status = blankToNull(this.status);
        o.versjon = this.versjon;
        o.personident = blankToNull(this.personident);
        o.aktoerId = blankToNull(this.aktoerId);
        o.orgnr = blankToNull(this.orgnr);
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

    public OppgaveV2 toOppgaveV2() {
        OppgaveV2 o = new OppgaveV2();

        o.kategorisering = new OppgaveV2.Kategorisering();
        o.kategorisering.tema = new OppgaveV2.Kode();
        o.kategorisering.tema.kode = blankToNull(this.tema);
        o.kategorisering.oppgavetype = new OppgaveV2.Kode();
        o.kategorisering.oppgavetype.kode = blankToNull(this.oppgavetype);
        if (String.isNotBlank(this.behandlingstema)) {
            o.kategorisering.behandlingstema = new OppgaveV2.Kode();
            o.kategorisering.behandlingstema.kode = this.behandlingstema;
        }
        if (String.isNotBlank(this.behandlingstype)) {
            o.kategorisering.behandlingstype = new OppgaveV2.Kode();
            o.kategorisering.behandlingstype.kode = this.behandlingstype;
        }

        if (String.isNotBlank(this.tildeltEnhetsnr) || String.isNotBlank(this.tilordnetRessurs)) {
            o.fordeling = new OppgaveV2.Fordeling();
            if (String.isNotBlank(this.tildeltEnhetsnr)) {
                o.fordeling.enhet = new OppgaveV2.Enhet();
                o.fordeling.enhet.nr = this.tildeltEnhetsnr;
            }
            if (String.isNotBlank(this.tilordnetRessurs)) {
                o.fordeling.medarbeider = new OppgaveV2.Medarbeider();
                o.fordeling.medarbeider.navident = this.tilordnetRessurs;
            }
        }

        o.beskrivelse = blankToNull(this.beskrivelse);
        o.prioritet = convertPrioritet(this.prioritet);
        o.aktivDato = Datetime.now().format('yyyy-MM-dd');
        o.fristDato = String.isNotBlank(this.fristFerdigstillelse)
            ? this.fristFerdigstillelse
            : String.valueOf(CRM_DueDateUtility.setDueDate(this));

        if (String.isNotBlank(this.personident)) {
            o.bruker = new OppgaveV2.Bruker();
            o.bruker.ident = this.personident;
            o.bruker.type = 'PERSON';
        } else if (String.isNotBlank(this.aktoerId)) {
            o.bruker = new OppgaveV2.Bruker();
            o.bruker.ident = this.aktoerId;
            o.bruker.type = 'PERSON';
        } else if (String.isNotBlank(this.orgnr)) {
            o.bruker = new OppgaveV2.Bruker();
            o.bruker.ident = this.orgnr;
            o.bruker.type = 'ARBEIDSGIVER';
        }

        if (String.isNotBlank(this.journalpostId) || String.isNotBlank(this.saksreferanse)) {
            o.arkivreferanse = new OppgaveV2.Arkivreferanse();
            o.arkivreferanse.journalpostId = blankToNull(this.journalpostId);
            o.arkivreferanse.saksnr = blankToNull(this.saksreferanse);
        }

        if (String.isNotBlank(this.kommentarTekst) || String.isNotBlank(this.opprettetAvEnhetsnr)) {
            o.meta = new OppgaveV2.PostMeta();
            o.meta.kommentar = blankToNull(this.kommentarTekst);
            if (String.isNotBlank(this.opprettetAvEnhetsnr)) {
                o.meta.representerer = new OppgaveV2.Representerer();
                o.meta.representerer.enhet = new OppgaveV2.Enhet();
                o.meta.representerer.enhet.nr = this.opprettetAvEnhetsnr;
            }
        }

        if (String.isNotBlank(this.eksternHenvendelseId)) {
            o.utvidelser = new OppgaveV2.Utvidelser();
            o.utvidelser.henvendelseId = this.eksternHenvendelseId;
        }

        return o;
    }

    private String convertPrioritet(String prioritet) {
        if (prioritet == null) {
            return null;
        }
        if (prioritet.equalsIgnoreCase('NORM')) {
            return 'NORMAL';
        }
        return prioritet.toUpperCase();
    }

    // Prevent serializing empty string values to the API, as this can cause validation errors for certain fields
    private String blankToNull(String value) {
        return String.isNotBlank(value) ? value : null;
    }
}
