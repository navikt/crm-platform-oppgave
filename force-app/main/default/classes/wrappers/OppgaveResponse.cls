public class OppgaveResponse {
    @invocableVariable(label='Success')
    public Boolean isSuccess;

    @invocableVariable(label='Error message')
    public String errorMessage;

    @invocableVariable(label='Error UUID')
    public String errorUuid;

    @invocableVariable(label='HTTP status code')
    public Integer statusCode;

    @invocableVariable(label='Oppgave')
    public Oppgave oppgave;

    public static OppgaveResponse success(Oppgave oppgave) {
        OppgaveResponse resp = new OppgaveResponse();
        resp.isSuccess = true;
        resp.oppgave = oppgave;
        return resp;
    }

    public static OppgaveResponse failure(String responseBody, Integer statusCode) {
        OppgaveResponse resp = new OppgaveResponse();
        resp.isSuccess = false;
        try {
            OppgaveErrorResponse err = (OppgaveErrorResponse) JSON.deserialize(
                responseBody,
                OppgaveErrorResponse.class
            );
            resp.errorMessage = err.feilmelding;
            resp.errorUuid = err.uuid;
            resp.statusCode = statusCode;
        } catch (Exception e) {
            resp.errorMessage = responseBody;
            resp.statusCode = statusCode;
        }
        return resp;
    }

    private class OppgaveErrorResponse {
        public String uuid;
        public String feilmelding;
    }
}
