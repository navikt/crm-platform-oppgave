public with sharing class CRM_FlowUtils {

    @InvocableMethod(label='Formats a date and/or time' category='Utility')
    public static List<String> formatDateList(List<DateTimeInputWrapper> datetimeInputList) {
        List<String> returnList = new List<String>();

        for (DateTimeInputWrapper datetimeInput : datetimeInputList) {
            returnList.add(formatDate(datetimeInput));
        }
        return returnList;
    }
    public static String formatDate(DateTimeInputWrapper datetimeInput) {
        Datetime chosenTime;
        
        if (datetimeInput.inputDatetime != null){
            chosenTime = datetimeInput.inputDatetime;
        } else {
            chosenTime = Datetime.now();
        }
        
        return chosenTime.format(datetimeInput.format);
    }

    public class DateTimeInputWrapper {
        @invocableVariable(label='The datetime to format, will default to the current time in the user\'s timezone')
        public Datetime inputDatetime;
        @invocableVariable(label='The format to display the date and time. E.g: dd-MM-yyyy HH:mm:ss' required=true)
        public String format;

        public DateTimeInputWrapper() {
        }

        public DateTimeInputWrapper(Datetime inputDatetime, String format) {
            this.inputDatetime = inputDatetime;
            this.format = format;
        }

        public DateTimeInputWrapper(String format) {
            this.format = format;
        }
    }
}
