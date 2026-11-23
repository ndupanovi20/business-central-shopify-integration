codeunit 50110 "Shopify Client"
{
    procedure ExecuteGraphQL(
        QueryText: Text;
        Variables: JsonObject;
        var ResponseJson: JsonObject)
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        ShopifyAuth:
            Codeunit "Shopify Auth";

        Client:
            HttpClient;

        Content:
            HttpContent;

        ContentHeaders:
            HttpHeaders;

        RequestHeaders:
            HttpHeaders;

        Response:
            HttpResponseMessage;

        AccessToken:
            SecretText;

        RequestJson:
            JsonObject;

        RequestText: Text;
        ResponseText: Text;
        GraphQLUrl: Text;
        GraphQLErrorText: Text;
        IsHandled: Boolean;
    begin
        OnBeforeExecuteGraphQL(QueryText, Variables, ResponseJson, IsHandled);
        if IsHandled then
            exit;

        if not ShopifySetup.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist.');

        ShopifySetup.TestField(
            "Shop Domain");

        ShopifySetup.TestField(
            "API Version");

        ValidateShopDomain(
            ShopifySetup."Shop Domain");

        if QueryText = '' then
            Error(
                'Shopify GraphQL query cannot be empty.');

        AccessToken :=
            ShopifyAuth.GetAccessToken();

        RequestJson.Add(
            'query',
            QueryText);

        RequestJson.Add(
            'variables',
            Variables);

        RequestJson.WriteTo(
            RequestText);

        Content.WriteFrom(
            RequestText);

        Content.GetHeaders(
            ContentHeaders);

        ContentHeaders.Clear();

        if not ContentHeaders.TryAddWithoutValidation(
            'Content-Type',
            'application/json')
        then
            Error(
                'Content-Type header could not be added.');

        RequestHeaders :=
            Client.DefaultRequestHeaders();

        RequestHeaders.Clear();

        if not RequestHeaders.TryAddWithoutValidation(
            'X-Shopify-Access-Token',
            AccessToken)
        then
            Error(
                'Shopify access token header could not be added.');

        if not RequestHeaders.TryAddWithoutValidation(
            'Accept',
            'application/json')
        then
            Error(
                'Accept header could not be added.');

        GraphQLUrl :=
            StrSubstNo(
                'https://%1/admin/api/%2/graphql.json',
                ShopifySetup."Shop Domain",
                ShopifySetup."API Version");

        if not Client.Post(
            GraphQLUrl,
            Content,
            Response)
        then
            Error(
                'The GraphQL request to Shopify could not be sent.');

        Response.Content.ReadAs(
            ResponseText);

        if not Response.IsSuccessStatusCode() then
            Error(
                'Shopify GraphQL request failed. HTTP status: %1. Response: %2',
                Response.HttpStatusCode(),
                ShortenText(
                    ResponseText,
                    1000));

        Clear(
            ResponseJson);

        if not ResponseJson.ReadFrom(
            ResponseText)
        then
            Error(
                'Shopify returned invalid GraphQL JSON.');

        GraphQLErrorText :=
            GetGraphQLErrors(
                ResponseJson);

        if GraphQLErrorText <> '' then
            Error(
                'Shopify GraphQL error: %1',
                GraphQLErrorText);
    end;

    procedure GetShopName(): Text
    var
        Variables:
            JsonObject;

        ResponseJson:
            JsonObject;

        DataObject:
            JsonObject;

        ShopObject:
            JsonObject;

        QueryText: Text;
    begin
        QueryText :=
            'query TestConnection {' +
            ' shop {' +
            '  name' +
            '  myshopifyDomain' +
            ' }' +
            '}';

        ExecuteGraphQL(
            QueryText,
            Variables,
            ResponseJson);

        DataObject :=
            GetObject(
                ResponseJson,
                'data');

        ShopObject :=
            GetObject(
                DataObject,
                'shop');

        exit(
            GetText(
                ShopObject,
                'name'));
    end;

    procedure FindVariantBySku(
        Sku: Text;
        var ProductId: Text;
        var VariantId: Text;
        var InventoryItemId: Text): Boolean
    var
        Variables:
            JsonObject;

        ResponseJson:
            JsonObject;

        DataObject:
            JsonObject;

        VariantsObject:
            JsonObject;

        VariantObject:
            JsonObject;

        ProductObject:
            JsonObject;

        InventoryItemObject:
            JsonObject;

        NodesArray:
            JsonArray;

        Token:
            JsonToken;

        QueryText: Text;
        SearchText: Text;
    begin
        ProductId :=
            '';

        VariantId :=
            '';

        InventoryItemId :=
            '';

        if Sku = '' then
            exit(false);

        SearchText :=
            StrSubstNo(
                'sku:"%1"',
                Sku);

        Variables.Add(
            'search',
            SearchText);

        QueryText :=
            'query FindVariant($search: String!) {' +
            ' productVariants(first: 1, query: $search) {' +
            '  nodes {' +
            '   id' +
            '   sku' +
            '   inventoryItem { id }' +
            '   product { id }' +
            '  }' +
            ' }' +
            '}';

        ExecuteGraphQL(
            QueryText,
            Variables,
            ResponseJson);

        DataObject :=
            GetObject(
                ResponseJson,
                'data');

        VariantsObject :=
            GetObject(
                DataObject,
                'productVariants');

        NodesArray :=
            GetArray(
                VariantsObject,
                'nodes');

        if NodesArray.Count() = 0 then
            exit(false);

        NodesArray.Get(
            0,
            Token);

        VariantObject :=
            Token.AsObject();

        VariantId :=
            GetText(
                VariantObject,
                'id');

        ProductObject :=
            GetObject(
                VariantObject,
                'product');

        ProductId :=
            GetText(
                ProductObject,
                'id');

        InventoryItemObject :=
            GetObject(
                VariantObject,
                'inventoryItem');

        InventoryItemId :=
            GetText(
                InventoryItemObject,
                'id');

        exit(true);
    end;

    procedure CheckUserErrors(
        PayloadObject: JsonObject)
    var
        ErrorsArray:
            JsonArray;

        ErrorObject:
            JsonObject;

        Token:
            JsonToken;

        MessageText: Text;
        CombinedErrors: Text;

        I: Integer;
    begin
        if not PayloadObject.Get(
            'userErrors',
            Token)
        then
            exit;

        if not Token.IsArray() then
            exit;

        ErrorsArray :=
            Token.AsArray();

        if ErrorsArray.Count() = 0 then
            exit;

        for I := 0 to ErrorsArray.Count() - 1 do begin
            ErrorsArray.Get(
                I,
                Token);

            if Token.IsObject() then begin
                ErrorObject :=
                    Token.AsObject();

                MessageText :=
                    GetOptionalText(
                        ErrorObject,
                        'message');

                if MessageText = '' then
                    MessageText :=
                        'Unknown Shopify user error.';

                if CombinedErrors <> '' then
                    CombinedErrors +=
                        ' | ';

                CombinedErrors +=
                    MessageText;
            end;
        end;

        if CombinedErrors = '' then
            CombinedErrors :=
                'Unknown Shopify user error.';

        Error(
            'Shopify user error: %1',
            CombinedErrors);
    end;

    procedure GetObject(
        ParentObject: JsonObject;
        PropertyName: Text): JsonObject
    var
        Token:
            JsonToken;
    begin
        if not ParentObject.Get(
            PropertyName,
            Token)
        then
            Error(
                'JSON property %1 was not found.',
                PropertyName);

        if not Token.IsObject() then
            Error(
                'JSON property %1 is not an object.',
                PropertyName);

        exit(
            Token.AsObject());
    end;

    procedure GetArray(
        ParentObject: JsonObject;
        PropertyName: Text): JsonArray
    var
        Token:
            JsonToken;
    begin
        if not ParentObject.Get(
            PropertyName,
            Token)
        then
            Error(
                'JSON property %1 was not found.',
                PropertyName);

        if not Token.IsArray() then
            Error(
                'JSON property %1 is not an array.',
                PropertyName);

        exit(
            Token.AsArray());
    end;

    procedure GetText(
        ParentObject: JsonObject;
        PropertyName: Text): Text
    var
        Token:
            JsonToken;
    begin
        if not ParentObject.Get(
            PropertyName,
            Token)
        then
            Error(
                'JSON property %1 was not found.',
                PropertyName);

        if not Token.IsValue() then
            Error(
                'JSON property %1 is not a value.',
                PropertyName);

        if Token.AsValue().IsNull() then
            Error(
                'JSON property %1 is null.',
                PropertyName);

        exit(
            Token.AsValue().AsText());
    end;

    procedure GetOptionalText(
        ParentObject: JsonObject;
        PropertyName: Text): Text
    var
        Token:
            JsonToken;
    begin
        if not ParentObject.Get(
            PropertyName,
            Token)
        then
            exit('');

        if not Token.IsValue() then
            exit('');

        if Token.AsValue().IsNull() then
            exit('');

        exit(
            Token.AsValue().AsText());
    end;

    procedure TryGetObject(
        ParentObject: JsonObject;
        PropertyName: Text;
        var ResultObject: JsonObject): Boolean
    var
        Token:
            JsonToken;
    begin
        Clear(
            ResultObject);

        if not ParentObject.Get(
            PropertyName,
            Token)
        then
            exit(false);

        if not Token.IsObject() then
            exit(false);

        ResultObject :=
            Token.AsObject();

        exit(true);
    end;

    procedure TryGetArray(
        ParentObject: JsonObject;
        PropertyName: Text;
        var ResultArray: JsonArray): Boolean
    var
        Token:
            JsonToken;
    begin
        Clear(
            ResultArray);

        if not ParentObject.Get(
            PropertyName,
            Token)
        then
            exit(false);

        if not Token.IsArray() then
            exit(false);

        ResultArray :=
            Token.AsArray();

        exit(true);
    end;

    local procedure GetGraphQLErrors(
        ResponseJson: JsonObject): Text
    var
        ErrorsArray:
            JsonArray;

        ErrorObject:
            JsonObject;

        Token:
            JsonToken;

        MessageText: Text;
        ResultText: Text;

        I: Integer;
    begin
        if not ResponseJson.Get(
            'errors',
            Token)
        then
            exit('');

        if not Token.IsArray() then
            exit(
                'Shopify returned an invalid GraphQL errors structure.');

        ErrorsArray :=
            Token.AsArray();

        if ErrorsArray.Count() = 0 then
            exit('');

        for I := 0 to ErrorsArray.Count() - 1 do begin
            ErrorsArray.Get(
                I,
                Token);

            if Token.IsObject() then begin
                ErrorObject :=
                    Token.AsObject();

                MessageText :=
                    GetOptionalText(
                        ErrorObject,
                        'message');

                if MessageText = '' then
                    MessageText :=
                        'Unknown GraphQL error.';

                if ResultText <> '' then
                    ResultText +=
                        ' | ';

                ResultText +=
                    MessageText;
            end;
        end;

        if ResultText = '' then
            ResultText :=
                'Unknown GraphQL error.';

        exit(
            ShortenText(
                ResultText,
                1500));
    end;

    local procedure ValidateShopDomain(
        ShopDomain: Text)
    var
        NormalizedDomain: Text;
        RequiredSuffix: Text;
    begin
        NormalizedDomain :=
            LowerCase(
                ShopDomain);

        RequiredSuffix :=
            '.myshopify.com';

        if StrPos(
            NormalizedDomain,
            'https://') > 0
        then
            Error(
                'Shop Domain must not contain https://.');

        if StrPos(
            NormalizedDomain,
            'http://') > 0
        then
            Error(
                'Shop Domain must not contain http://.');

        if StrPos(
            NormalizedDomain,
            '/') > 0
        then
            Error(
                'Shop Domain must contain only the myshopify.com domain.');

        if StrPos(
            NormalizedDomain,
            ' ') > 0
        then
            Error(
                'Shop Domain cannot contain spaces.');

        if StrLen(
            NormalizedDomain)
           <= StrLen(
                RequiredSuffix)
        then
            Error(
                'Shop Domain is invalid.');

        if CopyStr(
            NormalizedDomain,
            StrLen(NormalizedDomain) -
            StrLen(RequiredSuffix) + 1)
           <> RequiredSuffix
        then
            Error(
                'Shop Domain must end with %1.',
                RequiredSuffix);
    end;

    local procedure ShortenText(
        InputText: Text;
        MaximumLength: Integer): Text
    begin
        if StrLen(
            InputText)
           <= MaximumLength
        then
            exit(
                InputText);

        exit(
            CopyStr(
                InputText,
                1,
                MaximumLength) +
            '...');
    end;
    [IntegrationEvent(false, false)]
    local procedure OnBeforeExecuteGraphQL(QueryText: Text; Variables: JsonObject; var ResponseJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

}