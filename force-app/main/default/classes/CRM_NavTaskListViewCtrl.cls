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
}
