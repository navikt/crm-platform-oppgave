public with sharing class OppgaveManager {

    static LoggerUtility logger = new LoggerUtility('Oppgave');
    
    @AuraEnabled
    public static List<CRM_OppgaveOppfolging> getOppgaveOppfolging(String oppgaveId) {
        CRM_NavTaskOppgaveService service = new CRM_NavTaskOppgaveService();
        HttpResponse response = service.getOppgaveOppfolgingById(oppgaveId);
        if (response.getStatusCode() == 200) {
                List<CRM_OppgaveOppfolging> oppfolgingList = (List<CRM_OppgaveOppfolging>) JSON.deserialize(
                    response.getBody(),
                    List<CRM_OppgaveOppfolging>.class
                );

                // Skal vi gjøre dette før vi returnerer? Kopierte det fra sync løsningen.
                // String comment = '';

                // for (CRM_OppgaveOppfolging oppfolgingOppgave : oppfolgingList) {
                //     Datetime createdTime = Datetime.valueofGMT(oppfolgingOppgave.opprettetTidspunkt.replace('T', ' '));
                //     String formattedDateTime = createdTime.format('dd.MM.yyyy HH:mm', 'Norway/Oslo');
                //     comment += '--- ' + formattedDateTime + ' ' + '(' + oppfolgingOppgave.opprettetAv + ') ---\n' + oppfolgingOppgave.kommentar + '\n\n';
                // }

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
    }
    
    @AuraEnabled
    public static Oppgave getOppgaveById(String oppgaveId)  {
        CRM_NavTaskOppgaveService service = new CRM_NavTaskOppgaveService();
        HttpResponse response = service.getOppgaveById(oppgaveId);
        if(response.getStatuscode() == 200) {
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
        CRM_NavTaskOppgaveService service = new CRM_NavTaskOppgaveService();
        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.tilordnetRessurs = navIdent;
        query.statuskategori = OppgaveStatuskategori.AAPEN;
        HttpResponse response = service.queryOppgave(query);
        if(response.getStatusCode() == 200) {
            List<Oppgave> oppgaver = (List<Oppgave>) JSON.deserialize(response.getBody(), List<Oppgave>.class);
            return oppgaver;
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
    public static List<Oppgave> getOpenOppgaver(Id personId, Integer offset) {
        CRM_NavTaskOppgaveService service = new CRM_NavTaskOppgaveService();
        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.aktoerId = new List<String>{ personId };
        query.statuskategori = OppgaveStatuskategori.AAPEN;
        query.returnLimit = 100;
        if(offset != null && offset > 0) {
            query.offset = offset;
        }
        HttpResponse response = service.queryOppgave(query);
        if(response.getStatusCode() == 200) {
            List<Oppgave> oppgaver = (List<Oppgave>) JSON.deserialize(response.getBody(), List<Oppgave>.class);
            return oppgaver;
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
    public static List<Oppgave> getAllOppgaver(Id personId, Integer offset) {
        CRM_NavTaskOppgaveService service = new CRM_NavTaskOppgaveService();
        CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
        query.aktoerId = new List<String>{ personId };
        query.returnLimit = 100;
        if(offset != null && offset > 0) {
            query.offset = offset;
        }
        HttpResponse response = service.queryOppgave(query);
        if(response.getStatusCode() == 200) {
            List<Oppgave> oppgaver = (List<Oppgave>) JSON.deserialize(response.getBody(), List<Oppgave>.class);
            return oppgaver;
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
}