@RestResource(urlMapping = '/credit/application/slate')
global with sharing class SlateApplications {

    @HttpPost
    global static SlateResponse create(List<hed__Application__c> applications) {
        if(applications.isEmpty()) return new SlateResponse(true, 'No Applications submitted.');

        Map<String, List<String>> emailMap = new Map<String, List<String>>();
        Map<String, hed__Application__c> slateIdAppMap = new Map<String, hed__Application__c>();
        for(hed__Application__c application : applications) {
            if(application.hed__Applicant__r.csuoee__CSU_ID__c != null || application.hed__Applicant__c != null) {
                return new SlateResponse(false, 'hed__Applicant__c or hed__Applicant__r.csuoee__CSU_ID__c in input - just use the bulk ingest endpoint for that.');
            }
            if(application.csuoee__Slate_ID__c == null) {
                return new SlateResponse(false, 'Slate ID not set!');
            }

            // Email searches
            List<String> emailList = new List<String>();
            emailList.add(application.csuoee__Slate_Email1__c);
            if(application.csuoee__Slate_Email2__c != null && application.csuoee__Slate_Email2__c != '') emailList.add(application.csuoee__Slate_Email2__c);
            if(application.csuoee__Slate_Email3__c != null && application.csuoee__Slate_Email3__c != '') emailList.add(application.csuoee__Slate_Email3__c);
            emailMap.put(application.csuoee__Slate_ID__c, emailList);

            // Application map
            slateIdAppMap.put(application.csuoee__Slate_ID__c, application);
        }

        // Search for Contacts
        ContactEmailMatcher contactMatcher = new ContactEmailMatcher(emailMap, new List<String>{'hed__UniversityEmail__c', 'hed__WorkEmail__c', 'hed__AlternateEmail__c'}, new List<String>{'AccountId'});
        Map<String, Contact> contactResultMap = contactMatcher.match();
        LeadEmailMatcher leadMatcher = new LeadEmailMatcher(emailMap, new List<String>(), new List<String>{'hed__External_Id__c', 'FirstName', 'LastName'});
        Map<String, Lead> leadResultMap = leadMatcher.match();

        // Start with Leads
        List<Lead> slateIdUpdate = new List<Lead>();
        List<Account> slateAccounts = new List<Account>();
        List<Contact> slateContacts = new List<Contact>();
        List<Account> slateMapping = new List<Account>();
        Map<String, String> uuidMapping = new Map<String, String>();
        for(String slateId : leadResultMap.keySet()) {
            Lead lead = leadResultMap.get(slateId);
            Contact contact = contactResultMap.remove(slateId);

            if(lead.hed__External_Id__c == null) {
                lead.hed__External_Id__c = slateId;
                slateIdUpdate.add(lead);
            } else if(lead.hed__External_Id__c != slateId) {
                return new SlateResponse(false, 'Lead '+lead.Id+' already has a separate SlateId in hed__External_Id__c.');
            }

            if(contact == null) {
                String uuid = generateContact(slateAccounts, slateContacts, slateMapping, slateId, lead.FirstName, lead.LastName);
                uuidMapping.put(slateId, uuid);
            }
        }

        if(!slateIdUpdate.isEmpty()) {
            update slateIdUpdate;
        }

        // Pick up & apply any contacts
        for(String slateId : contactResultMap.keySet()) {
            Contact contact = contactResultMap.get(slateId);

            slateIdAppMap.get(slateId).hed__Applicant__c = contact.Id;
        }

        // What's left? Who do we have NO record of?
        for(hed__Application__c application : applications) {
            if(application.hed__Applicant__c == null) {
                String frontDoorId = uuidMapping.get(application.csuoee__Slate_ID__c);

                if(frontDoorId == null) {
                    if(application.hed__Application_JSON__c == null) return new SlateResponse(false, 'Slate ID: '+application.csuoee__Slate_ID__c+' does not have any JSON to describe a student, and no student was found in Salesforce.');
                    SlateApplication jsonApplication = (SlateApplication)JSON.deserialize(application.hed__Application_JSON__c, SlateApplication.class);
                    String[] nameSplit = jsonApplication.Name.split(',');
                    frontDoorId = generateContact(slateAccounts, slateContacts, slateMapping, application.csuoee__Slate_ID__c, (nameSplit.size()>1)?nameSplit[1]:'', nameSplit[0]);
                    uuidMapping.put(application.csuoee__Slate_ID__c, frontDoorId);
                }
                application.hed__Applicant__r = new Contact(csuoee__Front_Door_ID__c = frontDoorId);
            }
        }

        if(!slateAccounts.isEmpty()) {
            try {
                // Batch insert Slate Applications
                insert slateAccounts;
                insert slateContacts;
    
                upsert slateMapping hed__School_Code__c;
            } catch(DmlException e) {
                return new SlateResponse(false, e.getMessage());
            }
        }

        upsert applications csuoee__Slate_ID__c;

        return new SlateResponse(true, 'Slate Applications created.');
    }

    private static String generateContact(List<Account> slateAccounts, List<Contact> slateContacts, List<Account> slateMapping, String slateId, String firstName, String lastName) {
        Account slateApplication = new Account(RecordTypeId = CreditHelpers.getSlateApplicationRecordType().Id, Name = (lastName + ' Slate Application'), Parent = new Account(hed__School_Code__c = '126818'), hed__School_Code__c = slateId);
        slateAccounts.add(slateApplication);
        String uuid = System.UUID.randomUUID().toString();
        Contact student = new Contact(csuoee__Front_Door_ID__c = uuid, FirstName = firstName, LastName = lastName, Account = new Account(hed__School_Code__c = slateId));
        slateContacts.add(student);

        slateMapping.add(new Account(hed__School_Code__c = slateId, hed__Primary_Contact__r = new Contact(csuoee__Front_Door_ID__c = uuid)));
        return uuid;
    }
    
}