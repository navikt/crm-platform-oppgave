/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 10-02-2023
 * @last modified by  : mamikals
 **/
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
            System.debug(ex);
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        } finally {
            logger.publish();
        }

        return new List<Id>{ retId };
    }

    @AuraEnabled
    public static void doOppgaveSync(String jsonQuery) {
        CRM_OppgaveQuery query = (CRM_OppgaveQuery) JSON.deserialize(jsonQuery, CRM_OppgaveQuery.class);
        query.opprettetFom = query.opprettetFom == null ? System.now().addYears(-1) : null; //Get oppgaver for the given actor created maximum of one year back in time
        query.returnlimit = 100;
        CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();
        oppgaveService.setContext(CRM_NavTaskOppgaveService.Context.SYSTEM_CONTEXT);

        try {
            HttpResponse response = oppgaveService.queryOppgave(query);
            CRM_OppgaveQueryResponse oppgaveResp = convertResponse(response, oppgaveService);
            if (oppgaveResp != null)
                doNavTaskUpsert(oppgaveResp.convertToNavTasks());
        } catch (Exception ex) {
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        } finally {
            logger.publish();
        }
    }

    @AuraEnabled
    public static void syncOppgaveByExtRef(String oppgaveRef) {
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
                queryResp.oppgaver = new List<CRM_KafkaOppgave>{ kfOppg };
                List<NavTask__c> navTaskList = queryResp.convertToNavTasks();

                doNavTaskUpsert(navTaskList);
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
            System.debug(ex);
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        } finally {
            logger.publish();
        }
    }

    @AuraEnabled
    public static void syncOppgaveOppfolgingByExtRef(String oppgaveRef) {
        CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();

        HttpResponse response;
        try {
            response = oppgaveService.getOppgaveOppfolgingById(oppgaveRef);
            Integer statusCode = response.getStatusCode();
            String responseBody = response.getBody();
            
            if (statusCode == 200 || statusCode == 201) {
                List<CRM_OppgaveOppfolging> oppfolgingList = (List<CRM_OppgaveOppfolging>) JSON.deserialize(
                    responseBody,
                    List<CRM_OppgaveOppfolging>.class
                );
                if (oppfolgingList.isEmpty()) {
                    System.debug('Empty response received.');
                    return;
                }

                List<NavTask__c> navTaskList = new List<NavTask__c>();
                String comment = '';

                for (CRM_OppgaveOppfolging oppfolgingOppgave : oppfolgingList) {
                    Datetime createdTime = Datetime.valueofGMT(oppfolgingOppgave.opprettetTidspunkt.replace('T', ' '));
                    String formattedDateTime = createdTime.format('dd.MM.yyyy HH:mm', 'Norway/Oslo');
                    comment += '--- ' + formattedDateTime + ' ' + '(' + oppfolgingOppgave.opprettetAv + ') ---\n' + oppfolgingOppgave.kommentar + '\n\n';
                }
                NavTask__c oppgave = new NavTask__c();
                oppgave.INT_External_Reference__c = Decimal.valueOf(oppgaveRef);
                oppgave.CRM_Comment__c = comment.trim();
                navTaskList.add(oppgave);

                doNavTaskUpsert(navTaskList);
            } else {
                logger.httpError(
                    'Error getting oppgaveOppfolging by ID',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
            }
        } catch (Exception ex) {
            System.debug(ex);
            logger.error(ex + '. Body: ' + response.getBody(), null, CRM_ApplicationDomain.Domain.NKS);
        } finally {
            logger.publish();
        }
    }

    public static void doMassOppgaveSync(CRM_OppgaveQueryList query) {
        CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();
        oppgaveService.setContext(CRM_NavTaskOppgaveService.Context.SYSTEM_CONTEXT);

        try {
            HttpResponse response = oppgaveService.queryOppgave(query);
            CRM_OppgaveQueryResponse oppgaveResp = convertResponse(response, oppgaveService);
            if (oppgaveResp != null)
                doNavTaskUpsert(oppgaveResp.convertToNavTasks());
        } catch (Exception ex) {
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        } finally {
            logger.publish();
        }
    }

    private static CRM_OppgaveQueryResponse convertResponse(
        HttpResponse response,
        CRM_NavTaskOppgaveService oppgaveService
    ) {
        Integer statusCode = response.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            return (CRM_OppgaveQueryResponse) JSON.deserialize(response.getBody(), CRM_OppgaveQueryResponse.class);
        } else {
            logger.httpError(
                'Error getting oppgaver',
                response,
                null,
                CRM_ApplicationDomain.Domain.NKS,
                oppgaveService.getTransactionId()
            );
            return null;
        }
    }

     /**
     * Performing a database upsert to update exisiting tasks (using SF ID) and create new ones
     * @author Stian Ruud Schikora | 03-28-2022
     * @param tasksToUpsert
     **/
    public static void doNavTaskUpsert(List<NavTask__c> tasksToUpsert) {
        Map<Decimal, NavTask__c> navTaskMap = new Map<Decimal, NavTask__c>();

        for (NavTask__c navTask : tasksToUpsert) {
            navTaskMap.put(navTask.INT_External_Reference__c, navTask);
        }

        for (NavTask__c existingTask : [
            SELECT Id, INT_External_Reference__c
            FROM NavTask__c
            WHERE INT_External_Reference__c IN :navTaskMap.keySet()
            FOR UPDATE
        ]) {
            NavTask__c navTask = navTaskMap.get(existingTask.INT_External_Reference__c);
            navTask.Id = existingTask.Id;
            navTaskMap.put(navTask.INT_External_Reference__c, navTask);
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
