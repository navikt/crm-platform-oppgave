public without sharing class CRM_NavTaskDbHandler {
    /**
     * @description: Method handling insertion of NAV tasks called from flow
     * Primarily to handle issue with race conditions when handling incoming kafka events
     * @author Stian Ruud Schikora | 02-25-2022
     * @param navTasksToInsert
     * @return List<NavTask__c>
     **/
    @InvocableMethod(label='Insert NAV task' category='Task Handling')
    public static List<NavTask__c> insertNavTasks(List<NavTask__c> navTasksToInsert) {
        List<Database.SaveResult> saveResults = Database.insert(navTasksToInsert, false);
        Map<Decimal, Integer> existingReferenceIndexMap = new Map<Decimal, Integer>();

        for (Integer i = 0; i < saveResults.size(); i++) {
            if (saveResults[i].isSuccess()) {
                //Successful insert
            } else {
                for (Database.Error err : saveResults[i].getErrors()) {
                    if (
                        err.getStatusCode() == StatusCode.DUPLICATE_VALUE &&
                        err.getMessage().containsIgnoreCase('INT_External_Reference__c')
                    ) {
                        //If we catch an error where the external reference already exist, we add this to a query set
                        existingReferenceIndexMap.put(navTasksToInsert[i].INT_External_Reference__c, i);
                    }
                }
            }
        }

        Integer listIndex;
        for (NavTask__c existNavTask : [
            SELECT Id, INT_External_Reference__c
            FROM NavTask__c
            WHERE INT_External_Reference__c IN :existingReferenceIndexMap.keySet()
        ]) {
            listIndex = existingReferenceIndexMap.get(existNavTask.INT_External_Reference__c);
            navTasksToInsert[listIndex].Id = existNavTask.Id;
        }
        return navTasksToInsert;
    }
}
