global class OppgaveRetry_Scheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        OppgaveRetry_Batch batch = new OppgaveRetry_Batch();
        Database.executebatch(batch, 200);
    }
}
