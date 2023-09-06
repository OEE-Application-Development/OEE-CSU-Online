global with sharing class CreditHandleEnrollments {
    @InvocableMethod(Label='Handle Credit Student Enrollment' Description='Creates or updates a credit enrollment for a student.')
    global static List<hed__Course_Enrollment__c> handleStudentEnrollment(List<CombinedFunctions.EnrollmentRequest> requests) {
        List<hed__Course_Enrollment__c> returnList = new List<hed__Course_Enrollment__c>();
        for(CombinedFunctions.EnrollmentRequest request : requests) {
            try {
                returnList.add(handleEnrollment(request.userId, request.offeringReference, request.isDrop, request.statusInfo));
            } catch(Exception e) {
                returnList.add(null);
            }
        }
        return returnList;
    }

    private static hed__Course_Enrollment__c handleEnrollment(String creditId, String reference, Boolean isDrop, String bannerStatus) {
        Contact contact = [select Id from Contact where csuoee__CSU_ID__c = :creditId or csuoee__EID__c = :creditId LIMIT 1];
        if(contact == null) return null;

        hed__Course_Enrollment__c enrollment = CombinedFunctions.handleStudentEnrollment(contact, reference, isDrop);
        hed__Course_Offering__c offering = [select Id, csuoee__Campus_Code__c from hed__Course_Offering__c where Id = :enrollment.hed__Course_Offering__c LIMIT 1];
        // journey logic
        if(isDrop) {
            if(!validBannerEnrollment(bannerStatus) && validCampusCode(offering)) {
                //Has a confirmation email been sent? If not, we don't need to send anything.
                hed__Course_Enrollment__c emailCheck = [select Id, hed__Contact__c, csuoee__Offering_Reference__c, csuoee__Credit_Registration_Email_Sent__c from hed__Course_Enrollment__c where Id = :enrollment.Id LIMIT 1];
                if(emailCheck.csuoee__Credit_Registration_Email_Sent__c) {
                    csuoee__Marketing_Cloud_Journey_Event_Settings__c journeySettings = [select csuoee__Credit_Drop_EventType__c, csuoee__Credit_Confirmation_Key__c from csuoee__Marketing_Cloud_Journey_Event_Settings__c LIMIT 1];

                    // OK, add the event object
                    csuoee__Marketing_Cloud_Journey_Event__c event = new csuoee__Marketing_Cloud_Journey_Event__c(csuoee__ContactWhoId__c = emailCheck.hed__Contact__c, csuoee__Event__c = journeySettings.csuoee__Credit_Confirmation_Key__c, csuoee__Event_Type__c = journeySettings.csuoee__Credit_Drop_EventType__c, csuoee__Key__c = emailCheck.csuoee__Offering_Reference__c+'-'+emailCheck.Id+'-'+bannerStatus);
                    insert event;
                }
            }
        } else {
            // Valid Banner enrollment?
            if(validBannerEnrollment(bannerStatus) && validCampusCode(offering)) {
                // Check if the email has already been sent.
                hed__Course_Enrollment__c emailCheck = [select Id, hed__Contact__c, csuoee__Offering_Reference__c, csuoee__Credit_Registration_Email_Sent__c from hed__Course_Enrollment__c where Id = :enrollment.Id LIMIT 1];
                if(!emailCheck.csuoee__Credit_Registration_Email_Sent__c) {
                    csuoee__Marketing_Cloud_Journey_Event_Settings__c journeySettings = [select csuoee__Credit_Confirmation_EventType__c, csuoee__Credit_Confirmation_Key__c from csuoee__Marketing_Cloud_Journey_Event_Settings__c LIMIT 1];

                    // OK, add the event object
                    csuoee__Marketing_Cloud_Journey_Event__c event = new csuoee__Marketing_Cloud_Journey_Event__c(csuoee__ContactWhoId__c = emailCheck.hed__Contact__c, csuoee__Event__c = journeySettings.csuoee__Credit_Confirmation_Key__c, csuoee__Event_Type__c = journeySettings.csuoee__Credit_Confirmation_EventType__c, csuoee__Key__c = emailCheck.csuoee__Offering_Reference__c+'-'+emailCheck.Id+'-'+bannerStatus);
                    insert event;
                }
            }
        }

        return enrollment;
    }

    private static boolean validBannerEnrollment(String bannerStatus) {
        switch on bannerStatus {
            when 'LA', 'RE', 'NG', 'XE', 'RW' {
                return true;
            }
            when 'AU', 'WD', 'XF', 'WL', 'XW', 'UW', 'UN', 'XD', 'DW', 'UX', 'ZD', 'CW', 'CN', 'RD', 'UC', 'XU', 'UNPAID', 'UNPAID_DW' {
                return false;
            }
            when else {
                return false;
            }
        }
    }

    private static boolean validCampusCode(hed__Course_Offering__c offering) {
        return 'MC'.equals(offering.csuoee__Campus_Code__c);
    }

}