@IsTest
public with sharing class OppgaveService_Test {
    @IsTest
    static void getOppgaveById_UserContext_Success() {
        OppgaveService service = new OppgaveService();
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID', 200, 'OK');

        Test.startTest();
        HttpResponse res = service.getOppgaveById('123');
        Test.stopTest();

        Assert.areEqual(200, res.getStatusCode(), 'getOppgaveById should return 200 from mock in User Context');
        Assert.isTrue(String.isNotBlank(service.getTransactionId()), 'TransactionId should be set');
    }

    @IsTest
    static void getOppgaveById_SystemContext_Success() {
        OppgaveService service = new OppgaveService();
        service.setSystemContext();
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.getOppgaveById('999');
        Test.stopTest();

        Assert.areEqual(200, res.getStatusCode(), 'getOppgaveById should return 200 from mock in System Context');
        Assert.isTrue(
            String.isNotBlank(service.getTransactionId()),
            'TransactionId should be set in system context as well'
        );
    }

    @IsTest
    static void getOppgaveById_Error() {
        OppgaveService service = new OppgaveService();
        service.setSystemContext();
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID', 500, 'ERROR');
        Test.startTest();
        HttpResponse res = service.getOppgaveById('999');
        Test.stopTest();

        Assert.areEqual(500, res.getStatusCode(), 'getOppgaveById should return 500 from mock');
        Assert.isTrue(
            String.isNotBlank(service.getTransactionId()),
            'TransactionId should be set in system context as well'
        );
    }

    @IsTest
    static void getOppgaveList_UserContext_Success() {
        OppgaveService service = new OppgaveService();
        CRM_OppgaveQueryList queryList = new CRM_OppgaveQueryList();
        queryList.aktoerId = new List<String>{ '12345' };
        queryList.status = new List<String>{ 'AAPEN', 'FEILREGISTRERT' };

        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.getOppgaveList(queryList);
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'getOppgaveList should return 200 from mock');
    }

    @IsTest
    static void getOppgaveList_SystemContext_Success() {
        OppgaveService service = new OppgaveService();
        service.setSystemContext();
        CRM_OppgaveQueryList queryList = new CRM_OppgaveQueryList();
        queryList.aktoerId = new List<String>{ '12345' };
        queryList.status = new List<String>{ 'AAPEN', 'FEILREGISTRERT' };

        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.getOppgaveList(queryList);
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'getOppgaveList should return 200 from mock');
    }

    @IsTest
    static void getOppgaveList_Error() {
        OppgaveService service = new OppgaveService();
        CRM_OppgaveQueryList queryList = new CRM_OppgaveQueryList();
        queryList.aktoerId = new List<String>{ '12345' };
        queryList.status = new List<String>{ 'AAPEN', 'FEILREGISTRERT' };

        ApiMock.setTestMock('GET_OPPGAVE', 500, 'OK');
        Test.startTest();
        HttpResponse res = service.getOppgaveList(queryList);
        Test.stopTest();
        Assert.areEqual(500, res.getStatusCode(), 'getOppgaveList should return 500 from mock');
    }

    @IsTest
    static void postTask_UserContext_Success() {
        Oppgave request = new Oppgave();
        OppgaveService service = new OppgaveService();
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.postTask(request);
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'postTask should return 200 from mock');
    }

    @IsTest
    static void postTask_SystemContext_Success() {
        OppgaveService service = new OppgaveService();
        service.setSystemContext();
        Oppgave request = new Oppgave();
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.postTask(request);
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'postTask should return 200 from mock');
    }

    @IsTest
    static void postTask_Error() {
        Oppgave request = new Oppgave();
        OppgaveService service = new OppgaveService();
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 500, 'OK');
        Test.startTest();
        HttpResponse res = service.postTask(request);
        Test.stopTest();
        Assert.areEqual(500, res.getStatusCode(), 'postTask should return 500 from mock');
    }

    @IsTest
    static void editTask_UserContext_Success() {
        Oppgave request = new Oppgave();
        OppgaveService service = new OppgaveService();
        request.id = 12345;
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.editTask(request);
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'editTask should return 200 from mock');
    }

    @IsTest
    static void editTask_SystemContext_Success() {
        OppgaveService service = new OppgaveService();
        service.setSystemContext();
        Oppgave request = new Oppgave();
        request.id = 12345;
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.editTask(request);
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'editTask should return 200 from mock');
    }

    @IsTest
    static void editTask_Error() {
        Oppgave request = new Oppgave();
        OppgaveService service = new OppgaveService();
        request.id = 12345;
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 500, 'OK');
        Test.startTest();
        HttpResponse res = service.editTask(request);
        Test.stopTest();
        Assert.areEqual(500, res.getStatusCode(), 'editTask should return 500 from mock');
    }

    @IsTest
    static void editTask_NoId_Error() {
        Oppgave request = new Oppgave();
        OppgaveService service = new OppgaveService();
        ApiMock.setTestMock('PATCH_EDIT_OPPGAVE', 500, 'OK');
        Test.startTest();
        try {
            HttpResponse res = service.editTask(request);
            Assert.fail();
        } catch (OppgaveService.MissingParameterException ex) {
            Assert.isNotNull(ex.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void getTaskTypes_UserContext_Success() {
        OppgaveService service = new OppgaveService();
        ApiMock.setTestMock('GET_OPPGAVETYPE', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.getTaskTypes('FAR');
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'getTaskType should return 200 from mock');
    }

    @IsTest
    static void getTaskTypes_SystemContext_Success() {
        OppgaveService service = new OppgaveService();
        service.setSystemContext();
        ApiMock.setTestMock('GET_OPPGAVETYPE', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.getTaskTypes('FAR');
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'getTaskType should return 200 from mock');
    }

    @IsTest
    static void getTaskTypes_Error() {
        OppgaveService service = new OppgaveService();
        ApiMock.setTestMock('GET_OPPGAVETYPE', 500, 'OK');
        Test.startTest();
        HttpResponse res = service.getTaskTypes('FAR');
        Test.stopTest();
        Assert.areEqual(500, res.getStatusCode(), 'getTaskType should return 500 from mock');
    }

    @IsTest
    static void getGjelderValues_UserContext_Success() {
        OppgaveService service = new OppgaveService();
        ApiMock.setTestMock('GET_OPPGAVE_GJELDER', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.getGjelderValues();
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'getGjelderValues should return 200 from mock');
    }

    @IsTest
    static void getGjelderValues_SystemContext_Success() {
        OppgaveService service = new OppgaveService();
        service.setSystemContext();
        ApiMock.setTestMock('GET_OPPGAVE_GJELDER', 200, 'OK');
        Test.startTest();
        HttpResponse res = service.getGjelderValues();
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'getGjelderValues should return 200 from mock');
    }

    @IsTest
    static void getGjelderValues_Error() {
        OppgaveService service = new OppgaveService();
        ApiMock.setTestMock('GET_OPPGAVE_GJELDER', 500, 'OK');
        Test.startTest();
        HttpResponse res = service.getGjelderValues();
        Test.stopTest();
        Assert.areEqual(500, res.getStatusCode(), 'getGjelderValues should return 500 from mock');
    }
}
