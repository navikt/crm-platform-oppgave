public with sharing class NKS_OppgaveManager {
    @AuraEnabled
    public static List<CRM_OppgaveOppfolging> getOppgaveOppfolging(String oppgaveId) {
        return null;
    }

    @AuraEnabled
    public static NKS_Oppgave getOppgaveById(String oppgaveId)  {
        return null;
    }

    @AuraEnabled
    public static List<NKS_Oppgave> getAllAssignedOpenOppgaver(String navident) {
        return null;
    }

    @AuraEnabled
    public static List<NKS_Oppgave> getOpenOppgaver(Id personId, Integer offset) {
        return null;
    }

    @AuraEnabled
    public static List<NKS_Oppgave> getAllOppgaver(Id personId, Integer offset) {
        return null;
    }
}