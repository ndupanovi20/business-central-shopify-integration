codeunit 50103 "Shopify Auth"
{
    procedure TestAuthentication(): Boolean
    var
        AccessToken: SecretText;
    begin
        AccessToken := GetAccessToken();

        exit(not AccessToken.IsEmpty());
    end;

    [NonDebuggable]
    procedure GetAccessToken(): SecretText
    var
        ShopifySetup: Record "Shopify Integration Setup";
        ShopifySetupMgt: Codeunit "Shopify Setup Mgt.";
        TypeHelper: Codeunit "Type Helper";

        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Response: HttpResponseMessage;

        ClientSecret: SecretText;
        ClientIdSecret: SecretText;
        EncodedClientId: SecretText;
        EncodedClientSecret: SecretText;
        RequestBody: SecretText;
        ResponseSecret: SecretText;
        AccessToken: SecretText;

        ResponseText: Text;
        AccessTokenText: Text;
        TokenUrl: Text;

        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        if not ShopifySetup.Get('SETUP') then
            Error('Shopify Integration Setup does not exist.');

        ShopifySetup.TestField("Shop Domain");
        ShopifySetup.TestField("Client ID");

        ShopifySetupMgt.GetClientSecret(ClientSecret);

        ClientIdSecret := ShopifySetup."Client ID";

        EncodedClientId := TypeHelper.UrlEncode(ClientIdSecret);
        EncodedClientSecret := TypeHelper.UrlEncode(ClientSecret);

        RequestBody :=
            SecretStrSubstNo(
                'grant_type=client_credentials&client_id=%1&client_secret=%2',
                EncodedClientId,
                EncodedClientSecret);

        Content.WriteFrom(RequestBody);

        Content.GetHeaders(ContentHeaders);

        // Ukloni sve defaultne HttpContent headere
        ContentHeaders.Clear();

        if not ContentHeaders.TryAddWithoutValidation(
            'Content-Type',
            'application/x-www-form-urlencoded')
        then
            Error('OAuth Content-Type header could not be added.');

        TokenUrl :=
            StrSubstNo(
                'https://%1/admin/oauth/access_token',
                ShopifySetup."Shop Domain");

        if not Client.Post(TokenUrl, Content, Response) then
            Error('The request to Shopify could not be sent.');

        Response.Content.ReadAs(ResponseSecret);
        ResponseText := ResponseSecret.Unwrap();

        if not Response.IsSuccessStatusCode() then
            Error(
                'Shopify authentication failed. HTTP status: %1. Response: %2',
                Response.HttpStatusCode(),
                ResponseText);

        if not ResponseJson.ReadFrom(ResponseText) then
            Error('Shopify returned invalid JSON.');

        if not ResponseJson.Get('access_token', Token) then
            Error('Shopify did not return an access token.');

        AccessTokenText := Token.AsValue().AsText();

        if AccessTokenText = '' then
            Error('Shopify returned an empty access token.');

        AccessToken := AccessTokenText;

        Clear(AccessTokenText);
        Clear(ResponseText);
        Clear(ResponseSecret);

        exit(AccessToken);
    end;
}