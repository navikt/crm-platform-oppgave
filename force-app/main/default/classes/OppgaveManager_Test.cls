@IsTest
public with sharing class OppgaveManager_Test {
    @TestSetup
    static void makeData() {
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '123456789', Name = '12345678901'));
    }

    @IsTest
    static void getOppgaveById_Success() {
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID_V2', 200, 'OK');
        Test.startTest();
        OppgaveV2 oppg = OppgaveManager.getOppgaveById('1234');
        Test.stopTest();
        Assert.isNotNull(oppg, 'Should return an Oppgave');
    }

    @IsTest
    static void getOppgaveById_Error() {
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID_V2', 500, 'Error');
        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        OppgaveV2 oppg = OppgaveManager.getOppgaveById('1234');
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
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', 0, null);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get open Oppgaver');
    }

    @IsTest
    static void getOpenOppgaver_Offset_Success() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', 100, null);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get open Oppgaver');
    }

    @IsTest
    static void getOpenOppgaver_Error() {
        ApiMock.setTestMock('GET_OPPGAVE', 500, 'Error');
        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', 0, null);
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
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', null, null);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get open Oppgaver');
    }

    @IsTest
    static void getAllOppgaver_Success() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getAllOppgaver('12345678901', 0, null);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get all open Oppgaver');
    }

    @IsTest
    static void getAllOppgaver_Offset_Success() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getAllOppgaver('12345678901', 100, null);
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size());
        Assert.isNotNull(oppgaver[0].id, 'Should get all open Oppgaver');
    }

    @IsTest
    static void getOpenOppgaver_WithYtelser_ResolvesTema() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');
        insert new Common_Code__c(Name = 'Sykepenger', CRM_Code__c = 'SYK', CRM_Code_Set__c = 'Tema');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', 0, new List<String>{ 'Sykepenger' });
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size(), 'Should get oppgaver when ytelser is provided');
    }

    @IsTest
    static void getAllOppgaver_WithUnknownYtelser_StillCallsApi() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getAllOppgaver('12345678901', 0, new List<String>{ 'UkjentYtelse' });
        Test.stopTest();
        Assert.areNotEqual(0, oppgaver.size(), 'Should still call API even if ytelser cannot be resolved');
    }

    @IsTest
    static void getAllOppgaver_Error() {
        ApiMock.setTestMock('GET_OPPGAVE', 500, 'Error');
        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getAllOppgaver('12345678901', 0, null);
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
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.methodType = 'POST';
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        Assert.isTrue(taskResponse.isSuccess);
        Assert.isNotNull(taskResponse.oppgave.tildeltEnhetsnr);
    }

    @IsTest
    static void postTask_System_Success() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.POST_AS_SYSTEM = true;
        taskRequest.methodType = 'POST';
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        Assert.isTrue(taskResponse.isSuccess);
        Assert.isNotNull(taskResponse.oppgave.tildeltEnhetsnr);
    }

    @IsTest
    static void postTask_NoIdent_Success() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.methodType = 'POST';
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        Assert.isTrue(taskResponse.isSuccess);
        Assert.isNotNull(taskResponse.oppgave.tildeltEnhetsnr);
    }

    @IsTest
    static void postTask_Metadata_Success() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.eksternHenvendelseId = '12345';
        taskRequest.methodType = 'POST';
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        Assert.isTrue(taskResponse.isSuccess);
        Assert.isNotNull(taskResponse.oppgave.tildeltEnhetsnr);
    }

    @IsTest
    static void postTask_KommentarTekst_Success() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.kommentarTekst = 'This is a test';
        taskRequest.methodType = 'POST';
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        Assert.isTrue(taskResponse.isSuccess);
        Assert.isNotNull(taskResponse.oppgave.tildeltEnhetsnr);
    }

    @IsTest
    static void postTask_Error() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 500, 'Error');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.POST_AS_SYSTEM = true;
        taskRequest.methodType = 'POST';

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Assert.isFalse(taskResponse.isSuccess);
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before posting oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after trying to post oppgaver');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void postTask_400_Error() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 400, 'Bad Request');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.POST_AS_SYSTEM = true;
        taskRequest.methodType = 'POST';

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Assert.isFalse(taskResponse.isSuccess);
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before posting oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after trying to post oppgave');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void postTask_LogCategory_Error() {
        String testLogCategory = 'TestLog';

        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 500, 'Error');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.POST_AS_SYSTEM = true;
        taskRequest.logCategory = testLogCategory;
        taskRequest.methodType = 'POST';

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = :testLogCategory];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, UUID__c
            FROM Application_Log__c
            WHERE Category__c = :testLogCategory
        ];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void postTask_ScheduledRequest_Error() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 500, 'Error');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.methodType = 'POST';

        List<Scheduled_Request__c> schRequestsBefore = [SELECT Id FROM Scheduled_Request__c];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Scheduled_Request__c> schRequestsAfter = [
            SELECT Id, Method__c, Status__c, Payload__c
            FROM Scheduled_Request__c
        ];

        Assert.areEqual(0, schRequestsBefore.size(), 'No scheduled requests before');
        Assert.areEqual(1, schRequestsAfter.size(), 'One scheduled request after');
        Scheduled_Request__c schRequest = schRequestsAfter[0];
        Assert.areEqual('Post', schRequest.Method__c);
        Assert.areEqual('Scheduled', schRequest.Status__c);
        OppgaveRequest payload = (OppgaveRequest) JSON.deserialize(schRequest.Payload__c, OppgaveRequest.class);
        Assert.isNotNull(payload);
    }

    @IsTest
    static void postTask_No_ScheduledRequest_Error() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 400, 'Bad Request');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.methodType = 'POST';

        List<Scheduled_Request__c> schRequestsBefore = [SELECT Id FROM Scheduled_Request__c];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Scheduled_Request__c> schRequestsAfter = [
            SELECT Id, Method__c, Status__c, Payload__c
            FROM Scheduled_Request__c
        ];

        Assert.areEqual(0, schRequestsBefore.size(), 'No scheduled requests before');
        Assert.areEqual(0, schRequestsAfter.size(), 'No scheduled requests after');
    }

    @IsTest
    static void patchEditTask_Success() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'OK');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678902';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        taskRequest.methodType = 'PATCH';
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        Assert.isTrue(taskResponse.isSuccess);
        Assert.isNotNull(taskResponse.oppgave.versjon);
    }

    @IsTest
    static void patchEditTask_System_Success() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'OK');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.POST_AS_SYSTEM = true;
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        taskRequest.methodType = 'PATCH';
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        Assert.isTrue(taskResponse.isSuccess);
        Assert.isNotNull(taskResponse.oppgave.versjon);
    }

    @IsTest
    static void patchEditTask_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 500, 'Error');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        taskRequest.methodType = 'PATCH';

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Assert.isFalse(taskResponse.isSuccess);
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before editing oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after trying to edit oppgave');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void patchEditTask_400_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 400, 'Bad Request');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        taskRequest.methodType = 'PATCH';

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Assert.isFalse(taskResponse.isSuccess);
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before editing oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after trying to edit oppgave');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void patchEditTask_NoId_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'Ok');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.versjon = 2;
        taskRequest.methodType = 'PATCH';

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Assert.isFalse(taskResponse.isSuccess);
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before editing oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after trying to edit oppgave');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void patchEditTask_NoVersjon_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'Ok');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.methodType = 'PATCH';

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave'];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Application_Log__c> logsAfter = [SELECT Id, UUID__c FROM Application_Log__c WHERE Category__c = 'Oppgave'];

        Assert.isFalse(taskResponse.isSuccess);
        Assert.areEqual(0, logsBefore.size(), 'Should not have logs before editing oppgave');
        Assert.areEqual(1, logsAfter.size(), 'Should have one log after trying to edit oppgave');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void patchEditTask_LogCategory_Error() {
        String testLogCategory = 'TestLog';

        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 500, 'Error');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        taskRequest.logCategory = testLogCategory;
        taskRequest.methodType = 'PATCH';

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = :testLogCategory];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, UUID__c
            FROM Application_Log__c
            WHERE Category__c = :testLogCategory
        ];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Assert.isNotNull(logsAfter[0].UUID__c, 'Should have transaction ID in log');
    }

    @IsTest
    static void patchEditTask_ScheduledRequest_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 500, 'Error');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        taskRequest.methodType = 'PATCH';

        List<Scheduled_Request__c> schRequestsBefore = [SELECT Id FROM Scheduled_Request__c];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Scheduled_Request__c> schRequestsAfter = [
            SELECT Id, Method__c, Status__c, Payload__c
            FROM Scheduled_Request__c
        ];

        Assert.areEqual(0, schRequestsBefore.size(), 'No scheduled requests before');
        Assert.areEqual(1, schRequestsAfter.size(), 'One scheduled request after');
        Scheduled_Request__c schRequest = schRequestsAfter[0];
        Assert.areEqual('Patch', schRequest.Method__c);
        Assert.areEqual('Scheduled', schRequest.Status__c);
        OppgaveRequest payload = (OppgaveRequest) JSON.deserialize(schRequest.Payload__c, OppgaveRequest.class);
        Assert.isNotNull(payload);
    }

    @IsTest
    static void patchEditTask_No_ScheduledRequest_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 400, 'Bad Request');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        taskRequest.methodType = 'PATCH';

        List<Scheduled_Request__c> schRequestsBefore = [SELECT Id FROM Scheduled_Request__c];
        Test.startTest();
        OppgaveResponse taskResponse = OppgaveManager.executeOppgave(new List<OppgaveRequest>{ taskRequest })[0];
        Test.stopTest();
        List<Scheduled_Request__c> schRequestsAfter = [
            SELECT Id, Method__c, Status__c, Payload__c
            FROM Scheduled_Request__c
        ];

        Assert.areEqual(0, schRequestsBefore.size(), 'No scheduled requests before');
        Assert.areEqual(0, schRequestsAfter.size(), 'No scheduled requests after');
    }

    @IsTest
    static void getPersonInfoTest() {
        Test.startTest();
        Map<String, Person__c> result = OppgaveManager.getPersonInfo(new List<String>{ '12345678901' });
        Test.stopTest();

        Assert.areEqual(1, result.size());
    }

    @IsTest
    static void getPersonInfoNullTest() {
        Test.startTest();
        Map<String, Person__c> result = OppgaveManager.getPersonInfo(null);
        Test.stopTest();

        Assert.areEqual(0, result.size());
    }

    @IsTest
    static void patchEditTaskFromLwc_Success() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'OK');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678902';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        taskRequest.methodType = 'PATCH';

        Test.startTest();
        OppgaveResponse result = OppgaveManager.patchEditTaskFromLwc(JSON.serialize(taskRequest));
        Test.stopTest();

        Assert.isTrue(result.isSuccess);
    }

    @IsTest
    static void getCommonCodeNames_ReturnsMatchingCodeSets() {
        insert new List<Common_Code__c>{
            new Common_Code__c(Name = 'Sykepenger', CRM_Code__c = 'SYK', CRM_Code_Set__c = 'Tema'),
            new Common_Code__c(Name = 'Behandling', CRM_Code__c = 'BEH', CRM_Code_Set__c = 'Behandlingstema'),
            new Common_Code__c(Name = 'Type', CRM_Code__c = 'TYP', CRM_Code_Set__c = 'Behandlingstyper'),
            new Common_Code__c(Name = 'Oppgavetype', CRM_Code__c = 'OPP', CRM_Code_Set__c = 'Oppgavetyper')
        };

        Test.startTest();
        Map<String, String> result = OppgaveManager.getCommonCodeNames();
        Test.stopTest();

        Assert.areEqual(4, result.size(), 'Should only include the four supported code sets');
        Assert.areEqual('Sykepenger', result.get('SYK'));
        Assert.areEqual('Behandling', result.get('BEH'));
        Assert.areEqual('Type', result.get('TYP'));
        Assert.areEqual('Oppgavetype', result.get('OPP'));
    }

    @IsTest
    static void getCommonCodeNames_NoCommonCodes_ReturnsEmptyMap() {
        Test.startTest();
        Map<String, String> result = OppgaveManager.getCommonCodeNames();
        Test.stopTest();

        Assert.isNotNull(result, 'Should not return null');
        Assert.areEqual(0, result.size(), 'Should return empty map when no common codes exist');
    }

    @IsTest
    static void getNavUnitNames_ReturnsUnitNumberToShortNameMap() {
        insert new List<NavUnit__c>{
            new NavUnit__c(Name = 'NAV Test 1', INT_UnitNumber__c = '4100'),
            new NavUnit__c(Name = 'NAV Test 2', INT_UnitNumber__c = '4200')
        };

        Test.startTest();
        Map<String, String> result = OppgaveManager.getNavUnitNames();
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'Should return one entry per NavUnit');
        Assert.areEqual('NAV Test 1', result.get('4100'));
        Assert.areEqual('NAV Test 2', result.get('4200'));
    }

    @IsTest
    static void getNavUnitNames_NoUnits_ReturnsEmptyMap() {
        Test.startTest();
        Map<String, String> result = OppgaveManager.getNavUnitNames();
        Test.stopTest();

        Assert.isNotNull(result, 'Should not return null');
        Assert.areEqual(0, result.size(), 'Should return empty map when no NavUnits exist');
    }

    @IsTest
    static void getTemaCodes_NullYtelser_NoTemaQueryParam() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', 0, null);
        Test.stopTest();

        Assert.areNotEqual(0, oppgaver.size(), 'Should call API even when ytelser is null');
    }

    @IsTest
    static void getTemaCodes_EmptyYtelser_NoTemaQueryParam() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        List<Oppgave> oppgaver = OppgaveManager.getOpenOppgaver('12345678901', 0, new List<String>{});
        Test.stopTest();

        Assert.areNotEqual(0, oppgaver.size(), 'Should call API even when ytelser is empty');
    }
}
