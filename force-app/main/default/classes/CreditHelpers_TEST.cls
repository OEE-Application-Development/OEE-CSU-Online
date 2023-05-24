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
    
}