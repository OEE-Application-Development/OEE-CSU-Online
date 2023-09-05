trigger CSUOEE_RunCreditRegistrationProcess on hed__Course_Enrollment__c (after insert) {
    for(hed__Course_Enrollment__c enrollment : (List<hed__Course_Enrollment__c>) Trigger.new) {
        if(enrollment.hed__Status__c != 'Enrolled' && !enrollment.csuoee__Banner_Confirmed__c) {
            Map<String, Object> inputMap = new Map<String, Object>();
            inputMap.put('CourseEnrollmentToTrack', enrollment);

            // Start tracking it!
            Flow.Interview.createInterview('csuoee', 'Credit_Registration_Process', inputMap).start();
        }
    }
}