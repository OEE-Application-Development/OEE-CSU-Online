global class SlateIntegrationBatch implements Database.Batchable<Object>, Database.AllowsCallouts, Schedulable {

    
    global void execute(SchedulableContext ctx){
        List<hed__Term__c> termList = new List<hed__Term__c>([SELECT Id, Name FROM hed__Term__c WHERE RecordType.Name = 'Credit']);


        SlateIntegrationBatch updateDonationsBatch = new SlateIntegrationBatch(termList);
        Database.executebatch(updateDonationsBatch, 200);
    }
    // Set Term lookup

    public List<hed__term__c> termIterable;

    public SlateIntegrationBatch(List<hed__term__c> termIterable) {
        this.termIterable = termIterable;
    }

    public static Id termHandler (String slateTermTxt, List<hed__Term__c> terms) {
        Id returnTermId;
        for (hed__Term__c trow: terms) {
            if(trow.Name == slateTermTxt) {
                returnTermId = trow.Id;
                return returnTermId;
            }
        }

        return returnTermId;
    }


    global Iterable<Object> start(Database.BatchableContext bc) {
        List<object> objList = new List<Object>();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Slate_Grad/manage/query/run?id=330b9299-5efa-452a-a9d3-e25c89add368&cmd=service&output=json&h=cd189a82-0b2c-4ee9-a52e-e384fd52d84d');
        req.setMethod('GET');
        req.setTimeout(120000);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        for(Row r : ((SlateWrapperClass)JSON.deserialize(res.getBody(), SlateWrapperClass.class)).row) {
            objList.add(r);
        }

        // Undergraduate

        HttpRequest req2 = new HttpRequest();
        req2.setEndpoint('callout:Slate_UG/manage/query/run?id=b85e0542-ae22-4953-9803-dade45a93f1d&cmd=service&output=json&h=610a2e83-2322-10d2-9150-830446fbb323');
        req2.setMethod('GET');
        req2.setTimeout(120000);
        Http http2 = new Http();
        HTTPResponse res2 = http2.send(req2);
        for(Row r : ((SlateWrapperClass)JSON.deserialize(res2.getBody(), SlateWrapperClass.class)).row) {
            objList.add(r);
        }

        // Handle List

        List<Slate_Staging_Record__c> listToDelete = [select id from Slate_Staging_Record__c];
        if(!listToDelete.isEmpty()) {
            delete listToDelete;
        }
        return objList;
    }

    global void execute(Database.BatchableContext bc, List<object> scope){
        List<Slate_Staging_Record__c> listToInsert = new List<Slate_Staging_Record__c>();
        for(Object o: scope){
            Row stagingResObj = (ROW)o;
            Slate_Staging_Record__c stagingObj = new Slate_Staging_Record__c();
            stagingObj.Slate_Id__c = stagingResObj.slateId;
            stagingObj.CSU_Id__c = !String.isBlank(stagingResObj.CSUID) ? stagingResObj.csuId : '';
            stagingObj.FirstName__c = stagingResObj.name.split(',').size() > 1 ? stagingResObj.name.split(',').get(1) : '';
            stagingObj.Name__c = stagingResObj.name.split(',').size() > 0 ? stagingResObj.name.split(',').get(0) : '';
            //stagingObj.Term__c = stagingResObj.term;
            //This modification makes the TERM record management more important... Without a program CREDIT term record the application term match won't work...
            if(!String.isBlank(stagingResObj.term)){
                String processedTerm = stagingResObj.term.replace(' Freshman','').replace(' Transfer','').replace(' Non-Degree','').replace(' Second Bachelor/Post-Bachelor','');
                stagingObj.Application_Term__c = termHandler(processedTerm,termIterable);
            }
            stagingObj.AppStatus__c = !String.isBlank(stagingResObj.appStatus) ? stagingResObj.appStatus : '';
            stagingObj.CurrentProgramCode__c = !String.isBlank(stagingResObj.currentProgramCode) ? stagingResObj.currentProgramCode : '';
            stagingObj.CurrentSiteCode__c = !String.isBlank(stagingResObj.currentSiteCode) ? stagingResObj.currentSiteCode : '';
            stagingObj.Decision__c = !String.isBlank(stagingResObj.decision) ? stagingResObj.decision : '';
            stagingObj.MissingChecklistItems__c = !String.isBlank(stagingResObj.missingChecklistItems) ? stagingResObj.missingChecklistItems : '';
            stagingObj.FulfilledChecklistItems__c = !String.isBlank(stagingResObj.fulfilledChecklistItems) ? stagingResObj.fulfilledChecklistItems : '';
            stagingObj.Email1__c = !String.isBlank(stagingResObj.email1) ? stagingResObj.email1 : '';
            stagingObj.Email2__c = !String.isBlank(stagingResObj.email2) ? stagingResObj.email2 : '';
            stagingObj.Email3__c = !String.isBlank(stagingResObj.email3) ? stagingResObj.email3 : '';
            stagingObj.DevicePrimaryPhone1__c = !String.isBlank(stagingResObj.devicePrimaryPhone1) ? stagingResObj.devicePrimaryPhone1 : '';
            stagingObj.OfficialGPA__c = !String.isBlank(stagingResObj.OfficialGPA) ? stagingResObj.officialGPA : '';
            Date dT;
            if(!String.isBlank(stagingResObj.createdDate)) {
                List<String> strDT = stagingResObj.createdDate.split('T');
                dt = Date.ValueOf(strDT[0]);
            }
            stagingObj.CreatedDate__c = dt != null ?  dt : null;
            listToInsert.add(stagingObj);
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