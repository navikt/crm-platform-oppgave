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
    static void retryScheduledRequest_Post_200_Success() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        String payload = JSON.serialize(taskRequest);

        Scheduled_Request__c schRequest = new Scheduled_Request__c(
            Method__c = 'Post',
            Status__c = 'Scheduled',
            Payload__c = payload
        );
        insert schRequest;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c];

        Test.startTest();
        OppgaveManager.retryScheduledRequest(schRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, Log_Level__c, Category__c
            FROM Application_Log__c
        ];

        List<Scheduled_Request__c> schRequestAfter = [SELECT Id FROM Scheduled_Request__c WHERE Id = :schRequest.Id];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Application_Log__c log = logsAfter[0];
        Assert.areEqual('Info', log.Log_Level__c, 'Should log info level log');
        Assert.areEqual('Oppgave Retry', log.Category__c, 'Should log in Oppgave Retry category');
        Assert.isTrue(schRequestAfter.isEmpty(), 'Request should have been deleted');
    }

    @IsTest
    static void retryScheduledRequest_Post_400_Error() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 400, 'Bad Request');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = 'Geir';
        String payload = JSON.serialize(taskRequest);

        Scheduled_Request__c schRequest = new Scheduled_Request__c(
            Method__c = 'Post',
            Status__c = 'Scheduled',
            Payload__c = payload
        );
        insert schRequest;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c];

        Test.startTest();
        OppgaveManager.retryScheduledRequest(schRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, Log_Level__c, Category__c
            FROM Application_Log__c
        ];

        List<Scheduled_Request__c> schRequestAfter = [
            SELECT Id, Status__c
            FROM Scheduled_Request__c
            WHERE Id = :schRequest.Id
        ];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Application_Log__c log = logsAfter[0];
        Assert.areEqual('Error', log.Log_Level__c, 'Should log error level log');
        Assert.areEqual('Oppgave Retry', log.Category__c, 'Should log in Oppgave Retry category');
        Assert.isFalse(schRequestAfter.isEmpty(), 'Request should still be there');
        Assert.areEqual('Failed', schRequestAfter[0].Status__c, 'Request status should be Failed');
    }

    @IsTest
    static void retryScheduledRequest_Post_500_Error() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 500, 'Internal Server Error');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        String payload = JSON.serialize(taskRequest);

        Scheduled_Request__c schRequest = new Scheduled_Request__c(
            Method__c = 'Post',
            Status__c = 'Scheduled',
            Payload__c = payload
        );
        insert schRequest;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c];

        Test.startTest();
        OppgaveManager.retryScheduledRequest(schRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, Log_Level__c, Category__c
            FROM Application_Log__c
        ];

        List<Scheduled_Request__c> schRequestAfter = [
            SELECT Id, Status__c
            FROM Scheduled_Request__c
            WHERE Id = :schRequest.Id
        ];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Application_Log__c log = logsAfter[0];
        Assert.areEqual('Error', log.Log_Level__c, 'Should log error level log');
        Assert.areEqual('Oppgave Retry', log.Category__c, 'Should log in Oppgave Retry category');
        Assert.isFalse(schRequestAfter.isEmpty(), 'Request should still be there');
        Assert.areEqual('Scheduled', schRequestAfter[0].Status__c, 'Request status should be Scheduled');
    }

    @IsTest
    static void retryScheduledRequest_Post_500_OldRequest_Error() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 500, 'Internal Server Error');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        String payload = JSON.serialize(taskRequest);

        Scheduled_Request__c schRequest = new Scheduled_Request__c(
            Method__c = 'Post',
            Status__c = 'Scheduled',
            Payload__c = payload
        );
        insert schRequest;
        Test.setCreatedDate(schRequest.Id, DateTime.now().addDays(-2));

        // We fetch the record agin to get the updated CreatedDate after Test.setCreatedDate
        Scheduled_Request__c realSchRequest = [
            SELECT Id, Method__c, Status__c, Payload__c, CreatedDate
            FROM Scheduled_Request__c
            WHERE Id = :schRequest.Id
        ];

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c];

        Test.startTest();
        OppgaveManager.retryScheduledRequest(realSchRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, Log_Level__c, Category__c
            FROM Application_Log__c
        ];

        List<Scheduled_Request__c> schRequestAfter = [
            SELECT Id, Status__c
            FROM Scheduled_Request__c
            WHERE Id = :realSchRequest.Id
        ];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Application_Log__c log = logsAfter[0];
        Assert.areEqual('Critical', log.Log_Level__c, 'Should log critical level log');
        Assert.areEqual('Oppgave Retry', log.Category__c, 'Should log in Oppgave Retry category');
        Assert.isFalse(schRequestAfter.isEmpty(), 'Request should still be there');
        Assert.areEqual('Failed', schRequestAfter[0].Status__c, 'Request status should be Failed');
    }

    @IsTest
    static void retryScheduledRequest_Patch_200_Success() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'OK');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678902';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        String payload = JSON.serialize(taskRequest);

        Scheduled_Request__c schRequest = new Scheduled_Request__c(
            Method__c = 'Patch',
            Status__c = 'Scheduled',
            Payload__c = payload
        );
        insert schRequest;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c];

        Test.startTest();
        OppgaveManager.retryScheduledRequest(schRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, Log_Level__c, Category__c
            FROM Application_Log__c
        ];

        List<Scheduled_Request__c> schRequestAfter = [SELECT Id FROM Scheduled_Request__c WHERE Id = :schRequest.Id];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Application_Log__c log = logsAfter[0];
        Assert.areEqual('Info', log.Log_Level__c, 'Should log info level log');
        Assert.areEqual('Oppgave Retry', log.Category__c, 'Should log in Oppgave Retry category');
        Assert.isTrue(schRequestAfter.isEmpty(), 'Request should have been deleted');
    }

    @IsTest
    static void retryScheduledRequest_Patch_400_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 400, 'Bad Request');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        String payload = JSON.serialize(taskRequest);

        Scheduled_Request__c schRequest = new Scheduled_Request__c(
            Method__c = 'Patch',
            Status__c = 'Scheduled',
            Payload__c = payload
        );
        insert schRequest;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c];

        Test.startTest();
        OppgaveManager.retryScheduledRequest(schRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, Log_Level__c, Category__c
            FROM Application_Log__c
        ];

        List<Scheduled_Request__c> schRequestAfter = [
            SELECT Id, Status__c
            FROM Scheduled_Request__c
            WHERE Id = :schRequest.Id
        ];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Application_Log__c log = logsAfter[0];
        Assert.areEqual('Error', log.Log_Level__c, 'Should log error level log');
        Assert.areEqual('Oppgave Retry', log.Category__c, 'Should log in Oppgave Retry category');
        Assert.isFalse(schRequestAfter.isEmpty(), 'Request should still be there');
        Assert.areEqual('Failed', schRequestAfter[0].Status__c, 'Request status should be Failed');
    }

    @IsTest
    static void retryScheduledRequest_Patch_500_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 500, 'Internal Server Error');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        String payload = JSON.serialize(taskRequest);

        Scheduled_Request__c schRequest = new Scheduled_Request__c(
            Method__c = 'Patch',
            Status__c = 'Scheduled',
            Payload__c = payload
        );
        insert schRequest;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c];

        Test.startTest();
        OppgaveManager.retryScheduledRequest(schRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, Log_Level__c, Category__c
            FROM Application_Log__c
        ];

        List<Scheduled_Request__c> schRequestAfter = [
            SELECT Id, Status__c
            FROM Scheduled_Request__c
            WHERE Id = :schRequest.Id
        ];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Application_Log__c log = logsAfter[0];
        Assert.areEqual('Error', log.Log_Level__c, 'Should log error level log');
        Assert.areEqual('Oppgave Retry', log.Category__c, 'Should log in Oppgave Retry category');
        Assert.isFalse(schRequestAfter.isEmpty(), 'Request should still be there');
        Assert.areEqual('Scheduled', schRequestAfter[0].Status__c, 'Request status should be Scheduled');
    }

    @IsTest
    static void retryScheduledRequest_Patch_500_OldRequest_Error() {
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 500, 'Internal Server Error');
        OppgaveRequest taskRequest = new OppgaveRequest();
        taskRequest.personIdent = '12345678901';
        taskRequest.id = 12345;
        taskRequest.versjon = 2;
        String payload = JSON.serialize(taskRequest);

        Scheduled_Request__c schRequest = new Scheduled_Request__c(
            Method__c = 'Patch',
            Status__c = 'Scheduled',
            Payload__c = payload
        );
        insert schRequest;
        Test.setCreatedDate(schRequest.Id, DateTime.now().addDays(-2));

        // We fetch the record agin to get the updated CreatedDate after Test.setCreatedDate
        Scheduled_Request__c realSchRequest = [
            SELECT Id, Method__c, Status__c, Payload__c, CreatedDate
            FROM Scheduled_Request__c
            WHERE Id = :schRequest.Id
        ];

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c];

        Test.startTest();
        OppgaveManager.retryScheduledRequest(realSchRequest);
        Test.stopTest();
        List<Application_Log__c> logsAfter = [
            SELECT Id, Log_Level__c, Category__c
            FROM Application_Log__c
        ];

        List<Scheduled_Request__c> schRequestAfter = [
            SELECT Id, Status__c, createdDate
            FROM Scheduled_Request__c
            WHERE Id = :realSchRequest.Id
        ];

        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Application_Log__c log = logsAfter[0];
        Assert.areEqual('Critical', log.Log_Level__c, 'Should log critical level log');
        Assert.areEqual('Oppgave Retry', log.Category__c, 'Should log in Oppgave Retry category');
        Assert.isFalse(schRequestAfter.isEmpty(), 'Request should still be there');
        Assert.areEqual('Failed', schRequestAfter[0].Status__c, 'Request status should be Failed');
    }

    @IsTest
    static void retryScheduledRequest_UnknownMethod_Error() {
        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c WHERE Category__c = 'Oppgave Retry'];
        Scheduled_Request__c schRequest = new Scheduled_Request__c(
            Method__c = 'Unknown',
            Status__c = 'Scheduled',
            Payload__c = '{}'
        );
        insert schRequest;
        Test.startTest();
        OppgaveManager.retryScheduledRequest(schRequest);
        Test.stopTest();

        List<Scheduled_Request__c> schRequestAfter = [
            SELECT Id, Status__c
            FROM Scheduled_Request__c
            WHERE Id = :schRequest.Id
        ];

        List<Application_Log__c> logsAfter = [
            SELECT Id, Log_Level__c, Category__c
            FROM Application_Log__c
            WHERE Category__c = 'Oppgave Retry'
        ];
        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(1, logsAfter.size(), 'One log from category after');
        Application_Log__c log = logsAfter[0];
        Assert.areEqual('Error', log.Log_Level__c, 'Should log error level log');
        Assert.areEqual('Oppgave Retry', log.Category__c, 'Should log in Oppgave Retry category');
        Assert.isFalse(schRequestAfter.isEmpty(), 'Request should still be there');
        Assert.areEqual('Failed', schRequestAfter[0].Status__c, 'Request status should be Failed');
    }
}
