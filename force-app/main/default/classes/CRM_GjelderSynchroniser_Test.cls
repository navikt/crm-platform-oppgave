@isTest
public class CRM_GjelderSynchroniser_Test {
    @TestSetup
    static void makeData() {
        CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code_Set__c = 'Tema', CRM_Code__c = 'PEN', Name = 'Pensjon', CRM_Active__c = true)
        );
        CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(
                CRM_Code_Set__c = 'Tema',
                CRM_Code__c = 'RVE',
                Name = 'Rettferdsvederlag',
                CRM_Active__c = true
            )
        );
        CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(
                CRM_Code_Set__c = 'Tema',
                CRM_Code__c = 'REK',
                Name = 'Rekruttering og stilling',
                CRM_Active__c = true
            )
        );
        CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(
                CRM_Code_Set__c = 'Tema',
                CRM_Code__c = 'AAP',
                Name = 'Arbeidsavklaringspenger',
                CRM_Active__c = true
            )
        );
        CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(
                CRM_Code_Set__c = 'Behandlingstema',
                CRM_Code__c = 'ab0464',
                Name = 'Kommunikasjon',
                CRM_Active__c = true
            )
        );
    }

    @isTest
    static void testDoSync() {
        ApiMock.setTestMock('GET_OPPGAVE_GJELDER', 200, 'OK');
        CRM_GjelderSynchroniser sync = new CRM_GjelderSynchroniser();
        Test.startTest();
        sync.doSync();
        Test.stopTest();

        System.assert([SELECT Id FROM Common_Code__c WHERE CRM_Code_Set__c = 'Gjelder'].size() > 0);
        System.assert(
            [SELECT Id FROM Common_Code__c WHERE CRM_Code_Set__c = 'Gjelder' AND CRM_Subtype__c != NULL].size() > 0
        );
        System.assert(
            [SELECT Id FROM Common_Code__c WHERE CRM_Code_Set__c = 'Gjelder' AND CRM_Subtheme__c != NULL].size() > 0
        );
        System.assertEquals(
            0,
            [SELECT Id FROM Common_Code__c WHERE CRM_Code_Set__c = 'Gjelder' AND CRM_Parent_Code__r.CRM_Code__c = 'INF']
                .size()
        );
        Assert.isFalse(
            [
                SELECT CRM_Active__c
                FROM Common_Code__c
                WHERE CRM_Code_Set__c = 'Behandlingstema' AND CRM_Code__c = 'ab0464'
                LIMIT 1
            ]
            .CRM_Active__c,
            'Subtheme was not disabled even though it was not used by any gjelder'
        );
    }
}
