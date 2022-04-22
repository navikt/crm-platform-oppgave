public class CRM_OppgaveQuery {
    public String id; //Matches the INT_External_Reference__c on NavTask__c
    public String aktoerId;
    public String orgnr;
    public OppgaveStatuskategori statuskategori;
    public String tildeltEnhetsnr;
    public String tilordnetRessurs;
    public Integer returnlimit;
    public Date fristFom;
    public Date fristTom;
    public Datetime opprettetFom; //Lower limit for the oppgave created date
}
