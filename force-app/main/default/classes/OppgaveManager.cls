public with sharing class OppgaveManager {
    static LoggerUtility logger = new LoggerUtility('Oppgave');

    // 'system' is a reserved identifier in Apex, so the API's "system" property is mapped to
    // OppgaveV2.TidspunktAv.systemKilde before deserializing.
    private static OppgaveV2 deserializeOppgaveV2(String body) {
        return (OppgaveV2) JSON.deserialize(body.replace('"system":', '"systemKilde":'), OppgaveV2.class);
    }

    @AuraEnabled
    public static OppgaveV2 getOppgaveById(String oppgaveId) {
        OppgaveService service = new OppgaveService();
        HttpResponse response = service.getOppgaveById(oppgaveId);
        if (response.getStatusCode() == 200) {
            return deserializeOppgaveV2(response.getBody());
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
        query.returnLimit = 500;
        query.sorteringsfelt = 'OPPRETTET_TIDSPUNKT';
        query.sorteringsrekkefolge = 'DESC';
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
    public static List<Oppgave> getOpenOppgaver(String personIdent, Integer offset, List<String> ytelser) {
        OppgaveService service = new OppgaveService();
        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.aktoerId = new List<String>{ personIdent };
        query.statuskategori = OppgaveStatuskategori.AAPEN;
        query.returnLimit = 200;
        query.sorteringsfelt = 'OPPRETTET_TIDSPUNKT';
        query.sorteringsrekkefolge = 'DESC';
        if (offset != null && offset > 0) {
            query.offset = offset;
        }
        query.tema = getTemaCodes(ytelser);

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
    public static List<Oppgave> getAllOppgaver(String personIdent, Integer offset, List<String> ytelser) {
        OppgaveService service = new OppgaveService();
        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.aktoerId = new List<String>{ personIdent };
        query.returnLimit = 200;
        query.sorteringsfelt = 'OPPRETTET_TIDSPUNKT';
        query.sorteringsrekkefolge = 'DESC';
        if (offset != null && offset > 0) {
            query.offset = offset;
        }
        query.tema = getTemaCodes(ytelser);

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
        List<Scheduled_Request__c> pendingRetries = new List<Scheduled_Request__c>();

        String userDepartment = getUserDepartment();
        AccessCache accessCache = buildAccessCache(taskRequest);

        for (OppgaveRequest request : taskRequest) {
            switch on request.methodType {
                when 'POST' {
                    responses.add(postTask(request, pendingRetries, userDepartment, accessCache));
                }
                when 'PATCH' {
                    responses.add(patchEditTask(request, pendingRetries, userDepartment, accessCache));
                }
                when else {
                    throw new IllegalArgumentException('Unknown methodType: ' + request.methodType);
                }
            }
        }
        OppgaveRetry.insertScheduledRequests(pendingRetries);
        return responses;
    }

    public static OppgaveResponse postTask(OppgaveRequest request) {
        String userDepartment = getUserDepartment();
        AccessCache accessCache = buildAccessCache(new List<OppgaveRequest>{ request });
        return postTask(request, null, userDepartment, accessCache);
    }

    private static OppgaveResponse postTask(
        OppgaveRequest request,
        List<Scheduled_Request__c> pendingRetries,
        String userDepartment,
        AccessCache accessCache
    ) {
        LoggerUtility postLogger = String.isNotBlank(request.logCategory)
            ? new LoggerUtility(request.logCategory)
            : logger;

        Boolean retry = true;
        OppgaveResponse result;
        String idempotencyKey = new Uuid().getValue();
        try {
            Boolean systemContext = false;
            if (
                request.POST_AS_SYSTEM == true ||
                !hasPersonAccess(request, accessCache) ||
                !UserInfo.getUserType().equalsIgnoreCase('Standard')
            ) {
                systemContext = true;
            }

            // meta.representerer.enhet.nr must be set when created by a veileder (OBO), and must not be set
            // when performed by system (CCF)
            if (systemContext) {
                request.opprettetAvEnhetsnr = null;
            } else if (String.isBlank(request.opprettetAvEnhetsnr)) {
                request.opprettetAvEnhetsnr = userDepartment;
            }

            OppgaveService oppgaveService = new OppgaveService(
                request.logCategory,
                CRM_ApplicationDomain.Domain.NKS,
                systemContext
            );
            HttpResponse response = oppgaveService.postTask(request.toOppgaveV2(), idempotencyKey);
            Integer statusCode = response.getStatusCode();
            if (statusCode == 200 || statusCode == 201) {
                retry = false;
                result = OppgaveResponse.success(deserializeOppgaveV2(response.getBody()));
            } else if (statusCode == 400 || statusCode == 401 || statusCode == 403 || statusCode == 422) {
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
                Scheduled_Request__c schRequest = OppgaveRetry.buildScheduledRequest(
                    'Post',
                    JSON.serialize(request),
                    idempotencyKey
                );
                if (pendingRetries != null) {
                    pendingRetries.add(schRequest);
                } else {
                    OppgaveRetry.insertScheduledRequests(new List<Scheduled_Request__c>{ schRequest });
                }
            }
            postLogger.publish();
        }
        return result;
    }

    @AuraEnabled
    public static OppgaveResponse postTaskFromLwc(String requestJson) {
        OppgaveRequest request = (OppgaveRequest) JSON.deserialize(requestJson, OppgaveRequest.class);
        return postTask(request);
    }

    @AuraEnabled
    public static OppgaveResponse patchEditTaskFromLwc(String requestJson) {
        OppgaveRequest request = (OppgaveRequest) JSON.deserialize(requestJson, OppgaveRequest.class);
        return patchEditTask(request);
    }

    @AuraEnabled
    public static OppgaveResponse patchEditTask(OppgaveRequest request) {
        String userDepartment = getUserDepartment();
        AccessCache accessCache = buildAccessCache(new List<OppgaveRequest>{ request });
        return patchEditTask(request, null, userDepartment, accessCache);
    }

    private static OppgaveResponse patchEditTask(
        OppgaveRequest request,
        List<Scheduled_Request__c> pendingRetries,
        String userDepartment,
        AccessCache accessCache
    ) {
        LoggerUtility patchLogger = String.isNotBlank(request.logCategory)
            ? new LoggerUtility(request.logCategory)
            : logger;

        Boolean retry = true;
        OppgaveResponse result;
        try {
            if (request.versjon == null || request.versjon == 0) {
                throw new IllegalArgumentException('Versjon is required for edit requests');
            }

            if (String.isBlank(request.endretAvEnhetsnr)) {
                request.endretAvEnhetsnr = userDepartment;
            }

            Boolean systemContext = false;
            if (
                request.POST_AS_SYSTEM == true ||
                !hasPersonAccess(request, accessCache) ||
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
                    Scheduled_Request__c schRequest = OppgaveRetry.buildScheduledRequest(
                        'Patch',
                        JSON.serialize(request),
                        null
                    );
                    if (pendingRetries != null) {
                        pendingRetries.add(schRequest);
                    } else {
                        OppgaveRetry.insertScheduledRequests(new List<Scheduled_Request__c>{ schRequest });
                    }
                } catch (Exception except) {
                    patchLogger.exception(except, null, CRM_ApplicationDomain.Domain.NKS);
                }
            }
            patchLogger.publish();
        }
        return result;
    }

    private static Boolean hasPersonAccess(OppgaveRequest taskRequest, AccessCache cache) {
        if (!String.isBlank(taskRequest.personIdent)) {
            return cache.personIdents.contains(taskRequest.personIdent);
        }
        if (!String.isBlank(taskRequest.aktoerId)) {
            return cache.actorIds.contains(taskRequest.aktoerId);
        }
        return false;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Person__c> getPersonInfo(List<String> personIdents) {
        Map<String, Person__c> result = new Map<String, Person__c>();
        if (personIdents == null || personIdents.isEmpty()) {
            return result;
        }
        for (Person__c p : [
            SELECT Name, CRM_FullName__c, CRM_Age__c, CRM_Account__c, INT_DateOfBirth__c
            FROM Person__c
            WHERE Name IN :personIdents
        ]) {
            result.put(p.Name, p);
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCommonCodeNames() {
        Map<String, String> result = new Map<String, String>();
        for (Common_Code__c cc : [
            SELECT Name, CRM_Code__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c IN ('Behandlingstema', 'Behandlingstyper', 'Tema', 'Oppgavetyper')
        ]) {
            result.put(cc.CRM_Code__c, cc.Name);
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getNavUnitNames() {
        Map<String, String> result = new Map<String, String>();

        // Load all NAV units to build the complete unit-number-to-name lookup.
        // A LIMIT would omit units and leave some unit numbers without a name.
        for (NavUnit__c nu : [SELECT Name, INT_UnitNumber__c FROM NavUnit__c]) {
            result.put(nu.INT_UnitNumber__c, nu.Name);
        }
        return result;
    }

    private static List<String> getTemaCodes(List<String> ytelser) {
        if (ytelser == null || ytelser.isEmpty()) {
            return null;
        }
        List<String> codes = new List<String>();
        for (Common_Code__c cc : [
            SELECT CRM_Code__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Tema' AND Name IN :ytelser
        ]) {
            codes.add(cc.CRM_Code__c);
        }
        return codes.isEmpty() ? null : codes;
    }

    private static AccessCache buildAccessCache(List<OppgaveRequest> requests) {
        AccessCache cache = new AccessCache();

        Set<String> personIdents = new Set<String>();
        Set<String> actorIds = new Set<String>();

        for (OppgaveRequest r : requests) {
            if (String.isNotBlank(r.personIdent)) {
                personIdents.add(r.personIdent);
            } else if (String.isNotBlank(r.aktoerId)) {
                actorIds.add(r.aktoerId);
            }
        }

        if (!personIdents.isEmpty()) {
            for (Person__c p : [
                SELECT Name
                FROM Person__c
                WHERE Name IN :personIdents
            ]) {
                cache.personIdents.add(p.Name);
            }
        }

        if (!actorIds.isEmpty()) {
            for (Person__c p : [
                SELECT INT_ActorId__c
                FROM Person__c
                WHERE INT_ActorId__c IN :actorIds
            ]) {
                cache.actorIds.add(p.INT_ActorId__c);
            }
        }

        return cache;
    }

    private static String getUserDepartment() {
        return [
            SELECT Department
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ]
        ?.Department;
    }

    private class AccessCache {
        Set<String> personIdents = new Set<String>();
        Set<String> actorIds = new Set<String>();
    }

    private class OppgaveListResponse {
        private Integer antallTreffTotalt;
        private List<Oppgave> oppgaver;
    }
}
