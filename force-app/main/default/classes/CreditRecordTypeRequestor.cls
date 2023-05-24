global with sharing class CreditRecordTypeRequestor  {
    
    @InvocableMethod(Label='Get Credit Record Types' Description='Currently supports: "Term"')
    global static List<RecordType> getCreditRecordTypes(List<CreditRecordTypeRequest> requests) {
        List<RecordType> recordTypes = new List<RecordType>();
        for(CreditRecordTypeRequest request : requests) {
            try {
                switch on request.recordTypeName {
                    when 'Term' {
                        recordTypes.add(CreditHelpers.getCreditTermType());
                    }
                    when 'Educational Institution' {
                        recordTypes.add(CreditHelpers.getEducationInstitutionType());
                    }
                    when else {
                        recordTypes.add(null);
                    }
                }
            } catch(System.QueryException qe) {
                recordTypes.add(null);
            }
        }
        return recordTypes;
    }

    global class CreditRecordTypeRequest {
        @InvocableVariable(Required=true Description='e.g. Term for Credit Term RecordType')
        global String recordTypeName;

        public CreditRecordTypeRequest(){}
        public CreditRecordTypeRequest(String recordTypeName) {
            this.recordTypeName = recordTypeName;
        }
    }

}