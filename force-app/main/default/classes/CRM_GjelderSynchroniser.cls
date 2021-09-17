public with sharing class CRM_GjelderSynchroniser {
    CRM_NavTaskOppgaveService service;
    private Set<String> processed;
    private List<Common_Code__c> gjelderList;
    private List<Common_Code__c> behandlingsList;
    private Map<String, Object> gjelderMap;
    private Common_Code__C currentGjelder;

    public CRM_GjelderSynchroniser() {
        checkService();
    }

    public CRM_GjelderSynchroniser(CRM_NavTaskOppgaveService service) {
        this.service = service;
    }

    private void checkService() {
        if (service == null) {
            service = new CRM_NavTaskOppgaveService();
        }
    }

    public HttpResponse getResponse() {
        checkService();
        return service.getGjelderValues();
    }

    public void doSync() {
        HttpResponse response = getResponse();
        Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        // Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(
        //     '{"PEN":[],"RVE": [{"behandlingstema": null,"behandlingstemaTerm": null,"behandlingstype": "ae0004","behandlingstypeTerm": "Behandle vedtak"}],"REK": [{"behandlingstema": null,"behandlingstemaTerm": null,"behandlingstype": "ae0004","behandlingstypeTerm": "Behandle vedtak"},{"behandlingstema": null,"behandlingstemaTerm": null,"behandlingstype": "ae0007","behandlingstypeTerm": "Utbetaling"},{"behandlingstema": null,"behandlingstemaTerm": null,"behandlingstype": "ae0116","behandlingstypeTerm": "Meldekort"}],"AAP": [{"behandlingstema": "ab0241","behandlingstemaTerm": "Dagliglivet","behandlingstype": "ae0106","behandlingstypeTerm": "Utland"}]}'
        // );

        List<Common_Code__c> usedThemeList = [
            SELECT CRM_Code__c, CRM_UniqueKey__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Tema'
        ];
        Map<String, String> themeMap = new Map<String, String>();
        for (Common_Code__c theme : usedThemeList) {
            themeMap.put(theme.CRM_Code__c, theme.CRM_UniqueKey__c);
        }
        gjelderList = new List<Common_Code__c>();
        behandlingsList = new List<Common_Code__c>();
        processed = new Set<String>();

        for (String theme : parsedJson.keySet()) {
            List<Object> currentTheme = (List<Object>) parsedJson.get(theme);
            if (!themeMap.keySet().contains(theme)) {
                //Checks if the theme is in Salesforce, and skips it if not.
                continue;
            }
            for (Integer i = 0; i < currentTheme.size(); i++) {
                gjelderMap = (Map<String, Object>) currentTheme[i];
                currentGjelder = new Common_Code__c(
                    CRM_Code_Set__c = 'Gjelder',
                    CRM_Parent_Code__r = new Common_Code__c(CRM_UniqueKey__c = themeMap.get(theme))
                );
                currentGjelder.CRM_Code__c = theme;
                currentGjelder.Name = '';

                if (gjelderMap.get('behandlingstema') != null) {
                    createSubCode('Behandlingstema');
                }

                if (gjelderMap.get('behandlingstype') != null) {
                    createSubCode('Behandlingstype');
                }
                currentGjelder.CRM_UniqueKey__c = 'Gjelder' + currentGjelder.CRM_Code__c;
                gjelderList.add(currentGjelder);
            }
        }
        upsert behandlingsList Common_Code__c.CRM_UniqueKey__c;
        upsert gjelderList Common_Code__c.CRM_UniqueKey__c;
    }

    private void createSubCode(String codeSet) {
        String subcode = (String) gjelderMap.get(codeSet.toLowerCase());
        String term = (String) gjelderMap.get(codeSet.toLowerCase() + 'Term');

        // Har brukt if else her, men switch case lengre nede. Er det noe vits i å bruke switch case?
        // Og hvis ikke, hvordan gjør vi error handeling? Og er det egenltig en bedre måte å gjøre dette på?
        // Kanskje en elif?
        if (codeSet == 'Behandlingstema') {
            currentGjelder.CRM_Subtheme__r = new Common_Code__c(CRM_UniqueKey__c = codeSet + subcode);
        } else {
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
            behandlingsList.add(subCommonCode);
            processed.add(codeSet + subcode);
        }

        switch on codeSet {
            when 'Behandlingstema' {
                currentGjelder.CRM_Code__c += 'TM' + subcode;
                currentGjelder.Name += term;
            }
            when 'Behandlingstype' {
                currentGjelder.CRM_Code__c += 'TY' + subcode;
                if (currentGjelder.Name != '') {
                    currentGjelder.Name += ' - ';
                }
                currentGjelder.Name += term;
                currentGjelder.Name = currentGjelder.Name.abbreviate(80);
            }
            when else {
                // Hvordan logger vi errors? Lol
                currentGjelder.Name = 'An error has occurred';
            }
        }
    }
}
