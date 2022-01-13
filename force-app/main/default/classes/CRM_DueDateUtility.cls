public without sharing class CRM_DueDateUtility {
    //Defining map to handle bulk requests
    private static Map<Id, String> commonCodeMap {
        get {
            if (commonCodeMap == null) {
                commonCodeMap = new Map<Id, String>();
                for (Common_Code__c comCode : [
                    SELECT Id, CRM_Code__c
                    FROM Common_Code__c
                    WHERE CRM_Code_Set__c IN ('Tema', 'Oppgavetyper')
                ]) {
                    commonCodeMap.put(comCode.Id, comCode.CRM_Code__c);
                }
            }
            return commonCodeMap;
        }
        private set {
        }
    }

    private static Map<String, NAV_Task_Due_Date__mdt> dueDateMap {
        get {
            if (dueDateMap == null) {
                dueDateMap = new Map<String, NAV_Task_Due_Date__mdt>();
                for (NAV_Task_Due_Date__mdt dueDate : [
                    SELECT CRM_Business_Days__c, CRM_Theme_Code__c, CRM_Task_Type__c
                    FROM NAV_Task_Due_Date__mdt
                ]) {
                    dueDateMap.put(dueDate.CRM_Theme_Code__c + '_' + dueDate.CRM_Task_Type__c, dueDate);
                }
            }
            return dueDateMap;
        }
        private set {
        }
    }
    /**
     * Method to populate a due date, based on both theme, and task type
     * Calculate number of days from mdt, and will not set on holidays
     * @author Lars Petter Johnsen
     * @date 11.06.2021
     */
    @invocableMethod(label='get Due Date' category='Oppgave')
    public static List<Date> setDueDate(List<NavTask__c> taskList) {
        List<Date> dateList = new List<Date>();
        List<Holiday> holidays = [SELECT ActivityDate FROM Holiday];
        List<Date> holidayDateList = new List<Date>();
        for (Holiday h : holidays) {
            holidayDateList.add(h.ActivityDate);
        }

        for (NavTask__c task : taskList) {
            String theme = commonCodeMap.containsKey(task.NKS_Theme__c) ? commonCodeMap.get(task.NKS_Theme__c) : null;
            String taskType = commonCodeMap.containsKey(task.NKS_TaskType__c)
                ? commonCodeMap.get(task.NKS_TaskType__c)
                : null;
            NAV_Task_Due_Date__mdt duedateRecord;
            if (dueDateMap.containsKey(theme + '_' + taskType)) {
                duedateRecord = dueDateMap.get(theme + '_' + taskType);
            } else {
                LoggerUtility logger = new LoggerUtility('Oppgave');
                logger.warning('Error retrieving duedate rule themecode = ' + theme + 'TaskType = ' + taskType, null);
                logger.publish();
            }

            Date today = Date.today();
            //Number of business days defaults to 2 if nothing else is defined
            Integer numberofBusinessdays = duedateRecord != null
                ? Integer.valueOf(duedateRecord.CRM_Business_Days__c)
                : 2;

            Boolean valid = false;
            Integer businessdaysbetween = 0;
            Date newDueDate = today;
            while (valid == false) {
                DateTime dt = (DateTime) newDueDate;
                String day = dt.format('EEE');

                if (day == 'Sat' || day == 'Sun' || holidayDateList.contains(newDueDate)) {
                    newDueDate = newDueDate.addDays(1);
                } else {
                    if (businessdaysbetween >= numberofBusinessdays) {
                        valid = true;
                        break;
                    }
                    businessdaysbetween++;
                    newDueDate = newDueDate.addDays(1);
                }
            }
            dateList.add(newDueDate);
        }
        return dateList;
    }
}
