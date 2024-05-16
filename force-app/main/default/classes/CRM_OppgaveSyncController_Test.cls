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
        CRM_OppgaveSyncController.doOppgaveSync(JSON.serialize(query));
        Test.stopTest();

        System.assert([SELECT COUNT() FROM NavTask__c] > 0);
    }

    @isTest
    static void testOppgaveSyncError() {
        ApiMock.setTestMock('GET_OPPGAVE', 401, 'ERROR');
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '1234567891113'));

        Test.startTest();
        CRM_OppgaveQuery query = new CRM_OppgaveQuery();
        query.aktoerId = '1234567891113';
        CRM_OppgaveSyncController.doOppgaveSync(JSON.serialize(query));
        Test.stopTest();

        System.assert([SELECT COUNT() FROM NavTask__c] == 0);
    }

    @isTest
    static void testSyncById() {
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID', 200, 'OK');
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '1234567891113'));

        Test.startTest();
        CRM_OppgaveQuery query = new CRM_OppgaveQuery();
        query.aktoerId = '1234567891113';
        CRM_OppgaveSyncController.syncOppgaveByExtRef('1234567892');
        Test.stopTest();

        System.assert([SELECT COUNT() FROM NavTask__c] > 0);
    }

    @isTest
    static void testSyncOppfolgingById() {
        ApiMock.setTestMock('GET_OPPGAVEOPPFOLGING_BY_ID', 200, 'OK');
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '1234567891113'));

        Test.startTest();
        CRM_OppgaveQuery query = new CRM_OppgaveQuery();
        query.aktoerId = '1234567891113';
        CRM_OppgaveSyncController.syncOppgaveOppfolgingByExtRef('1234567892');
        Test.stopTest();

        System.assert([SELECT COUNT() FROM NavTask__c] > 0);
    }

    @isTest
    static void testSyncOppfolgingByIdError() {
        ApiMock.setTestMock('GET_OPPGAVEOPPFOLGING_BY_ID', 401, 'ERROR');
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '1234567891113'));

        Test.startTest();
        CRM_OppgaveQuery query = new CRM_OppgaveQuery();
        query.aktoerId = '1234567891113';
        CRM_OppgaveSyncController.syncOppgaveOppfolgingByExtRef('1234567892');
        Test.stopTest();

        System.assert([SELECT COUNT() FROM NavTask__c] == 0);
    }

    @isTest
    static void testSyncByIdError() {
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID', 401, 'ERROR');
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '1234567891113'));

        Test.startTest();
        CRM_OppgaveQuery query = new CRM_OppgaveQuery();
        query.aktoerId = '1234567891113';
        CRM_OppgaveSyncController.syncOppgaveByExtRef('1234567892');
        Test.stopTest();

        System.assert([SELECT COUNT() FROM NavTask__c] == 0);
    }

    @isTest
    static void testInvocable() {
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID', 200, 'OK');
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '1234567891113'));

        Test.startTest();
        CRM_OppgaveSyncController.handleNavTaskRequests(new List<String>{ '5436732' });
        Test.stopTest();

        System.assert([SELECT COUNT() FROM NavTask__c] > 0);
    }

    @isTest
    static void testInvocableLogError() {
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID', 500, 'Internal Server Error');
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '1234567891113'));

        Test.startTest();
        CRM_OppgaveSyncController.handleNavTaskRequests(new List<String>{ '5436732' });
        Test.stopTest();

        System.assert([SELECT COUNT() FROM NavTask__c] == 0);
    }

    @isTest
    static void testDoMassOppgaveSync() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.aktoerId = new List<String>{ 'Test' };
        query.statuskategori = OppgaveStatuskategori.AAPEN;
        query.tildeltEnhetsnr = '4100';
        query.tilordnetRessurs = 'Z999999';
        query.fristFom = System.today().addYears(-1);
        query.returnlimit = 100;

        Test.startTest();
        CRM_OppgaveSyncController.doMassOppgaveSync(query);
        Test.stopTest();
    }
}
