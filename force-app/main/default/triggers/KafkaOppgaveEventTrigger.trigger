trigger KafkaOppgaveEventTrigger on Kafka_Oppgave_Event__e(after insert) {
    System.debug('SOMETHING');
    CRM_KafkaOppgaveEventHandler.processOppgaveEvents(Trigger.new);
}
