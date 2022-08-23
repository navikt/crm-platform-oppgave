@isTest
public class CRM_NavTaskListViewCtrl_Test {
    @TestSetup
    static void makeData() {
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavTask__c(Name = 'TEST'));
    }

    @isTest
    static void testGetRecords() {
        List<String> fieldsToQuery = new List<String>{ 'Name' };
        String filter = 'Name = \'Test\'';
        Test.startTest();
        List<NavTask__c> retList = CRM_NavTaskListViewCtrl.getRecords(fieldsToQuery, filter, false, 10);
        Test.stopTest();

        System.assertNotEquals(0, retList.size());
    }

    @isTest
    static void testSyncOpenAndAssigned() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        CRM_NavTaskListViewCtrl.syncOpenAndAssigned();
        Test.stopTest();
    }
}
