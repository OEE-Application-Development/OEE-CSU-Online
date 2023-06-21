@isTest
public class SlateIntegrationBatchTest {


    @TestSetup
    private static void makeData(){
        Id academicProgramId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Academic_Program').getRecordTypeId();
        Id cTermId = Schema.SObjectType.hed__Term__c.getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();


        Account a = new Account(
            Name = 'CSU'
        );
        insert a;

        Account p = new Account(
            Name = 'CSU Program A',
            hed__school_code__c = 'TEST-PROGRAM-A',
            RecordTypeId = academicProgramId
        );

        insert p;

        Account ptwo = new Account(
            Name = 'CSU Program B',
            hed__school_code__c = 'TEST-PROGRAM-B',
            RecordTypeId = academicProgramId
        );

        insert ptwo;


        hed__term__c t = new hed__term__c(
            Name = 'Summer 2022',
            hed__Account__c = a.id,
            RecordTypeId = cTermId
        );

        insert t;


    }
    @isTest private static void testMethod1() {
        Test.setMock(HttpCalloutMock.class, new SlateIntegrationMockImpl());
        
        Test.startTest();
        SchedulableContext sc = null;
        List<hed__Term__c> testTerms = new List<hed__Term__c>([SELECT Id, Name FROM hed__Term__c WHERE RecordType.Name = 'Credit']);
        List<Account> testAccts = new List<Account>([SELECT Id, hed__School_Code__c FROM Account WHERE RecordType.Name = 'Academic Program']);
        SlateIntegrationBatch testsche = new SlateIntegrationBatch(testTerms,testAccts);
        testsche.execute(sc); 
        Test.stopTest();

        List<AsyncApexJob> jobsApexBatch = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'BatchApex'];
        System.assertEquals(1, jobsApexBatch.size(), 'Batch job should have been scheduled');        
    }

    @isTest private static void testMethod2() {
        String termSTR = 'Summer 2022 Freshman';
        String termSTRF = 'Summer 2022 Freshie';
        String fN = 'Firster First,Namer Name';

        Test.startTest();
        String testedVal = SlateIntegrationBatch.undergradHandler(termSTR);
        String testedValF = SlateIntegrationBatch.undergradHandler(termSTRF);

        List<Account> lAccount = new List<Account>([SELECT Id, hed__School_Code__c FROM Account WHERE RecordType.Name = 'Academic Program']);
        Id acctTest;

        acctTest = SlateIntegrationBatch.acadAcctHandler('TEST-PROGRAM-B',lAccount);

        system.assert(acctTest!=null,'Account ID not Assigned');
        system.assertEquals(testedVal,'Freshman','TRUE case error');
        system.assertEquals(testedValF,'','FALSE case error');
        Test.stopTest();
    }

    public class SlateIntegrationMockImpl implements HttpCalloutMock{
        public HttpResponse respond(HTTPRequest req){
          HttpResponse res = new HttpResponse();
          res.setStatus('OK');
          res.setStatusCode(200);
          res.setBody('{"row": [{"SlateID": "123456", "Name": "Kyle Winterrowd", "Term":"Summer 2022","currentProgramCode":"TEST-PROGRAM-A"}]}');
          return res;
        }
    }
}