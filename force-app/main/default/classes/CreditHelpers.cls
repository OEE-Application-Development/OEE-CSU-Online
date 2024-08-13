global with sharing class CreditHelpers {

    /* Record Types */
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

    private static RecordType studentEnrollmentRecordType = null;
    global static RecordType getStudentEnrollmentRecordType() {
        if(studentEnrollmentRecordType == null) {
            studentEnrollmentRecordType = [select Id from RecordType where NamespacePrefix = 'csuoee' and SobjectType = 'hed__Course_Enrollment__c' and DeveloperName = 'Student' LIMIT 1];
        }

        return studentEnrollmentRecordType;
    }

    private static RecordType pendingEnrollmentRecordType = null;
    global static RecordType getPendingEnrollmentRecordType() {
        if(pendingEnrollmentRecordType == null) {
            pendingEnrollmentRecordType = [select Id from RecordType where NamespacePrefix = 'csuoee' and SobjectType = 'hed__Course_Enrollment__c' and DeveloperName = 'Student_Pending' LIMIT 1];
        }

        return pendingEnrollmentRecordType;
    }

    private static RecordType slateApplicationRecordType = null;
    global static RecordType getSlateApplicationRecordType() {
        if(slateApplicationRecordType == null) {
            slateApplicationRecordType = [select Id from RecordType where NamespacePrefix = 'csuoee' and SobjectType = 'Account' and DeveloperName = 'Slate_Application_Account' LIMIT 1];
        }

        return slateApplicationRecordType;
    }
    
}