public without sharing class CRM_NavTaskManager {
    private static LoggerUtility logger = new LoggerUtility('Oppgave');

    @InvocableMethod(label='Process NAV task' category='Task Handling')
    public static List<NavTaskResponse> handleNavTaskRequests(List<NavTaskRequest> taskRequests) {
        List<NavTaskResponse> responseList = new List<NavTaskResponse>();
        Set<String> unitNumbers = new Set<String>();

        for (NavTaskRequest taskRequest : taskRequests) {
            NavTaskResponse response;
            switch on (taskRequest.requestType) {
                when 'POST' {
                    response = postTask(taskRequest);
                }
                when 'EDIT' {
                    response = patchEditTask(taskRequest);
                }
            }
            responseList.add(response);

            if (response.success && response.tildeltEnhetsnr != null) {
                unitNumbers.add(response.tildeltEnhetsnr);
            }  
        }
        Map<String, Id> unitIdByUnitNumber = new Map<String, Id>();
        if (!unitNumbers.isEmpty()) {
            for (NavUnit__c unit : [
                SELECT Id, INT_UnitNumber__c
                FROM NavUnit__c
                WHERE INT_UnitNumber__c IN :unitNumbers
            ]) {
                unitIdByUnitNumber.put(unit.INT_UnitNumber__c, unit.Id);
            }
        }

        for (NavTaskResponse response : responseList) {
            if (response.success && response.tildeltEnhetsnr != null) {
                String unitNumber = response.tildeltEnhetsnr;
                if (unitNumber != null) {
                    response.task.CRM_NavUnit__c = unitIdByUnitNumber.get(unitNumber);
                }
            }
        }
        
        return responseList;
    }

    /**
     * @description: Method to trigger a new post of a previously failed NAV Task
     * @author Stian Ruud Schikora | 09-23-2021
     * @param tasksIdsToRerun
     **/
    public static void rerunFailedTasks(Set<String> tasksIdsToRerun) {
        if (tasksIdsToRerun.size() > Limits.getLimitCallouts() / 2)
            throw new LimitException('List size exceeds callout limit');

        rerunFailedTask(tasksIdsToRerun);
    }

    /**
     * @description: Invokes flow in future context as every interview performs callout followed by DML
     * @author Stian Ruud Schikora | 09-23-2021
     * @param taskId
     **/
    @future
    private static void rerunFailedTask(Set<String> taskIds) {
        Map<String, Object> flowInputs = new Map<String, Object>{ 'recordIds' => taskIds };
        Flow.Interview flow = Flow.Interview.createInterview('CRM_Retry_NAV_Task_Post', flowInputs);
        flow.start();
    }

    /**
     * Get oppgaver for a given actorId that has been created maximum one year back in time
     * @author Stian Ruud Schikora | 03-22-2022
     * @param actorId
     * @return List<CRM_KafkaOppgave>
     **/
    public static CRM_OppgaveQueryResponse getActorOppgaver(String actorId) {
        CRM_OppgaveQuery query = new CRM_OppgaveQuery();
        CRM_OppgaveQueryResponse oppgaveResp;
        query.aktoerId = actorId;
        query.opprettetFom = System.now().addYears(-1); //Get oppgaver for the given actor created maximum og one year back in time
        CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();

        try {
            HttpResponse response = oppgaveService.queryOppgave(query);
            Integer statusCode = response.getStatusCode();

            if (statusCode == 200 || statusCode == 201) {
                oppgaveResp = (CRM_OppgaveQueryResponse) JSON.deserialize(
                    response.getBody(),
                    CRM_OppgaveQueryResponse.class
                );
            } else {
                logger.httpError(
                    'Error getting oppgaver',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
            }
        } catch (Exception ex) {
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        } finally {
            logger.publish();
        }

        return oppgaveResp;
    }

    /**
     * @description: Performs a callout to Oppgave for delegating a NAV task to an external system
     * Task is updated with the external reference and the NAV unit number the task was delegated to
     * @author Stian Ruud Schikora | 11-03-2020
     * @param task [NavTask__c]
     **/
    public static NavTaskResponse postTask(NavTaskRequest taskRequest) {
        NavTaskResponse resp = new NavTaskResponse();
        NavTask__c task = taskRequest.task;

        try {
            CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();
            if (taskRequest.POST_AS_SYSTEM == true) {
                oppgaveService.setContext(CRM_NavTaskOppgaveService.Context.SYSTEM_CONTEXT);
            } else {
                //If user creating request does not have access to the person record, or does not posess a standard license the callout is done in System context
                if (!hasPersonAccess(taskRequest.task) || !UserInfo.getUserType().equalsIgnoreCase('Standard')) {
                    oppgaveService.setContext(CRM_NavTaskOppgaveService.Context.SYSTEM_CONTEXT);
                }
            }

            HttpResponse response = oppgaveService.postTask(createOppgaveRequest(taskRequest));
            Integer statusCode = response.getStatusCode();

            if (statusCode == 200 || statusCode == 201) {
                OppgaveResponse apiResp = (OppgaveResponse) JSON.deserialize(response.getBody(), OppgaveResponse.class);
                task.INT_External_Reference__c = apiResp.id;
                resp.setResponse(true, null, task, apiResp.tildeltEnhetsnr);
            } else {
                logger.httpError(
                    'Error posting oppgave',
                    response,
                    task,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                resp.setResponse(false, oppgaveService.getTransactionId(), task, null);
            }
        } catch (Exception ex) {
            logger.exception(ex, task, CRM_ApplicationDomain.Domain.NKS);
            resp.setResponse(false, logger.peek().UUID__c, task, null);
        } finally {
            logger.publish();
        }

        return resp;
    }

    /**
     * @description: Checks if the running user has access to the person record. Determines context of API callout
     * @author Stian Ruud Schikora | 07-12-2021
     * @param task
     * @return Boolean
     **/
    private static Boolean hasPersonAccess(NavTask__c task) {
        Id userId = UserInfo.getUserId();
        Id personId = [SELECT Id, CRM_Person__c FROM Account WHERE Id = :task.CRM_Account__c]?.CRM_Person__c;

        return getPersonAccess(personId);
    }

    @AuraEnabled(cacheable=true)
    public static Boolean getPersonAccess(String personId) {
        Boolean access = personId != null
            ? [
                  SELECT RecordId, HasReadAccess
                  FROM UserRecordAccess
                  WHERE UserId = :UserInfo.getUserId() AND RecordId = :personId
              ]
              .HasReadAccess
            : false;

        return access;
    }

    /**
     * @description: Performs callout to oppgave API to perform a patch edit of a previously
     * submitted NAV task. Throws an OppgaveException if the callout is unsuccessful
     * @author Stian Ruud Schikora | 11-15-2020
     * @param task [NavTask__c]
     **/
    public static NavTaskResponse patchEditTask(NavTaskRequest taskRequest) {
        NavTaskResponse resp = new NavTaskResponse();
        NavTask__c task = taskRequest.task;

        try {
            CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();
            if (taskRequest.POST_AS_SYSTEM == true) {
                oppgaveService.setContext(CRM_NavTaskOppgaveService.Context.SYSTEM_CONTEXT);
            } else {
                //If user creating request does not have access to the person record, or does not posess a standard license the callout is done in System context
                if (!hasPersonAccess(taskRequest.task) || !UserInfo.getUserType().equalsIgnoreCase('Standard')) {
                    oppgaveService.setContext(CRM_NavTaskOppgaveService.Context.SYSTEM_CONTEXT);
                }
            }

            HttpResponse response = oppgaveService.editTask(createOppgaveRequest(taskRequest));
            Integer statusCode = response.getStatusCode();

            if (statusCode == 200 || statusCode == 201) {
                OppgaveResponse apiResp = (OppgaveResponse) JSON.deserialize(response.getBody(), OppgaveResponse.class);
                task.NKS_Task_Version__c = apiResp.versjon;
                resp.setResponse(true, null, task, null);
            } else {
                logger.httpError(
                    'Error editing oppgave',
                    response,
                    task,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                resp.setResponse(false, oppgaveService.getTransactionId(), task, null);
            }
        } catch (Exception ex) {
            logger.exception(ex, task, CRM_ApplicationDomain.Domain.NKS);
            resp.setResponse(false, logger.peek().UUID__c, task, null);
        } finally {
            logger.publish();
        }

        return resp;
    }

    /**
     * @description: Performs callout to oppgave API to perform a GET for valid task types. Throws an OppgaveException if the callout is unsuccessful
     * @author Celine Tomren | 03-29-2021
     * @param themeCode
     **/
    public static NavTaskTypeResponse getTaskTypes(String themeCode) {
        NavTaskTypeResponse response = new NavTaskTypeResponse();

        CRM_NavTaskOppgaveService oppgaveService = new CRM_NavTaskOppgaveService();

        try {
            HttpResponse httpResp = oppgaveService.getTaskTypes(themeCode);
            Integer statusCode = httpResp.getStatusCode();
            if (statusCode == 200 || statusCode == 201) {
                response.success = true;
                String bodyString = httpResp.getBody();
                if (String.isNotBlank(bodyString)) {
                    bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');
                }
                response.tasktypes = (List<OppgaveTypeResponse>) JSON.deserialize(
                    bodyString,
                    List<OppgaveTypeResponse>.class
                );
            } else {
                logger.httpError(
                    'Error getting task types',
                    httpResp,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                response.success = false;
                response.errorMessage = oppgaveService.getTransactionId();
            }
        } catch (Exception ex) {
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
            response.success = false;
            response.errorMessage = logger.peek().UUID__C;
        } finally {
            logger.publish();
        }

        return response;
    }

    /**
     * @description: Converts the NavTask to a serialized oppgave request
     * @author Stian Ruud Schikora | 11-27-2020
     * @param task
     * @return String
     **/
    private static String createOppgaveJsonRequest(NavTaskRequest taskRequest) {
        return JSON.serialize(new CRM_OppgaveRequest(taskRequest), true);
    }

    /**
     * @description: Converts the NavTask to a serialized oppgave request
     * @author Stian Ruud Schikora | 11-27-2020
     * @param task
     * @return String
     **/
    private static CRM_OppgaveRequest createOppgaveRequest(NavTaskRequest taskRequest) {
        return new CRM_OppgaveRequest(taskRequest);
    }

    //#################################################
    //#### Invocable request and response wrappers ####
    //#################################################

    public class NavTaskRequest {
        @invocableVariable(label='Request type for the NAV task, valid valued are POST or EDIT' required=true)
        public String requestType;
        @invocableVariable
        public NavTask__c task;
        @invocableVariable
        public String themeGroupCode;
        @invocableVariable
        public String themeCode;
        @invocableVariable
        public String subthemeCode;
        @invocableVariable
        public String subtypeCode;
        @invocableVariable
        public String taskTypeCode;
        @invocableVariable
        public String actorId;
        @invocableVariable
        public String assignToUnitNumber;
        @invocableVariable
        public String createdByUnitNumber;
        @invocableVariable(
            label='Default POST is done in user context as long as user has person record access, this value allows to force system-system post'
        )
        public Boolean POST_AS_SYSTEM = false;

        public NavTaskRequest() {
            this.requestType = null;
            this.task = null;
        }

        public NavTaskRequest(String requestType, NavTask__c task) {
            this.requestType = requestType;
            this.task = task;
        }
    }

    public class NavTaskResponse {
        @invocableVariable
        public Boolean success;
        @invocableVariable
        public String errorMessage;
        @invocableVariable
        public NavTask__c task;
        @invocableVariable
        public String tildeltEnhetsNr;

        public NavTaskResponse() {
            this.success = false;
            this.errorMessage = null;
            this.task = null;
            this.tildeltEnhetsNr = null;
        }

        public void setResponse(Boolean success, String errorMessage, NavTask__c task, String tildeltEnhetsNr) {
            this.success = success;
            this.errorMessage = errorMessage;
            this.task = task;
            this.tildeltEnhetsNr = tildeltEnhetsNr;
        }

        public NavTaskResponse(Boolean success, String errorMessage, NavTask__c task, String tildeltEnhetsNr) {
            this.success = success;
            this.errorMessage = errorMessage;
            this.task = task;
            this.tildeltEnhetsNr = tildeltEnhetsNr;
        }
    }

    public class NavTaskTypeResponse {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String errorMessage;
        @AuraEnabled
        public List<OppgaveTypeResponse> tasktypes;

        public NavTaskTypeResponse() {
            this.success = false;
            this.errorMessage = null;
            this.tasktypes = null;
        }
    }

    //### API WRAPPERS ###//

    @testVisible
    private class OppgaveResponse {
        @testVisible
        private Long id;
        @testVisible
        private String tildeltEnhetsnr;
        @testVisible
        private Integer versjon; //Version number of the task needed for the patch/edit callout
    }

    public class OppgaveTypeResponse {
        @AuraEnabled
        public String oppgavetype;

        public OppgaveTypeResponse() {
            this.oppgavetype = null;
        }
    }
}
