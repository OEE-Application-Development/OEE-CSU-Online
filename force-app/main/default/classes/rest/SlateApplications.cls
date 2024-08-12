@RestResource(urlMapping = '/credit/application/slate')
global with sharing class SlateApplications {

    @HttpPost
    global static SlateResponse create(List<hed__Application__c> applications) {
        Map<Id, List<String>> emailMap = new Map<Id, List<String>>();
        for(hed__Application__c application : applications) {
            if(application.hed__Applicant__r.csuoee__CSU_ID__c != null || application.hed__Applicant__c != null) {
                return new SlateResponse(false, 'hed__Applicant__c or hed__Applicant__r.csuoee__CSU_ID__c in input - just use the bulk ingest endpoint for that.');
            }

            List<String> emailList = new List<String>();
            emailList.add(application.csuoee__Slate_Email1__c);
            if(application.csuoee__Slate_Email2__c != null && application.csuoee__Slate_Email2__c != '') emailList.add(application.csuoee__Slate_Email2__c);
            if(application.csuoee__Slate_Email3__c != null && application.csuoee__Slate_Email3__c != '') emailList.add(application.csuoee__Slate_Email3__c);
            emailMap.put(application.Id, emailList);
        }

        // Search for Contact / Lead.
        return new SlateResponse(true, 'Slate Applications created.');
    }
    
}