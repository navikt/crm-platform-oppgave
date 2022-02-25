@isTest
public class CRM_NavTaskDbHandler_Test {
    @TestSetup
    static void makeData() {
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavTask__c(Name = 'TEST TASK', INT_External_Reference__c = 1234));
    }

    @isTest
    static void testInsertHandling() {
        List<NavTask__c> tasksToInsert = new List<NavTask__c>();
        tasksToInsert.add(new NavTask__c(Name = 'NEW TEST'));
        tasksToInsert.add(new NavTask__c(INT_External_Reference__c = 1234));
        Test.startTest();
        List<NavTask__c> tasks = CRM_NavTaskDbHandler.insertNavTasks(tasksToInsert);
        Test.stopTest();

        System.assert([SELECT COUNT() FROM NavTask__c] == 2);
    }
}
