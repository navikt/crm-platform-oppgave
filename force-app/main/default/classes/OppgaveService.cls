/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 10-02-2023
 * @last modified by  : mamikals
 **/
public without sharing class OppgaveService {
    public enum Context {
        SYSTEM_CONTEXT,
        USER_CONTEXT
    }
    private LoggerUtility logger = new LoggerUtility('Oppgave');
    private Context context;
    private String transactionId;

    public OppgaveService() {
    }

    public OppgaveService(Context context) {
        this.context = context;
    }

    public void setContext(Context context) {
        this.context = context;
    }

    // TODO: Will be implemented as part of getOppgaveById when oppgave v2 api is ready by appending ?include=kommentarer in req.
    /*
    public HttpResponse getOppgaveOppfolgingById(String Id) {
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

        apiCtrl.initRequest('Oppgave_API', 'GET_OPPGAVEOPPFOLGING_BY_ID', queryParams);
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setHeaders(httpHeaders);

        addXCorrelation(apiCtrl);
        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }*/

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

    public HttpResponse getOppgaveList(CRM_OppgaveQueryList query) {
        ApiController apiCtrl = setupController('GET_OPPGAVE');
        Map<String, List<String>> convertedParams = convertToQueryParams(query);
        for (String param : convertedParams.keySet()) {
            if (!convertedParams.get(param).isEmpty()) {
                for (String paramValue : convertedParams.get(param)) {
                    apiCtrl.addUrlParam(param, paramValue);
                }
            }
        }

        addXCorrelation(apiCtrl);
        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }

    private ApiController setupController(String request) {
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

        apiCtrl.initRequest('Oppgave_API', request);
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setHeaders(httpHeaders);
        return apiCtrl;
    }

    private Map<String, String> convertToQueryParams(CRM_OppgaveQuery query) {
        Map<String, String> returnMap = new Map<String, String>();
        String jsonParams = JSON.serialize(query, true); //Suppressing null values
        JSONParser parser = JSON.createParser(jsonParams);

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String key = parser.getText();
                String value;
                parser.nextToken();
                if (key.equals('fristFom') || key.equals('fristTom')) {
                    value = parser.getDatetimeValue().format('yyyy-MM-dd');
                } else if (key.equals('opprettetFom')) {
                    value = parser.getDatetimeValue().format('yyyy-MM-dd\'T\'HH:mm:ss');
                } else if (key.equals('returnlimit')) {
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

    private Map<String, List<String>> convertToQueryParams(CRM_OppgaveQueryList query) {
        Map<String, List<String>> returnMap = new Map<String, List<String>>();
        String jsonParams = JSON.serialize(query, true); //Suppressing null values
        JSONParser parser = JSON.createParser(jsonParams);

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String key = parser.getText();
                List<String> value = new List<String>();
                parser.nextToken();

                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                    while (parser.nextToken() != JSONToken.END_ARRAY) {
                        addFilteredQueryParams(parser, key, value);
                    }
                } else {
                    addFilteredQueryParams(parser, key, value);
                }
                returnMap.put(key, value);
            }
        }

        return returnMap;
    }

    private void addFilteredQueryParams(JSONParser parser, String key, List<String> value) {
        if (key.equals('fristFom') || key.equals('fristTom')) {
            value.add(parser.getDatetimeValue().format('yyyy-MM-dd'));
        } else if (key.equals('opprettetFom')) {
            value.add(parser.getDatetimeValue().format('yyyy-MM-dd\'T\'HH:mm:ss'));
        } else if (key.equals('returnlimit')) {
            //limit is reserved in SF so need special parsing handling
            key = 'limit';
            value.add(String.valueOf(parser.getIntegerValue()));
        } else {
            value.add(parser.getText());
        }
    }

    public HttpResponse postTask(Oppgave request) {
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

    public HttpResponse editTask(Oppgave request) {
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

    private void addXCorrelation(ApiController apiCtrl) {
        String requestId = new Uuid().getValue();
        apiCtrl.addHeader('X-Correlation-ID', requestId); //Adds the unique transaction ID to the request
        this.transactionId = requestId;
        logger.publish();
    }

    public String getTransactionId() {
        return this.transactionId;
    }

    private class MissingParameterException extends Exception {
    }
}
