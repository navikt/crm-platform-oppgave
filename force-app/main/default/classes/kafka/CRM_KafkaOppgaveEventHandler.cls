public without sharing class CRM_KafkaOppgaveEventHandler {
    private static LoggerUtility logger = new LoggerUtility('Oppgave');
    /**
     * @description: Converts the platform events into KafkaMessage__c and calls for processing using the KafkaOppgaveHandler
     * @author Stian Ruud Schikora | 08-03-2021
     * @param kfOppgEvents
     **/
    public static void processOppgaveEvents(List<Kafka_Oppgave_Event__e> kfOppgEvents) {
        CRM_KafkaOppgaveHandler messageHandler = new CRM_KafkaOppgaveHandler();
        List<KafkaMessage__c> transformedMessages;
        try {
            transformedMessages = doEventTransform(kfOppgEvents);
            messageHandler.processMessages(transformedMessages);
        } catch (JSONException jsonEx) {
            //JSONException means that the event transformation has failed. This is critical and should be investigated in the app posting the events
            logger.exception(jsonEx, null, CRM_ApplicationDomain.Domain.NKS);
        } catch (Exception ex) {
            //Unhandled Exceptions means the transaction has rolled back. Converted messages should be stored and thus handled asynchronously
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
            if (transformedMessages != null)
                submitToAsyncProcess(transformedMessages);
            logger.publish();
            return;
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
     * @description: Method handling insert of all transformed events to async processing. This is called when i.e. an unhandled exception is caught as this most likely
     * will result in that all handled events are rolled back
     * @author Stian Ruud Schikora | 09-23-2021
     * @param kafkaMessages
     **/
    @TestVisible
    private static void submitToAsyncProcess(List<KafkaMessage__c> kafkaMessages) {
        try {
            for (KafkaMessage__c kfMsg : kafkaMessages) {
                kfMsg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
            }
            insert kafkaMessages;
        } catch (Exception ex) {
            logger.exception(ex, null, CRM_ApplicationDomain.Domain.NKS);
        } finally {
            logger.publish();
        }
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
