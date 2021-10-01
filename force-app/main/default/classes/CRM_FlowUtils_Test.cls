@isTest
public with sharing class CRM_FlowUtils_Test {

    @isTest
    static void testFormat(){
        List<CRM_FlowUtils.DateTimeInputWrapper> inputList = new List<CRM_FlowUtils.DateTimeInputWrapper>();
        Datetime testDatetime = Datetime.now();
        inputList.add(new CRM_FlowUtils.DateTimeInputWrapper(testDatetime,'dd-MM-yyyy HH:mm:ss'));
        Test.startTest();
        List<String> testResults = CRM_FlowUtils.formatDateList(inputList);
        Test.stopTest();
        System.assertEquals(testDatetime.format('dd-MM-yyyy HH:mm:ss'), testResults[0]);
    }

    @isTest
    static void testStaticFormat(){
        List<CRM_FlowUtils.DateTimeInputWrapper> inputList = new List<CRM_FlowUtils.DateTimeInputWrapper>();
        Datetime testDatetime = Datetime.newInstance(1999, 08, 17, 23, 59, 12);
        inputList.add(new CRM_FlowUtils.DateTimeInputWrapper(testDatetime,'MM-dd-;;:_yyyy HH---m'));
        Test.startTest();
        List<String> testResults = CRM_FlowUtils.formatDateList(inputList);
        Test.stopTest();
        System.assertEquals('08-17-;;:_1999 23---59', testResults[0]);
    }
}
