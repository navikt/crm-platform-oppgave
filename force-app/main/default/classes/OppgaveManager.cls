public with sharing class OppgaveManager {
    static LoggerUtility logger = new LoggerUtility('Oppgave');

    @AuraEnabled
    public static OppgaveV2 getOppgaveById(String oppgaveId) {
        OppgaveService service = new OppgaveService();
        HttpResponse response = service.getOppgaveById(oppgaveId);
        if (response.getStatusCode() == 200) {
            String body = response.getBody().replace('"system":', '"systemKilde":');
            OppgaveV2 oppgave = (OppgaveV2) JSON.deserialize(body, OppgaveV2.class);
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
    public static Map<String, Person__c> getPersonInfo(List<String> personIdents) {
        Map<String, Person__c> result = new Map<String, Person__c>();
        if (personIdents == null || personIdents.isEmpty()) {
            return result;
        }
        for (Person__c p : [
            SELECT Name, CRM_FullName__c, CRM_Age__c
            FROM Person__c
            WHERE Name IN :personIdents
        ]) {
            result.put(p.Name, p);
        }
        return result;
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
        query.returnLimit = 500;
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
        OppgaveService service = new OppgaveService('getOppgaver', CRM_ApplicationDomain.Domain.NKS, true);
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

    @invocableMethod(label='Execute Oppgave' category='Oppgave')
    public static List<OppgaveResponse> executeOppgave(List<OppgaveRequest> taskRequest) {
        List<OppgaveResponse> responses = new List<OppgaveResponse>();
        for (OppgaveRequest request : taskRequest) {
            switch on request.methodType {
                when 'POST' {
                    responses.add(postTask(request));
                }
                when 'PATCH' {
                    responses.add(patchEditTask(request));
                }
                when else {
                    throw new IllegalArgumentException('Unknown methodType: ' + request.methodType);
                }
            }
        }
        return responses;
    }

    public static OppgaveResponse postTask(OppgaveRequest request) {
        LoggerUtility postLogger = String.isNotBlank(request.logCategory)
            ? new LoggerUtility(request.logCategory)
            : logger;

        Boolean retry = true;
        OppgaveResponse result;
        try {
            Boolean systemContext = false;
            if (
                request.POST_AS_SYSTEM == true ||
                !hasPersonAccess(request) ||
                !UserInfo.getUserType().equalsIgnoreCase('Standard')
            ) {
                systemContext = true;
            }

            OppgaveService oppgaveService = new OppgaveService(
                request.logCategory,
                CRM_ApplicationDomain.Domain.NKS,
                systemContext
            );
            HttpResponse response = oppgaveService.postTask(request.toOppgave());
            Integer statusCode = response.getStatusCode();
            if (statusCode == 200 || statusCode == 201) {
                retry = false;
                result = OppgaveResponse.success((Oppgave) JSON.deserialize(response.getBody(), Oppgave.class));
            } else if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
                // No retry
                retry = false;
                postLogger.httpError(
                    'Error posting oppgave',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                result = OppgaveResponse.failure(response.getBody(), retry);
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
                result = OppgaveResponse.failure(response.getBody(), retry);
            }
        } catch (Exception ex) {
            postLogger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
            return OppgaveResponse.failure(ex.getMessage(), retry);
        } finally {
            if (retry) {
                String scheduledRequest = JSON.serialize(request);
                OppgaveRetry.createScheduledRequest('Post', scheduledRequest);
            }
            postLogger.publish();
        }
        return result;
    }

    @AuraEnabled
    public static OppgaveResponse patchEditTask(OppgaveRequest request) {
        LoggerUtility patchLogger = String.isNotBlank(request.logCategory)
            ? new LoggerUtility(request.logCategory)
            : logger;

        Boolean retry = true;
        OppgaveResponse result;
        try {
            if (request.versjon == null || request.versjon == 0) {
                throw new IllegalArgumentException('Versjon is required for edit requests');
            }

            Boolean systemContext = false;
            if (
                request.POST_AS_SYSTEM == true ||
                !hasPersonAccess(request) ||
                !UserInfo.getUserType().equalsIgnoreCase('Standard')
            ) {
                systemContext = true;
            }

            OppgaveService oppgaveService = new OppgaveService(
                request.logCategory,
                CRM_ApplicationDomain.Domain.NKS,
                systemContext
            );
            HttpResponse response = oppgaveService.editTask(request.toOppgave());
            Integer statusCode = response.getStatusCode();

            if (statusCode == 200 || statusCode == 201) {
                retry = false;
                result = OppgaveResponse.success((Oppgave) JSON.deserialize(response.getBody(), Oppgave.class));
            } else if (statusCode == 400 || statusCode == 401 || statusCode == 403 || statusCode == 409) {
                // No retry
                retry = false;
                patchLogger.httpError(
                    'Error editing oppgave',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                result = OppgaveResponse.failure(response.getBody(), retry);
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
                result = OppgaveResponse.failure(response.getBody(), retry);
            }
        } catch (Exception ex) {
            patchLogger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
            return OppgaveResponse.failure(ex.getMessage(), retry);
        } finally {
            if (retry) {
                try {
                    String scheduledRequest = JSON.serialize(request);
                    OppgaveRetry.createScheduledRequest('Patch', scheduledRequest);
                } catch (Exception except) {
                    patchLogger.exception(except, null, CRM_ApplicationDomain.Domain.NKS);
                }
            }
            patchLogger.publish();
        }
        return result;
    }

    private static Boolean hasPersonAccess(OppgaveRequest taskRequest) {
        if (String.isBlank(taskRequest.personIdent)) {
            return false;
        }
        List<Person__c> persons = [
            SELECT Id
            FROM Person__c
            WHERE Name = :taskRequest.personIdent
            LIMIT 1
        ];
        return !persons.isEmpty();
    }

    private class OppgaveListResponse {
        private Integer antallTreffTotalt;
        private List<Oppgave> oppgaver;
    }
}
