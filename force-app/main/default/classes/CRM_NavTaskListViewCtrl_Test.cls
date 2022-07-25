@isTest
public class CRM_NavTaskListViewCtrl_Test {
    @TestSetup
    static void makeData() {
        CRM_OPPGAVE_TestDataFactory.createRecord(new NavTask__c(Name = 'TEST'));
    }

    @isTest
    static void testGetRecords() {
        List<CRM_NavTaskListViewCtrl.FilteredBy> filterList = new List<CRM_NavTaskListViewCtrl.FilteredBy>();
        CRM_NavTaskListViewCtrl.FilteredBy filter = new CRM_NavTaskListViewCtrl.FilteredBy();
        filter.fieldApiName = 'Name';
        filter.operator = 'Equals';
        filter.operandLabels = new List<String>{ 'TEST' };
        filterList.add(filter);

        CRM_NavTaskListViewCtrl.FilteredBy testFilter = new CRM_NavTaskListViewCtrl.FilteredBy();
        testFilter.operandLabels = new List<String>{ 'TEST1', 'TEST2' };
        testFilter.operator = 'Equals';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'NotEquals';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'Excludes';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'GreaterOrEqual';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'GreaterThan';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'Includes';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'LessThanOrEqual';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'LessThan';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'NotContain';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'NotEqual';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'StartsWith';
        System.assertNotEquals(null, testFilter.soqlFilter);
        testFilter.operator = 'Within';
        try {
            String sowlFilter = testFilter.soqlFilter;
        } catch (CRM_NavTaskListViewCtrl.UnsupportedOperandException ex) {
            System.assert(true);
        }

        List<String> fieldsToQuery = new List<String>{ 'Name' };
        Test.startTest();
        List<NavTask__c> retList = CRM_NavTaskListViewCtrl.getRecords(
            fieldsToQuery,
            JSON.serialize(filterList),
            false,
            10
        );
        Test.stopTest();

        System.assertNotEquals(0, retList.size());
    }
}
