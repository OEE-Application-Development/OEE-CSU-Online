@isTest
global class SlateIntegrationBatchTest {


    @TestSetup
    private static void makeData(){
        hed__term__c t = new hed__term__c();
        t.Name = 'Summer 2022';
        insert t;
    }
    @isTest global static void testMethod1() {
        Test.setMock(HttpCalloutMock.class, new SlateIntegrationMockImpl());
        
        Test.startTest();
        SchedulableContext sc = null;
        List<hed__Term__c> testTerms = new List<hed__Term__c>([SELECT Id, Name FROM hed__Term__c WHERE RecordType.Name = 'Credit']);
        SlateIntegrationBatch testsche = new SlateIntegrationBatch(testTerms);
        testsche.execute(sc); 
        Test.stopTest();
        
    }

    global class SlateIntegrationMockImpl implements HttpCalloutMock{
        global HttpResponse respond(HTTPRequest req){
          HttpResponse res = new HttpResponse();
          res.setStatus('OK');
          res.setStatusCode(200);
          res.setBody('{"row": [{"SlateID": "123456", "Name": "Kyle Winterrowd", "Term":"Summer 2022"}]}');
          return res;
        }
    }
}