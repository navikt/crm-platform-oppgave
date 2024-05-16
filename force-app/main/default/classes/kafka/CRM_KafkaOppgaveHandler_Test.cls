/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 09-15-2021
 * @last modified by  : mamikals
 **/

@isTest
public class CRM_KafkaOppgaveHandler_Test {
    static CRM_KafkaOppgaveHandler handler = new CRM_KafkaOppgaveHandler();
    static CRM_KafkaOppgave version1;
    static CRM_KafkaOppgave version2;
    static CRM_KafkaOppgave errorTest;
    static CRM_KafkaOppgave invalidNavUnitTest;
    static CRM_KafkaOppgave updateTest;
    static CRM_KafkaOppgave behandlingstemaTest;
    static CRM_KafkaOppgave behandlingstypeTest;
    static CRM_KafkaOppgave beggeTest;
    static String behandlingsTemaId;
    static String behandlingsTypeId;
    static String beggeTemaId;
    static String beggeTypeId;

    private static void makeMocks() {
        CRM_KafkaOppgave.LegacyIdent idt = new CRM_KafkaOppgave.LegacyIdent();
        idt.identType = 'AKTOERID';
        idt.verdi = '123456789';

        CRM_KafkaOppgave testOppgave = new CRM_KafkaOppgave();
        testOppgave.id = 53336;
        testOppgave.tildeltEnhetsnr = '2990';
        testOppgave.tilordnetRessurs = 'Z994995';
        testOppgave.tema = 'BAR';
        testOppgave.oppgavetype = 'KONT_BRUK';
        testOppgave.versjon = 1;
        testOppgave.beskrivelse = 'TEST DESCRIPTION';
        testOppgave.fristFerdigstillelse = '2021-01-14';
        testOppgave.opprettetTidspunkt = '2021-01-12';
        testOppgave.prioritet = 'NORM';
        testOppgave.status = 'AAPNET';
        testOppgave.ident = idt;

        version1 = testOppgave;

        version2 = testOppgave.clone();
        version2.versjon = 2;
        version2.beskrivelse = 'NEW TEST DESCRIPTION';

        errorTest = testOppgave.clone();
        errorTest.id = 53337;
        errorTest.ident = new CRM_KafkaOppgave.LegacyIdent();
        errorTest.ident.verdi = '0000000';
        errorTest.ident.identType = 'AKTOERID';

        invalidNavUnitTest = testOppgave.clone();
        invalidNavUnitTest.id = 53338;
        invalidNavUnitTest.tildeltEnhetsnr = '0000';

        updateTest = testOppgave.clone();
        updateTest.id = 53339;

        behandlingstemaTest = testOppgave.clone();
        behandlingstemaTest.id = 53340;
        behandlingstemaTest.behandlingstema = 'ab0401';

        behandlingstypeTest = testOppgave.clone();
        behandlingstemaTest.id = 53341;
        behandlingstypeTest.behandlingstype = 'ae0117';

        beggeTest = testOppgave.clone();
        beggeTest.id = 53342;
        beggeTest.behandlingstema = 'ab0011';
        beggeTest.behandlingstype = 'ae0118';
    }
    @TestSetup
    static void makeData() {
        CRM_OPPGAVE_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '123456789'));
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavUnit__c(INT_UnitNumber__c = '2990'));
        CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'BAR', Name = 'Barnebidrag', CRM_Code_Set__c = 'Tema')
        );
        CRM_OPPGAVE_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'KONT_BRUK', Name = 'Kontakt Bruker', CRM_Code_Set__c = 'Oppgavetyper')
        );
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavTask__c(Name = 'TEST TASK', INT_External_Reference__c = 53339));
        behandlingsTemaId = CRM_OPPGAVE_TestDataFactory.createRecord(
                new Common_Code__c(
                    Name = 'Individuelle tiltak',
                    CRM_Code__c = 'ab0401',
                    CRM_Code_set__c = 'Behandlingstema'
                )
            )
            .Id;
        behandlingsTypeId = CRM_OPPGAVE_TestDataFactory.createRecord(
                new Common_Code__c(Name = 'Veteran sak', CRM_Code__c = 'ae0117', CRM_Code_set__c = 'Behandlingstyper')
            )
            .Id;
        beggeTemaId = CRM_OPPGAVE_TestDataFactory.createRecord(
                new Common_Code__c(Name = 'Nasjonal', CRM_Code__c = 'ae0118', CRM_Code_set__c = 'Behandlingstyper')
            )
            .Id;
        beggeTypeId = CRM_OPPGAVE_TestDataFactory.createRecord(
                new Common_Code__c(
                    Name = 'Gjenlevendepensjon',
                    CRM_Code__c = 'ab0011',
                    CRM_Code_set__c = 'Behandlingstema'
                )
            )
            .Id;
    }

    @isTest
    static void testMessageProcessing() {
        List<KafkaMessage__c> messages = new List<KafkaMessage__c>();
        makeMocks();

        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53336',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(version1)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53336',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(version2)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53337',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(errorTest)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53338',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(invalidNavUnitTest)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53339',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(updateTest)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53340',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(behandlingstemaTest)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53341',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(behandlingstypeTest)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53342',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(beggeTest)))
            )
        );

        Test.startTest();
        handler.processMessages(messages);
        handler.getProcessedMessages();
        handler.setMessageError(new List<Database.Error>(), messages[0]);
        Test.stopTest();

        System.debug([SELECT Log_Message__c, Pay_Load__c FROM Application_Log__c]);

        System.assert([SELECT COUNT() FROM NavTask__c] != 0);
        System.assert([SELECT COUNT() FROM NavTask__c WHERE CRM_NavUnit__c = NULL] == 1);
        System.assert([SELECT COUNT() FROM NavTask__c WHERE Name = 'Kontakt Bruker'] != 0);

        System.assert([SELECT COUNT() FROM NavTask__c WHERE NKS_Subtheme__c = :behandlingsTemaId] != 0);
        System.assert([SELECT COUNT() FROM NavTask__c WHERE CRM_Subtype__c = :behandlingsTypeId] != 0);
        System.assert(
            [SELECT COUNT() FROM NavTask__c WHERE NKS_Subtheme__c = :beggeTemaId AND CRM_Subtype__c = :beggeTypeId] != 0
        );
    }

    @isTest
    static void testCompareTo() {
        CRM_KafkaOppgave.LegacyIdent idt = new CRM_KafkaOppgave.LegacyIdent();
        idt.identType = 'AKTOERID';
        idt.verdi = '123456789';

        CRM_KafkaOppgave testOppgave = new CRM_KafkaOppgave();
        testOppgave.id = 53336;
        testOppgave.tildeltEnhetsnr = '2990';
        testOppgave.tilordnetRessurs = 'Z994995';
        testOppgave.tema = 'BAR';
        testOppgave.oppgavetype = 'KONT_BRUK';
        testOppgave.versjon = 1;
        testOppgave.beskrivelse = 'TEST DESCRIPTION';
        testOppgave.fristFerdigstillelse = '2021-01-14';
        testOppgave.opprettetTidspunkt = '2021-01-12';
        testOppgave.prioritet = 'NORM';
        testOppgave.status = 'AAPNET';
        testOppgave.ident = idt;

        CRM_KafkaOppgave version2 = testOppgave.clone();

        Test.startTest();
        testOppgave.compareTo(version2);
        Test.stopTest();
    }

    @isTest
    static void testGetActorId() {
        CRM_KafkaOppgave.LegacyIdent idt = new CRM_KafkaOppgave.LegacyIdent();
        idt.identType = 'AKTOERID';
        idt.verdi = '123456789';

        CRM_KafkaOppgave testOppgave = new CRM_KafkaOppgave();
        testOppgave.ident = idt;

        Test.startTest();
        testOppgave.getActorId();
        Test.stopTest();
    }

    @isTest
    static void testGetActorIdWithAktoerId() {
        CRM_KafkaOppgave testOppgave = new CRM_KafkaOppgave();
        testOppgave.aktoerId = 'testId';

        Test.startTest();
        testOppgave.getActorId();
        Test.stopTest();
    }

    @isTest
    static void testGetActorIdElseClause() {
        CRM_KafkaOppgave testOppgave = new CRM_KafkaOppgave();
        CRM_KafkaOppgave.Ident idt = new CRM_KafkaOppgave.Ident();
        idt.gruppe = 'AKTOERID';
        idt.ident = '123456789';


        testOppgave.identer = new List<CRM_KafkaOppgave.Ident> { idt };
        Test.startTest();
        testOppgave.getActorId();
        Test.stopTest();
    }
}