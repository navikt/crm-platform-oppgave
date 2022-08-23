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
        String query = 'SELECT Id, ';

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
}
