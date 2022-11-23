public without sharing class CRM_NavTaskBatchRerunner implements Database.Batchable<SObject> {
    private final String query;

    private CRM_NavTaskBatchRerunner(String query) {
        this.query = query;
    }

    public static void initiateRerun(String query) {
        if (!hasJobRunning()) {
            Database.executeBatch(new CRM_NavTaskBatchRerunner(query), 20);
        }
    }

    /**
     * @description Check if there are any running processes. If true, then a new job should not be submitted.
     * @return  `Boolean`
     */
    private static Boolean hasJobRunning() {
        return [
                SELECT COUNT()
                FROM AsyncApexJob
                WHERE
                    Status IN ('Holding', 'Preparing', 'Processing', 'Queued')
                    AND ApexClass.Name = 'CRM_NavTaskBatchRerunner'
            ] > 0;
    }

    /**
     * @description Return an active batch running if there is one
     * @return  `AsyncApexJob`
     */
    public static AsyncApexJob getRunningJob() {
        try {
            return (AsyncApexJob) [
                SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedDate
                FROM AsyncApexJob
                WHERE
                    Status IN ('Holding', 'Preparing', 'Processing', 'Queued')
                    AND ApexClass.Name = 'CRM_NavTaskBatchRerunner'
                LIMIT 1
            ];
        } catch (Exception ex) {
            return null;
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    //TODO: bulkify rerun flowx
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<String> taskIdsToRerun = new List<String>();
        for (NavTask__c taskToRerun : (List<NavTask__c>) scope) {
            taskIdsToRerun.add(taskToRerun.Id);
        }
        Map<String, Object> flowInputs = new Map<String, Object>{ 'recordIds' => taskIdsToRerun };
        Flow.Interview flow = Flow.Interview.createInterview('CRM_Retry_NAV_Task_Post', flowInputs);
        flow.start();
    }

    public void finish(Database.BatchableContext bc) {
    }
}
