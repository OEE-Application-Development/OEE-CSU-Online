global class SlateIntegrationBatch implements Database.Batchable<Object>, Database.AllowsCallouts, Schedulable {
    global void execute(SchedulableContext ctx){
        SlateIntegrationBatch updateDonationsBatch = new SlateIntegrationBatch();
        Database.executebatch(updateDonationsBatch, 200);
    }
    global Iterable<Object> start(Database.BatchableContext bc) {
        List<object> objList = new List<Object>();
        List<String> listRows = new List<String>();
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
            stagingObj.Slate_Id__c = stagingResObj.SlateID;
            stagingObj.CSU_Id__c = !String.isBlank(stagingResObj.CSUID) ? stagingResObj.CSUID : '';
            stagingObj.FirstName__c = stagingResObj.Name.split(',').size() > 1 ? stagingResObj.Name.split(',').get(1) : '';
            stagingObj.Name__c = stagingResObj.Name.split(',').size() > 0 ? stagingResObj.Name.split(',').get(0) : '';
            stagingObj.Term__c = stagingResObj.Term;
            stagingObj.AppStatus__c = !String.isBlank(stagingResObj.AppStatus) ? stagingResObj.AppStatus : '';
            stagingObj.CurrentProgramCode__c = !String.isBlank(stagingResObj.CurrentProgramCode) ? stagingResObj.CurrentProgramCode : '';
            stagingObj.CurrentSiteCode__c = !String.isBlank(stagingResObj.CurrentSiteCode) ? stagingResObj.CurrentSiteCode : '';
            stagingObj.Decision__c = !String.isBlank(stagingResObj.Decision) ? stagingResObj.Decision : '';
            stagingObj.MissingChecklistItems__c = !String.isBlank(stagingResObj.MissingChecklistItems) ? stagingResObj.MissingChecklistItems : '';
            stagingObj.FulfilledChecklistItems__c = !String.isBlank(stagingResObj.FulfilledChecklistItems) ? stagingResObj.FulfilledChecklistItems : '';
            stagingObj.Email1__c = !String.isBlank(stagingResObj.Email1) ? stagingResObj.Email1 : '';
            stagingObj.Email2__c = !String.isBlank(stagingResObj.Email2) ? stagingResObj.Email2 : '';
            stagingObj.Email3__c = !String.isBlank(stagingResObj.Email3) ? stagingResObj.Email3 : '';
            stagingObj.DevicePrimaryPhone1__c = !String.isBlank(stagingResObj.DevicePrimaryPhone1) ? stagingResObj.DevicePrimaryPhone1 : '';
            stagingObj.OfficialGPA__c = !String.isBlank(stagingResObj.OfficialGPA) ? stagingResObj.OfficialGPA : '';
            Date dT;
            if(!String.isBlank(stagingResObj.CreatedDate)) {
                List<String> strDT = stagingResObj.CreatedDate.split('T');
                dt = Date.ValueOf(strDT[0]);
            }
            stagingObj.CreatedDate__c = dt != null ?  dt : null;
            listToInsert.add(stagingObj);
        }
        insert listToInsert;
    }  

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
    
    Public Class SlateWrapperClass {
        Public List<Row> row;
    }
    
    public class Row {
        public String SlateID;
        public String CSUID;
        public String Name;
        public String Term;
        public String AppStatus;
        public String CurrentProgram;
        public String CurrentProgramCode;
        public String CurrentSiteCode;
        public String Decision;
        public String MissingChecklistItems;
        public String FulfilledChecklistItems;
        public String Email1;
        public String Email2;
        public String Email3;
        public String DevicePrimaryPhone1;
        public String Credits;
        public String OfficialGPA;
        public String CreatedDate;
    }    
}