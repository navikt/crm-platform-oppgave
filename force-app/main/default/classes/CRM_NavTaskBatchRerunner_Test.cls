@isTest
public class CRM_NavTaskBatchRerunner_Test {
    @TestSetup
    static void makeData() {
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavTask__c(Name = 'TEST'));
    }

    @isTest
    static void testRerun() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 200, 'OK');

        Test.startTest();
        CRM_NavTaskBatchRerunner.initiateRerun('SELECT Id FROM NavTask__c WHERE INT_External_Reference__c = null');
        AsyncApexJob runningJob = CRM_NavTaskBatchRerunner.getRunningJob();
        Test.stopTest();

        System.assert(runningJob != null, 'No job was returned');
    }
}
