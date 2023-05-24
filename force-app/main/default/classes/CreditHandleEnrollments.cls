global with sharing class CreditHandleEnrollments {
    @InvocableMethod(Label='Handle Credit Student Enrollment' Description='Creates or updates a credit enrollment for a student.')
    global static List<hed__Course_Enrollment__c> handleStudentEnrollment(List<CombinedFunctions.EnrollmentRequest> requests) {
        List<hed__Course_Enrollment__c> returnList = new List<hed__Course_Enrollment__c>();
        for(CombinedFunctions.EnrollmentRequest request : requests) {
            try {
                returnList.add(handleEnrollment(request.userId, request.offeringReference, request.isDrop));
            } catch(Exception e) {
                returnList.add(null);
            }
        }
        return returnList;
    }

    private static hed__Course_Enrollment__c handleEnrollment(String creditId, String reference, Boolean isDrop) {
        Contact contact = [select Id from Contact where csuoee__CSU_ID__c = :creditId or csuoee__EID__c = :creditId LIMIT 1];
        if(contact == null) return null;

        return CombinedFunctions.handleStudentEnrollment(contact, reference, isDrop);
    }
}