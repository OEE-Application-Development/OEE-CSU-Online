global class SlateIntegrationBatch implements Database.Batchable<Object>, Database.AllowsCallouts, Schedulable {

    
    global void execute(SchedulableContext ctx){
        List<hed__Term__c> termList = new List<hed__Term__c>([SELECT Id, Name FROM hed__Term__c WHERE RecordType.Name = 'Credit']);

        //Lookup for accounts to generate a Program List, using Schema to ensure the correct record Type Id
        Id academicProgramId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Academic_Program').getRecordTypeId();

        List<Account> acadList = new List<Account>([SELECT Id, hed__School_Code__c FROM Account WHERE RecordTypeId =: academicProgramId AND hed__School_Code__c != '']);

        SlateIntegrationBatch updateDonationsBatch = new SlateIntegrationBatch(termList,acadList);
        Database.executebatch(updateDonationsBatch, 200);
    }
    // Set Term lookup

    public List<hed__term__c> termIterable;

    public List<Account> accountIterable;

    public SlateIntegrationBatch(List<hed__term__c> termIterableLIST, List<Account> accountIterableLIST) {
        this.termIterable = termIterableLIST;
        this.accountIterable = accountIterableLIST;
    }

    @TestVisible private static Id termHandler (String slateTermTxt, List<hed__Term__c> terms) {
        Id returnTermId;
        String processedTerm = slateTermTxt.replace(' Freshman','').replace(' Transfer','').replace(' Non-Degree','').replace(' Second Bachelor/Post-Bachelor','');
        for (hed__Term__c trow: terms) {
            if(trow.Name == processedTerm) {
                returnTermId = trow.Id;
                return returnTermId;
            }
        }

        return returnTermId;
    }

    @TestVisible private static String undergradHandler(String slateTermStr) {
        String undergradValue;
        if (slateTermStr.contains('Freshman')) {
            undergradValue = 'Freshman';
        } else if (slateTermStr.contains('Transfer')) {
            undergradValue = 'Transfer';

        } else if (slateTermStr.contains('Second Bachelor')) {
            undergradValue = 'Second Bachelor/Post-Bachelor';

        } else if (slateTermStr.contains('Non-Degree')) {
            undergradValue = 'Non-Degree';

        } else {
            undergradValue = '';
        }

        return undergradValue;
    }

    @TestVisible private static Id acadAcctHandler (String programCode, List<Account> acadAcctList) {
        Id acctId;

        String regEXP = '-[A-Za-z]+-';
        String programCodeSF = '';

        for (Account actRow: acadAcctList) {
            programCodeSF = actRow.hed__School_Code__c;

            if(programCodeSF == programCode) {
                acctId = actRow.Id;
                break;
            } else if (programCodeSF?.replaceFirst(regEXP,'-') == programCode.replaceFirst(regEXP,'-')){
                acctId = actRow.Id;
                break;
            }
        }

        return acctId;
    }

    //Simplify the setup of a SSR, set to instance vs. static so this.variableName can be accessed
    @TestVisible private Slate_Staging_Record__c recordHandler(ROW rowItem, List<Account> acctLst, List<hed__Term__c> termLst) {
        Slate_Staging_Record__c stagingObj = new Slate_Staging_Record__c();
        stagingObj.Slate_Id__c = rowItem.slateId;
        stagingObj.CSU_Id__c = rowItem.CSUID;

        if(rowItem.name.split(',').size() > 1) {
            stagingObj.FirstName__c = rowItem.name.split(',').get(1);
            stagingObj.Name__c = rowItem.name.split(',').get(0);
        } else {
            stagingObj.Name__c = rowItem.name;
        }
        

        //This modification makes the TERM record management more important... Without a program CREDIT term record the application term match won't work...
        if(!String.isBlank(rowItem.term)){
            stagingObj.Application_Term__c = termHandler(rowItem.term,termIterable);
            stagingObj.Undergrad_Status__c = undergradHandler(rowItem.term);
        }

        stagingObj.AppStatus__c = rowItem.appStatus;
        stagingObj.Decision__c = rowItem.decision;

        if(rowItem.appStatus == 'Awaiting Submission'){
            stagingObj.Awaiting_Submission__c = true;
        }

        //Modification to set program
        if(!String.isBlank(rowItem.currentProgramCode)){
            Id accountId = acadAcctHandler(rowItem.currentProgramCode,accountIterable);
            
            if(accountId != null) {
                stagingObj.Application_Program__c = accountId;
                stagingObj.CurrentProgramCode__c = rowItem.currentProgramCode;
            } else {
                stagingObj.CurrentProgramCode__c = rowItem.currentProgramCode;
                stagingObj.CurrentSiteCode__c = rowItem.currentSiteCode;
            }

        }
        
        stagingObj.MissingChecklistItems__c = rowItem.missingChecklistItems;
        stagingObj.FulfilledChecklistItems__c = rowItem.fulfilledChecklistItems;
        stagingObj.Email1__c = !String.isBlank(rowItem.email1) ? rowItem.email1 : '';
        stagingObj.Email2__c = !String.isBlank(rowItem.email2) ? rowItem.email2 : '';
        stagingObj.Email3__c = !String.isBlank(rowItem.email3) ? rowItem.email3 : '';
        stagingObj.DevicePrimaryPhone1__c = rowItem.devicePrimaryPhone1;
        stagingObj.OfficialGPA__c = rowItem.OfficialGPA;
        Date dT;
        if(!String.isBlank(rowItem.createdDate)) {
            List<String> strDT = rowItem.createdDate.split('T');
            dt = Date.ValueOf(strDT[0]);
        }
        stagingObj.CreatedDate__c = dt != null ?  dt : null;

        return stagingObj;
    }

    //Actual Schedule Components

    global Iterable<Object> start(Database.BatchableContext bc) {
        List<object> objList = new List<Object>();
        
        HttpRequest reqGr = new HttpRequest();
        reqGr.setEndpoint('callout:Slate_Grad/manage/query/run?id=330b9299-5efa-452a-a9d3-e25c89add368&cmd=service&output=json&h=cd189a82-0b2c-4ee9-a52e-e384fd52d84d');
        reqGr.setMethod('GET');
        reqGr.setTimeout(120000);
        Http httpGR = new Http();
        HTTPResponse resGR = httpGR.send(reqGr);
        for(Row r : ((SlateWrapperClass)JSON.deserialize(resGR.getBody(), SlateWrapperClass.class)).row) {
            objList.add(r);
        }

        // Undergraduate

        HttpRequest reqUg = new HttpRequest();
        reqUg.setEndpoint('callout:Slate_UG/manage/query/run?id=b85e0542-ae22-4953-9803-dade45a93f1d&cmd=service&output=json&h=610a2e83-2322-10d2-9150-830446fbb323');
        reqUg.setMethod('GET');
        reqUg.setTimeout(120000);
        Http httpUG = new Http();
        HTTPResponse resUG = httpUG.send(reqUg);
        for(Row r : ((SlateWrapperClass)JSON.deserialize(resUG.getBody(), SlateWrapperClass.class)).row) {
            objList.add(r);
        }

        // Handle List Deletion to reset SSR

        List<Slate_Staging_Record__c> listToDelete = [select id from Slate_Staging_Record__c];
        if(!listToDelete.isEmpty()) {
            delete listToDelete;
        }
        return objList;
    }

    //Actual execute

    global void execute(Database.BatchableContext bc, List<object> scope){
        List<Slate_Staging_Record__c> listToInsert = new List<Slate_Staging_Record__c>();
        for(Object o: scope){
            Row stagingResObj = (ROW)o;
            Slate_Staging_Record__c stageObjToAdd = new Slate_Staging_Record__c();
            stageObjToAdd = recordHandler(stagingResObj,accountIterable,termIterable);
            listToInsert.add(stageObjToAdd);
        }
        try {
            insert listToInsert;
        } catch(Exception e) {
            System.debug(e);
        }
    }  

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
    
    public Class SlateWrapperClass {
        public List<Row> row;
    }
    
    // Row contains all fields from Slate, match columns returned by URL
    public Class Row {
        public String slateId;
        public String csuId;
        public String name;
        public String term;
        public String appStatus;
        public String currentProgram;
        public String currentProgramCode;
        public String currentSiteCode;
        public String decision;
        public String missingChecklistItems;
        public String fulfilledChecklistItems;
        public String email1;
        public String email2;
        public String email3;
        public String devicePrimaryPhone1;
        public String credits;
        public String officialGPA;
        public String createdDate;
    }

}