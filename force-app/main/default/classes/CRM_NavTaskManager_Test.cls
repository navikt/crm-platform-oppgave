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
