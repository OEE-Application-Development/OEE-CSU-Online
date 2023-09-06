trigger CSUOEE_SetVerificationDate on hed__Course_Enrollment__c (before insert, before update) {
    Map<Id, hed__Course_Enrollment__c> oldValues = (Map<Id, hed__Course_Enrollment__c>) Trigger.newMap;
    List<hed__Course_Enrollment__c> newValues = (List<hed__Course_Enrollment__c>) Trigger.new;
    for(hed__Course_Enrollment__c e : newValues) {
        if(String.isNotBlank(e.hed__Verification_Status__c)) {
            if(e.Id != null) {// Was an update
                hed__Course_Enrollment__c f = oldValues.get(e.Id);
                if(f == null) {
                    e.hed__Verification_Status_Date__c = Date.today();
                } else {
                    if(!e.hed__Verification_Status__c.equals(f.hed__Verification_Status__c)) {
                        e.hed__Verification_Status_Date__c = Date.today();
                    }
                }
            } else {
                e.hed__Verification_Status_Date__c = Date.today();
            }
        }

        if(e.Id == null) {
            RecordType studentType = CreditHelpers.getStudentEnrollmentRecordType();
            if(e.RecordTypeId == null ||  studentType.Id == e.RecordTypeId) {
                // If an insert, determine recordtype.
                if('Enrolled'.equals(e.hed__Status__c)) {
                    // Set as Student Enrollment
                    e.RecordTypeId = studentType.Id;
                } else {
                    // Set as Pending Student Enrollment
                    e.RecordTypeId = CreditHelpers.getPendingEnrollmentRecordType().Id;
                }
            }
        }
    }
}