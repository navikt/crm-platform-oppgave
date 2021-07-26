@isTest
public class CRM_NavTaskOppgaveService_Test {
    static CRM_NavTaskOppgaveService service = new CRM_NavTaskOppgaveService();
    static CRM_NavTaskOppgaveService systemService = new CRM_NavTaskOppgaveService(
        CRM_NavTaskOppgaveService.context.SYSTEM_CONTEXT
    );
    @isTest
    static void testPostOppgave() {
        CRM_OppgaveRequest request = new CRM_OppgaveRequest();

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', 'OK!', null));

        Test.startTest();
        HttpResponse response = service.postTask(request);
        Test.stopTest();

        System.assertEquals(200, response.getStatusCode());
        System.assertNotEquals(null, service.getTransactionId(), 'No transaction ID');
    }

    @isTest
    static void testEditOppgave() {
        CRM_OppgaveRequest request = new CRM_OppgaveRequest();
        request.id = 1234567;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', 'OK!', null));

        Test.startTest();
        HttpResponse response = service.editTask(request);
        Test.stopTest();

        System.assertEquals(200, response.getStatusCode());
        System.assertNotEquals(null, service.getTransactionId(), 'No transaction ID');
    }

    @isTest
    static void testGetTaskType() {
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', 'Something', null));

        Test.startTest();
        HttpResponse response = service.getTaskTypes('AAP');
        Test.stopTest();

        System.assertEquals(200, response.getStatusCode());
        System.assertNotEquals(null, service.getTransactionId(), 'No transaction ID');
    }

    @isTest
    static void testEditOppgaveMissingId() {
        CRM_OppgaveRequest request = new CRM_OppgaveRequest();
        request.id = null;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', 'OK!', null));

        Test.startTest();
        try {
            HttpResponse response = service.editTask(request);
            System.assert(false);
        } catch (Exception ex) {
            System.assert(true);
        }
        Test.stopTest();
    }
}
