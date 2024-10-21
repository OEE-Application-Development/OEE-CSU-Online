@RestResource(urlMapping = '/credit/lead/convert')
global with sharing class TryConvertCreditLead {
    
    private static final List<String> CREDIT_EMAIL_FIELDS = new List<String>{'hed__AlternateEmail__c', 'hed__UniversityEmail__c', 'hed__WorkEmail__c'};
    /**
     * Attempts convert of Contacts using University Email Fields.
     */
    @HttpPost
    global static void attemptConvert(List<Contact> contacts) {
        ConvertResult result = CombinedFunctions.attemptConvertByEmail(contacts, CREDIT_EMAIL_FIELDS);

        RestHelpers.setJsonResponse(result);
    }
    
}