public class OppgaveResponse {
    @invocableVariable(label='Success')
    @AuraEnabled
    public Boolean isSuccess;

    @invocableVariable(label='Error message')
    @AuraEnabled
    public String errorMessage;

    @invocableVariable(label='Error UUID')
    @AuraEnabled
    public String errorUuid;

    @invocableVariable(label='Will be retried?')
    @AuraEnabled
    public Boolean isRetry;

    @invocableVariable(label='Oppgave')
    @AuraEnabled
    public Oppgave oppgave;

    @invocableVariable(label='Oppgave V2')
    @AuraEnabled
    public OppgaveV2 oppgaveV2;

    public static OppgaveResponse success(Oppgave oppgave) {
        OppgaveResponse resp = new OppgaveResponse();
        resp.isSuccess = true;
        resp.oppgave = oppgave;
        return resp;
    }

    public static OppgaveResponse success(OppgaveV2 oppgave) {
        OppgaveResponse resp = new OppgaveResponse();
        resp.isSuccess = true;
        resp.oppgaveV2 = oppgave;
        return resp;
    }

    public static OppgaveResponse failure(String responseBody, Boolean isRetry) {
        OppgaveResponse resp = new OppgaveResponse();
        resp.isSuccess = false;
        resp.isRetry = isRetry;
        try {
            OppgaveErrorResponse err = (OppgaveErrorResponse) JSON.deserialize(
                responseBody,
                OppgaveErrorResponse.class
            );
            resp.errorMessage = err.detail != null ? err.detail : err.feilmelding;
            resp.errorUuid = err.traceId != null ? err.traceId : err.uuid;
        } catch (Exception e) {
            resp.errorMessage = responseBody;
        }
        return resp;
    }

    // Covers both the v1 error shape and the v2 shape
    private class OppgaveErrorResponse {
        public String uuid;
        public String feilmelding;
        public String detail;
        public String traceId;
    }
}
