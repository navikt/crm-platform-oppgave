@isTest
public class CRM_GjelderSynchroniser_Test {
    static String testJson = '{"INF":[{"behandlingstema": null,"behandlingstemaTerm": null,"behandlingstype": "ae0004","behandlingstypeTerm": "Behandle vedtak"}],"PEN":[],"RVE": [{"behandlingstema": null,"behandlingstemaTerm": null,"behandlingstype": "ae0004","behandlingstypeTerm": "Behandle vedtak"}],"REK": [{"behandlingstema": null,"behandlingstemaTerm": null,"behandlingstype": "ae0004","behandlingstypeTerm": "Behandle vedtak"},{"behandlingstema": null,"behandlingstemaTerm": null,"behandlingstype": "ae0007","behandlingstypeTerm": "Utbetaling"},{"behandlingstema": null,"behandlingstemaTerm": null,"behandlingstype": "ae0116","behandlingstypeTerm": "Meldekort"}],"AAP": [{"behandlingstema": "ab0241","behandlingstemaTerm": "Dagliglivet","behandlingstype": "ae0106","behandlingstypeTerm": "Utland"}]}';

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
    }

    @isTest
    static void testDoSync() {
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', testJson, null));

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
    }
}
