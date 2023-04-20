@isTest
global class SlateIntegrationBatchTest {
    @isTest global static void testMethod1() {
        Test.setMock(HttpCalloutMock.class, new SlateIntegrationMockImpl());
        
        Test.startTest();
        SchedulableContext sc = null;
        SlateIntegrationBatch testsche = new SlateIntegrationBatch();
        testsche.execute(sc); 
        Test.stopTest();
        
    }

    global class SlateIntegrationMockImpl implements HttpCalloutMock{
        global HttpResponse respond(HTTPRequest req){
          HttpResponse res = new HttpResponse();
          res.setStatus('OK');
          res.setStatusCode(200);
          res.setBody('{"row": [{"SlateID": "123456", "Name": "Kyle Winterrowd"}]}');
          return res;
        }
    }
}