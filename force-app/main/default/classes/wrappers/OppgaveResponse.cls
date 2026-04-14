public class OppgaveResponse {
    @invocableVariable(label='Success')
    public Boolean isSuccess;

    @invocableVariable(label='Error message')
    public String errorMessage;

    @invocableVariable(label='Error UUID')
    public String errorUuid;

    @invocableVariable(label='Oppgave')
    public Oppgave oppgave;

    public static OppgaveResponse success(Oppgave oppgave) {
        OppgaveResponse resp = new OppgaveResponse();
        resp.isSuccess = true;
        resp.oppgave = oppgave;
        return resp;
    }

    public static OppgaveResponse failure(String responseBody) {
        OppgaveResponse resp = new OppgaveResponse();
        resp.isSuccess = false;
        try {
            OppgaveErrorResponse err = (OppgaveErrorResponse) JSON.deserialize(
                responseBody,
                OppgaveErrorResponse.class
            );
            resp.errorMessage = err.feilmelding;
            resp.errorUuid = err.uuid;
        } catch (Exception e) {
            resp.errorMessage = responseBody;
        }
        return resp;
    }

    private class OppgaveErrorResponse {
        public String uuid;
        public String feilmelding;
    }
}
