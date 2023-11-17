trigger CSUOEE_RunCreditRegistrationProcess on hed__Course_Enrollment__c (after insert) {
    List<CreditConfirmedEvent.CreditConfirmedRequest> requests = new List<CreditConfirmedEvent.CreditConfirmedRequest>();
    for(hed__Course_Enrollment__c enrollment : (List<hed__Course_Enrollment__c>) Trigger.new) {
        try {
            CreditConfirmedEvent.CreditConfirmedRequest request = new CreditConfirmedEvent.CreditConfirmedRequest();
            request.userId = enrollment.hed__Contact__r.csuoee__CSU_ID__c;
            request.offeringReference = enrollment.hed__Course_Offering__r.lms_hed__LMS_Reference_Code__c;
            request.status = enrollment.hed__Status__c;
            request.bannerStatus = enrollment.csuoee__Banner_Status__c;

            requests.add(request);
        } catch(Exception e) {
            continue;
        }
    }

    CreditConfirmedEvent.enrollStudent(requests);
}