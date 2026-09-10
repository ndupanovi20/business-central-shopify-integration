codeunit 50132 "Shopify Order Sync"
{
    procedure ImportLatestOrders(): Integer
    var
        ShopifySetup: Record "Shopify Integration Setup";
    begin
        if not ShopifySetup.Get('SETUP') then
            Error('Shopify Integration Setup does not exist.');

        ShopifySetup.TestField("BC Customer No.");
        ShopifySetup.TestField("BC Location Code");

        FetchOrdersToBuffer(ShopifySetup);
        exit(ProcessOrderBuffer());
    end;

    local procedure FetchOrdersToBuffer(ShopifySetup: Record "Shopify Integration Setup")
    var
        ShopifyClient: Codeunit "Shopify Client";
        Variables: JsonObject;
        ResponseJson: JsonObject;
        DataObject: JsonObject;
        OrdersObject: JsonObject;
        OrderObject: JsonObject;
        PageInfoObject: JsonObject;
        OrdersArray: JsonArray;
        Token: JsonToken;
        QueryText: Text;
        Cursor: Text;
        HasNextPage: Boolean;
        ReachedCutoff: Boolean;
        I: Integer;
    begin
        QueryText :=
            'query GetOrders($first: Int!, $after: String) {' +
            ' orders(first: $first, after: $after, sortKey: CREATED_AT, reverse: true) {' +
            '  nodes {' +
            '   id name createdAt cancelledAt presentmentCurrencyCode' +
            '   displayFinancialStatus displayFulfillmentStatus' +
            '   currentTotalPriceSet { presentmentMoney { amount currencyCode } }' +
            '   lineItems(first: 250) {' +
            '    nodes {' +
            '     id title sku quantity currentQuantity' +
            '     originalUnitPriceSet { presentmentMoney { amount currencyCode } }' +
            '     discountAllocations {' +
            '      allocatedAmountSet { presentmentMoney { amount currencyCode } }' +
            '     }' +
            '    }' +
            '   }' +
            '   shippingLines(first: 50) {' +
            '    nodes {' +
            '     title' +
            '     discountedPriceSet { presentmentMoney { amount currencyCode } }' +
            '    }' +
            '   }' +
            '  }' +
            '  pageInfo { hasNextPage endCursor }' +
            ' }' +
            '}';

        Cursor := '';
        HasNextPage := true;

        while HasNextPage do begin
            ReachedCutoff := false;
            Clear(Variables);
            Clear(ResponseJson);

            Variables.Add('first', 50);

            if Cursor <> '' then
                Variables.Add('after', Cursor);

            ShopifyClient.ExecuteGraphQL(
                QueryText,
                Variables,
                ResponseJson);

            DataObject :=
                ShopifyClient.GetObject(
                    ResponseJson,
                    'data');

            OrdersObject :=
                ShopifyClient.GetObject(
                    DataObject,
                    'orders');

            OrdersArray :=
                ShopifyClient.GetArray(
                    OrdersObject,
                    'nodes');

            if OrdersArray.Count() > 0 then
                for I := 0 to OrdersArray.Count() - 1 do
                    if not ReachedCutoff then begin
                        OrdersArray.Get(
                            I,
                            Token);

                        OrderObject :=
                            Token.AsObject();

                        if IsBeforeImportCutoff(
                            OrderObject,
                            ShopifySetup)
                        then
                            ReachedCutoff := true
                        else
                            BufferOrder(
                                OrderObject,
                                ShopifySetup);
                    end;

            if ReachedCutoff then
                HasNextPage := false
            else begin
                PageInfoObject :=
                    ShopifyClient.GetObject(
                        OrdersObject,
                        'pageInfo');

                HasNextPage :=
                    GetBoolean(
                        PageInfoObject,
                        'hasNextPage');

                if HasNextPage then begin
                    Cursor :=
                        GetOptionalText(
                            PageInfoObject,
                            'endCursor');

                    if Cursor = '' then
                        HasNextPage := false;
                end;
            end;
        end;
    end;

    local procedure BufferOrder(
        OrderObject: JsonObject;
        ShopifySetup: Record "Shopify Integration Setup")
    var
        Buffer: Record "Shopify Order Buffer";
        ShopifyOrderImport: Record "Shopify Order Import";
        ShopifyOrderId: Text;
        ShopifyOrderName: Text;
        FinancialStatus: Text;
        FulfillmentStatus: Text;
        PayloadText: Text;
        SkipReason: Text;
        ShouldSkip: Boolean;
        BufferExists: Boolean;
    begin
        ShopifyOrderId :=
            GetRequiredText(
                OrderObject,
                'id');

        if ShopifyOrderImport.Get(
            ShopifyOrderId)
        then
            exit;

        ShopifyOrderName :=
            GetRequiredText(
                OrderObject,
                'name');

        FinancialStatus :=
            GetOptionalText(
                OrderObject,
                'displayFinancialStatus');

        FulfillmentStatus :=
            GetOptionalText(
                OrderObject,
                'displayFulfillmentStatus');

        ShouldSkip :=
            ShouldSkipOrder(
                OrderObject,
                ShopifySetup,
                SkipReason);

        OrderObject.WriteTo(
            PayloadText);

        Buffer.SetRange(
            "Shopify Order ID",
            ShopifyOrderId);

        BufferExists :=
            Buffer.FindFirst();

        Buffer.SetRange(
            "Shopify Order ID");

        if not BufferExists then begin
            Buffer.Init();

            Buffer."Shopify Order ID" :=
                CopyStr(
                    ShopifyOrderId,
                    1,
                    MaxStrLen(
                        Buffer."Shopify Order ID"));
        end;

        Buffer."Shopify Order Name" :=
            CopyStr(
                ShopifyOrderName,
                1,
                MaxStrLen(
                    Buffer."Shopify Order Name"));

        Buffer."Financial Status" :=
            CopyStr(
                FinancialStatus,
                1,
                MaxStrLen(
                    Buffer."Financial Status"));

        Buffer."Fulfillment Status" :=
            CopyStr(
                FulfillmentStatus,
                1,
                MaxStrLen(
                    Buffer."Fulfillment Status"));

        Buffer."Created At" :=
            GetDateTime(
                OrderObject,
                'createdAt');

        Buffer.SetPayload(
            PayloadText);

        if ShouldSkip then begin
            Buffer.Status :=
                Buffer.Status::Skipped;

            Buffer."Processed At" :=
                CurrentDateTime();

            Buffer."Last Error" :=
                CopyStr(
                    SkipReason,
                    1,
                    MaxStrLen(
                        Buffer."Last Error"));
        end else
            if not BufferExists then begin
                Buffer.Status :=
                    Buffer.Status::Pending;

                Clear(
                    Buffer."Processed At");

                Clear(
                    Buffer."Last Error");
            end else
                case Buffer.Status of
                    Buffer.Status::Skipped:
                        begin
                            Buffer.Status :=
                                Buffer.Status::Pending;

                            Clear(
                                Buffer."Processed At");

                            Clear(
                                Buffer."Last Error");
                        end;

                    Buffer.Status::Pending:
                        begin
                            Clear(
                                Buffer."Processed At");

                            Clear(
                                Buffer."Last Error");
                        end;

                    Buffer.Status::Error:
                        begin
                            // Failed orders remain Error.
                            // Retry is done explicitly from Order Buffer.
                        end;

                    Buffer.Status::Success:
                        exit;
                end;

        if BufferExists then
            Buffer.Modify(true)
        else
            Buffer.Insert(true);
    end;

    local procedure IsBeforeImportCutoff(
        OrderObject: JsonObject;
        ShopifySetup: Record "Shopify Integration Setup"): Boolean
    var
        ShopifyCreatedAt: DateTime;
    begin
        if ShopifySetup."Import Orders From" = 0DT then
            exit(false);

        ShopifyCreatedAt :=
            GetDateTime(
                OrderObject,
                'createdAt');

        exit(
            ShopifyCreatedAt <
            ShopifySetup."Import Orders From");
    end;

    local procedure ShouldSkipOrder(
        OrderObject: JsonObject;
        ShopifySetup: Record "Shopify Integration Setup";
        var SkipReason: Text): Boolean
    var
        FinancialStatus: Text;
    begin
        SkipReason := '';

        if IsCancelled(
            OrderObject)
        then begin
            SkipReason :=
                'Shopify order is cancelled.';

            exit(true);
        end;

        FinancialStatus :=
            UpperCase(
                GetOptionalText(
                    OrderObject,
                    'displayFinancialStatus'));

        case FinancialStatus of
            'VOIDED':
                begin
                    SkipReason :=
                        'Shopify order financial status is VOIDED.';

                    exit(true);
                end;

            'REFUNDED':
                begin
                    SkipReason :=
                        'Shopify order financial status is REFUNDED.';

                    exit(true);
                end;

            'PARTIALLY_REFUNDED':
                begin
                    SkipReason :=
                        'Shopify order financial status is PARTIALLY_REFUNDED. Partial refunds are not imported automatically.';

                    exit(true);
                end;
        end;

        if ShopifySetup."Import Only Paid Orders" then
            if FinancialStatus <> 'PAID' then begin
                SkipReason :=
                    StrSubstNo(
                        'Order skipped because financial status is %1 and Import Only Paid Orders is enabled.',
                        FinancialStatus);

                exit(true);
            end;

        exit(false);
    end;

    local procedure ProcessOrderBuffer(): Integer
    var
        Buffer: Record "Shopify Order Buffer";
        ImportedOrder: Record "Shopify Order Import";
        Runner: Codeunit "Shopify Order Import Runner";
        SyncLogMgt: Codeunit "Shopify Sync Log Mgt.";
        ErrorText: Text;
        ShopifyId: Text;
        StartedAt: DateTime;
        ImportedCount: Integer;
    begin
        Buffer.SetRange(
            Status,
            Buffer.Status::Pending);

        if not Buffer.FindSet() then
            exit(0);

        repeat
            StartedAt :=
                CurrentDateTime();

            ShopifyId :=
                Buffer."Shopify Order ID";

            if ImportedOrder.Get(
                ShopifyId)
            then begin
                Buffer.Status :=
                    Buffer.Status::Success;

                Buffer."Processed At" :=
                    CurrentDateTime();

                Clear(
                    Buffer."Last Error");

                Buffer.Modify(true);
            end else begin
                Commit();

                ClearLastError();

                if Runner.Run(Buffer) then begin
                    Buffer.Status :=
                        Buffer.Status::Success;

                    Buffer."Processed At" :=
                        CurrentDateTime();

                    Clear(
                        Buffer."Last Error");

                    Buffer.Modify(true);

                    ImportedCount += 1;

                    SyncLogMgt.LogSuccess(
                        "Shopify Sync Direction"::Inbound,
                        "Shopify Sync Entity"::Order,
                        GetBCOrderNo(
                            ShopifyId),
                        ShopifyId,
                        StrSubstNo(
                            'Shopify order %1 imported successfully.',
                            Buffer."Shopify Order Name"),
                        CurrentDateTime() - StartedAt);
                end else begin
                    ErrorText :=
                        GetLastErrorText();

                    if ErrorText = '' then
                        ErrorText :=
                            'Unknown error while importing Shopify order.';

                    Buffer.Status :=
                        Buffer.Status::Error;

                    Buffer."Processed At" :=
                        CurrentDateTime();

                    Buffer."Last Error" :=
                        CopyStr(
                            ErrorText,
                            1,
                            MaxStrLen(
                                Buffer."Last Error"));

                    Buffer.Modify(true);

                    SyncLogMgt.LogError(
                        "Shopify Sync Direction"::Inbound,
                        "Shopify Sync Entity"::Order,
                        '',
                        ShopifyId,
                        ErrorText,
                        CurrentDateTime() - StartedAt);
                end;
            end;

        until Buffer.Next() = 0;

        exit(
            ImportedCount);
    end;

    procedure ProcessBufferedOrder(
        var Buffer: Record "Shopify Order Buffer")
    var
        ShopifySetup: Record "Shopify Integration Setup";
        ShopifyOrderImport: Record "Shopify Order Import";
        SalesHeader: Record "Sales Header";
        OrderObject: JsonObject;
        PayloadText: Text;
        ShopifyOrderId: Text;
        ShopifyOrderName: Text;
        CurrencyText: Text;
        CurrencyCode: Code[10];
        ShopifyTotal: Decimal;
        ShopifyShipping: Decimal;
        TotalDiscount: Decimal;
        BCTotal: Decimal;
        LineCount: Integer;
    begin
        PayloadText :=
            Buffer.GetPayload();

        if PayloadText = '' then
            Error(
                'Shopify order buffer payload is empty.');

        if not OrderObject.ReadFrom(
            PayloadText)
        then
            Error(
                'Shopify order buffer contains invalid JSON.');

        ShopifyOrderId :=
            GetRequiredText(
                OrderObject,
                'id');

        if ShopifyOrderImport.Get(
            ShopifyOrderId)
        then
            exit;

        if not ShopifySetup.Get('SETUP') then
            Error(
                'Shopify Integration Setup does not exist.');

        ShopifySetup.TestField(
            "BC Customer No.");

        ShopifySetup.TestField(
            "BC Location Code");

        ShopifyOrderName :=
            GetRequiredText(
                OrderObject,
                'name');

        CurrencyText :=
            GetRequiredText(
                OrderObject,
                'presentmentCurrencyCode');

        CurrencyCode :=
            CopyStr(
                CurrencyText,
                1,
                MaxStrLen(
                    CurrencyCode));

        ShopifyTotal :=
            GetMoneyAmount(
                OrderObject,
                'currentTotalPriceSet',
                CurrencyCode);

        CreateSalesHeader(
            SalesHeader,
            ShopifySetup,
            ShopifyOrderName,
            CurrencyCode);

        ProcessOrderLines(
            OrderObject,
            SalesHeader,
            ShopifySetup,
            CurrencyCode,
            LineCount,
            TotalDiscount);

        ProcessShippingLines(
            OrderObject,
            SalesHeader,
            ShopifySetup,
            CurrencyCode,
            ShopifyShipping);

        SalesHeader.CalcFields(
            "Amount Including VAT");

        BCTotal :=
            SalesHeader."Amount Including VAT";

        if Abs(
            Round(
                BCTotal - ShopifyTotal,
                0.01))
            > 0.02
        then
            Error(
                'Order total mismatch. Shopify total: %1 %2. Business Central total: %3 %2.',
                ShopifyTotal,
                CurrencyCode,
                BCTotal);

        InsertImportRegistry(
            ShopifyOrderImport,
            OrderObject,
            SalesHeader,
            CurrencyCode,
            ShopifyTotal,
            BCTotal,
            ShopifyShipping,
            TotalDiscount,
            LineCount);
    end;

    local procedure CreateSalesHeader(
        var SalesHeader: Record "Sales Header";
        ShopifySetup: Record "Shopify Integration Setup";
        ShopifyOrderName: Text;
        CurrencyCode: Code[10])
    begin
        SalesHeader.Init();

        SalesHeader.Validate(
            "Document Type",
            SalesHeader."Document Type"::Order);

        SalesHeader."No." :=
            '';

        SalesHeader.Insert(true);

        SalesHeader.Validate(
            "Sell-to Customer No.",
            ShopifySetup."BC Customer No.");

        SalesHeader.Validate(
            "Location Code",
            ShopifySetup."BC Location Code");

        ApplyCurrency(
            SalesHeader,
            CurrencyCode);

        SalesHeader.Validate(
            "External Document No.",
            CopyStr(
                ShopifyOrderName,
                1,
                MaxStrLen(
                    SalesHeader."External Document No.")));

        SalesHeader."Your Reference" :=
            CopyStr(
                'Shopify ' + ShopifyOrderName,
                1,
                MaxStrLen(
                    SalesHeader."Your Reference"));

        SalesHeader.Modify(true);
    end;

    local procedure ProcessOrderLines(
        OrderObject: JsonObject;
        SalesHeader: Record "Sales Header";
        ShopifySetup: Record "Shopify Integration Setup";
        CurrencyCode: Code[10];
        var LineCount: Integer;
        var TotalDiscount: Decimal)
    var
        ShopifyClient: Codeunit "Shopify Client";
        Item: Record Item;
        LineItemsObject: JsonObject;
        LineObject: JsonObject;
        LinesArray: JsonArray;
        Token: JsonToken;
        SKUText: Text;
        ItemNo: Code[20];
        Quantity: Integer;
        UnitPrice: Decimal;
        DiscountAmount: Decimal;
        DiscountPercent: Decimal;
        OriginalLineTotal: Decimal;
        LineNo: Integer;
        I: Integer;
    begin
        LineItemsObject :=
            ShopifyClient.GetObject(
                OrderObject,
                'lineItems');

        LinesArray :=
            ShopifyClient.GetArray(
                LineItemsObject,
                'nodes');

        if LinesArray.Count() = 0 then
            Error(
                'Shopify order does not contain line items.');

        LineNo := 0;

        for I := 0 to LinesArray.Count() - 1 do begin
            LinesArray.Get(
                I,
                Token);

            LineObject :=
                Token.AsObject();

            Quantity :=
                GetInteger(
                    LineObject,
                    'currentQuantity');

            if Quantity > 0 then begin
                SKUText :=
                    GetOptionalText(
                        LineObject,
                        'sku');

                if SKUText = '' then
                    Error(
                        'Shopify order contains an item without SKU.');

                ItemNo :=
                    CopyStr(
                        SKUText,
                        1,
                        MaxStrLen(
                            ItemNo));

                if not Item.Get(
                    ItemNo)
                then
                    Error(
                        'Business Central item %1 does not exist.',
                        ItemNo);

                if Item.Blocked then
                    Error(
                        'Business Central item %1 is blocked.',
                        ItemNo);

                UnitPrice :=
                    GetMoneyAmount(
                        LineObject,
                        'originalUnitPriceSet',
                        CurrencyCode);

                DiscountAmount :=
                    GetLineDiscountAmount(
                        LineObject,
                        CurrencyCode);

                OriginalLineTotal :=
                    UnitPrice * Quantity;

                if DiscountAmount >
                   OriginalLineTotal
                then
                    Error(
                        'Discount for item %1 exceeds the original line amount.',
                        ItemNo);

                DiscountPercent :=
                    0;

                if OriginalLineTotal <> 0 then
                    DiscountPercent :=
                        Round(
                            (DiscountAmount /
                             OriginalLineTotal) * 100,
                            0.00001);

                LineNo += 10000;

                CreateItemSalesLine(
                    SalesHeader,
                    ShopifySetup,
                    ItemNo,
                    Quantity,
                    UnitPrice,
                    DiscountPercent,
                    LineNo);

                TotalDiscount +=
                    DiscountAmount;

                LineCount += 1;
            end;
        end;

        if LineCount = 0 then
            Error(
                'Shopify order does not contain any active quantities to import.');
    end;

    local procedure CreateItemSalesLine(
        SalesHeader: Record "Sales Header";
        ShopifySetup: Record "Shopify Integration Setup";
        ItemNo: Code[20];
        Quantity: Decimal;
        UnitPrice: Decimal;
        DiscountPercent: Decimal;
        LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();

        SalesLine.Validate(
            "Document Type",
            SalesHeader."Document Type");

        SalesLine.Validate(
            "Document No.",
            SalesHeader."No.");

        SalesLine.Validate(
            "Line No.",
            LineNo);

        SalesLine.Validate(
            Type,
            SalesLine.Type::Item);

        SalesLine.Validate(
            "No.",
            ItemNo);

        SalesLine.Validate(
            "Location Code",
            ShopifySetup."BC Location Code");

        SalesLine.Validate(
            Quantity,
            Quantity);

        SalesLine.Validate(
            "Unit Price",
            UnitPrice);

        if DiscountPercent <> 0 then
            SalesLine.Validate(
                "Line Discount %",
                DiscountPercent);

        SalesLine.Insert(true);
    end;

    local procedure ProcessShippingLines(
        OrderObject: JsonObject;
        SalesHeader: Record "Sales Header";
        ShopifySetup: Record "Shopify Integration Setup";
        CurrencyCode: Code[10];
        var ShippingTotal: Decimal)
    var
        ShopifyClient: Codeunit "Shopify Client";
        ShippingObject: JsonObject;
        ShippingLine: JsonObject;
        ShippingArray: JsonArray;
        Token: JsonToken;
        ShippingAmount: Decimal;
        ShippingTitle: Text;
        LineNo: Integer;
        I: Integer;
    begin
        ShippingObject :=
            ShopifyClient.GetObject(
                OrderObject,
                'shippingLines');

        ShippingArray :=
            ShopifyClient.GetArray(
                ShippingObject,
                'nodes');

        if ShippingArray.Count() = 0 then
            exit;

        LineNo :=
            900000;

        for I := 0 to ShippingArray.Count() - 1 do begin
            ShippingArray.Get(
                I,
                Token);

            ShippingLine :=
                Token.AsObject();

            ShippingAmount :=
                GetMoneyAmount(
                    ShippingLine,
                    'discountedPriceSet',
                    CurrencyCode);

            if ShippingAmount > 0 then begin
                if ShopifySetup."BC Shipping Item No." = '' then
                    Error(
                        'Shopify order contains shipping amount %1 %2, but BC Shipping Item No. is not configured.',
                        ShippingAmount,
                        CurrencyCode);

                ShippingTitle :=
                    GetOptionalText(
                        ShippingLine,
                        'title');

                CreateShippingSalesLine(
                    SalesHeader,
                    ShopifySetup,
                    ShippingTitle,
                    ShippingAmount,
                    LineNo);

                LineNo +=
                    10000;

                ShippingTotal +=
                    ShippingAmount;
            end;
        end;
    end;

    local procedure CreateShippingSalesLine(
        SalesHeader: Record "Sales Header";
        ShopifySetup: Record "Shopify Integration Setup";
        ShippingTitle: Text;
        ShippingAmount: Decimal;
        LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        if not Item.Get(
            ShopifySetup."BC Shipping Item No.")
        then
            Error(
                'Shipping item %1 does not exist.',
                ShopifySetup."BC Shipping Item No.");

        if Item.Blocked then
            Error(
                'Shipping item %1 is blocked.',
                ShopifySetup."BC Shipping Item No.");

        SalesLine.Init();

        SalesLine.Validate(
            "Document Type",
            SalesHeader."Document Type");

        SalesLine.Validate(
            "Document No.",
            SalesHeader."No.");

        SalesLine.Validate(
            "Line No.",
            LineNo);

        SalesLine.Validate(
            Type,
            SalesLine.Type::Item);

        SalesLine.Validate(
            "No.",
            ShopifySetup."BC Shipping Item No.");

        SalesLine.Validate(
            "Location Code",
            ShopifySetup."BC Location Code");

        SalesLine.Validate(
            Quantity,
            1);

        SalesLine.Validate(
            "Unit Price",
            ShippingAmount);

        if ShippingTitle <> '' then
            SalesLine.Validate(
                Description,
                CopyStr(
                    ShippingTitle,
                    1,
                    MaxStrLen(
                        SalesLine.Description)));

        SalesLine.Insert(true);
    end;

    local procedure GetLineDiscountAmount(
        LineObject: JsonObject;
        CurrencyCode: Code[10]): Decimal
    var
        Token: JsonToken;
        AllocationsArray: JsonArray;
        AllocationObject: JsonObject;
        ResultAmount: Decimal;
        I: Integer;
    begin
        if not LineObject.Get(
            'discountAllocations',
            Token)
        then
            exit(0);

        if not Token.IsArray() then
            exit(0);

        AllocationsArray :=
            Token.AsArray();

        if AllocationsArray.Count() = 0 then
            exit(0);

        for I := 0 to AllocationsArray.Count() - 1 do begin
            AllocationsArray.Get(
                I,
                Token);

            AllocationObject :=
                Token.AsObject();

            ResultAmount +=
                GetMoneyAmount(
                    AllocationObject,
                    'allocatedAmountSet',
                    CurrencyCode);
        end;

        exit(
            ResultAmount);
    end;

    local procedure InsertImportRegistry(
        var ImportRecord: Record "Shopify Order Import";
        OrderObject: JsonObject;
        SalesHeader: Record "Sales Header";
        CurrencyCode: Code[10];
        ShopifyTotal: Decimal;
        BCTotal: Decimal;
        ShippingTotal: Decimal;
        TotalDiscount: Decimal;
        LineCount: Integer)
    var
        ShopifyOrderId: Text;
    begin
        ShopifyOrderId :=
            GetRequiredText(
                OrderObject,
                'id');

        ImportRecord.Init();

        ImportRecord."Shopify Order ID" :=
            CopyStr(
                ShopifyOrderId,
                1,
                MaxStrLen(
                    ImportRecord."Shopify Order ID"));

        ImportRecord."Shopify Order Name" :=
            CopyStr(
                GetRequiredText(
                    OrderObject,
                    'name'),
                1,
                MaxStrLen(
                    ImportRecord."Shopify Order Name"));

        ImportRecord."BC Order No." :=
            SalesHeader."No.";

        ImportRecord."Shopify Created At" :=
            GetDateTime(
                OrderObject,
                'createdAt');

        ImportRecord."Imported At" :=
            CurrentDateTime();

        ImportRecord."Financial Status" :=
            CopyStr(
                GetOptionalText(
                    OrderObject,
                    'displayFinancialStatus'),
                1,
                MaxStrLen(
                    ImportRecord."Financial Status"));

        ImportRecord."Fulfillment Status" :=
            CopyStr(
                GetOptionalText(
                    OrderObject,
                    'displayFulfillmentStatus'),
                1,
                MaxStrLen(
                    ImportRecord."Fulfillment Status"));

        ImportRecord."Currency Code" :=
            CurrencyCode;

        ImportRecord."Shopify Total" :=
            ShopifyTotal;

        ImportRecord."BC Total" :=
            BCTotal;

        ImportRecord."Total Difference" :=
            Round(
                BCTotal - ShopifyTotal,
                0.01);

        ImportRecord."Shipping Amount" :=
            ShippingTotal;

        ImportRecord."Discount Amount" :=
            TotalDiscount;

        ImportRecord."Line Count" :=
            LineCount;

        ImportRecord.Insert(true);
    end;

    local procedure ApplyCurrency(
        var SalesHeader: Record "Sales Header";
        CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            exit;

        GeneralLedgerSetup.Get();

        if CurrencyCode =
           GeneralLedgerSetup."LCY Code"
        then begin
            SalesHeader.Validate(
                "Currency Code",
                '');

            exit;
        end;

        if not Currency.Get(
            CurrencyCode)
        then
            Error(
                'Currency %1 is not configured in Business Central.',
                CurrencyCode);

        SalesHeader.Validate(
            "Currency Code",
            CurrencyCode);
    end;

    local procedure GetMoneyAmount(
        ParentObject: JsonObject;
        PropertyName: Text;
        ExpectedCurrency: Code[10]): Decimal
    var
        ShopifyClient: Codeunit "Shopify Client";
        MoneyBagObject: JsonObject;
        MoneyObject: JsonObject;
        AmountText: Text;
        CurrencyText: Text;
        Amount: Decimal;
    begin
        MoneyBagObject :=
            ShopifyClient.GetObject(
                ParentObject,
                PropertyName);

        MoneyObject :=
            ShopifyClient.GetObject(
                MoneyBagObject,
                'presentmentMoney');

        CurrencyText :=
            ShopifyClient.GetText(
                MoneyObject,
                'currencyCode');

        if (ExpectedCurrency <> '') and
           (CurrencyText <> ExpectedCurrency)
        then
            Error(
                'Currency mismatch. Expected %1 but Shopify returned %2.',
                ExpectedCurrency,
                CurrencyText);

        AmountText :=
            ShopifyClient.GetText(
                MoneyObject,
                'amount');

        if not Evaluate(
            Amount,
            AmountText,
            9)
        then
            Error(
                'Shopify amount %1 could not be converted to Decimal.',
                AmountText);

        exit(
            Amount);
    end;

    local procedure GetBCOrderNo(
        ShopifyOrderId: Text): Code[20]
    var
        ImportRecord: Record "Shopify Order Import";
    begin
        if ImportRecord.Get(
            ShopifyOrderId)
        then
            exit(
                ImportRecord."BC Order No.");

        exit('');
    end;

    local procedure IsCancelled(
        OrderObject: JsonObject): Boolean
    var
        Token: JsonToken;
        Value: JsonValue;
    begin
        if not OrderObject.Get(
            'cancelledAt',
            Token)
        then
            exit(false);

        if not Token.IsValue() then
            exit(false);

        Value :=
            Token.AsValue();

        exit(
            not Value.IsNull());
    end;

    local procedure GetRequiredText(
        ParentObject: JsonObject;
        PropertyName: Text): Text
    var
        Token: JsonToken;
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

    local procedure GetOptionalText(
        ParentObject: JsonObject;
        PropertyName: Text): Text
    var
        Token: JsonToken;
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

    local procedure GetInteger(
        ParentObject: JsonObject;
        PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if not ParentObject.Get(
            PropertyName,
            Token)
        then
            Error(
                'JSON property %1 was not found.',
                PropertyName);

        exit(
            Token.AsValue().AsInteger());
    end;

    local procedure GetBoolean(
        ParentObject: JsonObject;
        PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not ParentObject.Get(
            PropertyName,
            Token)
        then
            Error(
                'JSON property %1 was not found.',
                PropertyName);

        exit(
            Token.AsValue().AsBoolean());
    end;

    local procedure GetDateTime(
        ParentObject: JsonObject;
        PropertyName: Text): DateTime
    var
        Token: JsonToken;
    begin
        if not ParentObject.Get(
            PropertyName,
            Token)
        then
            Error(
                'JSON property %1 was not found.',
                PropertyName);

        exit(
            Token.AsValue().AsDateTime());
    end;
}