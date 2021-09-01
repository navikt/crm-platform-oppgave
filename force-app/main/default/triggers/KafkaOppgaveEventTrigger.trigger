trigger KafkaOppgaveEventTrigger on Kafka_Oppgave_Event__e(after insert) {
    CRM_KafkaOppgaveEventHandler.processOppgaveEvents(Trigger.new);
}
