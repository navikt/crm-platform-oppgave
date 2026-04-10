/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 10-02-2023
 * @last modified by  : mamikals
 **/
public without sharing class OppgaveService extends ApiController {
    private Boolean isSystemContext = false;
    private String transactionId;

    public OppgaveService() {
        LoggerUtility logger = new LoggerUtility('Oppgave');
        setLogCategory('Oppgave')
            .setLogger(logger)
            .setLogCalloutRequest()
            .publishLogAfterCallout()
            .setLogDomain(CRM_ApplicationDomain.Domain.NKS);
        addServiceAuthHeader('Oppgave');
        setHeaders(new Map<String, String>{ 'Content-Type' => 'application/json', 'accept' => 'application/json' });
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
        switch on this.apiContext {
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
        initRequest('Oppgave_API', 'GET_OPPGAVE_BY_ID', new Map<String, String>{ 'id' => Id });
        addXCorrelation();

        doCallout();
        return getResponse();
    }

    public HttpResponse getOppgaveList(CRM_OppgaveQueryList query) {
        initRequest('Oppgave_API', 'GET_OPPGAVE');
        Map<String, List<String>> convertedParams = convertToQueryParams(query);
        for (String param : convertedParams.keySet()) {
            if (!convertedParams.get(param).isEmpty()) {
                for (String paramValue : convertedParams.get(param)) {
                    addUrlParam(param, paramValue);
                }
            }
        }

        addXCorrelation();
        doCallout();
        return getResponse();
    }

    public HttpResponse postTask(Oppgave request) {
        initRequest('Oppgave_API', 'POST_CREATE_OPPGAVE');
        setBody(JSON.serialize(request, true));

        addXCorrelation();
        doCallout();
        return getResponse();
    }

    public HttpResponse editTask(Oppgave request) {
        if (request.id == 0 || request.id == null) {
            throw new MissingParameterException('Request ID is required for edit requests');
        }

        initRequest('Oppgave_API', 'PATCH_EDIT_OPPGAVE', new Map<String, String>{ 'id' => String.valueOf(request.id) });
        setBody(JSON.serialize(request, true));

        addXCorrelation();
        doCallout();
        return getResponse();
    }

    public HttpResponse getTaskTypes(String themeCode) {
        initRequest('Oppgave_API', 'GET_OPPGAVETYPE', new Map<String, String>{ 'tema' => themeCode });

        addXCorrelation();
        doCallout();
        return getResponse();
    }

    public HttpResponse getGjelderValues() {
        initRequest('Oppgave_API', 'GET_OPPGAVE_GJELDER');

        addXCorrelation();
        doCallout();
        return getResponse();
    }

    private void addXCorrelation() {
        String requestId = new Uuid().getValue();
        addHeader('X-Correlation-ID', requestId); //Adds the unique transaction ID to the request
        transactionId = requestId;
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

    public String getTransactionId() {
        return this.transactionId;
    }

    @TestVisible
    private class MissingParameterException extends Exception {
    }
}
