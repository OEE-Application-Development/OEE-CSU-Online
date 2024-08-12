global with sharing class SlateResponse {

    public Boolean Success;
    public String Message;
    
    global SlateResponse(Boolean Success, String Message) {
        this.Success = Success;
        this.Message = Message;
    }

}