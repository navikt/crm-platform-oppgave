public with sharing class OppgaveRetry {
    public static Scheduled_Request__c createScheduledRequest(String methodName, String payload) {
        try {
            Scheduled_Request__c schRequest = new Scheduled_Request__c(
                Status__c = 'Scheduled',
                Method__c = methodName,
                Payload__c = payload
            );
            insert schRequest;
            return schRequest;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility('Oppgave Retry');
            logger.error(
                'Could not insert scheduled request for Oppgave. Method:' + methodName + ', payload: ' + payload,
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
            logger.publish();
        }
        return null;
    }

    public static void retryScheduledRequest(List<Scheduled_Request__c> schRequestList) {
        LoggerUtility logger = new LoggerUtility('Oppgave Retry');

        List<Scheduled_Request__c> requestsToUpdate = new List<Scheduled_Request__c>();
        List<Scheduled_Request__c> requestsToDelete = new List<Scheduled_Request__c>();

        for (Scheduled_Request__c schRequest : schRequestList) {
            String method = schRequest.Method__c;
            String requestString = schRequest.Payload__c;
            OppgaveRequest taskRequest = (OppgaveRequest) JSON.deserialize(requestString, OppgaveRequest.class);

            HttpResponse response;
            switch on method {
                when 'Post' {
                    OppgaveService oppgaveService = new OppgaveService();
                    oppgaveService.setSystemContext();

                    response = oppgaveService.postTask(taskRequest.toOppgave());
                }
                when 'Patch' {
                    OppgaveService oppgaveService = new OppgaveService();
                    oppgaveService.setSystemContext();

                    response = oppgaveService.editTask(taskRequest.toOppgave());
                }
                when else {
                    logger.error(
                        'Unknown method for scheduled request retry: ' + method,
                        schRequest,
                        CRM_ApplicationDomain.Domain.NKS
                    );
                    schRequest.status__c = 'Failed';
                    requestsToUpdate.add(schRequest);
                    continue;
                }
            }
            Integer statusCode = response.getStatusCode();
            if (statusCode == 200 || statusCode == 201) {
                logger.info(
                    'Deleting scheduled request after successful retry',
                    schRequest,
                    CRM_ApplicationDomain.Domain.NKS
                );
                requestsToDelete.add(schRequest);
                continue;
            } else if (statusCode == 400 || statusCode == 401 || statusCode == 403 || statusCode == 409) {
                logger.httpError('Error retrying oppgave', response, schRequest, CRM_ApplicationDomain.Domain.NKS);
                schRequest.status__c = 'Failed';
            } else {
                // Log error
                if (schRequest.createdDate < System.now().addDays(-1)) {
                    // If the request is older than 1 day, mark as failed to avoid infinite retry loop
                    logger.httpError(
                        'Error retrying oppgave post. Request marked as critical and failed due to age.',
                        response,
                        schRequest,
                        CRM_ApplicationDomain.Domain.NKS
                    );
                    logger.peek().Log_Level__c = 'Critical';
                    schRequest.status__c = 'Failed';
                } else {
                    logger.httpError(
                        'Error retrying oppgave post',
                        response,
                        schRequest,
                        CRM_ApplicationDomain.Domain.NKS
                    );
                    schRequest.status__c = 'Scheduled';
                }
            }
            requestsToUpdate.add(schRequest);
        }
        update requestsToUpdate;
        delete requestsToDelete;
        logger.publish();
    }
}
