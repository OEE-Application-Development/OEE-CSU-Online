global with sharing class SlateResponse {

    public Boolean Success;
    public String Message;
    
    global SlateResponse(Boolean Success, String Message) {
        this.IsError = IsError;
        this.Message = Message;
    }

}