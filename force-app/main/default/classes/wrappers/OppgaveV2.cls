public class OppgaveV2 {
    @AuraEnabled
    public Integer id;
    @AuraEnabled
    public String prioritet;
    @AuraEnabled
    public String beskrivelse;
    @AuraEnabled
    public String aktivDato;
    @AuraEnabled
    public String fristDato;
    @AuraEnabled
    public Integer versjon;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Arkivreferanse arkivreferanse;
    @AuraEnabled
    public String tilknyttetSystem;
    @AuraEnabled
    public Kategorisering kategorisering;
    @AuraEnabled
    public Fordeling fordeling;
    @AuraEnabled
    public Bruker bruker;
    @AuraEnabled
    public Tidspunkt opprettet;
    @AuraEnabled
    public Tidspunkt endret;
    @AuraEnabled
    public Tidspunkt avsluttet;
    @AuraEnabled
    public List<Kommentar> kommentarer;

    public class Kategorisering {
        @AuraEnabled
        public Kode tema;
        @AuraEnabled
        public Kode oppgavetype;
        @AuraEnabled
        public Kode behandlingstema;
        @AuraEnabled
        public Kode behandlingstype;
    }

    public class Kode {
        @AuraEnabled
        public String kode;
        @AuraEnabled
        public String term;
    }

    public class Fordeling {
        @AuraEnabled
        public Enhet enhet;
        @AuraEnabled
        public Medarbeider medarbeider;
        public Object mappe;
    }

    public class Enhet {
        @AuraEnabled
        public String nr;
    }

    public class Medarbeider {
        @AuraEnabled
        public String navident;
    }

    public class Bruker {
        @AuraEnabled
        public String ident;
        @AuraEnabled
        public String type;
    }

    public class Tidspunkt {
        @AuraEnabled
        public String tidspunkt;
        @AuraEnabled
        public TidspunktAv av;
    }

    public class TidspunktAv {
        @AuraEnabled
        public Enhet enhet;
        @AuraEnabled
        public Medarbeider medarbeider;
        @AuraEnabled
        public String systemKilde;
    }

    public class Kommentar {
        @AuraEnabled
        public String tekst;
        @AuraEnabled
        public Tidspunkt opprettet;
    }

    public class Arkivreferanse {
        @AuraEnabled
        public String saksnr;
        @AuraEnabled
        public String journalpostId;
    }
}
