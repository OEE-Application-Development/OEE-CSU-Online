@IsTest
private class CreditHelpers_TEST {

    @TestSetup
    static void setupCourseData(){
        csuoee__Marketing_Cloud_Journey_Event_Settings__c settings = new csuoee__Marketing_Cloud_Journey_Event_Settings__c(csuoee__Credit_Confirmation_EventType__c = 'fake-id', csuoee__Credit_Confirmation_Key__c = 'fake-key');
        insert settings;

        Contact c = new Contact(LastName = 'Test', csuoee__EID__c = 'TEST', csuoee__CSU_ID__c = 'TESTCSUID');
        insert c;

        Account uni = new Account(Name = 'CSU');
        insert uni;

        hed__Term__c t = new hed__Term__c(Name = '2023SP', csuoee__ODS_Term_ID__c = '202310', hed__Account__c = uni.Id);
        insert t;

        Account a = new Account(Name = 'MJR-CONC-DEGR', hed__School_Code__c = 'MJR-CONC-DEGR');
        insert a;

        hed__Course__c course = new hed__Course__c(hed__Course_ID__c = 'CO 333', hed__Account__c = a.Id, csuoee__Course_Code__c = 'CO 333');
        insert course;

        hed__Course_Offering__c offering = new hed__Course_Offering__c(hed__Term__c = t.Id, hed__Course__c = course.Id, Name = 'CO 333 100', hed__Section_ID__c = '100', lms_hed__LMS_Reference_Code__c = '2023SP-CO-333-100', csuoee__Campus_Code__c = 'MC', csuoee__Banner_CRN__c = '12345');
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
        Test.setMock(HttpCalloutMock.class, BaseTestUtil.getEventCalloutMock());
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
        Test.setMock(HttpCalloutMock.class, BaseTestUtil.getEventCalloutMock());

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

        Test.setMock(HttpCalloutMock.class, BaseTestUtil.getEventCalloutMock());
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

        Contact testContact = new Contact(LastName = 'Dupe');
        insert testContact;

        try {
            ce.hed__Contact__c = testContact.Id;
            update ce;

            System.assert(false);
        }catch (DmlException de) {
            System.assert(true);
        }
    }

    @IsTest
    private static void creditConfirmedEvent() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, BaseTestUtil.getEventCalloutMock());
        CreditConfirmedEvent.CreditConfirmedRequest t = new CreditConfirmedEvent.CreditConfirmedRequest();
        CreditConfirmedEvent.enrollStudent(new List<CreditConfirmedEvent.CreditConfirmedRequest>{new CreditConfirmedEvent.CreditConfirmedRequest('test-user', '2023SP-ACT-205-100')});

        Test.stopTest();
    }

    @IsTest
    private static void creditHandleStudentEnrollment() {
        //CombinedFunctions.EnrollmentRequest
        CombinedFunctions.EnrollmentRequest req = new CombinedFunctions.EnrollmentRequest();
        req.userId = 'TEST';
        req.offeringReference = '2023SP-CO-333-100';
        req.isDrop = false;
        req.statusInfo = 'RW';
        
        CombinedFunctions.EnrollmentRequest req2 = new CombinedFunctions.EnrollmentRequest();
        req2.userId = 'TEST';
        req2.offeringReference = '2023SP-CO-333-100';
        req2.isDrop = true;
        req2.statusInfo = 'AU';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, BaseTestUtil.getEventCalloutMock());
        List<hed__Course_Enrollment__c> enrollments = CreditHandleEnrollments.handleStudentEnrollment(new List<CombinedFunctions.EnrollmentRequest>{req, req2});

        System.assert(enrollments.get(0) != null);
        System.assert(enrollments.get(1) == null || enrollments.get(1).hed__Status__c == 'Withdrew');

        Test.stopTest();
    }

    @IsTest
    private static void createSend() {
        Test.setMock(HttpCalloutMock.class, BaseTestUtil.getEventCalloutMock());
        CreditSendRequest request = new CreditSendRequest();
        request.csuId = 'TESTCSUID';
        request.termCode = '202310';
        CreditRegistrationMessage.createSend(new List<CreditSendRequest>{request});

        try {
            csuoee__Marketing_Cloud_Journey_Event__c event = [select Id, csuoee__Key__c from csuoee__Marketing_Cloud_Journey_Event__c limit 1];
            System.assert(false, 'Event should not have been created.');
        } catch (QueryException qe) {
            // Shouldn't be anything
        }
        
        Contact c = [select Id from Contact LIMIT 1];
        hed__Course_Offering__c offering = [select Id from hed__Course_Offering__c LIMIT 1];

        RecordType studentType = [select Id from RecordType where DeveloperName = 'Student' limit 1];
        hed__Course_Enrollment__c e = new hed__Course_Enrollment__c(RecordTypeId = studentType.Id, hed__Contact__c = c.Id, hed__Course_Offering__c = offering.Id, csuoee__Banner_Enrollment_Reference__c = '202310-12345-12345678');
        insert e;

        CreditRegistrationMessage.createSend(new List<CreditSendRequest>{request});
        
        try {
            csuoee__Marketing_Cloud_Journey_Event__c event = [select Id, csuoee__Key__c from csuoee__Marketing_Cloud_Journey_Event__c limit 1];
            System.assert(false, 'Event should not have been created.');
        } catch (QueryException qe) {
            // Shouldn't be anything still! It's not verified.
        }

        e.hed__Verification_Status__c = 'Verified';
        update e;

        CreditRegistrationMessage.createSend(new List<CreditSendRequest>{request});

        csuoee__Marketing_Cloud_Journey_Event__c event = [select Id, csuoee__Key__c from csuoee__Marketing_Cloud_Journey_Event__c limit 1];
        System.assert(event != null, 'Could not find created event.');
    }
    
}