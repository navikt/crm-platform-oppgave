public class Oppgave {
    public Integer id;
    public String tildeltEnhetsnr; //Enheten oppgaven er tildelt. Dersom enhet ikke er angitt, så vil oppgaven automatisk fordeles iht. standard arbeidsfordelingsregler (se norg2)
    public String opprettetAvEnhetsnr;
    public String journalpostId;
    public String journalpostkilde;
    public String behandlesAvApplikasjon;
    public String tilordnetRessurs;
    public String endretAvEnhetsnr; // Unit Number fra User
    public String beskrivelse;
    public String saksreferanse;
    public String tema;
    public String behandlingstema;
    public String oppgavetype; // REQUIRED
    public String behandlingstype;
    public String aktivDato; //Datestring, REQUIRED
    public String fristFerdigstillelse; //Datestring
    public String prioritet; // [HOY, NORM, LAV],
    public String opprettetTidspunkt; //Datetime String
    public OppgaveStatuskategori status; //ENUM: [OPPRETTET, AAPNET, UNDER_BEHANDLING, FERDIGSTILT, FEILREGISTRERT]
    public Integer versjon;
    public List<Ident> identer; //To-be model
    public LegacyIdent ident;
    public String personIdent;
    public OppgaveMetadata metadata;
    public String aktoerId;
    public String orgnr;
    public Kommentar kommentar;

    public class OppgaveMetadata {
        public String EKSTERN_HENVENDELSE_ID;
    }

    public class Kommentar {
        public String tekst;
        public Boolean automatiskGenerert;
    }

    public class Ident {
        public String ident;
        public String gruppe;
    }

    public class LegacyIdent {
        public String identType;
        public String verdi;
    }
}