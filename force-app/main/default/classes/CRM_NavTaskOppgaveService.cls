public without sharing class CRM_NavTaskOppgaveService {
    public enum Context {
        SYSTEM_CONTEXT,
        USER_CONTEXT
    }
    private LoggerUtility logger = new LoggerUtility('Oppgave');
    private Context context;
    private String transactionId;

    public CRM_NavTaskOppgaveService() {
    }

    public CRM_NavTaskOppgaveService(Context context) {
        this.context = context;
    }

    public void setContext(Context context) {
        this.context = context;
    }

    /**
     * Get an oppgave by its unique ID
     * @author Stian Ruud Schikora | 03-21-2022
     * @param Id
     * @return HttpResponse
     **/
    public HttpResponse getOppgaveById(String Id) {
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
        Map<String, String> queryParams = new Map<String, String>{ 'id' => Id };

        apiCtrl.initRequest('Oppgave_API', 'GET_OPPGAVE_BY_ID', queryParams);
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setHeaders(httpHeaders);

        addXCorrelation(apiCtrl);
        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }

    /**
     * Submit a query request to oppgave returning N tasks from the endpoint
     * @author Stian Ruud Schikora | 03-21-2022
     * @param query
     * @return HttpResponse
     **/
    public HttpResponse queryOppgave(CRM_OppgaveQuery query) {
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

        apiCtrl.initRequest('Oppgave_API', 'GET_OPPGAVE');
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setHeaders(httpHeaders);
        apiCtrl.setUrlParams(convertToQueryParams(query));

        addXCorrelation(apiCtrl);
        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }

    /**
     * Converts the CRM_OppgaveQuery instance to a valid map og key value pairs that can be added to the HttpRequest
     * @author Stian Ruud Schikora | 03-21-2022
     * @param query
     * @return Map<String, String>
     **/
    private Map<String, String> convertToQueryParams(CRM_OppgaveQuery query) {
        Map<String, String> returnMap = new Map<String, String>();
        String jsonParams = JSON.serialize(query, true); //Suppressing null values
        JSONParser parser = JSON.createParser(jsonParams);

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String key = parser.getText();
                String value;
                parser.nextToken();
                if (key == 'fristFom' || key == 'fristTom') {
                    value = parser.getDatetimeValue().format('yyyy-MM-dd');
                } else if (key == 'opprettetFom') {
                    value = parser.getDatetimeValue().format('yyyy-MM-dd\'T\'HH:mm:ss');
                } else if (key == 'returnlimit') {
                    //limit is reserved in SF so need special parsing handling
                    key = 'limit';
                    value = String.valueOf(parser.getIntegerValue());
                } else {
                    value = parser.getText();
                }

                returnMap.put(key, value);
            }
        }

        return returnMap;
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
        //If no person access, callout is performed in system mode
        switch on this.context {
            when SYSTEM_CONTEXT {
                apiCtrl.setSystemContext();
            }
            when else {
                //No context change
            }
        }
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
        this.transactionId = requestId;
        logger.publish();
    }

    /**
     * @description: Returns UUID of the last API transaction initiated.
     * @author Stian Ruud Schikora | 07-26-2021
     * @return String
     **/
    public String getTransactionId() {
        return this.transactionId;
    }

    private class MissingParameterException extends Exception {
    }
}
