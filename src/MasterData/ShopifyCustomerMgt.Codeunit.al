codeunit 50292 "Shopify Customer Mgt."
{
    procedure RefreshCustomersFromShopify(ShowResultMessage: Boolean): Integer
    var
        ShopifyClient: Codeunit "Shopify Client";
        SyncLogMgt: Codeunit "Shopify Sync Log Mgt.";
        Variables: JsonObject;
        ResponseJson: JsonObject;
        DataObject: JsonObject;
        CustomersObject: JsonObject;
        PageInfoObject: JsonObject;
        CustomerObject: JsonObject;
        NodesArray: JsonArray;
        Token: JsonToken;
        QueryText: Text;
        Cursor: Text;
        CustomerId: Text;
        CustomerName: Text;
        CustomerEmail: Text;
        CustomerPhone: Text;
        HasNextPage: Boolean;
        ImportedCount: Integer;
        I: Integer;
        StartedAt: DateTime;
    begin
        StartedAt := CurrentDateTime();

        QueryText :=
            'query GetCustomers($first: Int!, $after: String) {' +
            ' customers(first: $first, after: $after) {' +
            '  nodes {' +
            '   id displayName firstName lastName' +
            '   defaultEmailAddress { emailAddress }' +
            '   defaultPhoneNumber { phoneNumber }' +
            '  }' +
            '  pageInfo { hasNextPage endCursor }' +
            ' }' +
            '}';

        Cursor := '';
        HasNextPage := true;

        while HasNextPage do begin
            Clear(Variables);
            Clear(ResponseJson);

            Variables.Add('first', 100);
            if Cursor <> '' then
                Variables.Add('after', Cursor);

            ShopifyClient.ExecuteGraphQL(
                QueryText,
                Variables,
                ResponseJson);

            DataObject := ShopifyClient.GetObject(ResponseJson, 'data');
            CustomersObject := ShopifyClient.GetObject(DataObject, 'customers');
            NodesArray := ShopifyClient.GetArray(CustomersObject, 'nodes');

            if NodesArray.Count() > 0 then
                for I := 0 to NodesArray.Count() - 1 do begin
                    NodesArray.Get(I, Token);
                    CustomerObject := Token.AsObject();

                    CustomerId := GetOptionalText(CustomerObject, 'id');
                    CustomerName := GetOptionalText(CustomerObject, 'displayName');
                    CustomerEmail := GetCustomerEmail(CustomerObject);
                    CustomerPhone := GetCustomerPhone(CustomerObject);

                    if CustomerId <> '' then begin
                        UpsertDiscoveredCustomer(
                            CustomerId,
                            CustomerName,
                            CustomerEmail,
                            CustomerPhone);
                        ImportedCount += 1;
                    end;
                end;

            PageInfoObject := ShopifyClient.GetObject(CustomersObject, 'pageInfo');
            HasNextPage := GetBoolean(PageInfoObject, 'hasNextPage');

            if HasNextPage then begin
                Cursor := GetOptionalText(PageInfoObject, 'endCursor');
                if Cursor = '' then
                    HasNextPage := false;
            end;
        end;

        SyncLogMgt.LogSuccess(
            "Shopify Sync Direction"::Inbound,
            "Shopify Sync Entity"::Customer,
            '',
            '',
            StrSubstNo(
                'Shopify customer mapping refresh completed. Customers returned: %1.',
                ImportedCount),
            CurrentDateTime() - StartedAt);

        if ShowResultMessage then
            Message(
                'Shopify customers refreshed successfully. Customers returned: %1.',
                ImportedCount);

        exit(ImportedCount);
    end;

    procedure ResolveCustomerForOrder(
        OrderObject: JsonObject;
        ShopifySetup: Record "Shopify Integration Setup";
        ShopifyOrderName: Text;
        var CustomerNo: Code[20];
        var ShopifyCustomerId: Text;
        var ShopifyCustomerName: Text;
        var ShopifyCustomerEmail: Text)
    var
        Mapping: Record "Shopify Customer Mapping";
        Customer: Record Customer;
        CustomerObject: JsonObject;
        HasCustomerObject: Boolean;
        ShopifyPhone: Text;
    begin
        CustomerNo := '';
        ShopifyCustomerId := '';
        ShopifyCustomerName := '';
        ShopifyCustomerEmail := GetOptionalText(OrderObject, 'email');
        ShopifyPhone := GetOptionalText(OrderObject, 'phone');

        HasCustomerObject := TryGetObject(OrderObject, 'customer', CustomerObject);

        if HasCustomerObject then begin
            ShopifyCustomerId := GetOptionalText(CustomerObject, 'id');
            ShopifyCustomerName := GetOptionalText(CustomerObject, 'displayName');

            if ShopifyCustomerEmail = '' then
                ShopifyCustomerEmail := GetCustomerEmail(CustomerObject);

            if ShopifyPhone = '' then
                ShopifyPhone := GetCustomerPhone(CustomerObject);
        end;

        if ShopifyCustomerName = '' then
            ShopifyCustomerName := GetOrderAddressName(OrderObject);

        if ShopifyCustomerName = '' then
            ShopifyCustomerName := ShopifyCustomerEmail;

        if ShopifySetup."Customer Strategy" =
           ShopifySetup."Customer Strategy"::"Generic Customer"
        then begin
            ShopifySetup.TestField("BC Customer No.");
            CustomerNo := ShopifySetup."BC Customer No.";
            exit;
        end;

        if ShopifyCustomerId = '' then begin
            UseFallbackCustomerOrError(
                ShopifySetup,
                'Shopify order does not contain a registered Shopify customer ID.',
                CustomerNo);
            exit;
        end;

        if Mapping.Get(ShopifyCustomerId) then begin
            if Mapping."BC Customer No." <> '' then begin
                if not Customer.Get(Mapping."BC Customer No.") then
                    Error(
                        'Shopify customer %1 is mapped to Business Central customer %2, but that customer does not exist.',
                        ShopifyCustomerId,
                        Mapping."BC Customer No.");

                if Customer.Blocked <> Customer.Blocked::" " then
                    Error(
                        'Business Central customer %1 mapped to Shopify customer %2 is blocked.',
                        Customer."No.",
                        ShopifyCustomerId);

                CustomerNo := Customer."No.";
                UpdateMappingUsage(
                    Mapping,
                    ShopifyCustomerName,
                    ShopifyCustomerEmail,
                    ShopifyPhone,
                    ShopifyOrderName);
                exit;
            end;

            if ShopifySetup."Customer Strategy" =
               ShopifySetup."Customer Strategy"::"Mapped Customer"
            then begin
                UseFallbackCustomerOrError(
                    ShopifySetup,
                    StrSubstNo(
                        'Shopify customer %1 has a mapping record but no Business Central customer is assigned.',
                        ShopifyCustomerId),
                    CustomerNo);
                exit;
            end;
        end;

        case ShopifySetup."Customer Strategy" of
            ShopifySetup."Customer Strategy"::"Mapped Customer":
                UseFallbackCustomerOrError(
                    ShopifySetup,
                    StrSubstNo(
                        'Shopify customer %1 is not mapped to a Business Central customer.',
                        ShopifyCustomerId),
                    CustomerNo);

            ShopifySetup."Customer Strategy"::"Create or Map Customer":
                begin
                    CustomerNo :=
                        CreateCustomerFromOrder(
                            OrderObject,
                            ShopifySetup,
                            ShopifyCustomerName,
                            ShopifyCustomerEmail,
                            ShopifyPhone);

                    SaveMapping(
                        ShopifyCustomerId,
                        ShopifyCustomerName,
                        ShopifyCustomerEmail,
                        ShopifyPhone,
                        CustomerNo,
                        true,
                        ShopifyOrderName);
                end;
        end;
    end;

    procedure ApplyOrderAddresses(
        var SalesHeader: Record "Sales Header";
        OrderObject: JsonObject)
    var
        BillingAddress: JsonObject;
        ShippingAddress: JsonObject;
        HasBilling: Boolean;
        HasShipping: Boolean;
    begin
        HasBilling :=
            TryGetObject(
                OrderObject,
                'billingAddress',
                BillingAddress);

        HasShipping :=
            TryGetObject(
                OrderObject,
                'shippingAddress',
                ShippingAddress);

        if HasBilling then begin
            ApplyBillingAddress(
                SalesHeader,
                BillingAddress);

            ApplySellToAddress(
                SalesHeader,
                BillingAddress);
        end else
            if HasShipping then begin
                ApplyBillingAddress(
                    SalesHeader,
                    ShippingAddress);

                ApplySellToAddress(
                    SalesHeader,
                    ShippingAddress);
            end;

        if HasShipping then
            ApplyShipToAddress(
                SalesHeader,
                ShippingAddress)
        else
            if HasBilling then
                ApplyShipToAddress(
                    SalesHeader,
                    BillingAddress);

        SalesHeader.Modify(true);
    end;

    local procedure CreateCustomerFromOrder(
        OrderObject: JsonObject;
        ShopifySetup: Record "Shopify Integration Setup";
        ShopifyCustomerName: Text;
        ShopifyCustomerEmail: Text;
        ShopifyPhone: Text): Code[20]
    var
        TemplateCustomer: Record Customer;
        NewCustomer: Record Customer;
        AddressObject: JsonObject;
        HasAddress: Boolean;
        CustomerName: Text;
    begin
        ShopifySetup.TestField("BC Customer No.");

        if not TemplateCustomer.Get(ShopifySetup."BC Customer No.") then
            Error(
                'Template/fallback Business Central customer %1 does not exist.',
                ShopifySetup."BC Customer No.");

        if TemplateCustomer.Blocked <> TemplateCustomer.Blocked::" " then
            Error(
                'Template/fallback Business Central customer %1 is blocked.',
                TemplateCustomer."No.");

        NewCustomer.Init();
        NewCustomer.Insert(true);

        CustomerName := ShopifyCustomerName;
        if CustomerName = '' then
            CustomerName := 'Shopify Customer';

        NewCustomer.Validate(
            Name,
            CopyStr(
                CustomerName,
                1,
                MaxStrLen(NewCustomer.Name)));

        if TemplateCustomer."Customer Posting Group" <> '' then
            NewCustomer.Validate(
                "Customer Posting Group",
                TemplateCustomer."Customer Posting Group");

        if TemplateCustomer."Gen. Bus. Posting Group" <> '' then
            NewCustomer.Validate(
                "Gen. Bus. Posting Group",
                TemplateCustomer."Gen. Bus. Posting Group");

        if TemplateCustomer."VAT Bus. Posting Group" <> '' then
            NewCustomer.Validate(
                "VAT Bus. Posting Group",
                TemplateCustomer."VAT Bus. Posting Group");

        if TemplateCustomer."Payment Terms Code" <> '' then
            NewCustomer.Validate(
                "Payment Terms Code",
                TemplateCustomer."Payment Terms Code");

        if TemplateCustomer."Payment Method Code" <> '' then
            NewCustomer.Validate(
                "Payment Method Code",
                TemplateCustomer."Payment Method Code");

        NewCustomer."Prices Including VAT" :=
            TemplateCustomer."Prices Including VAT";

        NewCustomer."Customer Price Group" :=
            TemplateCustomer."Customer Price Group";

        NewCustomer."Customer Disc. Group" :=
            TemplateCustomer."Customer Disc. Group";

        if ShopifyCustomerEmail <> '' then
            NewCustomer."E-Mail" :=
                CopyStr(
                    ShopifyCustomerEmail,
                    1,
                    MaxStrLen(NewCustomer."E-Mail"));

        if ShopifyPhone <> '' then
            NewCustomer."Phone No." :=
                CopyStr(
                    ShopifyPhone,
                    1,
                    MaxStrLen(NewCustomer."Phone No."));

        HasAddress :=
            TryGetObject(
                OrderObject,
                'billingAddress',
                AddressObject);

        if not HasAddress then
            HasAddress :=
                TryGetObject(
                    OrderObject,
                    'shippingAddress',
                    AddressObject);

        if not HasAddress then
            HasAddress :=
                TryGetCustomerDefaultAddress(
                    OrderObject,
                    AddressObject);

        if HasAddress then
            ApplyAddressToCustomer(
                NewCustomer,
                AddressObject);

        NewCustomer.Modify(true);

        exit(NewCustomer."No.");
    end;

    local procedure ApplyAddressToCustomer(
        var Customer: Record Customer;
        AddressObject: JsonObject)
    begin
        Customer.Address :=
            CopyStr(
                GetOptionalText(AddressObject, 'address1'),
                1,
                MaxStrLen(Customer.Address));

        Customer."Address 2" :=
            CopyStr(
                GetOptionalText(AddressObject, 'address2'),
                1,
                MaxStrLen(Customer."Address 2"));

        Customer.City :=
            CopyStr(
                GetOptionalText(AddressObject, 'city'),
                1,
                MaxStrLen(Customer.City));

        Customer."Post Code" :=
            CopyStr(
                GetOptionalText(AddressObject, 'zip'),
                1,
                MaxStrLen(Customer."Post Code"));

        Customer.County :=
            CopyStr(
                GetProvince(AddressObject),
                1,
                MaxStrLen(Customer.County));

        Customer."Country/Region Code" :=
            CopyStr(
                GetOptionalText(AddressObject, 'countryCodeV2'),
                1,
                MaxStrLen(Customer."Country/Region Code"));
    end;

    local procedure ApplySellToAddress(
        var SalesHeader: Record "Sales Header";
        AddressObject: JsonObject)
    begin
        SalesHeader."Sell-to Customer Name" :=
            CopyStr(
                GetAddressName(AddressObject),
                1,
                MaxStrLen(SalesHeader."Sell-to Customer Name"));

        SalesHeader."Sell-to Address" :=
            CopyStr(
                GetOptionalText(AddressObject, 'address1'),
                1,
                MaxStrLen(SalesHeader."Sell-to Address"));

        SalesHeader."Sell-to Address 2" :=
            CopyStr(
                GetOptionalText(AddressObject, 'address2'),
                1,
                MaxStrLen(SalesHeader."Sell-to Address 2"));

        SalesHeader."Sell-to City" :=
            CopyStr(
                GetOptionalText(AddressObject, 'city'),
                1,
                MaxStrLen(SalesHeader."Sell-to City"));

        SalesHeader."Sell-to Post Code" :=
            CopyStr(
                GetOptionalText(AddressObject, 'zip'),
                1,
                MaxStrLen(SalesHeader."Sell-to Post Code"));

        SalesHeader."Sell-to County" :=
            CopyStr(
                GetProvince(AddressObject),
                1,
                MaxStrLen(SalesHeader."Sell-to County"));

        SalesHeader."Sell-to Country/Region Code" :=
            CopyStr(
                GetOptionalText(AddressObject, 'countryCodeV2'),
                1,
                MaxStrLen(SalesHeader."Sell-to Country/Region Code"));
    end;

    local procedure ApplyBillingAddress(
        var SalesHeader: Record "Sales Header";
        AddressObject: JsonObject)
    begin
        SalesHeader."Bill-to Name" :=
            CopyStr(
                GetAddressName(AddressObject),
                1,
                MaxStrLen(SalesHeader."Bill-to Name"));

        SalesHeader."Bill-to Address" :=
            CopyStr(
                GetOptionalText(AddressObject, 'address1'),
                1,
                MaxStrLen(SalesHeader."Bill-to Address"));

        SalesHeader."Bill-to Address 2" :=
            CopyStr(
                GetOptionalText(AddressObject, 'address2'),
                1,
                MaxStrLen(SalesHeader."Bill-to Address 2"));

        SalesHeader."Bill-to City" :=
            CopyStr(
                GetOptionalText(AddressObject, 'city'),
                1,
                MaxStrLen(SalesHeader."Bill-to City"));

        SalesHeader."Bill-to Post Code" :=
            CopyStr(
                GetOptionalText(AddressObject, 'zip'),
                1,
                MaxStrLen(SalesHeader."Bill-to Post Code"));

        SalesHeader."Bill-to County" :=
            CopyStr(
                GetProvince(AddressObject),
                1,
                MaxStrLen(SalesHeader."Bill-to County"));

        SalesHeader."Bill-to Country/Region Code" :=
            CopyStr(
                GetOptionalText(AddressObject, 'countryCodeV2'),
                1,
                MaxStrLen(SalesHeader."Bill-to Country/Region Code"));
    end;

    local procedure ApplyShipToAddress(
        var SalesHeader: Record "Sales Header";
        AddressObject: JsonObject)
    begin
        Clear(SalesHeader."Ship-to Code");

        SalesHeader."Ship-to Name" :=
            CopyStr(
                GetAddressName(AddressObject),
                1,
                MaxStrLen(SalesHeader."Ship-to Name"));

        SalesHeader."Ship-to Address" :=
            CopyStr(
                GetOptionalText(AddressObject, 'address1'),
                1,
                MaxStrLen(SalesHeader."Ship-to Address"));

        SalesHeader."Ship-to Address 2" :=
            CopyStr(
                GetOptionalText(AddressObject, 'address2'),
                1,
                MaxStrLen(SalesHeader."Ship-to Address 2"));

        SalesHeader."Ship-to City" :=
            CopyStr(
                GetOptionalText(AddressObject, 'city'),
                1,
                MaxStrLen(SalesHeader."Ship-to City"));

        SalesHeader."Ship-to Post Code" :=
            CopyStr(
                GetOptionalText(AddressObject, 'zip'),
                1,
                MaxStrLen(SalesHeader."Ship-to Post Code"));

        SalesHeader."Ship-to County" :=
            CopyStr(
                GetProvince(AddressObject),
                1,
                MaxStrLen(SalesHeader."Ship-to County"));

        SalesHeader."Ship-to Country/Region Code" :=
            CopyStr(
                GetOptionalText(AddressObject, 'countryCodeV2'),
                1,
                MaxStrLen(SalesHeader."Ship-to Country/Region Code"));

        SalesHeader."Ship-to Contact" :=
            CopyStr(
                GetAddressContact(AddressObject),
                1,
                MaxStrLen(SalesHeader."Ship-to Contact"));
    end;

    local procedure UseFallbackCustomerOrError(
        ShopifySetup: Record "Shopify Integration Setup";
        ReasonText: Text;
        var CustomerNo: Code[20])
    begin
        if not ShopifySetup."Fallback to Generic Customer" then
            Error(ReasonText);

        ShopifySetup.TestField("BC Customer No.");
        CustomerNo := ShopifySetup."BC Customer No.";
    end;

    local procedure SaveMapping(
        ShopifyCustomerId: Text;
        ShopifyCustomerName: Text;
        ShopifyCustomerEmail: Text;
        ShopifyPhone: Text;
        CustomerNo: Code[20];
        CreatedAutomatically: Boolean;
        ShopifyOrderName: Text)
    var
        Mapping: Record "Shopify Customer Mapping";
        IsNew: Boolean;
    begin
        if ShopifyCustomerId = '' then
            exit;

        IsNew :=
            not Mapping.Get(
                ShopifyCustomerId);

        if IsNew then begin
            Mapping.Init();
            Mapping."Shopify Customer ID" :=
                CopyStr(
                    ShopifyCustomerId,
                    1,
                    MaxStrLen(Mapping."Shopify Customer ID"));
            Mapping."Created At" := CurrentDateTime();
        end;

        Mapping."BC Customer No." := CustomerNo;
        Mapping."Created Automatically" := CreatedAutomatically;

        if IsNew then
            Mapping.Insert(true)
        else
            Mapping.Modify(true);

        UpdateMappingUsage(
            Mapping,
            ShopifyCustomerName,
            ShopifyCustomerEmail,
            ShopifyPhone,
            ShopifyOrderName);
    end;

    local procedure UpdateMappingUsage(
        var Mapping: Record "Shopify Customer Mapping";
        ShopifyCustomerName: Text;
        ShopifyCustomerEmail: Text;
        ShopifyPhone: Text;
        ShopifyOrderName: Text)
    begin
        Mapping."Shopify Customer Name" :=
            CopyStr(
                ShopifyCustomerName,
                1,
                MaxStrLen(Mapping."Shopify Customer Name"));

        Mapping."Shopify E-Mail" :=
            CopyStr(
                ShopifyCustomerEmail,
                1,
                MaxStrLen(Mapping."Shopify E-Mail"));

        Mapping."Shopify Phone No." :=
            CopyStr(
                ShopifyPhone,
                1,
                MaxStrLen(Mapping."Shopify Phone No."));

        Mapping."Last Shopify Order Name" :=
            CopyStr(
                ShopifyOrderName,
                1,
                MaxStrLen(Mapping."Last Shopify Order Name"));

        Mapping."Last Used At" := CurrentDateTime();
        Mapping.Modify(true);
    end;

    local procedure UpsertDiscoveredCustomer(
        ShopifyCustomerId: Text;
        ShopifyCustomerName: Text;
        ShopifyCustomerEmail: Text;
        ShopifyPhone: Text)
    var
        Mapping: Record "Shopify Customer Mapping";
        IsNew: Boolean;
    begin
        if ShopifyCustomerId = '' then
            exit;

        IsNew := not Mapping.Get(ShopifyCustomerId);

        if IsNew then begin
            Mapping.Init();
            Mapping."Shopify Customer ID" :=
                CopyStr(
                    ShopifyCustomerId,
                    1,
                    MaxStrLen(Mapping."Shopify Customer ID"));
            Mapping."Created At" := CurrentDateTime();
        end;

        Mapping."Shopify Customer Name" :=
            CopyStr(
                ShopifyCustomerName,
                1,
                MaxStrLen(Mapping."Shopify Customer Name"));

        Mapping."Shopify E-Mail" :=
            CopyStr(
                ShopifyCustomerEmail,
                1,
                MaxStrLen(Mapping."Shopify E-Mail"));

        Mapping."Shopify Phone No." :=
            CopyStr(
                ShopifyPhone,
                1,
                MaxStrLen(Mapping."Shopify Phone No."));

        if IsNew then
            Mapping.Insert(true)
        else
            Mapping.Modify(true);
    end;

    local procedure TryGetCustomerDefaultAddress(
        OrderObject: JsonObject;
        var AddressObject: JsonObject): Boolean
    var
        CustomerObject: JsonObject;
    begin
        if not TryGetObject(OrderObject, 'customer', CustomerObject) then
            exit(false);

        exit(
            TryGetObject(
                CustomerObject,
                'defaultAddress',
                AddressObject));
    end;

    local procedure GetCustomerEmail(CustomerObject: JsonObject): Text
    var
        EmailObject: JsonObject;
    begin
        if not TryGetObject(CustomerObject, 'defaultEmailAddress', EmailObject) then
            exit('');

        exit(GetOptionalText(EmailObject, 'emailAddress'));
    end;

    local procedure GetCustomerPhone(CustomerObject: JsonObject): Text
    var
        PhoneObject: JsonObject;
    begin
        if not TryGetObject(CustomerObject, 'defaultPhoneNumber', PhoneObject) then
            exit('');

        exit(GetOptionalText(PhoneObject, 'phoneNumber'));
    end;

    local procedure GetOrderAddressName(OrderObject: JsonObject): Text
    var
        AddressObject: JsonObject;
    begin
        if TryGetObject(OrderObject, 'shippingAddress', AddressObject) then
            exit(GetAddressName(AddressObject));

        if TryGetObject(OrderObject, 'billingAddress', AddressObject) then
            exit(GetAddressName(AddressObject));

        exit('');
    end;

    local procedure GetAddressName(AddressObject: JsonObject): Text
    var
        ResultText: Text;
    begin
        ResultText := GetOptionalText(AddressObject, 'name');
        if ResultText <> '' then
            exit(ResultText);

        ResultText := GetOptionalText(AddressObject, 'firstName');

        if GetOptionalText(AddressObject, 'lastName') <> '' then begin
            if ResultText <> '' then
                ResultText += ' ';
            ResultText += GetOptionalText(AddressObject, 'lastName');
        end;

        if ResultText = '' then
            ResultText := GetOptionalText(AddressObject, 'company');

        exit(ResultText);
    end;

    local procedure GetAddressContact(AddressObject: JsonObject): Text
    begin
        exit(GetAddressName(AddressObject));
    end;

    local procedure GetProvince(AddressObject: JsonObject): Text
    var
        ResultText: Text;
    begin
        ResultText := GetOptionalText(AddressObject, 'provinceCode');
        if ResultText <> '' then
            exit(ResultText);

        exit(GetOptionalText(AddressObject, 'province'));
    end;

    local procedure TryGetObject(
        ParentObject: JsonObject;
        PropertyName: Text;
        var ResultObject: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        Clear(ResultObject);

        if not ParentObject.Get(PropertyName, Token) then
            exit(false);

        if Token.IsValue() then
            if Token.AsValue().IsNull() then
                exit(false);

        if not Token.IsObject() then
            exit(false);

        ResultObject := Token.AsObject();
        exit(true);
    end;

    local procedure GetOptionalText(
        ParentObject: JsonObject;
        PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not ParentObject.Get(PropertyName, Token) then
            exit('');

        if not Token.IsValue() then
            exit('');

        if Token.AsValue().IsNull() then
            exit('');

        exit(Token.AsValue().AsText());
    end;

    local procedure GetBoolean(
        ParentObject: JsonObject;
        PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not ParentObject.Get(PropertyName, Token) then
            Error('JSON property %1 was not found.', PropertyName);

        exit(Token.AsValue().AsBoolean());
    end;
}
