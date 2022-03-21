public class CRM_OppgaveQuery {
    public String id; //Matches the INT_External_Reference__c on NavTask__c
    public String aktoerId;
    public String orgnr;
    public OppgaveStatuskategori statuskategori;
    public String tildeltEnhetsnr;
    public String tilordnetRessurs;
    public Date fristFom;
    public Date fristTom;
    public Date opprettetFom; //Lower limit for the oppgave created date
}
