@isTest
public class CRM_NavTaskRerunCtrl_Test {
    @TestSetup
    static void makeData() {
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavTask__c(Name = 'TEST'));
    }

    @isTest
    static void testValidateQuery() {
        Test.startTest();
        Integer recordCount = CRM_NavTaskRerunCtrl.validateQuery('Name = \'TEST\'');
        Test.stopTest();

        System.assertEquals(1, recordCount, 'Wrong count returned');
    }

    @isTest
    static void testGetRunningProcess() {
        Test.startTest();
        AsyncApexJob retJob = CRM_NavTaskRerunCtrl.getRunningProcess();
        Test.stopTest();

        System.assertEquals(null, retJob, 'A job should not be returned');
    }

    @isTest
    static void testGetJobInfo() {
        Test.startTest();
        AsyncApexJob retJob = CRM_NavTaskRerunCtrl.getJobInfo('INVALID_ID');
        Test.stopTest();

        System.assertEquals(null, retJob, 'A job should not be returned');
    }

    @isTest
    static void testInitRerun() {
        Test.startTest();
        CRM_NavTaskRerunCtrl.initRerun('Name = \'TEST\'');
        AsyncApexJob retJob = CRM_NavTaskRerunCtrl.getRunningProcess();
        retJob = CRM_NavTaskRerunCtrl.getJobInfo(retJob.Id);
        Test.stopTest();

        System.assertNotEquals(null, retJob, 'No job was started');
    }
}
