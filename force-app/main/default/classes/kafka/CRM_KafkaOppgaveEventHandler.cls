public without sharing class CRM_KafkaOppgaveEventHandler {
    private static LoggerUtility logger = new LoggerUtility();
    /**
     * @description: Converts the platform events into KafkaMessage__c and calls for processing using the KafkaOppgaveHandler
     * @author Stian Ruud Schikora | 08-03-2021
     * @param kfOppgEvents
     **/
    public static void processOppgaveEvents(List<Kafka_Oppgave_Event__e> kfOppgEvents) {
        CRM_KafkaOppgaveHandler messageHandler = new CRM_KafkaOppgaveHandler();
        messageHandler.processMessages(doEventTransform(kfOppgEvents));

        List<KafkaMessage__c> processedMessages = messageHandler.getProcessedMessages();
        handleProcessedMessages(processedMessages);
    }

    /**
     * @description: Transforms Kafka_Oppgave_Event__c -> KafkaMessage__c
     * @author Stian Ruud Schikora | 08-03-2021
     * @param kfOppgEvents
     * @return List<KafkaMessage__c>
     **/
    private static List<KafkaMessage__c> doEventTransform(List<Kafka_Oppgave_Event__e> kfOppgEvents) {
        String jsonEvents = JSON.serialize(kfOppgEvents);

        return (List<KafkaMessage__c>) JSON.deserialize(jsonEvents, List<KafkaMessage__c>.class);
    }

    /**
     * @description: Stores the processed KafkaMessage__c records
     * @author Stian Ruud Schikora | 08-03-2021
     * @param processedMessages
     **/
    private static void handleProcessedMessages(List<KafkaMessage__c> processedMessages) {
        try {
            insert processedMessages;
        } catch (Exception ex) {
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        }
    }
}
