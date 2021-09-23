public with sharing class CRM_NavTaskManager {
    private static LoggerUtility logger = new LoggerUtility('Oppgave');

    @InvocableMethod(label='Process NAV task' category='Task Handling')
    public static List<NavTaskResponse> handleNavTaskRequests(List<NavTaskRequest> taskRequests) {
        List<NavTaskResponse> responseList = new List<NavTaskResponse>();

        for (NavTaskRequest taskRequest : taskRequests) {
            switch on (taskRequest.requestType) {
                when 'POST' {
                    responseList.add(postTask(taskRequest));
                }
                when 'EDIT' {
                    responseList.add(patchEditTask(taskRequest));
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
        if (tasksIdsToRerun.size() > Limits.getLimitFutureCalls())
            throw new LimitException('List size exceeds future call limit');

        for (String taskId : tasksIdsToRerun) {
            rerunFailedTask(taskId);
        }
    }

    /**
     * @description: Invokes flow in future context as every interview performs callout followed by DML
     * @author Stian Ruud Schikora | 09-23-2021
     * @param taskId
     **/
    @future
    private static void rerunFailedTask(String taskId) {
        Map<String, Object> flowInputs = new Map<String, Object>{ 'recordId' => taskId };
        Flow.Interview flow = Flow.Interview.createInterview('CRM_Retry_NAV_Task_Post', flowInputs);
        flow.start();
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
            //formatComment(taskRequest); Moving comment formating to flow
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
                task.CRM_NavUnit__c = [
                    SELECT Id
                    FROM NavUnit__c
                    WHERE INT_UnitNumber__c = :apiResp.tildeltEnhetsnr
                    LIMIT 1
                ]
                ?.Id; //Setting the appropriate NAV unit received from the API
                resp.setResponse(true, null, task);
            } else {
                logger.httpError(
                    'Error posting oppgave',
                    response,
                    task,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                resp.setResponse(false, oppgaveService.getTransactionId(), task);
            }
        } catch (Exception ex) {
            logger.exception(ex, task, CRM_ApplicationDomain.Domain.NKS);
            resp.setResponse(false, logger.peek().UUID__c, task);
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

        Boolean access = personId != null
            ? [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId = :userId AND RecordId = :personId]
              .HasReadAccess
            : false;

        return access;
    }

    /**
     * @description: Introduce default comment formating equal to other NAV systems
     * @author Stian Ruud Schikora | 07-06-2021
     * @param taskRequest
     **/
    private static void formatComment(NavTaskRequest taskRequest) {
        String navIdent = [SELECT Id, CRM_NAV_Ident__c FROM User WHERE Id = :UserInfo.getUserId()]?.CRM_NAV_Ident__c;

        String commentHeader =
            '--- ' +
            Datetime.now().format('dd.MM.yyyy HH:mm') +
            ' ' +
            UserInfo.getName() +
            ' (' +
            navIdent +
            ', ' +
            taskRequest.createdByUnitNumber +
            ') ---';
        taskRequest.task.NKS_Comments__c = commentHeader + '\n' + taskRequest.task.NKS_Comments__c;
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
            formatComment(taskRequest);
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
                resp.setResponse(true, null, task);
            } else {
                logger.httpError(
                    'Error editing oppgave',
                    response,
                    task,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                resp.setResponse(false, oppgaveService.getTransactionId(), task);
            }
        } catch (Exception ex) {
            logger.exception(ex, task, CRM_ApplicationDomain.Domain.NKS);
            resp.setResponse(false, logger.peek().UUID__c, task);
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

        public NavTaskResponse() {
            this.success = false;
            this.errorMessage = null;
            this.task = null;
        }

        public void setResponse(Boolean success, String errorMessage, NavTask__c task) {
            this.success = success;
            this.errorMessage = errorMessage;
            this.task = task;
        }

        public NavTaskResponse(Boolean success, String errorMessage, NavTask__c task) {
            this.success = success;
            this.errorMessage = errorMessage;
            this.task = task;
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
