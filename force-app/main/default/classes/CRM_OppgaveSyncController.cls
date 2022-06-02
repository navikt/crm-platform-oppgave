public without sharing class CRM_OppgaveSyncController {
    private static LoggerUtility logger = new LoggerUtility('Oppgave');

    @InvocableMethod(label='Get Oppgave By ID' category='Task Handling')
    public static List<Id> handleNavTaskRequests(List<String> oppgaveIds) {
        String oppgaveRef = oppgaveIds[0];
        Id retId;
        CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();

        try {
            HttpResponse response = oppgaveService.getOppgaveById(oppgaveRef);
            Integer statusCode = response.getStatusCode();
            if (statusCode == 200 || statusCode == 201) {
                CRM_KafkaOppgave kfOppg = (CRM_KafkaOppgave) JSON.deserialize(
                    response.getBody(),
                    CRM_KafkaOppgave.class
                );

                //Using the oppgave query response wrapper to convert and insert NAV Task
                CRM_OppgaveQueryResponse queryResp = new CRM_OppgaveQueryResponse();
                queryResp.antallTreffTotalt = 1;
                queryResp.oppgaver = new List<CRM_KafkaOppgave>{ kfOppg };
                List<NavTask__c> navTaskList = queryResp.convertToNavTasks();

                doNavTaskUpsert(navTaskList);
                retId = navTaskList[0].Id;
            } else {
                logger.httpError(
                    'Error getting oppgave by ID',
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

        return new List<Id>{ retId };
    }

    @AuraEnabled
    public static void doOppgaveSync(String jsonQuery) {
        CRM_OppgaveQueryResponse oppgaveResp;
        CRM_OppgaveQuery query = (CRM_OppgaveQuery) JSON.deserialize(jsonQuery, CRM_OppgaveQuery.class);
        query.opprettetFom = query.opprettetFom == null ? System.now().addYears(-1) : null; //Get oppgaver for the given actor created maximum og one year back in time
        query.returnlimit = 100;
        CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();
        oppgaveService.setContext(CRM_NavTaskOppgaveService.Context.SYSTEM_CONTEXT);

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

    /**
     * Performing a database upsert to update exisiting tasks (using SF ID) and create new ones
     * @author Stian Ruud Schikora | 03-28-2022
     * @param tasksToUpsert
     **/
    private static void doNavTaskUpsert(List<NavTask__c> tasksToUpsert) {
        Map<Decimal, NavTask__c> navTaskMap = new Map<Decimal, NavTask__c>();

        for (NavTask__c navTask : tasksToUpsert) {
            navTaskMap.put(navTask.INT_External_Reference__c, navTask);
        }

        for (NavTask__c dbNavTask : [
            SELECT Id, INT_External_Reference__c
            FROM NavTask__c
            WHERE INT_External_Reference__c IN :navTaskMap.keySet()
        ]) {
            NavTask__c mapTask = navTaskMap.get(dbNavTask.INT_External_Reference__c);
            mapTask.Id = dbNavTask.Id;
            navTaskMap.put(mapTask.INT_External_Reference__c, mapTask);
        }

        List<Database.UpsertResult> upsList = Database.upsert(tasksToUpsert, false);
        verifyUpsertResults(upsList, tasksToUpsert);
    }

    /**
     * @description: Verifies the upsert results and creates log entries for any errors
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
                    if (
                        error.getStatusCode() == StatusCode.DUPLICATE_VALUE &&
                        error.getMessage().containsIgnoreCase('INT_External_Reference__c')
                    ) {
                        //Handling race conditions. This should not be logged as an error
                    } else {
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
}
