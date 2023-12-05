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
        Contact contact = [select Id from Contact where csuoee__CSU_ID__c = :creditId or csuoee__EID__c = :creditId or csuoee__Front_Door_ID__c = :creditId LIMIT 1];
        if(contact == null) return null;

        return CombinedFunctions.handleStudentEnrollment(contact, reference, isDrop);
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