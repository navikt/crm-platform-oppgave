public without sharing class OppgaveService extends ApiController {
    private String transactionId;

    public OppgaveService() {
        this('Oppgave', CRM_ApplicationDomain.Domain.NKS, false);
    }

    public OppgaveService(String logCategory, CRM_ApplicationDomain.Domain domain) {
        this(logCategory, domain, false);
    }

    public OppgaveService(String logCategory, CRM_ApplicationDomain.Domain domain, Boolean systemContext) {
        String loggingCategory = String.isNotBlank(logCategory) ? logCategory : 'Oppgave';
        CRM_ApplicationDomain.Domain loggingDomain = domain != null ? domain : CRM_ApplicationDomain.Domain.NKS;
        LoggerUtility logger = new LoggerUtility(loggingCategory);
        setLogCategory(loggingCategory)
            .setLogger(logger)
            .setLogCalloutRequest()
            .publishLogAfterCallout()
            .setLogDomain(loggingDomain);
        // Set system context for callouts made from batch due to session cache not being supported in batch, which causes authentication to fail for callouts made from batch
        // System token uses platform cache - OBO token uses session cache
        if (systemContext) {
            setSystemContext();
        }
        setHeaders(new Map<String, String>{ 'Content-Type' => 'application/json', 'accept' => 'application/json' });
    }

    public HttpResponse getOppgaveById(String Id) {
        initRequest('Oppgave_API', 'GET_OPPGAVE_BY_ID_V2', new Map<String, String>{ 'id' => Id });
        addSaasProxyServiceAuthHeader();
        addUrlParam('include', 'kommentarer');
        addUrlParam('include', 'utvidelser');
        addXCorrelation();

        doCallout();
        return getResponse();
    }

    public HttpResponse getOppgaveList(CRM_OppgaveQueryList query) {
        initRequest('Oppgave_API', 'GET_OPPGAVE');
        addSaasProxyServiceAuthHeader();
        Map<String, String> convertedParams = convertToQueryParams(query);
        for (String param : convertedParams.keySet()) {
            String paramValue = convertedParams.get(param);
            addUrlParam(param, paramValue);
        }

        addXCorrelation();
        doCallout();
        return getResponse();
    }

    public HttpResponse postTask(Oppgave request) {
        initRequest('Oppgave_API', 'POST_CREATE_OPPGAVE');
        addSaasProxyServiceAuthHeader();
        setBody(JSON.serialize(request, true));
        addXCorrelation();
        doCallout();
        return getResponse();
    }

    public HttpResponse editTask(Oppgave request) {
        if (request.id == 0 || request.id == null) {
            throw new MissingParameterException('Request ID is required for edit requests');
        }
        if (request.versjon == 0 || request.versjon == null) {
            throw new MissingParameterException('Versjon is required for edit requests');
        }

        initRequest('Oppgave_API', 'PATCH_EDIT_OPPGAVE', new Map<String, String>{ 'id' => String.valueOf(request.id) });
        addSaasProxyServiceAuthHeader();
        setBody(JSON.serialize(request, true));
        addXCorrelation();
        doCallout();
        return getResponse();
    }

    public HttpResponse getTaskTypes(String themeCode) {
        initRequest('Oppgave_API', 'GET_OPPGAVETYPE', new Map<String, String>{ 'tema' => themeCode });
        addSaasProxyServiceAuthHeader();
        addXCorrelation();
        doCallout();
        return getResponse();
    }

    public HttpResponse getGjelderValues() {
        initRequest('Oppgave_API', 'GET_OPPGAVE_GJELDER');
        addSaasProxyServiceAuthHeader();
        addXCorrelation();
        doCallout();
        return getResponse();
    }

    private void addXCorrelation() {
        String requestId = new Uuid().getValue();
        addHeader('X-Correlation-ID', requestId); //Adds the unique transaction ID to the request
        transactionId = requestId;
    }

    private Map<String, String> convertToQueryParams(CRM_OppgaveQueryList query) {
        Map<String, String> returnMap = new Map<String, String>();
        String jsonParams = JSON.serialize(query, true); //Suppressing null values
        JSONParser parser = JSON.createParser(jsonParams);

        while (parser.nextToken() != null) {
            // Loop until we find a field name, then format the key and value accordingly. This allows us to handle both simple values and arrays in the query object.
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String key = formatKeyName(parser.getText());
                String value;
                parser.nextToken();

                // Check if the value is an array, if so, convert it to a comma-separated string
                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                    List<String> valueList = new List<String>();
                    while (parser.nextToken() != JSONToken.END_ARRAY) {
                        // Add each value in the array to the list after formatting it
                        valueList.add(formatQueryParam(parser, key));
                    }
                    // Join the list into a comma-separated string for the query parameter
                    value = String.join(valueList, ',');
                } else {
                    value = formatQueryParam(parser, key);
                }

                returnMap.put(key, value);
            }
        }

        return returnMap;
    }

    private String formatKeyName(String key) {
        // Limit is a reserved keyword in Apex
        switch on key {
            when 'returnLimit' {
                return 'limit';
            }
            when else {
                return key;
            }
        }
    }

    private String formatQueryParam(JSONParser parser, String key) {
        // Format the param to the expected format
        if (key.equals('fristFom') || key.equals('fristTom')) {
            return parser.getDatetimeValue().format('yyyy-MM-dd');
        } else if (key.equals('opprettetFom')) {
            return parser.getDatetimeValue().format('yyyy-MM-dd\'T\'HH:mm:ss');
        } else if (key.equals('returnlimit')) {
            return String.valueOf(parser.getIntegerValue());
        } else {
            return parser.getText();
        }
    }

    public String getTransactionId() {
        return this.transactionId;
    }

    @TestVisible
    private class MissingParameterException extends Exception {
    }
}
