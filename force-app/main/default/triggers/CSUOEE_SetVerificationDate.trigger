trigger CSUOEE_SetVerificationDate on hed__Course_Enrollment__c (before insert, before update) {
    Map<Id, hed__Course_Enrollment__c> oldValues = (Map<Id, hed__Course_Enrollment__c>) Trigger.newMap;
    Map<Id, hed__Course_Enrollment__c> newValues = (Map<Id, hed__Course_Enrollment__c>) Trigger.newMap;
    for(Id enrollmentId : newValues.keySet()) {
        hed__Course_Enrollment__c e = newValues.get(enrollmentId);
        if(String.isNotBlank(e.hed__Verification_Status__c)) {
            hed__Course_Enrollment__c f = oldValues.get(enrollmentId);
            if(f == null) {
                e.hed__Verification_Status_Date__c = Date.today();
            } else {
                if(!e.hed__Verification_Status__c.equals(f.hed__Verification_Status__c)) {
                    e.hed__Verification_Status_Date__c = Date.today();
                }
            }
        }
    }
}