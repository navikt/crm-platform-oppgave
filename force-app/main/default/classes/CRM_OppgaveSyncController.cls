public without sharing class CRM_OppgaveSyncController {
    private static LoggerUtility logger = new LoggerUtility('Oppgave');

    @AuraEnabled(cacheable=true)
    public static void doOppgaveSync(CRM_OppgaveQuery query) {
        CRM_OppgaveQueryResponse oppgaveResp;
        query.opprettetFom = query.opprettetFom == null ? System.now().addYears(-1) : null; //Get oppgaver for the given actor created maximum og one year back in time
        CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();

        try {
            HttpResponse response = oppgaveService.queryOppgave(query);
            Integer statusCode = response.getStatusCode();

            if (statusCode == 200 || statusCode == 201) {
                oppgaveResp = (CRM_OppgaveQueryResponse) JSON.deserialize(
                    response.getBody(),
                    CRM_OppgaveQueryResponse.class
                );

                doNavTaskUpsert(oppgaveResp.convertToNavTasks());
            } else {
                logger.httpError(
                    'Error getting oppgaver',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
            }
        } catch (Exception ex) {
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        } finally {
            logger.publish();
        }
    }

    private static void doNavTaskUpsert(List<NavTask__c> tasksToUpsert) {
        Schema.SObjectField extRef = NavTask__c.Fields.INT_External_Reference__c;

        List<Database.UpsertResult> upsList = Database.upsert(tasksToUpsert, extRef, false);
        verifyUpsertResults(upsList, tasksToUpsert);
    }

    /**
     * @description: Verifies the upsert results and updates the KafkaMessages with
     * Correct status and error messages.
     * @author Stian Ruud Schikora | 02-26-2021
     * @param upsList
     * @param taskList
     **/
    private static void verifyUpsertResults(List<Database.UpsertResult> upsList, List<NavTask__c> taskList) {
        for (Integer index = 0; index < upsList.size(); index++) {
            if (upsList[index].isSuccess()) {
                //Successful upsert
            } else {
                for (Database.Error error : upsList[index].getErrors()) {
                    logger.error(
                        'Error syncing oppgave: ' + error.getMessage(),
                        null,
                        CRM_ApplicationDomain.Domain.NKS
                    );
                }
            }
        }
    }
}
