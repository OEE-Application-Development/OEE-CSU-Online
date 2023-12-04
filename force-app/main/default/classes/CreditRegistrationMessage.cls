@RestResource(urlMapping = '/credit/registration/message')
global class CreditRegistrationMessage {

    @HttpPost
    global static void createSend(List<String> csuIds) {
        // Get settings
        csuoee__Marketing_Cloud_Journey_Event_Settings__c settings = [select csuoee__Credit_Confirmation_EventType__c from csuoee__Marketing_Cloud_Journey_Event_Settings__c limit 1];

        // Generate Send Connections
        List<Contact> toNotify = [select Id, Name, (select hed__Course_Offering__c from hed__Student_Course_Enrollments__r) from Contact where csuoee__CSU_ID__c in :csuIds order by Name];
        List<csuoee__Marketing_Cloud_Journey_Event__c> events = new List<csuoee__Marketing_Cloud_Journey_Event__c>();
        for(Contact contact : toNotify) {
            String referenceList = '';
            for(hed__Course_Enrollment__c enrollment : contact.hed__Student_Course_Enrollments__r) {
                referenceList += enrollment.hed__Course_Offering__c;
            }

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