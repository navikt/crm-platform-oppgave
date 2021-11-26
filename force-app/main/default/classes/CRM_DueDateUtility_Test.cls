@isTest
public with sharing class CRM_DueDateUtility_Test {
    @TestSetup
    static void makeData() {
        Common_Code__c symCode = (Common_Code__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'SYM', Name = 'Sykemelding', CRM_Code_Set__c = 'Tema')
        );
        Common_Code__c vurKonsCode = (Common_Code__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(
                CRM_Code__c = 'VUR_KONS_YTE',
                Name = 'Vurder konsekvens for ytelse',
                CRM_Code_Set__c = 'Oppgavetyper'
            )
        );

        CRM_OPPGAVE_TestDataFactory.createRecord(
            new NavTask__c(
                Name = 'TEST TASK',
                INT_External_Reference__c = 53339,
                NKS_Theme__c = symCode.Id,
                NKS_TaskType__c = vurKonsCode.Id
            )
        );
    }
    @isTest
    static void setDueDateTest() {
        List<NavTask__c> navList = [SELECT Id, NKS_Theme__c, NKS_TaskType__c FROM NavTask__c];
        Test.startTest();
        List<Date> dateList = CRM_DueDateUtility.setDueDate(navList);
        Test.stopTest();
        System.assertEquals(false, dateList.isEmpty());
        System.assert(dateList[0] == Date.today());
    }
}
