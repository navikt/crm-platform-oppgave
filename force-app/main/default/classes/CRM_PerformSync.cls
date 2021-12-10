global with sharing class CRM_PerformSync implements Schedulable {
    global void execute(SchedulableContext sc) {
        for (Sync_Class_Binding__mdt binding : [
            SELECT Id, ApexClass__c
            FROM Sync_Class_Binding__mdt
        ]) {
            ((CRM_SyncInterface) Type.forName(binding.ApexClass__c)).doSync();
        }
    }
}
