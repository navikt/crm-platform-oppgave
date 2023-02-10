/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 10-02-2023
 * @last modified by  : mamikals
 **/
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

    @isTest
    static void testGetOppgaveById() {
        ApiMock.setTestMock('GET_OPPGAVE_BY_ID', 200, 'OK');

        Test.startTest();
        HttpResponse resp = service.getOppgaveById('DummyId');
        Test.stopTest();

        System.assertEquals(200, resp.getStatusCode());
        System.assert(resp.getBody() != null);
    }

    @isTest
    static void testGetOppgaveQuery() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        CRM_OppgaveQuery query = new CRM_OppgaveQuery();
        query.aktoerId = 'Test';
        query.statuskategori = OppgaveStatuskategori.AAPEN;
        query.tildeltEnhetsnr = '4100';
        query.tilordnetRessurs = 'Z999999';
        query.opprettetFom = System.today().addYears(-1);

        Test.startTest();
        HttpResponse resp = service.queryOppgave(query);
        Test.stopTest();

        System.assertEquals(200, resp.getStatusCode());
        System.assert(resp.getBody() != null);
    }

    @isTest
    static void testGetOppgaveQueryList() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.aktoerId = new List<String>{ 'Test' };
        query.statuskategori = OppgaveStatuskategori.AAPEN;
        query.tildeltEnhetsnr = '4100';
        query.tilordnetRessurs = 'Z999999';
        query.fristFom = System.today().addYears(-1);
        query.returnlimit = 100;

        Test.startTest();
        HttpResponse resp = service.queryOppgave(query);
        Test.stopTest();

        System.assertEquals(200, resp.getStatusCode());
        System.assert(resp.getBody() != null);
    }
}
