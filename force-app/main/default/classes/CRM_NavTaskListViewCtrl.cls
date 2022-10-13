public without sharing class CRM_NavTaskListViewCtrl {
    private class NotFoundException extends Exception {
    }

    public class UnsupportedOperandException extends Exception {
    }

    @AuraEnabled
    public static List<NavTask__c> getRecords(
        List<String> fieldsToQuery,
        String filterString,
        Boolean ownedByRunningUser,
        Integer numRecords
    ) {
        String query = 'SELECT Id, INT_External_Reference__c, ';

        for (String queryField : fieldsToQuery) {
            query += queryField + ',';
        }
        query = query.removeEnd(',');
        query += ' FROM NavTask__c';
        if (String.isNotBlank(filterString) || ownedByRunningUser)
            query += ' WHERE ';

        if (ownedByRunningUser == true)
            query += ' OwnerId = \'' + UserInfo.getUserId() + '\' AND ';

        query += filterString != null ? filterString : '';
        query = query.removeEnd('AND ');

        query += ' ORDER BY CRM_DueDate__c DESC LIMIT ' + String.valueOf(numRecords);
        return (List<NavTask__c>) Database.query(query);
    }

    /**
     * Syncs the running users open assigned person tasks from oppgave
     * @author Stian Ruud Schikora | 08-23-2022
     **/
    @AuraEnabled
    public static void syncOpenAndAssigned() {
        try {
            User runningUser = [SELECT Id, CRM_NAV_Ident__c FROM User WHERE Id = :UserInfo.getUserId()];
            CRM_OppgaveQuery oppgQuery = new CRM_OppgaveQuery();
            oppgQuery.tilordnetRessurs = runningUser.CRM_NAV_Ident__c;
            oppgQuery.statuskategori = OppgaveStatuskategori.AAPEN;

            CRM_OppgaveSyncController.doOppgaveSync(JSON.serialize(oppgQuery));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Syncs the running users open assigned person tasks from oppgave
     * @author Stian Ruud Schikora | 08-23-2022
     **/
    @AuraEnabled
    public static void refresh_syncOpenAndAssigned(List<NavTask__c> sfRecords) {
        try {
            User runningUser = [SELECT Id, CRM_NAV_Ident__c FROM User WHERE Id = :UserInfo.getUserId()];
            CRM_OppgaveQuery oppgQuery = new CRM_OppgaveQuery();
            oppgQuery.tilordnetRessurs = runningUser.CRM_NAV_Ident__c;
            oppgQuery.statuskategori = OppgaveStatuskategori.AAPEN;

            oppgQuery.opprettetFom = oppgQuery.opprettetFom == null ? System.now().addYears(-1) : null; //Get oppgaver for the given actor created maximum og one year back in time
            oppgQuery.returnlimit = 100;
            CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();
            oppgaveService.setContext(CRM_NavTaskOppgaveService.Context.SYSTEM_CONTEXT);

            HttpResponse response = oppgaveService.queryOppgave(oppgQuery);
            Integer statusCode = response.getStatusCode();

            if (statusCode == 200 || statusCode == 201) {
                CRM_OppgaveQueryResponse oppgaveResp = (CRM_OppgaveQueryResponse) JSON.deserialize(
                    response.getBody(),
                    CRM_OppgaveQueryResponse.class
                );
                List<NavTask__c> serviceTasks = oppgaveResp.convertToNavTasks();
                handleRecordDiff(sfRecords, serviceTasks); //Delete records not returned by service, might be missing som kafka message updates
                CRM_OppgaveSyncController.doNavTaskUpsert(serviceTasks);
            } else {
                throw new AuraHandledException('Error getting oppgaver');
            }

            CRM_OppgaveSyncController.doOppgaveSync(JSON.serialize(oppgQuery));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Removed close the tasks in case of the state being incorrect as a result from failed updates via kafka
     * @author Stian Ruud Schikora | 10-12-2022
     * @param records
     **/
    private static void handleRecordDiff(List<NavTask__c> sfRecords, List<NavTask__c> serviceRecords) {
        Boolean inServiceRecords = false;
        List<NavTask__c> recordsToDelete = new List<NavTask__c>();
        for (NavTask__c sfRecord : sfRecords) {
            for (NavTask__c serviceRecord : serviceRecords) {
                if (sfRecord.INT_External_Reference__c == serviceRecord.INT_External_Reference__c) {
                    inServiceRecords = true;
                    break;
                }
            }
            if (!inServiceRecords)
                recordsToDelete.add(sfRecord);
        }

        if (!recordsToDelete.isEmpty())
            delete recordsToDelete;
    }
}
