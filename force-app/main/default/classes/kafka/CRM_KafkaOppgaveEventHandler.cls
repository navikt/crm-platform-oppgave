public without sharing class CRM_KafkaOppgaveEventHandler {
    private static LoggerUtility logger = new LoggerUtility('Oppgave');
    /**
     * @description: Converts the platform events into KafkaMessage__c and calls for processing using the KafkaOppgaveHandler
     * @author Stian Ruud Schikora | 08-03-2021
     * @param kfOppgEvents
     **/
    public static void processOppgaveEvents(List<Kafka_Oppgave_Event__e> kfOppgEvents) {
        CRM_KafkaOppgaveHandler messageHandler = new CRM_KafkaOppgaveHandler();
        try {
            messageHandler.processMessages(doEventTransform(kfOppgEvents));
        } catch (Exception ex) {
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        }

        List<KafkaMessage__c> failedMessages = messageHandler.getFailedMessages();
        handleFailedMessages(failedMessages);

        logger.publish();
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
     * @param failedMessages
     **/
    private static void handleFailedMessages(List<KafkaMessage__c> failedMessages) {
        try {
            insert failedMessages;
        } catch (Exception ex) {
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        }
    }
}
