@IsTest
public with sharing class OppgaveRetry_Test {
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
        OppgaveRetry.retryScheduledRequest(schRequest);
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
        OppgaveRetry.retryScheduledRequest(schRequest);
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
        OppgaveRetry.retryScheduledRequest(schRequest);
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
        OppgaveRetry.retryScheduledRequest(realSchRequest);
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
        OppgaveRetry.retryScheduledRequest(schRequest);
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
        OppgaveRetry.retryScheduledRequest(schRequest);
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
        OppgaveRetry.retryScheduledRequest(schRequest);
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
        OppgaveRetry.retryScheduledRequest(realSchRequest);
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
        OppgaveRetry.retryScheduledRequest(schRequest);
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
