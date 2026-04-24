public with sharing class OppgaveRetry_Batch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private String query;

    public OppgaveRetry_Batch() {
        this.query = 'SELECT Id, Method__c, Status__c, Payload__c, CreatedDate FROM Scheduled_Request__c WHERE Status__c = \'Scheduled\' and Domain__c = \'NKS\'';
    }
    public OppgaveRetry_Batch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Scheduled_Request__c> oppgaveRequestList = (List<Scheduled_Request__c>) scope;
        LoggerUtility logger = new LoggerUtility('OppgaveRetry_Batch');
        try {
            OppgaveRetry.retryScheduledRequest(oppgaveRequestList);
        } catch (Exception ex) {
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        }
        logger.publish();
    }

    public void finish(Database.BatchableContext BC) {
        // No post-processing needed after batch completes
    }
}
