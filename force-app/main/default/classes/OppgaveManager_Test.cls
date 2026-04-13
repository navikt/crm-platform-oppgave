@IsTest
public with sharing class OppgaveManager_Test {
    @TestSetup
    static void makeData() {
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '123456789', Name = '12345678901'));
    }

    @IsTest
    static void getOppgaveById_Success() {
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID', 200, 'OK');
        Test.startTest();
        Oppgave oppg = OppgaveManager.getOppgaveById('1234');
        Test.stopTest();
        Assert.isNotNull(oppg, 'Should return an Oppgave');
    }

    @IsTest
    static void getOppgaveById_Error() {
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID', 500, 'Error');
        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        Oppgave oppg = OppgaveManager.getOppgaveById('1234');
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Assert.isNull(oppg, 'Should not return an Oppgave');
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before getting oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after getting oppgave');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void getAllAssignedOpenOppgaver_Success() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getAllAssignedOpenOppgaver('Z991234');
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get all assigned open oppgaver');
    }

    @IsTest
    static void getAllAssignedOpenOppgaver_Error() {
        ApiMock.setTestMock('GET_OPPGAVE', 500, 'Error');
        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getAllAssignedOpenOppgaver('Z991234');
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Assert.isNull(oppgaver, 'Should not return oppgave list');
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before getting open oppgaver');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after getting open oppgaver');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void getOpenOppgaver_Success() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', 0);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get open Oppgaver');
    }

    @IsTest
    static void getOpenOppgaver_Offset_Success() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', 100);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get open Oppgaver');
    }

    @IsTest
    static void getOpenOppgaver_Error() {
        ApiMock.setTestMock('GET_OPPGAVE', 500, 'Error');
        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', 0);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Assert.isNull(oppgaver, 'Should not return oppgave list');
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before getting open oppgaver');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after getting open oppgaver');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void getOpenOppgaver_NullOffset_Success() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', null);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get open Oppgaver');
    }

    @IsTest
    static void getAllOppgaver_Success() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getAllOppgaver('12345678901', 0);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get all open Oppgaver');
    }

    @IsTest
    static void getAllOppgaver_Offset_Success() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getAllOppgaver('12345678901', 100);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get all open Oppgaver');
    }

    @IsTest
    static void getAllOppgaver_Error() {
        ApiMock.setTestMock('GET_OPPGAVE', 500, 'Error');
        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getAllOppgaver('12345678901', 0);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Assert.isNull(oppgaver, 'Should not return oppgave list');
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before getting all oppgaver');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after getting all oppgaver');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void getOppgaver_Success() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');
        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.aktivDatoFom = Date.today();

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOppgaver(query);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get all open Oppgaver');
    }

    @IsTest
    static void getOppgaver_Error() {
        ApiMock.setTestMock('GET_OPPGAVE', 500, 'Error');
        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.aktivDatoFom = Date.today().addDays(-10);

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOppgaver(query);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Assert.isNull(oppgaver, 'Should not return oppgave list');
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before getting oppgaver');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after getting oppgaver');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void postTask_Success() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.postTask(taskRequest);
        Test.stopTest();
        Assert.isNotNull(taskResponse);
        Assert.isNotNull(taskResponse.tildeltEnhetsnr);
    }

    @IsTest
    static void postTask_System_Success() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.POST_AS_SYSTEM = true;
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.postTask(taskRequest);
        Test.stopTest();
        Assert.isNotNull(taskResponse);
        Assert.isNotNull(taskResponse.tildeltEnhetsnr);
    }

    @IsTest
    static void postTask_NoIdent_Success() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.postTask(taskRequest);
        Test.stopTest();
        Assert.isNotNull(taskResponse);
        Assert.isNotNull(taskResponse.tildeltEnhetsnr);
    }

    @IsTest
    static void postTask_Metadata_Success() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.eksternHenvendelseId = '12345';
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.postTask(taskRequest);
        Test.stopTest();
        Assert.isNotNull(taskResponse);
        Assert.isNotNull(taskResponse.tildeltEnhetsnr);
    }

    @IsTest
    static void postTask_KommentarTekst_Success() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.kommentarTekst = 'This is a test';
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.postTask(taskRequest);
        Test.stopTest();
        Assert.isNotNull(taskResponse);
        Assert.isNotNull(taskResponse.tildeltEnhetsnr);
    }

    @IsTest
    static void postTask_Error() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 500, 'Error');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.POST_AS_SYSTEM = true;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.postTask(taskRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Assert.isNull(taskResponse);
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before posting oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after trying to post oppgaver');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void postTask_LogCategory_Error() {
        String testLogCategory = 'TestLog';

        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 500, 'Error');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.POST_AS_SYSTEM = true;
        taskRequest.logCategory = testLogCategory;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = :testLogCategory];
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.postTask(taskRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, UUID__c
            FROM Application_Log__c
            WHERE Category__c = :testLogCategory
        ];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One loge from category after');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void patchEditTask_Success() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'OK');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.personIdent = '12345678902';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.patchEditTask(taskRequest);
        Test.stopTest();
        Assert.isNotNull(taskResponse);
        Assert.isNotNull(taskResponse.versjon);
    }

    @IsTest
    static void patchEditTask_System_Success() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'OK');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.POST_AS_SYSTEM = true;
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.patchEditTask(taskRequest);
        Test.stopTest();
        Assert.isNotNull(taskResponse);
        Assert.isNotNull(taskResponse.versjon);
    }

    @IsTest
    static void patchEditTask_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 500, 'Error');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.patchEditTask(taskRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Assert.isNull(taskResponse);
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before editing oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after trying to edit oppgave');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void patchEditTask_NoId_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'Ok');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.versjon = 2;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.patchEditTask(taskRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Assert.isNull(taskResponse);
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before editing oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after trying to edit oppgave');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void patchEditTask_NoVersjon_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'Ok');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.patchEditTask(taskRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Assert.isNull(taskResponse);
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before editing oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after trying to edit oppgave');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void patchEditTask_LogCategory_Error() {
        String testLogCategory = 'TestLog';

        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 500, 'Error');
        OppgaveManager.OppgaveRequest taskRequest = new OppgaveManager.OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        taskRequest.logCategory = testLogCategory;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = :testLogCategory];
        Test.startTest();
        Oppgave taskResponse = OppgaveManager.patchEditTask(taskRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, UUID__c
            FROM Application_Log__c
            WHERE Category__c = :testLogCategory
        ];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One loge from category after');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }
}
