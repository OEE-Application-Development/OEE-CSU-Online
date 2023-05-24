global with sharing class CreditHelpers {

    private static RecordType creditTermRecordType = null;
    global static RecordType getCreditTermType() {
        if(creditTermRecordType == null) {
            creditTermRecordType = [select Id from RecordType where NamespacePrefix = 'csuoee' and SobjectType = 'hed__Term__c' and DeveloperName = 'Credit' LIMIT 1];
        }

        return creditTermRecordType;
    }

    private static RecordType creditInstitutionRecordType = null;
    global static RecordType getEducationInstitutionType() {
        if(creditInstitutionRecordType == null) {
            creditInstitutionRecordType = [select Id from RecordType where SobjectType = 'Account' and DeveloperName = 'Educational_Institution' LIMIT 1];
        }

        return creditInstitutionRecordType;
    }
    
}