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
}
