@IsTest
public with sharing class OppgaveRetry_Test {
    // TESTS FOR OPPGAVERETRY HANDLING

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
        OppgaveRetry.retryScheduledRequest(new List<Scheduled_Request__c>{ schRequest });
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
        OppgaveRetry.retryScheduledRequest(new List<Scheduled_Request__c>{ schRequest });
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
        OppgaveRetry.retryScheduledRequest(new List<Scheduled_Request__c>{ schRequest });
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
        OppgaveRetry.retryScheduledRequest(new List<Scheduled_Request__c>{ realSchRequest });
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
        OppgaveRetry.retryScheduledRequest(new List<Scheduled_Request__c>{ schRequest });
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
        OppgaveRetry.retryScheduledRequest(new List<Scheduled_Request__c>{ schRequest });
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
        OppgaveRetry.retryScheduledRequest(new List<Scheduled_Request__c>{ schRequest });
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
        OppgaveRetry.retryScheduledRequest(new List<Scheduled_Request__c>{ realSchRequest });
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
        OppgaveRetry.retryScheduledRequest(new List<Scheduled_Request__c>{ schRequest });
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

    // TEST FOR SCHEDULER

    @IsTest
    static void OppgaveRetry_Schedule() {
        Test.startTest();

        Account a = new Account();
        a.Name = 'OppgaveRetry_Scheduler';
        insert as user a;

        // Schedule the test job

        String CRON_EXP = '0 0 0 3 9 ? 2042';

        String jobId = System.schedule('OppgaveRetry_Scheduler', CRON_EXP, new OppgaveRetry_Scheduler());

        // Get the information from the CronTrigger API object
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
            WITH USER_MODE
        ];

        // Verify the job has not run
        Assert.areEqual(0, ct.TimesTriggered);

        // Verify the next time the job will run
        Assert.areEqual('2042-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }

    // TEST FOR BATCH

    @IsTest
    static void OppgaveRetry_Batch() {
        ApiMock.setTestMock('POST_CREATE_OPPGAVE', 201, 'Created');
        List<Scheduled_Request__c> requests = new List<Scheduled_Request__c>();
        OppgaveRequest oppgReq1 = new OppgaveRequest();
        oppgReq1.personIdent = '12345678901';
        oppgReq1.oppgavetype = 'VURD_HENV';
        OppgaveRequest oppgReq2 = new OppgaveRequest();
        oppgReq2.personIdent = '12345678904';
        oppgReq2.oppgavetype = 'BEH_HENV';
        requests.add(
            new Scheduled_Request__c(Method__c = 'Post', Status__c = 'Scheduled', Payload__c = JSON.serialize(oppgReq1))
        );
        requests.add(
            new Scheduled_Request__c(Method__c = 'Post', Status__c = 'Scheduled', Payload__c = JSON.serialize(oppgReq2))
        );
        insert requests;

        List<Application_Log__c> logsBefore = [SELECT Id FROM Application_Log__c];

        Test.startTest();

        OppgaveRetry_Batch batch = new OppgaveRetry_Batch();
        ID batchprocessid = Database.executebatch(batch);
        Test.stopTest();

        List<Application_Log__c> logsAfter = [
            SELECT Id, Log_Level__c, Category__c, Log_Message__c
            FROM Application_Log__c
        ];

        List<Scheduled_Request__c> schRequestAfter = [
            SELECT Id, Status__c, Payload__c
            FROM Scheduled_Request__c
        ];

        Assert.areEqual(0, schRequestAfter.size(), 'Expected all requests to be processed and deleted');
        Assert.areEqual(0, logsBefore.size(), 'No logs from category before');
        Assert.areEqual(2, logsAfter.size(), 'Two logs from category after');
        for (Application_Log__c log : logsAfter) {
            Assert.areEqual('Info', log.Log_Level__c, 'Should log info level log');
            Assert.areEqual('Oppgave Retry', log.Category__c, 'Should log in Oppgave Retry category');
        }
    }
}
