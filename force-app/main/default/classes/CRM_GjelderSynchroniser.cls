public with sharing class CRM_GjelderSynchroniser implements CRM_SyncInterface {
    private Set<String> processed;
    private List<Common_Code__c> gjelderList;
    private List<Common_Code__c> behandlingsList;
    private Map<String, Object> gjelderMap;
    private Common_Code__C currentGjelder;
    private Map<String, String> themeMap;
    private Set<String> keyString;
    private Map<String, Common_Code__c> keyMap;
    private List<Common_Code__c> potentialSubList;
    private LoggerUtility logger;

    private void initSync() {
        List<Common_Code__c> usedThemeList = [
            SELECT CRM_Code__c, CRM_UniqueKey__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Tema'
        ];
        themeMap = new Map<String, String>();
        for (Common_Code__c theme : usedThemeList) {
            themeMap.put(theme.CRM_Code__c, theme.CRM_UniqueKey__c);
        }
        gjelderList = new List<Common_Code__c>();
        behandlingsList = new List<Common_Code__c>();
        processed = new Set<String>();
        potentialSubList = new List<Common_Code__c>();

        keyString = new Set<String>();
        keyMap = new Map<String, Common_Code__C>();
        for(Common_Code__c gjelder : [SELECT CRM_Code__c, CRM_UniqueKey__c, Id, Name FROM Common_Code__c WHERE CRM_Code_Set__c ='Gjelder']) {
            keyMap.put(gjelder.CRM_UniqueKey__c, gjelder);
            keyString.add(gjelder.CRM_UniqueKey__c);
        }
    }

    public void doSync() {
        executeSync();
    }

    @future(callout=true)
    public static void executeSync() {
        CRM_NavTaskOppgaveService service = new CRM_NavTaskOppgaveService(CRM_NavTaskOppgaveService.Context.SYSTEM_CONTEXT);
        CRM_GjelderSynchroniser sync = new CRM_GjelderSynchroniser();
        sync.startSync(service.getGjelderValues());
    }

    public void startSync(HttpResponse resp) {
        logger = new LoggerUtility();
        if(resp == null || resp.getBody() == null || resp.getStatusCode() != 200 && resp.getStatusCode() != 201) {
            logger.Error('Status code not 200/201: ' + resp.getStatus(), null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
            return;
        }
        Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
        initSync();

        for (String theme : parsedJson.keySet()) {
            List<Object> currentTheme = (List<Object>) parsedJson.get(theme);
            if (!themeMap.keySet().contains(theme)) {
                logger.Error('Missing theme: ' + theme, null, CRM_ApplicationDomain.Domain.NKS);
                continue;
            }
            for (Integer i = 0; i < currentTheme.size(); i++) {
                gjelderMap = (Map<String, Object>) currentTheme[i];
                currentGjelder = new Common_Code__c(
                    CRM_Code_Set__c = 'Gjelder',
                    CRM_Parent_Code__r = new Common_Code__c(CRM_UniqueKey__c = themeMap.get(theme))
                );
                potentialSubList.clear();

                // A gjelder is essentially a relation between a theme and subtheme and/or subtype.
                // So to create a unique "code" for gjelder, we combine the codes of the children/parent.
                // It will look like <ThemeCode>+TM<SubthemeCode>+TY<SubtypeCode>
                currentGjelder.CRM_Code__c = theme;
                currentGjelder.Name = '';

                if (gjelderMap.get('behandlingstema') != null) {
                    createSubCode('Behandlingstema');
                }

                if (gjelderMap.get('behandlingstype') != null) {
                    createSubCode('Behandlingstyper');
                }
                currentGjelder.CRM_UniqueKey__c = 'Gjelder' + currentGjelder.CRM_Code__c;

                // If we cannot add this, the gjelder is not new
                if(!keyString.add(currentGjelder.CRM_UniqueKey__c)) {
                    // If the name is not the same, we assume that it has changed
                    if(currentGjelder?.Name != keyMap.get(currentGjelder.CRM_UniqueKey__c)?.Name) {
                        gjelderList.add(currentGjelder);
                        behandlingsList.addAll(potentialSubList);
                    }
                    keyMap.remove(currentGjelder.CRM_UniqueKey__c);
                } else {
                    gjelderList.add(currentGjelder);
                    behandlingsList.addAll(potentialSubList);
                }
            }
        }
        logger.publish();
        
        upsert behandlingsList Common_Code__c.CRM_UniqueKey__c;
        upsert gjelderList Common_Code__c.CRM_UniqueKey__c;
        delete keyMap.values();
    }

    private void createSubCode(String codeSet) {
        String subcode = (String) gjelderMap.get(codeSet.substring(0,15).toLowerCase());
        String term = (String) gjelderMap.get(codeSet.substring(0,15).toLowerCase() + 'Term');

        if (codeSet == 'Behandlingstema') {
            currentGjelder.CRM_Subtheme__r = new Common_Code__c(CRM_UniqueKey__c = codeSet + subcode);
        } else if (codeSet == 'Behandlingstyper') {
            currentGjelder.CRM_Subtype__r = new Common_Code__c(CRM_UniqueKey__c = codeSet + subcode);
        }

        // We don't want to create/update multiple records of the same subtheme/type
        // The combination of codeSet + subCode is the same as the external ID
        if (!processed.contains(codeSet + subcode)) {
            Common_Code__c subCommonCode = new Common_Code__c(
                CRM_UniqueKey__c = codeSet + subcode,
                Name = term,
                CRM_Code__c = subcode,
                CRM_Active__c = true,
                CRM_Code_Set__c = codeSet
            );
            potentialSubList.add(subCommonCode);
            processed.add(codeSet + subcode);
        }

        if (codeSet == 'Behandlingstema') {
            currentGjelder.CRM_Code__c += 'TM' + subcode;
            currentGjelder.Name += term;
        } else if (codeSet == 'Behandlingstyper') {
            currentGjelder.CRM_Code__c += 'TY' + subcode;
            if (currentGjelder.Name != '') {
                currentGjelder.Name += ' - ';
            }
            currentGjelder.Name += term;
            currentGjelder.Name = currentGjelder.Name.abbreviate(80);
        }
    }
}
