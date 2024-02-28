public with sharing class CRM_OppgaveOppfolging {
    public Integer id;
    public String kommentar;
    public String opprettetAv;
    public String endretAv;
    public String opprettetTidspunkt;
    public String endretTidspunkt;

    public List<NavTask__c> convertToNavTasks() {
        if (this == null) {
            return null;
        }

        List<NavTask__c> returnList = new List<NavTask__c>();
        NavTask__c oppgave = new NavTask__c();
        oppgave.INT_External_Reference__c = this.id;
        oppgave.Comment__c = this.kommentar;
        returnList.add(oppgave);
        
        return returnList;
    }
}