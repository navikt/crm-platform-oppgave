public with sharing class CRM_GjelderSynchroniser implements CRM_SyncInterface {
    private Map<String, Map<String, Common_code__c>> commonCodeMaps;
    private LoggerUtility logger;
    private CRM_NavTaskOppgaveService service;

    public CRM_GjelderSynchroniser() {
        logger = new LoggerUtility('Gjelder');
    }

    public void doSync() {
        executeSync();
    }

    @future(callout=true)
    public static void executeSync() {
        new CRM_GjelderSynchroniser().startSync();
    }

    public String getGjelderHierarchy() {
        service = new CRM_NavTaskOppgaveService(CRM_NavTaskOppgaveService.Context.SYSTEM_CONTEXT);
        HttpResponse resp = service.getGjelderValues();
        if (resp == null || resp.getBody() == null || (resp.getStatusCode() != 200 && resp.getStatusCode() != 201)) {
            logger.Error('Status code not 200/201: ' + resp.getStatus(), null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
            return null;
        }
        return resp.getBody();
    }

    private void populateSoqlMap() {
        Map<String, Map<String, Common_code__c>> retMap = new Map<String, Map<String, Common_code__c>>();
        for (Common_Code__c cCode : [
            SELECT Id, CRM_Code__c, CRM_Code_Set__c, CRM_Available__c, CRM_Active__c, CRM_UniqueKey__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c IN ('Tema', 'Gjelder', 'Behandlingstema', 'Behandlingstyper')
        ]) {
            if (retMap.containsKey(cCode.CRM_Code_Set__c)) {
                retMap.get(cCode.CRM_Code_set__c).put(cCode.CRM_Code__c, cCode);
            } else {
                retMap.put(cCode.CRM_Code_set__c, new Map<String, Common_code__c>{ cCode.CRM_Code__c => cCode });
            }
        }
        commonCodeMaps = retMap;
    }

    public void startSync() {
        populateSoqlMap();
        String resp = getGjelderHierarchy();
        if (resp == null)
            return;

        List<ThemeInformation> responseInformation = (List<ThemeInformation>) JSON.deserialize(
            resp,
            List<ThemeInformation>.class
        );
        Set<String> gjelderKeysInResponse = new Set<String>();
        List<Common_code__c> gjelderListToUpsert = new List<Common_code__c>();
        Map<String, String> subthemeTermMap = new Map<String, String>();
        Map<String, String> subtypeTermMap = new Map<String, String>();

        for (ThemeInformation themeInformation : responseInformation) {
            if (!commonCodeMaps.get('Tema').containsKey(themeInformation.tema.tema)) {
                logger.Error(
                    'Missing theme: ' +
                    themeInformation.tema.term +
                    '(' +
                    themeInformation.tema.tema +
                    ')',
                    null,
                    CRM_ApplicationDomain.Domain.NKS
                );
                continue;
            }
            System.debug(themeInformation.tema.tema);
            for (Gjelder responseGjelder : themeInformation.gjelderverdier) {
                Common_code__c currentGjelder = new Common_Code__c(
                    CRM_Code_Set__c = 'Gjelder',
                    CRM_Active__c = true,
                    CRM_Parent_Code__c = commonCodeMaps.get('Tema').get(themeInformation.tema.tema).Id
                );

                // A gjelder is essentially a relation between a theme and subtheme and/or subtype.
                // So to create a unique "code" for gjelder, we combine the codes of the children/parent.
                // It will look like <ThemeCode>+TM<SubthemeCode>+TY<SubtypeCode>
                currentGjelder.CRM_Code__c = themeInformation.tema.tema;
                currentGjelder.Name = '';
                if (responseGjelder.behandlingstema != null) {
                    if (!subthemeTermMap.containsKey(responseGjelder.behandlingstema)) {
                        subthemeTermMap.put(responseGjelder.behandlingstema, responseGjelder.behandlingstemaTerm);
                    }
                    currentGjelder.CRM_Subtheme__r = new Common_Code__C(
                        CRM_UniqueKey__c = 'Behandlingstema' + responseGjelder.behandlingstema
                    );
                    currentGjelder.CRM_Code__c += 'TM' + responseGjelder.behandlingstema;
                    currentGjelder.Name = responseGjelder.behandlingstemaTerm;
                }
                if (responseGjelder.behandlingstype != null) {
                    if (!subtypeTermMap.containsKey(responseGjelder.behandlingstema)) {
                        subtypeTermMap.put(responseGjelder.behandlingstype, responseGjelder.behandlingstypeTerm);
                    }
                    currentGjelder.CRM_Subtype__r = new Common_Code__C(
                        CRM_UniqueKey__c = 'Behandlingstyper' + responseGjelder.behandlingstype
                    );
                    currentGjelder.CRM_Code__c += 'TY' + responseGjelder.behandlingstype;
                    currentGjelder.Name +=
                        (currentGjelder.Name == '' ? '' : ' - ') + responseGjelder.behandlingstypeTerm;
                }

                currentGjelder.Name = currentGjelder.Name.abbreviate(80);
                currentGjelder.CRM_UniqueKey__c = 'Gjelder' + currentGjelder.CRM_Code__c;
                gjelderKeysInResponse.add(currentGjelder.CRM_Code__c);
                gjelderListToUpsert.add(currentGjelder);
            }
        }

        List<Common_code__c> subcodeListToUpsert = new List<Common_code__c>();
        subcodeListToUpsert.addAll(createSubCodes(subthemeTermMap, 'Behandlingstema'));
        subcodeListToUpsert.addAll(createSubCodes(subtypeTermMap, 'Behandlingstyper'));

        // Go through all Subtheme, subtype and gjelders that were not in the respons and disable them
        subcodeListToUpsert.addAll(disableUnusedCodes(subthemeTermMap.keySet(), 'Behandlingstema'));
        subcodeListToUpsert.addAll(disableUnusedCodes(subtypeTermMap.keySet(), 'Behandlingstyper'));
        subcodeListToUpsert.addAll(disableUnusedCodes(gjelderKeysInResponse, 'Gjelder'));

        // Insert new subthemes and subtypes, and update old ones with new names or disable them
        upsertCommonCodes(subcodeListToUpsert, gjelderListToUpsert);
    }

    private List<Common_code__c> createSubCodes(Map<String, String> subcodeTermMap, String codeType) {
        List<Common_code__c> retList = new List<Common_code__c>();
        for (String subcode : subcodeTermMap.keySet()) {
            retList.add(
                new Common_code__c(
                    CRM_UniqueKey__c = codeType + subcode,
                    Name = subcodeTermMap.get(subcode),
                    CRM_Code__c = subcode,
                    CRM_Active__c = true,
                    CRM_Code_Set__c = codeType
                )
            );
        }
        return retList;
    }

    private List<Common_code__c> disableUnusedCodes(Set<String> codesInResponse, String type) {
        List<Common_code__c> retList = new List<Common_code__c>();
        if (!commonCodeMaps.containsKey(type))
            return retList;
        for (String codeInSF : commonCodeMaps.get(type).keySet()) {
            if (!codesInResponse.contains(codeInSF)) {
                Common_Code__c disabledSFCode = commonCodeMaps.get(type).get(codeInSF);
                disabledSFCode.CRM_Active__c = false;
                retList.add(disabledSFCode);
            }
        }
        return retList;
    }

    @TestVisible
    private void upsertCommonCodes(List<Common_code__c> subcodeListToUpsert, List<Common_code__c> gjelderListToUpsert) {
        try {
            upsert subcodeListToUpsert CRM_UniqueKey__c;
        } catch (Exception er) {
            logger.logMessage(
                LoggerUtility.LogLevel.Error,
                null,
                null,
                'Could not insert/update subthemes or subtypes: ' + er,
                JSON.serialize(subcodeListToUpsert),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
        }
        // Insert new gjelder and update disabled ones
        try {
            upsert gjelderListToUpsert CRM_UniqueKey__c;
        } catch (Exception e) {
            logger.logMessage(
                LoggerUtility.LogLevel.Error,
                null,
                null,
                'Could not insert/update Gjelder: ' + e,
                JSON.serialize(gjelderListToUpsert),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
        }
        logger.publish();
    }

    public class ThemeInformation {
        public Theme tema;
        public List<TaskType> oppgavetyper;
        public List<Gjelder> gjelderverdier;
    }

    public class Theme {
        public String tema;
        public String term;
    }

    public class TaskType {
        public String oppgavetype;
        public String term;
    }

    public class Gjelder {
        public String behandlingstema;
        public String behandlingstemaTerm;
        public String behandlingstype;
        public String behandlingstypeTerm;
    }
}
