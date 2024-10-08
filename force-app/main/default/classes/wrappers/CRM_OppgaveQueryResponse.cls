public class CRM_OppgaveQueryResponse {
    public List<CRM_KafkaOppgave> oppgaver;

    public List<NavTask__c> convertToNavTasks() {
        if (this.oppgaver == null || this.oppgaver.isEmpty()) {
            return null;
        }

        Boolean actorExists = false;
        Boolean mappedTheme = false;
        List<NavTask__c> returnList = new List<NavTask__c>();

        for (CRM_kafkaOppgave kafkaOppgave : this.oppgaver) {
            if (String.isBlank(kafkaOppgave.orgnr)) {
                actorExists =
                    this.actorAccMap.containsKey(kafkaOppgave.getActorId()) &&
                    String.isNotBlank(this.actorAccMap.get(kafkaOppgave.getActorId()));
                mappedTheme = this.commonCodeMap.containsKey('Tema' + kafkaOppgave.tema);
                
                // Added criteria to filter our oppgave related to organizations
                if (actorExists && mappedTheme) {
                    returnList.add(convertToNavTask(kafkaOppgave));
                }
            }
        }
        return returnList;
    }

    /**
     * Converts a CRM_KafkaOppgave into a valid NavTask__c record that can be inserted/updated
     * @author Stian Ruud Schikora | 03-22-2022
     * @param kafkaOppgave
     * @return NavTask__c
     **/
    private NavTask__c convertToNavTask(CRM_KafkaOppgave kafkaOppgave) {
        NavTask__c navTask = new NavTask__c();
        navTask.CRM_Account__c = this.actorAccMap.get(kafkaOppgave.getActorId());
        navTask.INT_External_Reference__c = kafkaOppgave.id;
        navTask.NKS_Task_Version__c = kafkaOppgave.versjon;
        navTask.CRM_NavUnit__c = this.navUnitMap.get(kafkaOppgave.tildeltEnhetsnr);
        navTask.Name = this.commonCodeMap.get('Oppgavetyper' + kafkaOppgave.oppgavetype)?.Name ?? 'Oppgave';
        navTask.NKS_Assignee__c = kafkaOppgave.tilordnetRessurs;
        navTask.NKS_Comments__c = kafkaOppgave.beskrivelse;
        navTask.NKS_TaskType__c = this.commonCodeMap.get('Oppgavetyper' + kafkaOppgave.oppgavetype)?.Id;
        navTask.NKS_Theme__c = this.commonCodeMap.get('Tema' + kafkaOppgave.tema)?.Id;
        navTask.NKS_Subtheme__c = this.commonCodeMap.get('Behandlingstema' + kafkaOppgave.behandlingstema)?.Id;
        navTask.CRM_Subtype__c = this.commonCodeMap.get('Behandlingstyper' + kafkaOppgave.behandlingstype)?.Id;
        navTask.CRM_DueDate__c = String.isNotBlank(kafkaOppgave.fristFerdigstillelse) ? Date.valueOf(kafkaOppgave.fristFerdigstillelse) : null;
        navTask.CRM_Priority__c = kafkaOppgave.prioritet;
        navTask.NKS_Status__c = kafkaOppgave.status;
        navTask.NKS_Date_Registered__c = String.isNotBlank(kafkaOppgave.opprettetTidspunkt) ? Date.valueOf(kafkaOppgave.opprettetTidspunkt) : null;
        navTask.CRM_NoPersonInformation__c = true; // Required for validation rule
        navTask.NKS_Henvendelse_BehandlingsId__c = kafkaOppgave.metadata?.EKSTERN_HENVENDELSE_ID;
        return navTask;
    }

    // Internal map of relevant common codes for oppgave
    private Map<String, Common_Code__c> commonCodeMap {
        get {
            if (this.commonCodeMap == null) {
                this.commonCodeMap = new Map<String, Common_Code__c>();
                for (Common_Code__c comCode : [
                    SELECT Id, Name, CRM_Code__c, CRM_Code_Set__c
                    FROM Common_Code__c
                    WHERE CRM_Code_Set__c IN ('Tema', 'Behandlingstema', 'Behandlingstyper', 'Oppgavetyper')
                ]) {
                    this.commonCodeMap.put(comCode.CRM_Code_Set__c + comCode.CRM_Code__c, comCode);
                }
            }
            return this.commonCodeMap;
        }
        private set {
        }
    }

    // Internal mapping of an actorId to a SF account ID
    private Map<String, Id> actorAccMap {
        get {
            if (this.oppgaver == null || this.oppgaver.isEmpty())
                return null;
            if (this.actorAccMap == null) {
                this.actorAccMap = new Map<String, Id>();
                Set<String> actorIdSet = new Set<String>();

                for (CRM_KafkaOppgave kfOppg : this.oppgaver) {
                    if (String.isBlank(kfOppg.orgnr)) {
                        actorIdSet.add(kfOppg.getActorId());
                    }
                }
                
                for (Person__c person : [
                    SELECT CRM_Account__c, INT_ActorId__c
                    FROM Person__c
                    WHERE INT_ActorId__c IN :actorIdSet
                ]) {
                    this.actorAccMap.put(person.INT_ActorId__c, person.CRM_Account__c);
                }
            }
            return this.actorAccMap;
        }
        private set {
        }
    }

    // Mapping the NAV Unit number to the Ids of the SF NavUnit__c records
    private Map<String, Id> navUnitMap {
        get {
            if (this.oppgaver == null || this.oppgaver.isEmpty())
                return null;
            if (this.navUnitMap == null) {
                this.navUnitMap = new Map<String, Id>();
                Set<String> navUnitNumberSet = new Set<String>();

                for (CRM_KafkaOppgave kfOppg : this.oppgaver) {
                    navUnitNumberSet.add(kfOppg.tildeltEnhetsnr);
                }

                for (NavUnit__c navUnit : [
                    SELECT INT_UnitNumber__c, Id
                    FROM NavUnit__c
                    WHERE INT_UnitNumber__c IN :navUnitNumberSet
                ]) {
                    this.navUnitMap.put(navUnit.INT_UnitNumber__c, navUnit.Id);
                }
            }
            return this.navUnitMap;
        }
        private set {
        }
    }
}
