public without sharing class CRM_KafkaOppgaveEventHandler {
    private static LoggerUtility logger = new LoggerUtility('Oppgave');
    /**
     * @description: Converts the platform events into KafkaMessage__c and calls for processing using the KafkaOppgaveHandler
     * @author Stian Ruud Schikora | 08-03-2021
     * @param kfOppgEvents
     **/
    public static void processOppgaveEvents(List<Kafka_Oppgave_Event__e> kfOppgEvents) {
        //logOffsets(JSON.serialize(kfOppgEvents)); Disable offset logging
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
     * Apply filter to only update NavTask__c that already exist in DB
     * @author Stian Ruud Schikora | 03-28-2022
     * @param kfOppgEvents
     **/
    private static void filterEvents(List<Kafka_Oppgave_Event__e> kfOppgEvents) {
        Set<Integer> oppgaveKeys = new Set<Integer>();
        Set<Integer> eventKeys = new Set<Integer>();
        Map<Integer, List<Kafka_Oppgave_Event__e>> oppgaveMap = new Map<Integer, List<Kafka_Oppgave_Event__e>>();

        for (Kafka_Oppgave_Event__e oppgEvent : kfOppgEvents) {
            eventKeys.add(Integer.valueOf(oppgEvent.CRM_Key__c));
        }

        for (NavTask__c navTask : [
            SELECT Id, INT_External_Reference__c
            FROM NavTask__c
            WHERE INT_External_Reference__c IN :eventKeys
        ]) {
            oppgaveKeys.add(Integer.valueOf(navTask.INT_External_Reference__c));
        }

        for (Integer i = kfOppgEvents.size() - 1; i >= 0; i--) {
            if (!oppgaveKeys.contains(Integer.valueOf(kfOppgEvents[i].CRM_Key__c))) {
                //If oppgave is not in SF DB we discard the event
                kfOppgEvents.remove(i);
            }
        }
    }

    /**
     * @description: Transforms Kafka_Oppgave_Event__c -> KafkaMessage__c
     * @author Stian Ruud Schikora | 08-03-2021
     * @param kfOppgEvents
     * @return List<KafkaMessage__c>
     **/
    private static List<KafkaMessage__c> doEventTransform(List<Kafka_Oppgave_Event__e> kfOppgEvents) {
        String jsonEvents;
        filterEvents(kfOppgEvents);
        jsonEvents = JSON.serialize(kfOppgEvents);

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

    @future
    public static void logOffsets(String jsonEvents) {
        List<Kafka_Oppgave_Event__e> kfOppgEvents = (List<Kafka_Oppgave_Event__e>) JSON.deserialize(
            jsonEvents,
            List<Kafka_Oppgave_Event__e>.class
        );
        List<Application_Log__c> offsetLogs = new List<Application_Log__c>();

        for (Kafka_Oppgave_Event__e kfOppgEvent : kfOppgEvents) {
            offsetLogs.add(
                new Application_Log__c(
                    Category__c = 'Oppgave Events',
                    CRM_Offset__c = Integer.valueOf(kfOppgEvent.CRM_Offset__c),
                    CRM_Partition__c = Integer.valueOf(kfOppgEvent.CRM_Partition__c),
                    Referrence_ID__c = kfOppgEvent.CRM_Key__c
                )
            );
        }

        insert offsetLogs;
    }

    public static void logLimits() {
        String message = 'Current limits\n';
        message += 'HEAP SIZE: ' + Limits.getHeapSize() + ' of ' + Limits.getLimitHeapSize() + '\n';
        message += 'CPU: ' + Limits.getCpuTime() + ' of ' + Limits.getLimitCpuTime() + '\n';
        message += 'SOQL ROWS: ' + Limits.getQueryRows() + ' of ' + Limits.getLimitQueryRows() + '\n';
        message += 'SOQL QUERIES: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries() + '\n';
        message += 'DML ROWS: ' + Limits.getDmlRows() + ' of ' + Limits.getLimitDmlRows() + '\n';
        message += 'DML STATEMENTS: ' + Limits.getDMLStatements() + ' of ' + Limits.getLimitDMLStatements();

        Logger.info(message, null, CRM_ApplicationDomain.Domain.NKS);
        logger.publish();
    }
}
