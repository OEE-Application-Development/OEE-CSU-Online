trigger CSUOEE_CreditMarketingJourneySend on hed__Course_Enrollment__c (after insert, after update) {
    String eventType = '', key = '';
    try {
        csuoee__Marketing_Cloud_Journey_Event_Settings__c settings = [select csuoee__Credit_Confirmation_Key__c, csuoee__Credit_Confirmation_EventType__c from csuoee__Marketing_Cloud_Journey_Event_Settings__c LIMIT 1];
        eventType = settings.csuoee__Credit_Confirmation_EventType__c;
        key = settings.csuoee__Credit_Confirmation_Key__c;
    } catch(QueryException qe) {

    }

    List<csuoee__Marketing_Cloud_Journey_Event__c> journeyEvents = new List<csuoee__Marketing_Cloud_Journey_Event__c>();
    List<hed__Course_Enrollment__c> patchNotificationSent = new List<hed__Course_Enrollment__c>();
    for (hed__Course_Enrollment__c enrollment : (List<hed__Course_Enrollment__c>) Trigger.new) {
        if(enrollment.csuoee__Student_Notified__c) continue;

        if(enrollment.hed__Course_Offering__r.csuoee__Campus_Code__c == 'MC') {
            journeyEvents.add(new csuoee__Marketing_Cloud_Journey_Event__c(
                csuoee__ContactWhoId__c = enrollment.hed__Contact__c,
                csuoee__Event__c = key,
                csuoee__Event_Type__c = eventType,
                csuoee__Key__c = key+'-'+enrollment.Id+'-Confirmation',
                csuoee__RelatedToId__c = enrollment.Id
            ));
            patchNotificationSent.add(new hed__Course_Enrollment__c(Id = enrollment.Id, csuoee__Student_Notified__c = true));
        }
    }

    if(!journeyEvents.isEmpty()) {
        insert journeyEvents;
    }
    if(!patchNotificationSent.isEmpty()) {
        update patchNotificationSent;
    }
}