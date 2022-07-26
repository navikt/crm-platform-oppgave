public without sharing class CRM_NavTaskListViewCtrl {
    private class NotFoundException extends Exception {
    }

    public class UnsupportedOperandException extends Exception {
    }

    @AuraEnabled
    public static List<NavTask__c> getRecords(
        List<String> fieldsToQuery,
        String filteredByJson,
        Boolean ownedByRunningUser,
        Integer numRecords
    ) {
        List<FilteredBy> filteredBy = new List<FilteredBy>();
        String query = 'SELECT Id, ';

        if (String.isNotBlank(filteredByJson))
            filteredBy = (List<FilteredBy>) JSON.deserialize(filteredByJson, List<FilteredBy>.class);

        for (String queryField : fieldsToQuery) {
            query += queryField + ',';
        }
        query = query.removeEnd(',');
        query += ' FROM NavTask__c';
        if (filteredBy.size() != 0 || ownedByRunningUser)
            query += ' WHERE ';

        if (ownedByRunningUser == true)
            query += ' OwnerId = \'' + UserInfo.getUserId() + '\' AND ';

        for (FilteredBy filter : filteredBy) {
            query += filter.soqlFilter + ' AND ';
        }
        query = query.removeEnd('AND ');

        query += ' ORDER BY CRM_DueDate__c LIMIT ' + String.valueOf(numRecords);
        System.debug('QUERY: ' + query);
        return (List<NavTask__c>) Database.query(query);
    }

    public class FilteredBy {
        @AuraEnabled
        public String fieldApiName;
        @AuraEnabled
        public List<String> operandLabels;
        @AuraEnabled
        public String operator;

        public String soqlFilter {
            get {
                String filter = this.fieldApiName;
                switch on this.operator {
                    when 'Contains' {
                        throw new UnsupportedOperandException('No current support for operand');
                    }
                    when 'Equals' {
                        if (this.operandLabels.size() > 1) {
                            filter += ' IN (';
                            for (String operandLabel : this.operandLabels) {
                                filter += '\'' + operandLabel + '\',';
                            }
                            filter = filter.removeEnd(',') + ')';
                        } else {
                            filter += String.isBlank(this.operandLabels[0])
                                ? ' = null'
                                : ' = \'' + this.operandLabels[0] + '\'';
                        }
                    }
                    when 'Excludes' {
                        filter += ' NOT LIKE %\'' + this.operandLabels[0] + '%\'';
                    }
                    when 'GreaterOrEqual' {
                        filter += ' >= ' + parseDate(this.operandLabels[0]);
                    }
                    when 'GreaterThan' {
                        filter += ' > ' + parseDate(this.operandLabels[0]);
                    }
                    when 'Includes' {
                        filter += ' LIKE %\'' + this.operandLabels[0] + '%\'';
                    }
                    when 'LessOrEqual' {
                        filter += ' <= ' + parseDate(this.operandLabels[0]);
                    }
                    when 'LessThan' {
                        filter += ' < ' + parseDate(this.operandLabels[0]);
                    }
                    when 'NotContain' {
                        filter += ' NOT LIKE %\'' + this.operandLabels[0] + '%\'';
                    }
                    when 'NotEqual' {
                        if (this.operandLabels.size() > 1) {
                            filter += ' NOT IN (';
                            for (String operandLabel : this.operandLabels) {
                                filter += '\'' + operandLabel + '\',';
                            }
                            filter = filter.removeEnd(',') + ')';
                        } else {
                            filter += String.isBlank(this.operandLabels[0])
                                ? ' != null'
                                : ' != \'' + this.operandLabels[0] + '\'';
                        }
                    }
                    when 'StartsWith' {
                        filter += ' LIKE %\'' + this.operandLabels[0] + '\'';
                    }
                    when 'Within' {
                        throw new UnsupportedOperandException('No current support for operand');
                    }
                    when else {
                        filter = '';
                    }
                }
                return filter;
            }
            private set {
            }
        }

        /**
         * If the input is a parseable date string. The string is parsed and returned on a SOQL friendly format
         * @author Stian Ruud Schikora | 07-26-2022
         * @param dateString
         * @return Boolean
         **/
        private String parseDate(String dateString) {
            try {
                Date parsedDate = Date.parse(dateString);
                Datetime output = parsedDate;
                return output.format('yyyy-MM-dd');
            } catch (TypeException typeEx) {
                return dateString;
            }
        }
    }
}
