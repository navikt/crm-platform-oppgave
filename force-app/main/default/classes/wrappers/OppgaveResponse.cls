public class OppgaveResponse {
    @invocableVariable(label='Success')
    public Boolean isSuccess;

    @invocableVariable(label='Error message')
    public String errorMessage;

    @invocableVariable(label='Error UUID')
    public String errorUuid;

    @invocableVariable(label='Will be retried?')
    public Boolean isRetry;

    @invocableVariable(label='Oppgave')
    public Oppgave oppgave;

    public static OppgaveResponse success(Oppgave oppgave) {
        OppgaveResponse resp = new OppgaveResponse();
        resp.isSuccess = true;
        resp.oppgave = oppgave;
        return resp;
    }

    public static OppgaveResponse failure(String responseBody, Boolean isRetry) {
        OppgaveResponse resp = new OppgaveResponse();
        resp.isSuccess = false;
        try {
            OppgaveErrorResponse err = (OppgaveErrorResponse) JSON.deserialize(
                responseBody,
                OppgaveErrorResponse.class
            );
            resp.errorMessage = err.feilmelding;
            resp.errorUuid = err.uuid;
            resp.isRetry = isRetry;
        } catch (Exception e) {
            resp.errorMessage = responseBody;
            resp.isRetry = isRetry;
        }
        return resp;
    }

    private class OppgaveErrorResponse {
        public String uuid;
        public String feilmelding;
    }
}
