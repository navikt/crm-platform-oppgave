public class CRM_KafkaOppgave implements Comparable {
    public Integer id;
    public String tildeltEnhetsnr; //Enheten oppgaven er tildelt. Dersom enhet ikke er angitt, så vil oppgaven automatisk fordeles iht. standard arbeidsfordelingsregler (se norg2)
    public String opprettetAvEnhetsnr;
    public String journalpostId;
    public String journalpostkilde;
    public String behandlesAvApplikasjon;
    public String tilordnetRessurs;
    public String beskrivelse;
    public String tema;
    public String behandlingstema;
    public String oppgavetype; // REQUIRED
    public String behandlingstype;
    public String aktivDato; //Datestring, REQUIRED
    public String fristFerdigstillelse; //Datestring
    public String prioritet; // [HOY, NORM, LAV],
    public String opprettetTidspunkt; //Datetime String
    public String status; //ENUM: [OPPRETTET, AAPNET, UNDER_BEHANDLING, FERDIGSTILT, FEILREGISTRERT]
    public Integer versjon;
    public List<Ident> identer; //To-be model
    public LegacyIdent ident;

    public Integer compareTo(Object compareToObj) {
        CRM_KafkaOppgave compareOppg = (CRM_KafkaOppgave) compareToObj;

        Integer returnValue = 0;
        if (versjon > compareOppg.versjon) {
            returnValue = 1;
        } else if (versjon > compareOppg.versjon) {
            returnValue = -1;
        }

        return returnValue;
    }

    public class Ident {
        public String ident;
        public String gruppe;
    }

    public class LegacyIdent {
        public String identType;
        public String verdi;
    }

    public String getActorId() {
        String actorId;
        if (
            ident != null &&
            String.isNotBlank(this.ident.identType) &&
            this.ident.identType.equalsIgnoreCase('AKTOERID')
        ) {
            actorId = this.ident.verdi;
        } else {
            for (Ident idt : this.identer) {
                if (String.isNotBlank(idt.gruppe) && idt.gruppe.equalsIgnoreCase('AKTOERID')) {
                    actorId = idt.ident;
                }
            }
        }

        return actorId;
    }
}
