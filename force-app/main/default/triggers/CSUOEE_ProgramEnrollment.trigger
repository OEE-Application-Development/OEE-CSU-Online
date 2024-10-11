trigger CSUOEE_ProgramEnrollment on hed__Program_Enrollment__c (before insert, after insert) {
    if(Trigger.isBefore) {
        CreditHelpers.handleProgramEnrollmentInsert(Trigger.new);
    } else {
        CreditHelpers.handleProgramEnrollmentAfterInsert(Trigger.new);
    }
}