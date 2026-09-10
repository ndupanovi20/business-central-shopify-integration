codeunit 50170 "Shopify Diagnostics"
{
    procedure RunDiagnostics()
    var
        SyncLogMgt:
            Codeunit "Shopify Sync Log Mgt.";

        ShopName: Text;
        ScopeText: Text;
        ErrorText: Text;

        StartedAt: DateTime;
        OperationDuration: Duration;
    begin
        StartedAt :=
            CurrentDateTime();

        if TryRunDiagnostics(
            ShopName,
            ScopeText)
        then begin
            OperationDuration :=
                CurrentDateTime() - StartedAt;

            SyncLogMgt.LogSuccess(
                "Shopify Sync Direction"::System,
                "Shopify Sync Entity"::Setup,
                'SETUP',
                '',
                StrSubstNo(
                    'Diagnostics passed. Shop: %1. Scopes: %2',
                    ShopName,
                    ScopeText),
                OperationDuration);

            Message(
                'Shopify diagnostics passed.\Shop: %1\Scopes: %2',
                ShopName,
                ScopeText);

            exit;
        end;

        ErrorText :=
            GetLastErrorText();

        if ErrorText = '' then
            ErrorText :=
                'Unknown Shopify diagnostics error.';

        OperationDuration :=
            CurrentDateTime() - StartedAt;

        SyncLogMgt.LogError(
            "Shopify Sync Direction"::System,
            "Shopify Sync Entity"::Setup,
            'SETUP',
            '',
            ErrorText,
            OperationDuration);

        Error(
            ErrorText);
    end;

    [TryFunction]
    local procedure TryRunDiagnostics(
        var ShopName: Text;
        var ScopeText: Text)
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        Customer:
            Record Customer;

        Location:
            Record Location;

        ShippingItem:
            Record Item;

        ShopifySetupMgt:
            Codeunit "Shopify Setup Mgt.";

        ShopifyClient:
            Codeunit "Shopify Client";

        Variables:
            JsonObject;

        ResponseJson:
            JsonObject;

        DataObject:
            JsonObject;

        InstallationObject:
            JsonObject;

        ScopesArray:
            JsonArray;

        QueryText: Text;
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist.');

        ShopifySetup.TestField(
            "Shop Domain");

        ShopifySetup.TestField(
            "Client ID");

        ShopifySetup.TestField(
            "API Version");

        ShopifySetup.TestField(
            "Shopify Location ID");

        ShopifySetup.TestField(
            "BC Location Code");

        ShopifySetup.TestField(
            "BC Customer No.");

        if ShopifySetup."Tag Imported Orders" then
            ShopifySetup.TestField(
                "Imported Order Tag");

        if not ShopifySetupMgt.HasClientSecret() then
            Error(
                'Shopify Client Secret has not been configured.');

        if not Customer.Get(
            ShopifySetup."BC Customer No.")
        then
            Error(
                'Business Central customer %1 does not exist.',
                ShopifySetup."BC Customer No.");

        if Customer.Blocked <>
           Customer.Blocked::" "
        then
            Error(
                'Business Central customer %1 is blocked.',
                ShopifySetup."BC Customer No.");

        if not Location.Get(
            ShopifySetup."BC Location Code")
        then
            Error(
                'Business Central location %1 does not exist.',
                ShopifySetup."BC Location Code");

        if ShopifySetup."BC Shipping Item No." <> '' then begin
            if not ShippingItem.Get(
                ShopifySetup."BC Shipping Item No.")
            then
                Error(
                    'Shipping item %1 does not exist.',
                    ShopifySetup."BC Shipping Item No.");

            if ShippingItem.Blocked then
                Error(
                    'Shipping item %1 is blocked.',
                    ShopifySetup."BC Shipping Item No.");
        end;

        if StrPos(
            ShopifySetup."Shopify Location ID",
            'gid://shopify/Location/')
           <> 1
        then
            Error(
                'Shopify Location ID does not have a valid Shopify GID format.');

        ShopName :=
            ShopifyClient.GetShopName();

        QueryText :=
            'query AccessScopeList {' +
            ' currentAppInstallation {' +
            '  accessScopes {' +
            '   handle' +
            '  }' +
            ' }' +
            '}';

        ShopifyClient.ExecuteGraphQL(
            QueryText,
            Variables,
            ResponseJson);

        DataObject :=
            ShopifyClient.GetObject(
                ResponseJson,
                'data');

        InstallationObject :=
            ShopifyClient.GetObject(
                DataObject,
                'currentAppInstallation');

        ScopesArray :=
            ShopifyClient.GetArray(
                InstallationObject,
                'accessScopes');

        ScopeText :=
            BuildScopeText(
                ScopesArray);

        RequireScope(
            ScopesArray,
            'write_products');

        RequireScope(
            ScopesArray,
            'read_products');

        RequireScope(
            ScopesArray,
            'write_inventory');

        RequireScope(
            ScopesArray,
            'read_inventory');

        RequireScope(
            ScopesArray,
            'read_locations');

        RequireScope(
            ScopesArray,
            'read_orders');

        if ShopifySetup."Tag Imported Orders" then
            RequireScope(
                ScopesArray,
                'write_orders');
    end;

    local procedure RequireScope(
        ScopesArray: JsonArray;
        RequiredScope: Text)
    begin
        if not HasScope(
            ScopesArray,
            RequiredScope)
        then
            Error(
                'Required Shopify scope %1 is not granted.',
                RequiredScope);
    end;

    local procedure HasScope(
        ScopesArray: JsonArray;
        ScopeToFind: Text): Boolean
    var
        Token:
            JsonToken;

        ScopeObject:
            JsonObject;

        I: Integer;
        ScopeHandle: Text;
    begin
        if ScopesArray.Count() = 0 then
            exit(false);

        for I := 0 to ScopesArray.Count() - 1 do begin
            ScopesArray.Get(
                I,
                Token);

            ScopeObject :=
                Token.AsObject();

            ScopeHandle :=
                GetOptionalText(
                    ScopeObject,
                    'handle');

            if ScopeHandle =
               ScopeToFind
            then
                exit(true);
        end;

        exit(false);
    end;

    local procedure BuildScopeText(
        ScopesArray: JsonArray): Text
    var
        Token:
            JsonToken;

        ScopeObject:
            JsonObject;

        ResultText: Text;
        ScopeHandle: Text;

        I: Integer;
    begin
        if ScopesArray.Count() = 0 then
            exit('');

        for I := 0 to ScopesArray.Count() - 1 do begin
            ScopesArray.Get(
                I,
                Token);

            ScopeObject :=
                Token.AsObject();

            ScopeHandle :=
                GetOptionalText(
                    ScopeObject,
                    'handle');

            if ScopeHandle <> '' then begin
                if ResultText <> '' then
                    ResultText +=
                        ', ';

                ResultText +=
                    ScopeHandle;
            end;
        end;

        exit(
            ResultText);
    end;

    local procedure GetOptionalText(
        JsonObjectValue: JsonObject;
        PropertyName: Text): Text
    var
        Token:
            JsonToken;

        Value:
            JsonValue;
    begin
        if not JsonObjectValue.Get(
            PropertyName,
            Token)
        then
            exit('');

        if not Token.IsValue() then
            exit('');

        Value :=
            Token.AsValue();

        if Value.IsNull() then
            exit('');

        exit(
            Value.AsText());
    end;
}