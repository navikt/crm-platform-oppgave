@isTest
public class CRM_KafkaOppgaveEventHandler_Test {
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
    }

    @isTest
    static void testEventHandling() {
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

        CRM_KafkaOppgave testOppgave2 = testOppgave.clone();
        testOppgave2.id = 53339;
        testOppgave2.versjon = 2;

        Kafka_Oppgave_Event__e oppgaveEvent = new Kafka_Oppgave_Event__e();
        oppgaveEvent.CRM_Key__c = String.valueOf(testOppgave.id);
        oppgaveEvent.CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(testOppgave)));
        oppgaveEvent.CRM_Topic__c = 'aapen-oppgave-dev-syntetisk';

        Kafka_Oppgave_Event__e oppgaveEvent2 = new Kafka_Oppgave_Event__e();
        oppgaveEvent.CRM_Key__c = String.valueOf(testOppgave2.id);
        oppgaveEvent.CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(testOppgave2)));
        oppgaveEvent.CRM_Topic__c = 'aapen-oppgave-dev-syntetisk';

        Test.startTest();
        Eventbus.publish(new List<Kafka_Oppgave_Event__e>{ oppgaveEvent, oppgaveEvent2 });
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM NavTask__c WHERE NKS_Task_Version__c > 1]);
        System.assertEquals(1, [SELECT COUNT() FROM NavTask__c]);
    }

    @isTest
    static void testSubmitToAsync() {
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

        Test.startTest();
        CRM_KafkaOppgaveEventHandler.submitToAsyncProcess(
            new List<KafkaMessage__c>{
                new KafkaMessage__c(
                    CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(testOppgave))),
                    CRM_Key__c = String.valueOf(testOppgave.Id),
                    CRM_Topic__c = 'aapen-oppgave-dev-syntetisk'
                )
            }
        );
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM KafkaMessage__c]);
    }
}
