public without sharing class CRM_NavTaskOppgaveService {
    public enum Context {
        SYSTEM_CONTEXT,
        USER_CONTEXT
    }
    private LoggerUtility logger = new LoggerUtility('Oppgave');
    private Context context;

    public CRM_NavTaskOppgaveService() {
    }

    public CRM_NavTaskOppgaveService(Context context) {
        this.context = context;
    }

    public void setContext(Context context) {
        this.context = context;
    }

    /**
     * @description: Performs callout to oppgave API to create a new task
     * @author Stian Ruud Schikora | 07-26-2021
     * @param request
     * @return HttpResponse
     **/
    public HttpResponse postTask(CRM_OppgaveRequest request) {
        //Static context requires own instance of the API controller
        ApiController apiCtrl = new ApiController();
        Map<String, String> httpHeaders = new Map<String, String>{
            'Content-Type' => 'application/json',
            'accept' => 'application/json'
        };
        //If no person access, callout is performed in system mode
        switch on this.context {
            when SYSTEM_CONTEXT {
                apiCtrl.setSystemContext();
            }
            when else {
                //No context change
            }
        }
        apiCtrl.initRequest('Oppgave_API', 'POST_CREATE_OPPGAVE');
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setHeaders(httpHeaders);
        apiCtrl.setBody(JSON.serialize(request, true));

        addXCorrelation(apiCtrl);
        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }

    /**
     * @description: Performs a callout to oppgave API to update an existing task
     * @author Stian Ruud Schikora | 07-26-2021
     * @param request
     * @return HttpResponse
     **/
    public HttpResponse editTask(CRM_OppgaveRequest request) {
        if (request.id == 0 || request.id == null) {
            throw new MissingParameterException('Request ID is required for edit requests');
        }

        //Static context requires own instance of the API controller
        ApiController apiCtrl = new ApiController();
        Map<String, String> httpHeaders = new Map<String, String>{
            'Content-Type' => 'application/json',
            'accept' => 'application/json'
        };
        //If no person access, callout is performed in system mode
        switch on this.context {
            when SYSTEM_CONTEXT {
                apiCtrl.setSystemContext();
            }
            when else {
                //No context change
            }
        }
        Map<String, String> paramMap = new Map<String, String>{ 'id' => String.valueOf(request.id) };
        apiCtrl.initRequest('Oppgave_API', 'PATCH_EDIT_OPPGAVE', paramMap);
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setHeaders(httpHeaders);
        apiCtrl.setBody(JSON.serialize(request, true));

        addXCorrelation(apiCtrl);
        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }

    /**
     * @description: Calls oppgave API to retrieve the valid oppgave types for the given theme code
     * @author Stian Ruud Schikora | 07-26-2021
     * @param themeCode
     * @return HttpResponse
     **/
    public HttpResponse getTaskTypes(String themeCode) {
        Map<String, String> httpHeaders = new Map<String, String>{
            'Content-Type' => 'application/json',
            'accept' => 'application/json'
        };

        ApiController apiCtrl = new ApiController();
        Map<String, String> paramMap = new Map<String, String>{ 'tema' => themeCode };
        apiCtrl.initRequest('Oppgave_API', 'GET_OPPGAVETYPE', paramMap);
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setHeaders(httpHeaders);

        addXCorrelation(apiCtrl);
        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }

    /**
     * @description: Calls oppgave API to retrieve all gjelder values
     * @author mamikals | 15-09-2021
     * @return HttpResponse
     **/
    public HttpResponse getGjelderValues() {
        Map<String, String> httpHeaders = new Map<String, String>{
            'Content-Type' => 'application/json',
            'accept' => 'application/json'
        };

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('Oppgave_API', 'GET_OPPGAVE_GJELDER');
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setHeaders(httpHeaders);

        addXCorrelation(apiCtrl);
        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }

    /**
     * @description: Adds the required X-Correlation header to the API request
     * @author Stian Ruud Schikora | 11-27-2020
     * @param apiCtrl
     * @param logger
     * @param task
     **/
    private void addXCorrelation(ApiController apiCtrl) {
        String requestId = logger.apiTransaction(
            apiCtrl.getrequestEndpoint(),
            apiCtrl.getRequest(),
            CRM_ApplicationDomain.Domain.NKS
        );
        apiCtrl.addHeader('X-Correlation-ID', requestId); //Adds the unique transaction ID to the request
    }

    /**
     * @description: Returns UUID of the last API transaction initiated.
     * @author Stian Ruud Schikora | 07-26-2021
     * @return String
     **/
    public String getTransactionId() {
        return this.logger.peek() != null ? this.logger.peek().UUID__c : null;
    }

    private class MissingParameterException extends Exception {
    }
}
