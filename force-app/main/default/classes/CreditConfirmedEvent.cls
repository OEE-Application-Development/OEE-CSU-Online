global with sharing class CreditConfirmedEvent {
    @InvocableMethod(Label='Enroll Student in Credit Section Event' Description='Sends confirmation request')
    global static List<AzureEventIntegration.AzureResponse> enrollStudent(List<CreditConfirmedRequest> requests) {
        List<AzureEventIntegration.AzureEvent> events = new List<AzureEventIntegration.AzureEvent>();
        for(CreditConfirmedRequest request : requests) {
            events.add(ConfirmedEvent(request.userId, request.offeringReference, request.status, request.bannerStatus));
        }

        return new List<AzureEventIntegration.AzureResponse>{AzureEventIntegration.sendEvents(events, true)};
    }

    private static AzureEventIntegration.AzureEvent ConfirmedEvent(String studentId, String sectionReference, String status, String bannerStatus) {
        return new AzureEventIntegration.AzureEvent(
            'registration', 
            'Confirmed', 
            'csuoee/credit/registration', 
            new Map<String, Object>{'studentId' => studentId, 'sectionReference' => sectionReference, 'status' => status, 'bannerStatus' => bannerStatus}
        );
    }

    global class CreditConfirmedRequest extends AzureEventIntegration.AzureRequest {
        @InvocableVariable(Required=true Description='User Id (CSU ID) of the Contact.')
        global String userId;

        @InvocableVariable(Required=true Description='Reference of the offering.')
        global String offeringReference;

        @InvocableVariable(Required=false Description='Enrollment Status. Defaults to Enrolled.')
        global String status = 'Enrolled';

        @InvocableVariable(Required=false Description='Banner Status of Enrollment. Defaults to RW.')
        global String bannerStatus = 'RW';

        global CreditConfirmedRequest(){
            super(true);
        }
        global CreditConfirmedRequest(String userId, String offeringReference) {
            super(true);
            this.userId = userId;
            this.offeringReference = offeringReference;
        }
    }
}