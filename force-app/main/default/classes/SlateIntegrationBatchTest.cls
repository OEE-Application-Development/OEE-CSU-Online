@isTest
public class SlateIntegrationBatchTest {
    @isTest static void testMethod1() {
        
        //Test.setMock(HttpCalloutMock.class, new SlateIntegrationMockImpl());
        
        Test.startTest();
        SchedulableContext sc = null;
        SlateIntegrationBatch testsche = new SlateIntegrationBatch();
        testsche.execute(sc); 
        Test.stopTest();
        
    }
}