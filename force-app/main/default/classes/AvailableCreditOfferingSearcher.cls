global class AvailableCreditOfferingSearcher {

    final List<String> requestedFields;
    final Map<String, Object> additionalFilter;
    global AvailableCreditOfferingSearcher() {
        requestedFields = new List<String>();
        additionalFilter = new Map<String, Object>();
    }
    global AvailableCreditOfferingSearcher(Map<String, Object> additionalFilter) {
        requestedFields = new List<String>();
        this.additionalFilter = additionalFilter;
    }
    global AvailableCreditOfferingSearcher(List<String> requestedFields, Map<String, Object> additionalFilter) {
        if(requestedFields.contains('Id'))requestedFields.remove(requestedFields.indexOf('Id'));
        this.requestedFields = requestedFields;
        this.additionalFilter = additionalFilter;
    }
    
    global List<hed__Course_Offering__c> searchCreditOfferings() {
        Date today = Date.today();
        requestedFields.add('Id');
        String qry = 'SELECT '+requestedFields.toString().substring(1, requestedFields.toString().length()-1)+' FROM hed__Course_Offering__c WHERE csuoee__Registration_Start_Date__c <= :fffff AND csuoee__Registration_End_Date__c >= :fffff AND hed__Course__r.RecordType.DeveloperName = \'Credit\'';
        for(String key : additionalFilter.keySet()) {
            qry += ' AND ' + key + ' = :'+key;
        }
        additionalFilter.put('fffff', today); // Make it weird to avoid conflict
        qry += ' ORDER BY hed__Course__r.csuoee__Course_Code__c, hed__Section_ID__c';
        return Database.queryWithBinds(qry, additionalFilter, AccessLevel.USER_MODE);
    }

}