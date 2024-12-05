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

    /** Trigger Helpers **/
    global static void handleProgramEnrollmentInsert(List<hed__Program_Enrollment__c> enrollments) {
        // Set Start & End dates via term if they're not set.
        Set<Id> termsToSearch = new Set<Id>();
        for(hed__Program_Enrollment__c enrollment : enrollments) {
            if(enrollment.hed__Start_Date__c == null || enrollment.hed__End_Date__c == null) {
                termsToSearch.add(enrollment.csuoee__Term__c);
            }
        }

        // Conditionally set empty values
        Map<Id, hed__Term__c> termMap = new Map<Id, hed__Term__c>([SELECT Id, hed__Start_Date__c, hed__End_Date__c FROM hed__Term__c WHERE Id IN :termsToSearch]);
        for(hed__Program_Enrollment__c enrollment : enrollments) {
            if(enrollment.hed__Start_Date__c == null && enrollment.csuoee__Term__c != null)enrollment.hed__Start_Date__c = termMap.get(enrollment.csuoee__Term__c).hed__Start_Date__c;
            if(enrollment.hed__End_Date__c == null && enrollment.csuoee__Term__c != null)enrollment.hed__End_Date__c = termMap.get(enrollment.csuoee__Term__c).hed__End_Date__c;
        }
    }

    global static void handleProgramEnrollmentAfterInsert(List<hed__Program_Enrollment__c> enrollments) {
        // Map of Contact Id to Account Id (Program)
        Map<Id, Id> contactProgramMap = new Map<Id, Id>();
        for(hed__Program_Enrollment__c enrollment : enrollments) {
            contactProgramMap.put(enrollment.hed__Contact__c, enrollment.hed__Account__c);
        }

        List<Contact> contactsToUpdate = new List<Contact>();
        for(Contact contact : [SELECT Id, csuoee__Primary_Academic_Program__c FROM Contact WHERE Id IN :contactProgramMap.keySet()]) {
            Id programId = contactProgramMap.get(contact.Id);
            if(contact.csuoee__Primary_Academic_Program__c == null || contact.csuoee__Primary_Academic_Program__c != programId) {
                contact.csuoee__Primary_Academic_Program__c = programId;
                contactsToUpdate.add(contact);
            }
        }

        if(!contactsToUpdate.isEmpty())update contactsToUpdate;
    }
    
}