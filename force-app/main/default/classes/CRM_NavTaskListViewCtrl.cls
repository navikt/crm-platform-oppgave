public without sharing class CRM_NavTaskListViewCtrl {
    private class NotFoundException extends Exception {
    }

    public class UnsupportedOperandException extends Exception {
    }

    @AuraEnabled(cacheable=true)
    public static List<NavTask__c> getRecords(
        List<String> fieldsToQuery,
        String filterString,
        Boolean ownedByRunningUser,
        Integer numRecords
    ) {
        List<String> fields = new List<String>{'Id', 'INT_External_Reference__c'};
        fields.addAll(fieldsToQuery);
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM NavTask__c';

        List<String> filters = new List<String>();
        if (ownedByRunningUser) {
            filters.add('OwnerId = \'' + UserInfo.getUserId() + '\'');
        }

        if (String.isNotBlank(filterString)) {
            filters.add(filterString);
        }

        if (!filters.isEmpty()) {
            query += ' WHERE ' + String.join(filters, ' AND ');
        }
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

            oppgQuery.opprettetFom = oppgQuery.opprettetFom == null ? System.now().addYears(-1) : null; // Get oppgaver for the given actor created maximum of one year back in time
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
                handleRecordDiff(sfRecords, serviceTasks); // Delete records not returned by service, might be missing som kafka message updates
                CRM_OppgaveSyncController.doNavTaskUpsert(serviceTasks);
            } else {
                throw new AuraHandledException('Error getting oppgaver');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Delete records not returned by service, might be missing som kafka message updates
     * @author Stian Ruud Schikora | 10-12-2022
     * @param records
     **/
    private static void handleRecordDiff(List<NavTask__c> sfRecords, List<NavTask__c> serviceRecords) {
        if (serviceRecords == null || serviceRecords.isEmpty() || sfRecords == null || sfRecords.isEmpty()) {
            return;
        }
        
        Set<Decimal> serviceExternalRefs = new Set<Decimal>();
        for (NavTask__c serviceRecord : serviceRecords) {
            serviceExternalRefs.add(serviceRecord.INT_External_Reference__c);
        }
    
        List<NavTask__c> recordsToDelete = new List<NavTask__c>();
        for (NavTask__c sfRecord : sfRecords) {
            if (!serviceExternalRefs.contains(sfRecord.INT_External_Reference__c)) {
                recordsToDelete.add(sfRecord);
            }
        }
    
        if (!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
        }
    }
}
