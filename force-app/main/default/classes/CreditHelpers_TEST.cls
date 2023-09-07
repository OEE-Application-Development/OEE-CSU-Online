@IsTest
private class CreditHelpers_TEST {

    @TestSetup
    static void setupCourseData(){
        Contact c = new Contact(LastName = 'Test', csuoee__EID__c = 'TEST');
        insert c;

        Account uni = new Account(Name = 'CSU');
        insert uni;

        hed__Term__c t = new hed__Term__c(Name = '2023SP', hed__Account__c = uni.Id);
        insert t;

        Account a = new Account(Name = 'MJR-CONC-DEGR', hed__School_Code__c = 'MJR-CONC-DEGR');
        insert a;

        hed__Course__c course = new hed__Course__c(hed__Course_ID__c = 'CO 333', hed__Account__c = a.Id, csuoee__Course_Code__c = 'CO 333');
        insert course;

        hed__Course_Offering__c offering = new hed__Course_Offering__c(hed__Term__c = t.Id, hed__Course__c = course.Id, Name = 'CO 333 100', hed__Section_ID__c = '100');
        insert offering;

        //TermReference-Enrollment-EID
        hed__Program_Enrollment__c pe = new hed__Program_Enrollment__c(csuoee__Enrollment_Reference__c = '2023SP-MJR-CONC-DEGR-TEST');
        insert pe;
    }

    @IsTest
    private static void recordTypeTest() {
        List<RecordType> types = CreditRecordTypeRequestor.getCreditRecordTypes(new List<CreditRecordTypeRequestor.CreditRecordTypeRequest>{new CreditRecordTypeRequestor.CreditRecordTypeRequest('Term'), new CreditRecordTypeRequestor.CreditRecordTypeRequest('Department'), new CreditRecordTypeRequestor.CreditRecordTypeRequest('Educational Institution'), new CreditRecordTypeRequestor.CreditRecordTypeRequest('')});

        System.assertEquals(4, types.size());
        System.assert(types.get(0) != null);
        System.assert(types.get(3) == null);
    }

    @IsTest
    private static void handleStudentEnrollment() {
        CreditHandleEnrollments.handleStudentEnrollment(new List<CombinedFunctions.EnrollmentRequest> {new CombinedFunctions.EnrollmentRequest('TEST', '2023SP-CO-333-100', false, null)}).get(0);
    }

    @IsTest
    private static void enrollmentReferenceInsert() {
        hed__Program_Enrollment__c pe = [select Id, csuoee__Term__c, hed__Account__c, hed__Contact__c from hed__Program_Enrollment__c LIMIT 1];
        Contact c = [select Id from Contact LIMIT 1];
        Account a = [select Id, Name from Account where Name = 'MJR-CONC-DEGR' LIMIT 1];
        hed__Term__c t = [select Id, Name from hed__Term__c LIMIT 1];

        System.assert(pe.csuoee__Term__c.equals(t.Id));
        System.assert(pe.hed__Account__c.equals(a.Id));
        System.assert(pe.hed__Contact__c.equals(c.Id));

        hed__Course_Offering__c offering = [select Id from hed__Course_Offering__c LIMIT 1];

        hed__Course_Enrollment__c e = new hed__Course_Enrollment__c(hed__Contact__c = c.Id, hed__Course_Offering__c = offering.Id);
        e.hed__Verification_Status__c = 'Verified';
        e.csuoee__Banner_Status__c = 'RW';
        insert e;
        e.hed__Verification_Status__c = 'Pending';
        update e;
        update e;

        CreditHandleEnrollments.handleStudentEnrollment(new List<CombinedFunctions.EnrollmentRequest> {new CombinedFunctions.EnrollmentRequest('TEST', '2023SP-CO-333-100', false, 'RW')});
        CreditHandleEnrollments.handleStudentEnrollment(new List<CombinedFunctions.EnrollmentRequest> {new CombinedFunctions.EnrollmentRequest('TEST', '2023SP-CO-333-100', true, 'AU')});
    }

    @IsTest
    private static void creditRegistrationProcess() {
        Contact c = [select Id from Contact LIMIT 1];
        hed__Course_Offering__c offering = [select Id from hed__Course_Offering__c LIMIT 1];

        hed__Course_Enrollment__c ce = new hed__Course_Enrollment__c(hed__Course_Offering__c = offering.Id, hed__Contact__c = c.Id, hed__Verification_Status__c = 'Unverified');
        insert ce;

        hed__Course_Enrollment__c ce2 = new hed__Course_Enrollment__c(hed__Course_Offering__c = offering.Id, hed__Contact__c = c.Id, hed__Status__c = 'Enrolled', hed__Verification_Status__c = 'Verified');
        insert ce2;

        ce = [select Id, hed__Status__c from hed__Course_Enrollment__c where Id = :ce.Id LIMIT 1];
        System.assertEquals('Current', ce.hed__Status__c, 'Failed to set enrollment status properly.');

        ce.hed__Status__c = 'Enrolled';
        ce.hed__Verification_Status__c = 'Verified';
        update ce;

        System.assertEquals('Enrolled', ce.hed__Status__c, 'Failed to set enrollment status properly.');

        ce.hed__Contact__c = '';
        update ce;
    }
    
}