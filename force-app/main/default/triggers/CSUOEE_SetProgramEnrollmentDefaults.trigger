trigger CSUOEE_SetProgramEnrollmentDefaults on hed__Program_Enrollment__c (before insert) {
    Map<String, Id> refMap = new Map<String, Id>();
    for(hed__Program_Enrollment__c enrollment : (List<hed__Program_Enrollment__c>) Trigger.new) {
        if(enrollment.csuoee__Enrollment_Reference__c == null) continue; // Skip if no reference

        //TermReference-Enrollment-EID
        String[] refSplit = enrollment.csuoee__Enrollment_Reference__c.split('-');
        if(enrollment.csuoee__Term__c == null) {
            String termRef = refSplit[0];
            if(!refMap.containsKey(termRef)) {
                try {
                    hed__Term__c term = [select Id from hed__Term__c where lms_hed__LMS_Reference_Code__c = :termRef LIMIT 1];
                    refMap.put(termRef, term.Id);
                } catch(Exception e) {
                    refMap.put(termRef, null);
                }
            }

            enrollment.csuoee__Term__c = refMap.get(termRef);
        }

        if(enrollment.hed__Account__c == null) {
            String programRef = refSplit[1];
            for(Integer refIdx = 2; refIdx < refSplit.size()-1;refIdx++) {
                programRef+='-'+refSplit[refIdx];
            }
            if(!refMap.containsKey(programRef)) {
                try {
                    Account program = [select Id from Account where hed__School_Code__c = :programRef LIMIT 1];
                    refMap.put(programRef, program.Id);
                } catch(Exception e) {
                    refMap.put(programRef, null);
                }
            }

            enrollment.hed__Account__c = refMap.get(programRef);
        }

        if(enrollment.hed__Contact__c == null) {
            String eid = refSplit[refSplit.size()-1];
            if(!refMap.containsKey(eid)) {
                try {
                    Contact c = [select Id from Contact where csuoee__EID__c = :eid LIMIT 1];
                    refMap.put(eid, c.Id);
                } catch(Exception e) {
                    refMap.put(eid, null);
                }
            }

            enrollment.hed__Contact__c = refMap.get(eid);
        }
    }
}