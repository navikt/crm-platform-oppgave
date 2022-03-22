@isTest
public class CRM_OppgaveSyncController_Test {
    @TestSetup
    static void makeData() {
        //Make necessary common code records
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavUnit__c(INT_UnitNumber__c = '4100'));
        CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code_Set__c = 'Oppgavetyper', CRM_Code__c = 'HAST_BANK_OPPLYS')
        );
        CRM_OPPGAVE_TestDataFactory.createRecord(new Common_Code__c(CRM_Code_Set__c = 'Tema', CRM_Code__c = 'AAP'));
    }

    @isTest
    static void testOppgaveSync() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '1234567891113'));

        Test.startTest();
        CRM_OppgaveQuery query = new CRM_OppgaveQuery();
        query.aktoerId = '1234567891113';
        CRM_OppgaveSyncController.doOppgaveSync(query);
        Test.stopTest();

        System.assert([SELECT COUNT() FROM NavTask__c] > 0);
    }
}
