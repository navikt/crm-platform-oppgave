@isTest
public class CRM_NavTaskManager_Test {
    @TestSetup
    static void makeData() {
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavTask__c());
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavUnit__c(INT_UnitNumber__c = '4100'));
    }

    @isTest
    static void testTaskPost() {
        String responseBody;
        CRM_NavTaskManager.OppgaveResponse resp = new CRM_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        NavTask__c task = getTask();

        CRM_NavTaskManager.NavTaskRequest taskRequest = new CRM_NavTaskManager.NavTaskRequest('POST', task);
        taskRequest.themeGroupCode = 'ARBD';
        taskRequest.themeCode = 'AAP';
        taskRequest.subthemeCode = 'ab0039';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', JSON.serialize(resp), null));

        Test.startTest();
        List<CRM_NavTaskManager.NavTaskResponse> taskResponses = CRM_NavTaskManager.handleNavTaskRequests(
            new List<CRM_NavTaskManager.NavTaskRequest>{ taskRequest }
        );
        Test.stopTest();

        System.assert(taskResponses[0].success);
    }

    @isTest
    static void testTaskPostFail() {
        String responseBody;
        CRM_NavTaskManager.OppgaveResponse resp = new CRM_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        NavTask__c task = getTask();

        CRM_NavTaskManager.NavTaskRequest taskRequest = new CRM_NavTaskManager.NavTaskRequest('POST', task);
        taskRequest.themeGroupCode = 'ARBD';
        taskRequest.themeCode = 'AAP';
        taskRequest.subthemeCode = 'ab0039';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(403, 'Forbidden', JSON.serialize(resp), null));

        Test.startTest();
        CRM_NavTaskManager.handleNavTaskRequests(new List<CRM_NavTaskManager.NavTaskRequest>{ taskRequest });
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Application_Log__c WHERE Log_Level__c = 'Error'] == 1);
    }

    @isTest
    static void testTaskPatch() {
        String responseBody;
        CRM_NavTaskManager.OppgaveResponse resp = new CRM_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        NavTask__c task = getTask();
        task.CRM_Priority__c = 'NORM';
        task.INT_External_Reference__c = 123456789;

        CRM_NavTaskManager.NavTaskRequest taskRequest = new CRM_NavTaskManager.NavTaskRequest('EDIT', task);
        taskRequest.themeGroupCode = 'ARBD';
        taskRequest.themeCode = 'AAP';
        taskRequest.subthemeCode = 'ab0039';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', JSON.serialize(resp), null));

        Test.startTest();
        List<CRM_NavTaskManager.NavTaskResponse> taskResponses = CRM_NavTaskManager.handleNavTaskRequests(
            new List<CRM_NavTaskManager.NavTaskRequest>{ taskRequest }
        );
        Test.stopTest();

        System.assert(taskResponses[0].success);
    }

    @isTest
    static void testTaskPatchFail() {
        String responseBody;
        CRM_NavTaskManager.OppgaveResponse resp = new CRM_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        resp.versjon = 2;
        NavTask__c task = getTask();
        task.CRM_Priority__c = 'NORM';
        task.INT_External_Reference__c = 123456789;

        CRM_NavTaskManager.NavTaskRequest taskRequest = new CRM_NavTaskManager.NavTaskRequest('EDIT', task);
        taskRequest.themeGroupCode = 'ARBD';
        taskRequest.themeCode = 'AAP';
        taskRequest.subthemeCode = 'ab0039';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(404, 'Not found', JSON.serialize(resp), null));

        Test.startTest();
        CRM_NavTaskManager.handleNavTaskRequests(new List<CRM_NavTaskManager.NavTaskRequest>{ taskRequest });
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Application_Log__c WHERE Log_Level__c = 'Error'] == 1);
    }

    @isTest
    static void testTaskTypeGet() {
        CRM_NavTaskManager.OppgaveTypeResponse resp = new CRM_NavTaskManager.OppgaveTypeResponse();
        resp.oppgavetype = 'VURD_HENV';

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(
                200,
                'OK',
                JSON.serialize(new List<CRM_NavTaskManager.OppgaveTypeResponse>{ resp }),
                null
            )
        );

        Test.startTest();
        CRM_NavTaskManager.NavTaskTypeResponse typeResponse = CRM_NavTaskManager.getTaskTypes('AAP');
        Test.stopTest();

        System.assert(!typeResponse.tasktypes.isEmpty());
    }

    @isTest
    static void testTaskTypeGetFail() {
        CRM_NavTaskManager.OppgaveTypeResponse resp = new CRM_NavTaskManager.OppgaveTypeResponse();
        resp.oppgavetype = 'VURD_HENV';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(404, 'Not found', JSON.serialize(resp), null));

        Test.startTest();
        CRM_NavTaskManager.getTaskTypes('AAP');
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Application_Log__c WHERE Log_Level__c = 'Error'] == 1);
    }

    @isTest
    static void testRerunFailedTasks() {
        CRM_NavTaskManager.OppgaveResponse resp = new CRM_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '1234567891012'));
        Account personAcc = [SELECT Id FROM Account WHERE CRM_Person__r.INT_ActorId__c = '1234567891012' LIMIT 1];
        NavUnit__c nUnit = [SELECT Id FROM NavUnit__c LIMIT 1];
        NavTask__c task = getTask();
        task.CRM_Account__c = personAcc.Id;
        task.CRM_NavUnit__c = nUnit.Id;
        update task;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', JSON.serialize(resp), null));

        Test.startTest();
        CRM_NavTaskManager.rerunFailedTasks(new Set<String>{ task.Id });
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM NavTask__c WHERE INT_External_Reference__c = 123456789]);
    }

    @isTest
    static void testGetActorOppgaver() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');
        List<NavTask__c> convertedTasks;
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '1234567891113'));
        Test.startTest();
        CRM_OppgaveQueryResponse queryResp = CRM_NavTaskManager.getActorOppgaver('1234567891113');
        Test.stopTest();

        convertedTasks = queryResp.convertToNavTasks();

        System.assert(convertedTasks != null);
    }

    private static NavTask__c getTask() {
        return [
            SELECT
                Id,
                CRM_Account__c,
                CRM_DueDate__c,
                INT_Journal_Entry_Id__c,
                CRM_Priority__c,
                NKS_Comments__c,
                NKS_Assignee__c,
                NKS_Task_Version__c,
                NKS_NAV_Case_Reference__c,
                NKS_Henvendelse_BehandlingsId__c
            FROM NavTask__c
            LIMIT 1
        ];
    }
}
