// Swagger: https://oppgave.intern.dev.nav.no/#/Oppgave
public class Oppgave {
    @AuraEnabled
    public Integer id;
    @AuraEnabled
    public String tildeltEnhetsnr; //Enheten oppgaven er tildelt. Dersom enhet ikke er angitt, så vil oppgaven automatisk fordeles iht. standard arbeidsfordelingsregler (se norg2)
    @AuraEnabled
    public String opprettetAvEnhetsnr;
    @AuraEnabled
    public String journalpostId;
    @AuraEnabled
    public String journalpostkilde;
    @AuraEnabled
    public String behandlesAvApplikasjon;
    @AuraEnabled
    public String tilordnetRessurs;
    @AuraEnabled
    public String endretAvEnhetsnr; // Unit Number fra User
    @AuraEnabled
    public String beskrivelse;
    @AuraEnabled
    public String beskrivelseAvOppgaven;
    @AuraEnabled
    public String saksreferanse;
    @AuraEnabled
    public String tema;
    @AuraEnabled
    public String behandlingstema;
    @AuraEnabled
    public String oppgavetype; // REQUIRED
    @AuraEnabled
    public String behandlingstype;
    @AuraEnabled
    public String aktivDato; //Datestring, REQUIRED
    @AuraEnabled
    public String fristFerdigstillelse; //Datestring
    @AuraEnabled
    public String prioritet; // [HOY, NORM, LAV],
    @AuraEnabled
    public String opprettetTidspunkt; //Datetime String
    @AuraEnabled
    public OppgaveStatuskategori status; //ENUM: [OPPRETTET, AAPNET, UNDER_BEHANDLING, FERDIGSTILT, FEILREGISTRERT]
    @AuraEnabled
    public Integer versjon;
    @AuraEnabled
    public List<Ident> identer;
    @AuraEnabled
    public LegacyIdent ident;
    @AuraEnabled
    public String personIdent;
    @AuraEnabled
    public OppgaveMetadata metadata; // Hidden in Swagger, but still in use
    @AuraEnabled
    public String aktoerId;
    @AuraEnabled
    public String orgnr;
    @AuraEnabled
    public Kommentar kommentar;
    @AuraEnabled
    public Bruker bruker;

    public class OppgaveMetadata {
        public String EKSTERN_HENVENDELSE_ID;
    }

    public class Kommentar {
        public String tekst;
        public Boolean automatiskGenerert;
    }

    // Hidden in Swagger, but still in use
    public class Ident {
        public String ident;
        public String gruppe;
    }

    // Hidden in Swagger, but still in use
    public class LegacyIdent {
        public String identType;
        public String verdi;
    }

    public class Bruker {
        @AuraEnabled
        public String ident;
        @AuraEnabled
        public String type; //ENUM: [ PERSON, ARBEIDSGIVER, SAMHANDLER ]
    }
}
