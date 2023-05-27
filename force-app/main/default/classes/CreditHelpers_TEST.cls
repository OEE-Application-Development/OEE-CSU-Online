@IsTest
private class CreditHelpers_TEST {

    @IsTest
    private static void recordTypeTest() {
        List<RecordType> types = CreditRecordTypeRequestor.getCreditRecordTypes(new List<CreditRecordTypeRequestor.CreditRecordTypeRequest>{new CreditRecordTypeRequestor.CreditRecordTypeRequest('Term'), new CreditRecordTypeRequestor.CreditRecordTypeRequest('Department'), new CreditRecordTypeRequestor.CreditRecordTypeRequest('Educational Institution'), new CreditRecordTypeRequestor.CreditRecordTypeRequest('')});

        System.assertEquals(4, types.size());
        System.assert(types.get(0) != null);
        System.assert(types.get(3) == null);
    }

    @IsTest
    private static void handleStudentEnrollment() {
        CreditHandleEnrollments.handleStudentEnrollment(new List<CombinedFunctions.EnrollmentRequest> {new CombinedFunctions.EnrollmentRequest('test', '2023SP-CO-333-100', false)});
    }

    @IsTest
    private static void enrollmentReferenceInsert() {
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

        pe = [select Id, csuoee__Term__c, hed__Account__c, hed__Contact__c from hed__Program_Enrollment__c where Id = :pe.Id LIMIT 1];

        System.assert(pe.csuoee__Term__c.equals(t.Id));
        System.assert(pe.hed__Account__c.equals(a.Id));
        System.assert(pe.hed__Contact__c.equals(c.Id));
    }
    
}