@RestResource(urlMapping = '/credit/application/slate')
global with sharing class SlateApplications {

    //TODO: Tell the slate team to allow us to pass IDs so this entire function is no longer required.
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
            if(application.csuoee__Application_Reference__c == null) {
                return new SlateResponse(false, 'All applications need a unique application reference.');
            }

            // Email searches
            List<String> emailList = new List<String>();
            emailList.add(application.csuoee__Slate_Email1__c);
            if(application.csuoee__Slate_Email2__c != null && application.csuoee__Slate_Email2__c != '') emailList.add(application.csuoee__Slate_Email2__c);
            if(application.csuoee__Slate_Email3__c != null && application.csuoee__Slate_Email3__c != '') emailList.add(application.csuoee__Slate_Email3__c);
            emailMap.put('S'+application.csuoee__Slate_ID__c, emailList);

            // Application map
            slateIdAppMap.put('S'+application.csuoee__Slate_ID__c, application);
        }

        // Search for Contacts
        ContactEmailMatcher contactMatcher = new ContactEmailMatcher(emailMap, new List<String>{'hed__UniversityEmail__c', 'hed__WorkEmail__c', 'hed__AlternateEmail__c'}, new List<String>{'AccountId'});
        Map<String, Contact> contactResultMap = contactMatcher.match();

        // Start with Leads
        List<Account> slateAccounts = new List<Account>();
        List<Contact> slateContacts = new List<Contact>();
        List<Account> slateMapping = new List<Account>();

        // Pick up & apply any contacts
        for(String slateId : contactResultMap.keySet()) {
            Contact contact = contactResultMap.get(slateId);

            slateIdAppMap.get(slateId).hed__Applicant__c = contact.Id;
        }

        Map<String, Contact> slateIdDeDupe = new Map<String, Contact>();
        
        // What's left? Who do we have NO record of?
        // Detect Previously created accounts
        for(Contact previous : [SELECT Id, csuoee__Front_Door_ID__c, Account.hed__School_Code__c FROM Contact WHERE Account.hed__School_Code__c IN :slateIdAppMap.keyset()]) {
            slateIdDeDupe.put(previous.Account.hed__School_Code__c, previous);
        }

        for(hed__Application__c application : applications) {
            if(application.hed__Applicant__c == null) {
                if(application.hed__Application_JSON__c == null) return new SlateResponse(false, 'Slate ID: '+application.csuoee__Slate_ID__c+' does not have any JSON to describe a student, and no student was found in Salesforce.');
                
                if(!slateIdDeDupe.containsKey('S'+application.csuoee__Slate_ID__c)) {
                    SlateApplication jsonApplication = (SlateApplication)JSON.deserialize(application.hed__Application_JSON__c, SlateApplication.class);
                    String[] nameSplit = jsonApplication.Name.split(',');
                    Account slateApplication = new Account(RecordTypeId = CreditHelpers.getSlateApplicationRecordType().Id, Name = (nameSplit[0] + ' Slate Application'), Parent = new Account(hed__School_Code__c = '126818'), hed__School_Code__c = 'S'+application.csuoee__Slate_ID__c);
                    slateAccounts.add(slateApplication);
                    String frontDoorId = System.UUID.randomUUID().toString();
                    Contact student = new Contact(
                        csuoee__Front_Door_ID__c = frontDoorId, 
                        FirstName = (nameSplit.size()>1)?nameSplit[1]:'', 
                        LastName = nameSplit[0], 
                        Account = new Account(hed__School_Code__c = 'S'+application.csuoee__Slate_ID__c), 
                        Email = application.csuoee__Slate_Email1__c,
                        csuoee__CSU_ID__c = jsonApplication.CSUID,
                        csuoee__Last_Updated_Via__c = 'SlateApplicationImport'
                    );
                    slateContacts.add(student);

                    slateMapping.add(new Account(hed__School_Code__c = 'S'+application.csuoee__Slate_ID__c, hed__Primary_Contact__r = new Contact(csuoee__Front_Door_ID__c = frontDoorId)));
    
                    application.hed__Applicant__r = new Contact(csuoee__Front_Door_ID__c = frontDoorId);
                    slateIdDeDupe.put('S'+application.csuoee__Slate_ID__c, student);
                } else {
                    application.hed__Applicant__r = new Contact(csuoee__Front_Door_ID__c = slateIdDeDupe.get('S'+application.csuoee__Slate_ID__c).csuoee__Front_Door_ID__c);
                }
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

        try {
            upsert applications csuoee__Application_Reference__c;
        } catch(DmlException e) {
            return new SlateResponse(false, e.getMessage());
        }

        return new SlateResponse(true, 'Slate Applications created.');
    }
    
}