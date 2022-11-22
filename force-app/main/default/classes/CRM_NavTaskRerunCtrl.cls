public without sharing class CRM_NavTaskRerunCtrl {
    /**
     * @description Validates the query filter to ensure the SOQL to be generate does not throw any error
     * @param queryFilter
     * @return  `Integer`
     * @exception
     */
    @AuraEnabled
    public static Integer validateQuery(String queryFilter) {
        String query = 'SELECT count() FROM NavTask__c WHERE ' + queryFilter.trim();
        try {
            return Database.countQuery(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Query to check if there are any active job for the nav task rerunner
     * @return  `AsyncApexJob`
     * @exception
     */
    @AuraEnabled
    public static AsyncApexJob getRunningProcess() {
        try {
            return CRM_NavTaskBatchRerunner.getRunningJob();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Get Apex job details for a specific job by ID
     * @param jobId
     * @return  `AsyncApexJob`
     */
    @AuraEnabled
    public static AsyncApexJob getJobInfo(String jobId) {
        try {
            return (AsyncApexJob) [
                SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedDate
                FROM AsyncApexJob
                WHERE Id = :jobId
                LIMIT 1
            ];
        } catch (Exception ex) {
            return null;
        }
    }

    /**
     * @description Initiate NavTaskBatchRerunner with the defined filter
     * @param queryFilter
     * @exception
     */
    @AuraEnabled
    public static void initRerun(String queryFilter) {
        String query = 'SELECT Id FROM NavTask__c WHERE ' + queryFilter.trim();
        try {
            CRM_NavTaskBatchRerunner.initiateRerun(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
