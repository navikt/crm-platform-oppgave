public with sharing class CRM_NavTaskWorkAllocationController {
    @AuraEnabled(cacheable=true)
    public static List<NavUnit__c> getWorkAllocations(
        String personId,
        String themeGroupCode,
        String themeCode,
        String themeSubThemeCode,
        String themeSubTypeCode,
        String taskType
    ) {
        Map<String, NavUnit__c> unitMap = new Map<String, NavUnit__c>();
        Person__c p = String.isNotBlank(personId) ? getPerson(personId) : null;
        NavUnitWorkAllocationInput input = new NavUnitWorkAllocationInput();
        input.temagruppe = themeGroupCode;
        input.tema = themeCode;
        input.behandlingstema = themeSubThemeCode;
        input.behandlingstype = themeSubTypeCode;
        input.oppgavetype = taskType;
        List<NavUnitWorkAllocation> workAllocations = NorgNavUnits.getWorkAllocation(
            p,
            input
        );
        if (workAllocations != null && workAllocations.size() > 0) {
            for (NavUnitWorkAllocation workAllocation : workAllocations) {
                unitMap.put(workAllocation.enhetNr, null);
            }
            for (NavUnit__c sfUnit : [
                SELECT Id, INT_UnitNumber__c
                FROM NavUnit__c
                WHERE INT_UnitNumber__c IN :unitMap.keySet()
            ]) {
                unitMap.put(sfUnit.INT_UnitNumber__c, sfUnit);
            }
        }
        return unitMap.values();
    }

    @AuraEnabled(cacheable=true)
    public static String getUserNavUnitId(String userUnitNumber) {
        return [SELECT Id FROM NavUnit__c WHERE INT_UnitNumber__c = :userUnitNumber]?.Id;
    }

    private static Person__c getPerson(Id personId) {
        return [
            SELECT Id, INT_IsNavEmployee__c, INT_Confidential__c, INT_DistrictNumber__c, INT_MunicipalityNumber__c
            FROM Person__c
            WHERE Id = :personId
        ][0];
    }
}
