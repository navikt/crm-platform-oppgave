public with sharing class OppgaveManager {
    static LoggerUtility logger = new LoggerUtility('Oppgave');

    // TODO: Will be implemented as part of getOppgaveById when oppgave v2 api is ready by appending ?include=kommentarer in req.
    /*@AuraEnabled
    public static List<CRM_OppgaveOppfolging> getOppgaveOppfolging(String oppgaveId) {
        OppgaveService service = new OppgaveService();
        HttpResponse response = service.getOppgaveOppfolgingById(oppgaveId);
        if (response.getStatusCode() == 200) {
            List<CRM_OppgaveOppfolging> oppfolgingList = (List<CRM_OppgaveOppfolging>) JSON.deserialize(
                response.getBody(),
                List<CRM_OppgaveOppfolging>.class
            );
            return oppfolgingList;
        } else {
            logger.httpError(
                'Error getting oppgaveOppfolging by ID',
                response,
                null,
                CRM_ApplicationDomain.Domain.NKS,
                service.getTransactionId()
            );
        }
        return null;
    }*/

    @AuraEnabled
    public static Oppgave getOppgaveById(String oppgaveId) {
        OppgaveService service = new OppgaveService();
        HttpResponse response = service.getOppgaveById(oppgaveId);
        if (response.getStatusCode() == 200) {
            Oppgave oppgave = (Oppgave) JSON.deserialize(response.getBody(), Oppgave.class);
            return oppgave;
        } else {
            logger.httpError(
                'Error getting oppgave by ID',
                response,
                null,
                CRM_ApplicationDomain.Domain.NKS,
                service.getTransactionId()
            );
            logger.publish();
        }
        return null;
    }

    @AuraEnabled
    public static List<Oppgave> getAllAssignedOpenOppgaver(String navIdent) {
        OppgaveService service = new OppgaveService();
        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.tilordnetRessurs = navIdent;
        query.statuskategori = OppgaveStatuskategori.AAPEN;
        HttpResponse response = service.getOppgaveList(query);
        if (response.getStatusCode() == 200) {
            OppgaveListResponse oppgaver = (OppgaveListResponse) JSON.deserialize(
                response.getBody(),
                OppgaveListResponse.class
            );
            return oppgaver.oppgaver;
        } else {
            logger.httpError(
                'Error getting assigned open oppgaver',
                response,
                null,
                CRM_ApplicationDomain.Domain.NKS,
                service.getTransactionId()
            );
            logger.publish();
        }
        return null;
    }

    @AuraEnabled
    public static List<Oppgave> getOpenOppgaver(String personIdent, Integer offset) {
        OppgaveService service = new OppgaveService();
        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.aktoerId = new List<String>{ personIdent };
        query.statuskategori = OppgaveStatuskategori.AAPEN;
        query.returnLimit = 100;
        if (offset != null && offset > 0) {
            query.offset = offset;
        }

        HttpResponse response = service.getOppgaveList(query);
        if (response.getStatusCode() == 200) {
            OppgaveListResponse oppgaver = (OppgaveListResponse) JSON.deserialize(
                response.getBody(),
                OppgaveListResponse.class
            );
            return oppgaver.oppgaver;
        } else {
            logger.httpError(
                'Error getting open oppgaver for person',
                response,
                null,
                CRM_ApplicationDomain.Domain.NKS,
                service.getTransactionId()
            );
            logger.publish();
        }
        return null;
    }

    @AuraEnabled
    public static List<Oppgave> getAllOppgaver(String personIdent, Integer offset) {
        OppgaveService service = new OppgaveService();
        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.aktoerId = new List<String>{ personIdent };
        query.returnLimit = 100;
        if (offset != null && offset > 0) {
            query.offset = offset;
        }

        HttpResponse response = service.getOppgaveList(query);
        if (response.getStatusCode() == 200) {
            OppgaveListResponse oppgaver = (OppgaveListResponse) JSON.deserialize(
                response.getBody(),
                OppgaveListResponse.class
            );
            return oppgaver.oppgaver;
        } else {
            logger.httpError(
                'Error getting all oppgaver for person',
                response,
                null,
                CRM_ApplicationDomain.Domain.NKS,
                service.getTransactionId()
            );
            logger.publish();
        }
        return null;
    }

    public static List<Oppgave> getOppgaver(CRM_OppgaveQueryList query) {
        OppgaveService service = new OppgaveService();
        HttpResponse response = service.getOppgaveList(query);
        if (response.getStatusCode() == 200) {
            OppgaveListResponse oppgaver = (OppgaveListResponse) JSON.deserialize(
                response.getBody(),
                OppgaveListResponse.class
            );
            return oppgaver.oppgaver;
        } else {
            logger.httpError(
                'Error getting oppgaver',
                response,
                null,
                CRM_ApplicationDomain.Domain.NKS,
                service.getTransactionId()
            );
            logger.publish();
        }
        return null;
    }

    public static Oppgave postTask(OppgaveRequest taskRequest) {
        Oppgave resp = new Oppgave();

        LoggerUtility postLogger = String.isNotBlank(taskRequest.logCategory)
            ? new LoggerUtility(taskRequest.logCategory)
            : logger;

        Boolean retry = true;
        try {
            OppgaveService oppgaveService = new OppgaveService();
            if (
                taskRequest.POST_AS_SYSTEM == true ||
                !hasPersonAccess(taskRequest) ||
                !UserInfo.getUserType().equalsIgnoreCase('Standard')
            ) {
                oppgaveService.setSystemContext();
            }

            HttpResponse response = oppgaveService.postTask(taskRequest.toOppgave());
            Integer statusCode = response.getStatusCode();
            if (statusCode == 200 || statusCode == 201) {
                retry = false;
                resp = (Oppgave) JSON.deserialize(response.getBody(), Oppgave.class);
            } else if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
                // No retry
                retry = false;
                // Throw error to show frontend cause and message
                postLogger.httpError(
                    'Error posting oppgave',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                resp = null;
            } else {
                // Retry
                retry = true;
                // Log error
                postLogger.httpError(
                    'Error posting oppgave',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                postLogger.peek().Log_Level__c = 'Warning';
                resp = null;
            }
        } catch (Exception ex) {
            postLogger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
            resp = null;
        } finally {
            if (retry) {
                try {
                    String request = JSON.serialize(taskRequest);
                    createScheduledRequest('Post', request);
                } catch (Exception except) {
                    postLogger.exception(except, null, CRM_ApplicationDomain.Domain.NKS);
                    resp = null;
                }
            }
            postLogger.publish();
        }

        return resp;
    }

    public static Oppgave patchEditTask(OppgaveRequest taskRequest) {
        Oppgave resp = new Oppgave();

        LoggerUtility patchLogger = String.isNotBlank(taskRequest.logCategory)
            ? new LoggerUtility(taskRequest.logCategory)
            : logger;

        Boolean retry = true;
        try {
            OppgaveService oppgaveService = new OppgaveService();
            if (
                taskRequest.POST_AS_SYSTEM == true ||
                !hasPersonAccess(taskRequest) ||
                !UserInfo.getUserType().equalsIgnoreCase('Standard')
            ) {
                oppgaveService.setSystemContext();
            }

            HttpResponse response = oppgaveService.editTask(taskRequest.toOppgave());
            Integer statusCode = response.getStatusCode();

            if (statusCode == 200 || statusCode == 201) {
                resp = (Oppgave) JSON.deserialize(response.getBody(), Oppgave.class);
            } else if (statusCode == 400 || statusCode == 401 || statusCode == 403 || statusCode == 409) {
                // No retry
                retry = false;
                // Throw error to show frontend cause and message
                patchLogger.httpError(
                    'Error editing oppgave',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                resp = null;
            } else {
                // Retry
                retry = true;
                // Log error
                patchLogger.httpError(
                    'Error editing oppgave',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                patchLogger.peek().Log_Level__c = 'Warning';
                resp = null;
            }
        } catch (Exception ex) {
            patchLogger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
            resp = null;
        } finally {
            if (retry) {
                try {
                    String request = JSON.serialize(taskRequest);
                    createScheduledRequest('Patch', request);
                } catch (Exception except) {
                    patchLogger.exception(except, null, CRM_ApplicationDomain.Domain.NKS);
                    resp = null;
                }
            }
            patchLogger.publish();
        }

        return resp;
    }

    private static Boolean hasPersonAccess(OppgaveRequest taskRequest) {
        if (String.isBlank(taskRequest.personIdent)) {
            return false;
        }
        List<Person__c> persons = [
            SELECT Id, HasReadAccess
            FROM Person__c
            WHERE Name = :taskRequest.personIdent
            LIMIT 1
        ];
        return !persons.isEmpty();
    }

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

    public static void retryScheduledRequest(Scheduled_Request__c schRequest) {
        LoggerUtility logger = new LoggerUtility('Oppgave Retry');

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
                logger.publish();
                schRequest.status__c = 'Failed';
                update schRequest;
                return;
            }
        }
        Integer statusCode = response.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            logger.info(
                'Deleting scheduled request after successful retry',
                schRequest,
                CRM_ApplicationDomain.Domain.NKS
            );
            delete schRequest;
            logger.publish();
            return;
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
                logger.httpError('Error retrying oppgave post', response, schRequest, CRM_ApplicationDomain.Domain.NKS);
                schRequest.status__c = 'Scheduled';
            }
        }
        update schRequest;
        logger.publish();
    }

    private class OppgaveListResponse {
        private Integer antallTreffTotalt;
        private List<Oppgave> oppgaver;
    }
}
