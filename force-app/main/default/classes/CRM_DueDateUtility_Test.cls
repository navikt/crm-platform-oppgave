@isTest
public with sharing class CRM_DueDateUtility_Test {
    @TestSetup
    static void makeData() {
        Common_Code__c symCode = (Common_Code__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'SYM', Name = 'Sykemelding', CRM_Code_Set__c = 'Tema')
        );
        Common_Code__c sykCode = (Common_Code__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'SYK', Name = 'Sykepenger', CRM_Code_Set__c = 'Tema')
        );
        Common_Code__c unknownCode = (Common_Code__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'UNK', Name = 'Unknown', CRM_Code_Set__c = 'Tema')
        );
        Common_Code__c vurKonsCode = (Common_Code__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(
                CRM_Code__c = 'VUR_KONS_YTE',
                Name = 'Vurder konsekvens for ytelse',
                CRM_Code_Set__c = 'Oppgavetyper'
            )
        );
        Common_Code__c kontBrukCode = (Common_Code__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'KONT_BRUK', Name = 'Kontakt bruker', CRM_Code_Set__c = 'Oppgavetyper')
        );
        List<NavTask__c> taskList = new List<NavTask__c>{
            new NavTask__c(
                Name = 'TEST TASK 1',
                INT_External_Reference__c = 53339,
                NKS_Theme__c = symCode.Id,
                NKS_TaskType__c = vurKonsCode.Id
            ),
            new NavTask__c(
                Name = 'TEST TASK 2',
                INT_External_Reference__c = 53340,
                NKS_Theme__c = sykCode.Id,
                NKS_TaskType__c = kontBrukCode.Id
            ),
            new NavTask__c(
                Name = 'TEST TASK 2',
                INT_External_Reference__c = 53341,
                NKS_Theme__c = unknownCode.Id,
                NKS_TaskType__c = kontBrukCode.Id
            )
        };
        CRM_OPPGAVE_TestDataFactory.createRecordList(taskList);

        // Creating a new context since Apex doesn't allow MIXED_DML_OPERATIONS (non-setup and setup inserts at the same time)
        Test.startTest();
        insertHolidays();
        Test.stopTest();
    }

    @future
    private static void insertHolidays() {
        insert new List<Holiday>{
            new Holiday(Name = 'Damba day', ActivityDate = Date.today().addDays(3)),
            new Holiday(Name = 'Echidna day', ActivityDate = Date.today().addDays(5), RecurrenceType = 'RecursYearly')
        };
    }

    @isTest
    static void setDueDateTest() {
        List<NavTask__c> navList = [
            SELECT Id, NKS_Theme__c, NKS_TaskType__c
            FROM NavTask__c
            WHERE INT_External_Reference__c != 53341
            ORDER BY INT_External_Reference__c
        ];

        Test.startTest();
        List<Date> dateList = CRM_DueDateUtility.setDueDate(navList);
        Test.stopTest();
        System.assertEquals(false, dateList.isEmpty());
        System.assertEquals(Date.today(), dateList[0]);
        System.assertNotEquals(Date.today(), dateList[1]);
    }

    @isTest
    static void testUnknownTheme() {
        List<NavTask__c> navList = [
            SELECT Id, NKS_Theme__c, NKS_TaskType__c
            FROM NavTask__c
            WHERE INT_External_reference__c = 53341
            ORDER BY INT_External_Reference__c
        ];

        Test.startTest();
        List<Date> dateList = CRM_DueDateUtility.setDueDate(navList);
        Test.stopTest();
        System.assertEquals(false, dateList.isEmpty());
        System.assert(dateList[0] == CRM_DueDateUtility.addBusinessDays(2));
    }
}
