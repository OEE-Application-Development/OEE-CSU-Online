@IsTest
private class CreditHelpers_TEST {

    @TestSetup
    static void setupCourseData(){
        csuoee__Marketing_Cloud_Journey_Event_Settings__c settings = new csuoee__Marketing_Cloud_Journey_Event_Settings__c(csuoee__Credit_Confirmation_EventType__c = 'fake-id', csuoee__Credit_Confirmation_Key__c = 'fake-key');
        insert settings;

        Contact c = new Contact(LastName = 'Test', csuoee__EID__c = 'TEST', csuoee__CSU_ID__c = 'TESTCSUID');
        insert c;

        Account fortCollinsCampus = new Account(Name = 'CSU Fort Collins', hed__School_Code__c = '126818');
        insert fortCollinsCampus;

        Account uni = new Account(Name = 'CSU');
        insert uni;

        hed__Term__c t = new hed__Term__c(Name = '2023SP', csuoee__ODS_Term_ID__c = '202310', hed__Start_Date__c = Date.today(), hed__End_Date__c = Date.today(), hed__Account__c = uni.Id, RecordTypeId = ([SELECT Id FROM RecordType WHERE SobjectType = 'hed__Term__c' AND DeveloperName = 'Credit' LIMIT 1]).Id);
        insert t;

        hed__Term__c altTerm = new hed__Term__c(Name = '2023SM', csuoee__ODS_Term_ID__c = '202360', hed__Account__c = uni.Id, RecordTypeId = ([SELECT Id FROM RecordType WHERE SobjectType = 'hed__Term__c' AND DeveloperName = 'Credit' LIMIT 1]).Id);
        insert altTerm;

        Account a = new Account(Name = 'MJR-CONC-DEGR', hed__School_Code__c = 'MJR-CONC-DEGR');
        insert a;

        hed__Course__c course = new hed__Course__c(hed__Course_ID__c = 'CO 333', hed__Account__c = a.Id, csuoee__Course_Code__c = 'CO 333', RecordTypeId = ([SELECT Id FROM RecordType WHERE SobjectType = 'hed__Course__c' AND DeveloperName = 'Credit' LIMIT 1]).Id);
        insert course;

        hed__Course_Offering__c offering = new hed__Course_Offering__c(hed__Term__c = t.Id, hed__Course__c = course.Id, Name = 'CO 333 100', hed__Section_ID__c = '100', lms_hed__LMS_Reference_Code__c = '2023SP-CO-333-100', csuoee__Campus_Code__c = 'MC', csuoee__Banner_CRN__c = '12345');
        insert offering;

        hed__Program_Enrollment__c pe = new hed__Program_Enrollment__c(csuoee__Enrollment_Reference__c = '2023SP-MJR-CONC-DEGR-TEST', hed__Contact__c = c.Id, hed__Account__c = a.Id, csuoee__Term__c = t.Id);
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

    @IsTest
    private static void testSearcher() {
        Test.startTest();
        List<hed__Course_Offering__c> available = (new AvailableCreditOfferingSearcher()).searchCreditOfferings();
        System.assert(available.isEmpty(), 'Should be empty.');

        Date today = Date.today();
        hed__Course_Offering__c offering = new hed__Course_Offering__c(hed__Term__c = ([SELECT Id FROM hed__Term__c LIMIT 1]).Id, hed__Course__c = ([SELECT Id FROM hed__Course__c LIMIT 1]).Id, Name = 'CO 333 110', hed__Section_ID__c = '110', lms_hed__LMS_Reference_Code__c = '2023SP-CO-333-110', csuoee__Campus_Code__c = 'MC', csuoee__Banner_CRN__c = '23456', csuoee__Registration_Start_Date__c = today.addDays(-1), csuoee__Registration_End_Date__c = today.addDays(1), hed__Capacity__c = 30, csuoee__Confirmed_Enrollments__c = 20);
        insert offering;

        available = (new AvailableCreditOfferingSearcher(new Map<String, Object>{})).searchCreditOfferings();
        System.assert(!available.isEmpty(), 'Should not be empty.');

        available = (new AvailableCreditOfferingSearcher(new List<String>{'Id', 'Name'}, new Map<String, Object>{'Name' => 'CO 333 110'})).searchCreditOfferings();
        System.assert(!available.isEmpty(), 'Should not be empty.');

        Test.stopTest();
    }

    @IsTest
    private static void slateApplicationTest() {
        Test.startTest();

        // Quick Return
        SlateResponse response = SlateApplications.create(new List<hed__Application__c>());
        System.assert(response.Success, 'Should not have failed: '+JSON.serialize(response));

        // Fail States
        response = SlateApplications.create(
            new List<hed__Application__c> {
                new hed__Application__c(
                    hed__Applicant__r = new Contact(csuoee__CSU_ID__c = '123456')
                )
            }
        );
        System.assert(!response.Success, 'Should have failed: '+JSON.serialize(response));

        response = SlateApplications.create(
            new List<hed__Application__c> {
                new hed__Application__c(
                    
                )
            }
        );
        System.assert(!response.Success, 'Should have failed: '+JSON.serialize(response));

        response = SlateApplications.create(
            new List<hed__Application__c> {
                new hed__Application__c(
                    csuoee__Slate_ID__c = 'S12345'
                )
            }
        );
        System.assert(!response.Success, 'Should have failed: '+JSON.serialize(response));

        response = SlateApplications.create(
            new List<hed__Application__c> {
                new hed__Application__c(
                    csuoee__Slate_ID__c = 'S12345',
                    hed__Applying_To__r = new Account(hed__School_Code__c = 'MJR-CONC-DEGR'),
                    csuoee__Slate_Email1__c = 'newstudent@gmail.com',
                    csuoee__Slate_Email2__c = 'newstudent@colostate.edu',
                    csuoee__Application_Reference__c = 'S12345-NULL'
                )
            }
        );
        System.assert(!response.Success, 'Should have failed: '+JSON.serialize(response));

        //And all the rest...
        Lead lead = new Lead(FirstName = 'New2', LastName = 'Student2', Email = 'alt@gmail.com', Company = 'CSU TEST');
        insert lead;

        Account peAcct = new Account(Name = 'New3 Student3 PE Account', hed__School_Code__c = 'learn.colostate.edu.12345');
        insert peAcct;
        Contact student2 = new Contact(AccountId = peAcct.Id, FirstName = 'New3', LastName = 'Student3', Email = 'new3.student3@gmail.com');
        insert student2;

        response = SlateApplications.create(
            new List<hed__Application__c> {
                new hed__Application__c(
                    csuoee__Slate_ID__c = 'S12345',
                    hed__Applying_To__r = new Account(hed__School_Code__c = 'MJR-CONC-DEGR'),
                    csuoee__Slate_Email1__c = 'newstudent@gmail.com',
                    csuoee__Slate_Email2__c = 'newstudent@colostate.edu',
                    hed__Application_JSON__c = '{"Name": "Student, New"}',
                    csuoee__Application_Reference__c = 'S12345-NULL'
                ),
                new hed__Application__c(
                    csuoee__Slate_ID__c = 'S123456',
                    hed__Applying_To__r = new Account(hed__School_Code__c = 'MJR-CONC-DEGR'),
                    csuoee__Slate_Email1__c = 'new2student2@gmail.com',
                    csuoee__Slate_Email2__c = 'alt@gmail.com',
                    hed__Application_JSON__c = '{"Name": "Student2, New2"}',
                    csuoee__Application_Reference__c = 'S123456-NULL'
                ),
                new hed__Application__c(
                    csuoee__Slate_ID__c = 'S1234567',
                    hed__Applying_To__r = new Account(hed__School_Code__c = 'MJR-CONC-DEGR'),
                    csuoee__Slate_Email1__c = 'new3.student3@gmail.com',
                    hed__Application_JSON__c = '{"Name": "Student3, New3"}',
                    csuoee__Application_Reference__c = 'S1234567-NULL'
                )
            }
        );
        System.assert(response.Success, 'Error: '+JSON.serialize(response));

        lead.hed__External_Id__c = 'wrongid';
        update lead;
        response = SlateApplications.create(
            new List<hed__Application__c> {
                new hed__Application__c(
                    csuoee__Slate_ID__c = 'S123456',
                    hed__Applying_To__r = new Account(hed__School_Code__c = 'MJR-CONC-DEGR'),
                    csuoee__Slate_Email1__c = 'new2student2@gmail.com',
                    csuoee__Slate_Email2__c = 'alt@gmail.com',
                    hed__Application_JSON__c = '{"Name": "Student2, New2"}',
                    hed__Term__r = new hed__Term__c(csuoee__ODS_Term_ID__c = '202310'),
                    csuoee__Application_Reference__c = 'S1234567-202310'
                ),
                new hed__Application__c(
                    csuoee__Slate_ID__c = 'S123456',
                    hed__Applying_To__r = new Account(hed__School_Code__c = 'MJR-CONC-DEGR'),
                    csuoee__Slate_Email1__c = 'new2student2@gmail.com',
                    csuoee__Slate_Email2__c = 'alt@gmail.com',
                    hed__Application_JSON__c = '{"Name": "Student2, New2"}',
                    hed__Term__r = new hed__Term__c(csuoee__ODS_Term_ID__c = '202310'),
                    csuoee__Application_Reference__c = 'S1234567-202310'
                )
            }
        );
        System.assert(!response.Success, 'Should have failed: '+JSON.serialize(response));

        response = SlateApplications.create(
            new List<hed__Application__c> {
                new hed__Application__c(
                    csuoee__Slate_ID__c = 'S999999',
                    hed__Applying_To__r = new Account(hed__School_Code__c = 'MJR-CONC-DEGR'),
                    csuoee__Slate_Email1__c = 'new5student5@gmail.com',
                    csuoee__Slate_Email2__c = 'alt@gmail.com',
                    hed__Application_JSON__c = '{"Name": "Shmo, Joe"}',
                    hed__Term__r = new hed__Term__c(csuoee__ODS_Term_ID__c = '202310'),
                    csuoee__Application_Reference__c = 'S999999-202310'
                ),
                new hed__Application__c(
                    csuoee__Slate_ID__c = 'S999999',
                    hed__Applying_To__r = new Account(hed__School_Code__c = 'MJR-CONC-DEGR'),
                    csuoee__Slate_Email1__c = 'new5student5@gmail.com',
                    csuoee__Slate_Email2__c = 'alt@gmail.com',
                    hed__Application_JSON__c = '{"Name": "Shmo, Joe"}',
                    hed__Term__r = new hed__Term__c(csuoee__ODS_Term_ID__c = '202360'),
                    csuoee__Application_Reference__c = 'S999999-202360'
                )
            }
        );
        System.assert(response.Success, 'Should have succeeded: '+JSON.serialize(response));
        
        response = SlateApplications.create(
            new List<hed__Application__c> {
                new hed__Application__c(
                    csuoee__Slate_ID__c = 'S123456',
                    hed__Applying_To__r = new Account(hed__School_Code__c = 'MJR-CONC-DEGR'),
                    csuoee__Slate_Email1__c = 'new2student2@gmail.com',
                    csuoee__Slate_Email2__c = 'alt@gmail.com',
                    hed__Application_JSON__c = '{"Name": "Student2, New2"}',
                    csuoee__Slate_Credits__c = 123468712643.12346123846
                )
            }
        );
        System.assert(!response.Success, 'Should have failed: '+JSON.serialize(response));

        Test.stopTest();
    }

    @IsTest
    private static void testProgramEnrollmentTriggers() {
        Test.startTest();
        hed__Program_Enrollment__c enrollment = [SELECT Id, hed__Start_Date__c, hed__End_Date__c FROM hed__Program_Enrollment__c WHERE csuoee__Enrollment_Reference__c = '2023SP-MJR-CONC-DEGR-TEST' LIMIT 1];

        System.assert(enrollment.hed__Start_Date__c != null, 'Date not automatically set on enrollment.');
        Test.stopTest();
    }
    
}