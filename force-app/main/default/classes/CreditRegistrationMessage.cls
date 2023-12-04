@RestResource(urlMapping = '/credit/registration/message')
global class CreditRegistrationMessage {

    @HttpPost
    global static void createSend(List<CreditSendRequest> requests) {
        // Get settings
        csuoee__Marketing_Cloud_Journey_Event_Settings__c settings = [select csuoee__Credit_Confirmation_EventType__c from csuoee__Marketing_Cloud_Journey_Event_Settings__c limit 1];
        
        List<String> csuIds = new List<String>();
        Map<String, String> requestMap = new Map<String, String>();
        for(CreditSendRequest request : requests) {
            csuIds.add(request.csuId);
            requestMap.put(request.csuId, request.termCode);
        }

        // Generate Send Connections
        List<Contact> toNotify = [select Id, Name, csuoee__CSU_ID__c, (select hed__Course_Offering__c, csuoee__Banner_Enrollment_Reference__c from hed__Student_Course_Enrollments__r) from Contact where csuoee__CSU_ID__c in :csuIds order by Name];
        List<csuoee__Marketing_Cloud_Journey_Event__c> events = new List<csuoee__Marketing_Cloud_Journey_Event__c>();
        for(Contact contact : toNotify) {
            String termCode = requestMap.get(contact.csuoee__CSU_ID__c);
            String referenceList = '';
            
            for(hed__Course_Enrollment__c enrollment : contact.hed__Student_Course_Enrollments__r) {
                if(enrollment.csuoee__Banner_Enrollment_Reference__c.startsWith(termCode)) {
                    referenceList += enrollment.hed__Course_Offering__c;
                }
            }

            if(referenceList == '') continue;

            events.add(new csuoee__Marketing_Cloud_Journey_Event__c(
                csuoee__ContactWhoId__c = contact.Id,
                csuoee__Event__c = settings.csuoee__Credit_Confirmation_EventType__c,
                csuoee__Event_Type__c = settings.csuoee__Credit_Confirmation_EventType__c,
                csuoee__Key__c = settings.csuoee__Credit_Confirmation_EventType__c+'-'+String.valueOf(referenceList.hashCode())
            ));
        }

        insert events;
    }
    
}