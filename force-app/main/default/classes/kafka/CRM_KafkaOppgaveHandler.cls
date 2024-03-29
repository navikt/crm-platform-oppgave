public without sharing class CRM_KafkaOppgaveHandler implements IKafkaMessageConsumer {
    private LoggerUtility logger = new LoggerUtility();
    private Map<String, String> actorAccMap = new Map<String, String>();
    private Map<String, List<KafkaMessage__c>> messageMap = new Map<String, List<KafkaMessage__c>>(); //Maps CRM_Key__c to a list of KafkaMessages for that key
    private Map<String, NavUnit__c> navUnitMap;
    private Map<String, Common_Code__c> commonCodeMap;

    //Default constructor
    public CRM_KafkaOppgaveHandler() {
        initCommonCodeMap();
        initNavUnitMap();
    }

    /**
     * @description: Initializes a map for all relevant records from common code
     * @author Stian Ruud Schikora | 03-26-2021
     **/
    private void initCommonCodeMap() {
        commonCodeMap = new Map<String, Common_Code__c>();
        for (Common_Code__c comCode : [
            SELECT Id, Name, CRM_Code__c, CRM_Code_Set__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c IN ('Tema', 'Behandlingstema', 'Behandlingstyper', 'Oppgavetyper')
        ]) {
            commonCodeMap.put(comCode.CRM_Code_Set__c + comCode.CRM_Code__c, comCode);
        }
    }

    /**
     * @description: Initializes a map of NAV units
     * @author Stian Ruud Schikora | 03-26-2021
     **/
    private void initNavUnitMap() {
        navUnitMap = new Map<String, NavUnit__c>();
        for (NavUnit__c navUnit : [SELECT Id, INT_UnitNumber__c, Name FROM NavUnit__c]) {
            navUnitMap.put(navUnit.INT_UnitNumber__c, navUnit);
        }
    }

    /**
     * @description: Returns a list of all the processed messages in the messagemap
     * @author Stian Ruud Schikora | 08-03-2021
     * @return List<KafkaMessage__c>
     **/
    public List<KafkaMessage__c> getProcessedMessages() {
        List<KafkaMessage__c> retList = new List<KafkaMessage__c>();
        for (List<KafkaMessage__c> msgList : this.messageMap.values()) {
            retList.addAll(msgList);
        }

        return retList;
    }

    /**
     * @description: Returns a list of all the messages where processing has failed
     * @author Stian Ruud Schikora | 08-03-2021
     * @return List<KafkaMessage__c>
     **/
    public List<KafkaMessage__c> getFailedMessages() {
        List<KafkaMessage__c> retList = new List<KafkaMessage__c>();
        for (List<KafkaMessage__c> msgList : this.messageMap.values()) {
            for (KafkaMessage__c kfMsg : msgList) {
                if (kfMsg.CRM_Status__c == KafkaMessageService.STATUS_ERROR)
                    retList.add(kfMsg);
            }
        }

        return retList;
    }

    public void processMessages(List<KafkaMessage__c> messages) {
        List<NavTask__c> tasksToUpsert = new List<NavTask__c>();
        Map<Decimal, NavTask__c> existingTaskMap = new Map<Decimal, NavTask__c>();
        Map<Decimal, List<CRM_KafkaOppgave>> kafkaTaskMap = convertToKafkaTasks(messages);
        List<CRM_KafkaOppgave> tasksToConvert = new List<CRM_KafkaOppgave>();

        for (NavTask__c navTask : [
            SELECT Id, INT_External_Reference__c, NKS_Comments__c, NKS_Task_Version__c
            FROM NavTask__c
            WHERE INT_External_Reference__c IN :kafkaTaskMap.keySet()
            FOR UPDATE
        ]) {
            existingTaskMap.put(navTask.INT_External_Reference__c, navTask);
        }

        for (Decimal taskRef : kafkaTaskMap.keySet()) {
            Integer existingTaskVersion = existingTaskMap.containsKey(taskRef)
                ? Integer.valueOf(existingTaskMap.get(taskRef).NKS_Task_Version__c)
                : 0;

            List<CRM_KafkaOppgave> kafkaTasks = kafkaTaskMap.get(taskRef);
            //List is sorted so last item is the newest version
            CRM_KafkaOppgave taskToConvert = kafkaTasks.get(kafkaTasks.size() - 1).versjon >= existingTaskVersion
                ? kafkaTasks.get(kafkaTasks.size() - 1)
                : null;
            if (taskToConvert != null)
                tasksToConvert.add(taskToConvert);
        }

        tasksToUpsert = convertToNavTasks(tasksToConvert);
        doUpsert(tasksToUpsert);
        logger.publish();
    }

    private void doUpsert(List<NavTask__c> tasksToUpsert) {
        Schema.SObjectField extRef = NavTask__c.Fields.INT_External_Reference__c;

        List<Database.UpsertResult> upsList = Database.upsert(tasksToUpsert, extRef, false);
        verifyUpsertResults(upsList, tasksToUpsert);
    }

    private void initAccountMap() {
        for (Person__c person : [
            SELECT Id, CRM_Account__c, INT_ActorId__c
            FROM Person__c
            WHERE INT_ActorId__c IN :this.actorAccMap.keySet()
        ]) {
            this.actorAccMap.put(person.INT_ActorId__c, person.CRM_Account__c);
        }
    }

    /**
     * @description: Deserialize the Kafka message value into the wrapper object
     * @author Stian Ruud Schikora | 01-15-2021
     * @param message
     * @return KafkaOppgave
     **/
    private CRM_KafkaOppgave convertToKafkaTask(KafkaMessage__c message) {
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        return (CRM_KafkaOppgave) JSON.deserialize(decodedValue, CRM_KafkaOppgave.class);
    }

    /**
     * @description: Generates a map of KafkaOppgave wrappers based on the kafka messages
     * @author Stian Ruud Schikora | 01-15-2021
     * @param messages
     * @return Map<Decimal, KafkaOppgave>
     **/
    private Map<Decimal, List<CRM_KafkaOppgave>> convertToKafkaTasks(List<KafkaMessage__c> messages) {
        Map<Decimal, List<CRM_KafkaOppgave>> returnMap = new Map<Decimal, List<CRM_KafkaOppgave>>();

        for (KafkaMessage__c message : messages) {
            try {
                Decimal messageKey = Decimal.valueOf(message.CRM_Key__c);
                CRM_KafkaOppgave kafkaOppgave = convertToKafkaTask(message);
                if (kafkaOppgave != null) {
                    if (kafkaOppgave.getActorId() != null)
                        actorAccMap.put(kafkaOppgave.getActorId(), ''); //Adding the actor ids to map for initialization aftert successful conversions
                    //If the map already contains the unique task reference, check which of the messages containcs the latest version number
                    if (returnMap.containsKey(messageKey)) {
                        List<CRM_KafkaOppgave> mapList = returnMap.get(messageKey);
                        mapList.add(kafkaOppgave);
                        returnMap.put(messageKey, mapList);
                    } else {
                        returnMap.put(messageKey, new List<CRM_KafkaOppgave>{ kafkaOppgave });
                    }
                    //Put in message map for later status update depending on DML
                    if (this.messageMap.containsKey(message.CRM_Key__c)) {
                        List<KafkaMessage__c> mappedMsgs = this.messageMap.get(message.CRM_Key__c);
                        mappedMsgs.add(message);
                        this.messageMap.put(message.CRM_Key__c, mappedMsgs);
                    } else {
                        this.messageMap.put(message.CRM_Key__c, new List<KafkaMessage__c>{ message });
                    }
                    message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                } else {
                    message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                }
            } catch (Exception ex) {
                message.CRM_ErrorMessage__c =
                    ex.getTypeName() +
                    ': ' +
                    ex.getMessage() +
                    ' (' +
                    ex.getLineNumber() +
                    ')';
                message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            }
        }
        initAccountMap();
        //Sorting the lists. First item is the oldest version
        for (List<CRM_KafkaOppgave> oppgaveList : returnMap.values()) {
            oppgaveList.sort();
        }
        return returnMap;
    }

    /**
     * @description: Performs converstion from KafkaOppgave => NavTask__c
     * @author Stian Ruud Schikora | 02-26-2021
     * @param kafkaOppgaver
     * @return List<NavTask__c>
     **/
    private List<NavTask__c> convertToNavTasks(List<CRM_KafkaOppgave> kafkaOppgaver) {
        List<NavTask__c> returnList = new List<NavTask__c>();
        NavTask__c convertedTask;

        for (CRM_KafkaOppgave kafkaOppgave : kafkaOppgaver) {
            try {
                convertedTask = convertToNavTask(kafkaOppgave);
            } catch (Exception ex) {
                convertedTask = null;
                //If conversion throws exception, add error to related kafka messages
                for (KafkaMessage__c message : getRelatedMessages(String.valueOf(kafkaOppgave.id))) {
                    String errorMsg =
                        'Exception: ' +
                        ex.getTypeName() +
                        ' - ' +
                        ex.getMessage() +
                        ' - ' +
                        ex.getStackTraceString();
                    message.CRM_ErrorMessage__c = errorMsg.mid(0, 255); //Handle if the total error message exceeds 255 characters

                    setMessageError(errorMsg, message);
                }
            }
            if (convertedTask != null)
                returnList.add(convertedTask);
        }

        return returnList;
    }

    /**
     * @description: Maps fields from KafkaOppgave wrapper class to NavTask__c fields
     * @author Stian Ruud Schikora | 01-15-2021
     * @param kafkaOppgave
     * @return NavTask__c
     **/
    private NavTask__c convertToNavTask(CRM_KafkaOppgave kafkaOppgave) {
        NavTask__c navTask = new NavTask__c();
        Boolean actorExists =
            this.actorAccMap.containsKey(kafkaOppgave.getActorId()) &&
            String.isNotBlank(this.actorAccMap.get(kafkaOppgave.getActorId()));
        Boolean mappedTheme = this.commonCodeMap.containsKey('Tema' + kafkaOppgave.tema);
        if (actorExists && mappedTheme) {
            navTask.CRM_Account__c = this.actorAccMap.get(kafkaOppgave.getActorId());
            navTask.INT_External_Reference__c = kafkaOppgave.id;
            navTask.NKS_Task_Version__c = kafkaOppgave.versjon;
            navTask.CRM_NavUnit__c = this.navUnitMap.containsKey(kafkaOppgave.tildeltEnhetsnr)
                ? this.navUnitMap.get(kafkaOppgave.tildeltEnhetsnr).Id
                : null;
            navTask.Name = this.commonCodeMap.containsKey('Oppgavetyper' + kafkaOppgave.oppgavetype)
                ? this.commonCodeMap.get('Oppgavetyper' + kafkaOppgave.oppgavetype).Name
                : 'Oppgave';
            navTask.NKS_Assignee__c = kafkaOppgave.tilordnetRessurs;
            navTask.NKS_Comments__c = kafkaOppgave.beskrivelse;
            navTask.NKS_TaskType__c = this.commonCodeMap.containsKey('Oppgavetyper' + kafkaOppgave.oppgavetype)
                ? this.commonCodeMap.get('Oppgavetyper' + kafkaOppgave.oppgavetype).Id
                : null;
            navTask.NKS_Theme__c = this.commonCodeMap.get('Tema' + kafkaOppgave.tema).Id;
            navTask.NKS_Subtheme__c = this.commonCodeMap.containsKey('Behandlingstema' + kafkaOppgave.behandlingstema)
                ? this.commonCodeMap.get('Behandlingstema' + kafkaOppgave.behandlingstema).Id
                : null;
            navTask.CRM_Subtype__c = this.commonCodeMap.containsKey('Behandlingstyper' + kafkaOppgave.behandlingstype)
                ? this.commonCodeMap.get('Behandlingstyper' + kafkaOppgave.behandlingstype).Id
                : null;
            navTask.CRM_DueDate__c = String.isNotBlank(kafkaOppgave.fristFerdigstillelse)
                ? Date.valueOf(kafkaOppgave.fristFerdigstillelse)
                : null;
            navTask.CRM_Priority__c = kafkaOppgave.prioritet;
            navTask.NKS_Status__c = kafkaOppgave.status;
            navTask.NKS_Date_Registered__c = String.isNotBlank(kafkaOppgave.opprettetTidspunkt)
                ? Date.valueOf(kafkaOppgave.opprettetTidspunkt)
                : null;
            navTask.CRM_NoPersonInformation__c = true; //Need to be default set because of validation rule
        } else {
            //If actor is not existing in Salesforce, create an application log
            if (!actorExists && kafkaOppgave.getActorId() != null) {
                this.logger.error(
                    'Error creating NAV task, actor not found: ' +
                    kafkaOppgave.getActorId() +
                    '\n Task reference: ' +
                    kafkaOppgave.id,
                    null,
                    CRM_ApplicationDomain.domain.NKS
                );
            }

            if ((!actorExists && kafkaOppgave.getActorId() != null) || !mappedTheme) {
                String errorMessage = !actorExists ? 'Actor not found: ' + kafkaOppgave.getActorId() : '';
                errorMessage += !mappedTheme ? ' - Theme not mapped: ' + kafkaOppgave.tema : '';
                for (KafkaMessage__c message : getRelatedMessages(String.valueOf(kafkaOppgave.id))) {
                    setMessageError(errorMessage, message);
                }
            }
            return null;
        }
        return navTask;
    }

    //##########################//
    //      ERROR HANDLING      //
    //##########################//

    /**
     * @description: Verifies the upsert results and updates the KafkaMessages with
     * Correct status and error messages.
     * @author Stian Ruud Schikora | 02-26-2021
     * @param upsList
     * @param taskList
     **/
    private void verifyUpsertResults(List<Database.UpsertResult> upsList, List<NavTask__c> taskList) {
        for (Integer index = 0; index < upsList.size(); index++) {
            if (upsList[index].isSuccess()) {
                //Successful upsert
            } else {
                //Sets an error on every kafka message with the unique key
                for (
                    KafkaMessage__c message : getRelatedMessages(
                        String.valueOf(taskList[index].INT_External_Reference__c)
                    )
                ) {
                    setMessageError(upsList[index].getErrors(), message);
                }
            }
        }
    }

    /**
     * @description: Sets the message error
     * @author Stian Ruud Schikora | 02-26-2021
     * @param errList [List<Database.Error>]
     * @param message
     **/
    @testVisible
    private void setMessageError(List<Database.Error> errList, KafkaMessage__c message) {
        String errorMsg = '';
        for (Database.Error err : errList) {
            errorMsg = err.getStatusCode() + ': ' + err.getMessage() + ' - ' + 'FIELDS: ' + err.getFields();
        }
        message.CRM_ErrorMessage__c = errorMsg.mid(0, 255); //Handle if the total error message exceeds 255 characters
        message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
    }

    /**
     * @description: Sets the message error
     * @author Stian Ruud Schikora | 02-26-2021
     * @param String : errorMessage
     * @param message
     **/
    private void setMessageError(String errorMessage, KafkaMessage__c message) {
        message.CRM_ErrorMessage__c = errorMessage;
        message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
    }

    /**
     * @description: Returns a list of kafka messages with a matching CRM_Key__c
     * and the INT_EXternal_Reference__c field
     * @author Stian Ruud Schikora | 02-26-2021
     * @param String : reference
     * @return List<KafkaMessage__c>
     **/
    private List<KafkaMessage__c> getRelatedMessages(String reference) {
        return this.messageMap.get(reference);
    }
}
