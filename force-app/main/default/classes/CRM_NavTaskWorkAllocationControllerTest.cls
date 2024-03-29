@IsTest
private with sharing class CRM_NavTaskWorkAllocationControllerTest {
    @isTest
    static void getWorkAllocations_Success() {
        String unitJSON =
            '[' +
            '	{' +
            '		"enhetId": 100000770,' +
            '		"navn": "Test Unit",' +
            '		"enhetNr": "1234",' +
            '		"antallRessurser": 0,' +
            '		"status": "Aktiv",' +
            '		"orgNivaa": "EN",' +
            '		"type": "YTA",' +
            '		"organisasjonsnummer": null,' +
            '		"underEtableringDato": "1970-01-01",' +
            '		"aktiveringsdato": "1970-01-01",' +
            '		"underAvviklingDato": null,' +
            '		"nedleggelsesdato": null,' +
            '		"oppgavebehandler": true,' +
            '		"versjon": 2,' +
            '		"sosialeTjenester": null,' +
            '		"kanalstrategi": null,' +
            '		"orgNrTilKommunaltNavKontor": null' +
            '	}' +
            ']';
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', unitJSON, null));
        Person__c p = (Person__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new Person__c(
                Name = '1234567890',
                INT_LastName__c = 'Potter',
                INT_IsNavEmployee__c = false,
                INT_Confidential__c = 'UGRADERT',
                INT_GTMunicipalityNumber__c = '1234'
            ),
            true
        );
        NavUnit__c unit1 = (NavUnit__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new NavUnit__c(Name = 'Test Unit', INT_UnitNumber__c = '1234'),
            true
        );
        NavUnit__c unit2 = (NavUnit__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new NavUnit__c(Name = 'Test Unit2', INT_UnitNumber__c = '4321'),
            true
        );
        List<NavUnit__c> result;
        Test.startTest();
        result = CRM_NavTaskWorkAllocationController.getWorkAllocations(
            p.Id,
            'themeGroupCode',
            'themeCode',
            'themeSubThemeCode',
            'themeSubTypeCode',
            'taskType'
        );
        Test.stopTest();
        System.assertNotEquals(null, result, 'Excpected a successful result');
        System.assertEquals(1, result.size(), 'Expected one unit');
        System.assertEquals(unit1.Id, result[0].Id, 'Expected to the sf id populated with the correct Id');
    }
    @isTest
    static void getWorkAllocations_NoPerson() {
        String unitJSON =
            '[' +
            '	{' +
            '		"enhetId": 100000770,' +
            '		"navn": "Test Unit",' +
            '		"enhetNr": "1234",' +
            '		"antallRessurser": 0,' +
            '		"status": "Aktiv",' +
            '		"orgNivaa": "EN",' +
            '		"type": "YTA",' +
            '		"organisasjonsnummer": null,' +
            '		"underEtableringDato": "1970-01-01",' +
            '		"aktiveringsdato": "1970-01-01",' +
            '		"underAvviklingDato": null,' +
            '		"nedleggelsesdato": null,' +
            '		"oppgavebehandler": true,' +
            '		"versjon": 2,' +
            '		"sosialeTjenester": null,' +
            '		"kanalstrategi": null,' +
            '		"orgNrTilKommunaltNavKontor": null' +
            '	}' +
            ']';
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', unitJSON, null));
        NavUnit__c unit1 = (NavUnit__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new NavUnit__c(Name = 'Test Unit', INT_UnitNumber__c = '1234'),
            true
        );
        NavUnit__c unit2 = (NavUnit__c) CRM_OPPGAVE_TestDataFactory.createRecord(
            new NavUnit__c(Name = 'Test Unit2', INT_UnitNumber__c = '4321'),
            true
        );
        List<NavUnit__c> result;
        Test.startTest();
        result = CRM_NavTaskWorkAllocationController.getWorkAllocations(
            null,
            'themeGroupCode',
            'themeCode',
            'themeSubThemeCode',
            'themeSubTypeCode',
            'taskType'
        );
        Test.stopTest();
        System.assertNotEquals(null, result, 'Excpected a successful result');
        System.assertEquals(1, result.size(), 'Expected one unit');
        System.assertEquals(unit1.Id, result[0].Id, 'Expected to the sf id populated with the correct Id');
    }
    @isTest
    static void testGetUserNavUnit() {
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavUnit__c(INT_UnitNumber__c = '0701'));
        Test.startTest();
        NavUnit__c navUnit = CRM_NavTaskWorkAllocationController.getUserNavUnit('0701');
        Test.stopTest();
        System.assert(navUnit.INT_UnitNumber__c == '0701');
    }
}
