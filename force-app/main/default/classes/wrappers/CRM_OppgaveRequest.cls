public class CRM_OppgaveRequest {
    public Integer id;
    private String tildeltEnhetsnr; //Enheten oppgaven er tildelt. Dersom enhet ikke er angitt, så vil oppgaven automatisk fordeles iht. standard arbeidsfordelingsregler (se norg2)
    private String opprettetAvEnhetsnr;
    private String aktoerId;
    private String journalpostId;
    private String journalpostkilde;
    private String behandlesAvApplikasjon;
    private String orgnr;
    private String tilordnetRessurs;
    private String beskrivelse;
    private String temagruppe;
    private String tema;
    private String behandlingstema;
    private String oppgavetype; // REQUIRED
    private String behandlingstype;
    private String aktivDato; //Datestring, REQUIRED
    private String fristFerdigstillelse; //Datestring
    private String prioritet; // [HOY, NORM, LAV],
    private Integer versjon;
    private String saksreferanse; //NKS-111 adding support for relating task to existing NAV Cases
    private OppgaveMetadata metadata;

    public CRM_OppgaveRequest() {
    }

    //Constructor for converting a NavTaskRequest to a valid API oppgave request
    public CRM_OppgaveRequest(CRM_NavTaskManager.NavTaskRequest taskRequest) {
        NavTask__c task = taskRequest.task;

        DateTime dueDate = task.CRM_DueDate__c;
        fristFerdigstillelse = dueDate.format('yyyy-MM-dd');
        journalpostId = task.INT_Journal_Entry_Id__c;
        prioritet = String.valueOf(task.CRM_Priority__c); //Using String.valueOf() as there is an issue when this is passed from a flow pickslit: https://trailblazer.salesforce.com/issues_view?id=a1p3A0000003fH1QAI
        aktoerId = taskRequest.actorId;
        oppgavetype = taskRequest.taskTypeCode;
        aktivDato = Datetime.now().format('yyyy-MM-dd');
        beskrivelse = task.NKS_Comments__c;
        tildeltEnhetsnr = taskRequest.assignToUnitNumber;
        tilordnetRessurs = task.NKS_Assignee__c; //NKS -205 support for delegating NAV task to oneself in GoSys
        opprettetAvEnhetsnr = taskRequest.createdByUnitNumber;
        versjon = taskRequest.requestType == 'EDIT' ? Integer.valueOf(task.NKS_Task_Version__c) : null;
        id = taskRequest.requestType == 'EDIT' ? Integer.valueOf(task.INT_External_Reference__c) : null;
        tema = taskRequest.themeCode;
        behandlingstema = taskRequest.subthemeCode;
        behandlingstype = taskRequest.subtypeCode;
        saksreferanse = task.NKS_NAV_Case_Reference__c;
        if (String.isNotBlank(task.NKS_Henvendelse_BehandlingsId__c)) {
            metadata = new OppgaveMetadata(task.NKS_Henvendelse_BehandlingsId__c);
        }
    }
    private class OppgaveMetadata {
        private String EKSTERN_HENVENDELSE_ID;

        public OppgaveMetadata(String EKSTERN_HENVENDELSE_ID) {
            this.EKSTERN_HENVENDELSE_ID = EKSTERN_HENVENDELSE_ID;
        }
    }
}
