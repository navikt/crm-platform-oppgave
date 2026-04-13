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
                resp = (Oppgave) JSON.deserialize(response.getBody(), Oppgave.class);
            } else {
                postLogger.httpError(
                    'Error posting oppgave',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                resp = null;
            }
        } catch (Exception ex) {
            postLogger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
            resp = null;
        } finally {
            postLogger.publish();
        }

        return resp;
    }

    public static Oppgave patchEditTask(OppgaveRequest taskRequest) {
        Oppgave resp = new Oppgave();

        LoggerUtility patchLogger = String.isNotBlank(taskRequest.logCategory)
            ? new LoggerUtility(taskRequest.logCategory)
            : logger;

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
            } else {
                patchLogger.httpError(
                    'Error editing oppgave',
                    response,
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    oppgaveService.getTransactionId()
                );
                resp = null;
            }
        } catch (Exception ex) {
            patchLogger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
            resp = null;
        } finally {
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
        return !persons.isEmpty() && persons[0].HasReadAccess;
    }

    private class OppgaveListResponse {
        private Integer antallTreffTotalt;
        private List<Oppgave> oppgaver;
    }
}
