codeunit 50277 "Shopify Refund Mgt."
{
    procedure ImportRefundsForImportedOrders(
        ShowResultMessage: Boolean): Integer
    var
        ImportRecord: Record "Shopify Order Import";
        ImportedCount: Integer;
    begin
        ImportRecord.Reset();
        ImportRecord.SetFilter("Posted Invoice No.", '<>%1', '');

        if ImportRecord.FindSet() then
            repeat
                ImportedCount += ImportRefundsForOrder(ImportRecord, false);
            until ImportRecord.Next() = 0;

        if ShowResultMessage then
            Message(
                'Shopify refund import completed.\Imported or refreshed refunds: %1',
                ImportedCount);

        exit(ImportedCount);
    end;

    procedure ImportRefundsForOrder(
        ImportRecord: Record "Shopify Order Import";
        ShowResultMessage: Boolean): Integer
    var
        ShopifySetup: Record "Shopify Integration Setup";
        ShopifyClient: Codeunit "Shopify Client";
        Variables: JsonObject;
        ResponseJson: JsonObject;
        DataObject: JsonObject;
        OrderObject: JsonObject;
        RefundObject: JsonObject;
        RefundsArray: JsonArray;
        Token: JsonToken;
        QueryText: Text;
        ImportedCount: Integer;
        I: Integer;
    begin
        GetSetup(ShopifySetup);

        ImportRecord.TestField("Shopify Order ID");
        ImportRecord.TestField("Posted Invoice No.");

        Variables.Add('id', ImportRecord."Shopify Order ID");

        QueryText :=
            'query GetOrderRefunds($id: ID!) {' +
            ' order(id: $id) {' +
            '  id name' +
            '  refunds(first: 50) {' +
            '   id legacyResourceId createdAt processedAt note' +
            '   totalRefundedSet { presentmentMoney { amount currencyCode } }' +
            '   refundLineItems(first: 250) {' +
            '    nodes {' +
            '     id quantity restockType restocked' +
            '     location { id }' +
            '     lineItem { id sku }' +
            '     subtotalSet { presentmentMoney { amount currencyCode } }' +
            '     totalTaxSet { presentmentMoney { amount currencyCode } }' +
            '    }' +
            '   }' +
            '   refundShippingLines(first: 50) {' +
            '    nodes {' +
            '     id shippingLine { id title }' +
            '     subtotalAmountSet { presentmentMoney { amount currencyCode } }' +
            '     taxAmountSet { presentmentMoney { amount currencyCode } }' +
            '    }' +
            '   }' +
            '   orderAdjustments(first: 50) {' +
            '    nodes {' +
            '     id reason' +
            '     amountSet { presentmentMoney { amount currencyCode } }' +
            '     taxAmountSet { presentmentMoney { amount currencyCode } }' +
            '    }' +
            '   }' +
            '   transactions(first: 50) {' +
            '    nodes {' +
            '     id kind status' +
            '     amountSet { presentmentMoney { amount currencyCode } }' +
            '    }' +
            '   }' +
            '  }' +
            ' }' +
            '}';

        ShopifyClient.ExecuteGraphQL(
            QueryText,
            Variables,
            ResponseJson);

        DataObject := ShopifyClient.GetObject(ResponseJson, 'data');

        if not ShopifyClient.TryGetObject(
            DataObject,
            'order',
            OrderObject)
        then
            Error(
                'Shopify order %1 could not be found while importing refunds.',
                ImportRecord."Shopify Order Name");

        RefundsArray := ShopifyClient.GetArray(OrderObject, 'refunds');

        if RefundsArray.Count() > 0 then
            for I := 0 to RefundsArray.Count() - 1 do begin
                RefundsArray.Get(I, Token);
                RefundObject := Token.AsObject();

                if UpsertRefund(
                    ImportRecord,
                    RefundObject,
                    ShopifySetup)
                then
                    ImportedCount += 1;
            end;

        if ShowResultMessage then
            Message(
                'Shopify refund refresh completed for order %1.\Imported or refreshed refunds: %2',
                ImportRecord."Shopify Order Name",
                ImportedCount);

        exit(ImportedCount);
    end;

    procedure ProcessBackgroundRefundWork(
        ShowResultMessage: Boolean): Integer
    var
        ShopifySetup: Record "Shopify Integration Setup";
        ImportedCount: Integer;
        ProcessedCount: Integer;
    begin
        GetSetup(ShopifySetup);

        if ShopifySetup."Auto Import Shopify Refunds" then
            ImportedCount :=
                ImportRefundsForImportedOrders(false);

        if ShopifySetup."Auto Process Shopify Refunds" then
            ProcessedCount :=
                ProcessPendingRefunds(false);

        if ShowResultMessage then
            Message(
                'Shopify refund background work completed.\Refunds imported/refreshed: %1\Refunds processed: %2',
                ImportedCount,
                ProcessedCount);

        exit(ImportedCount + ProcessedCount);
    end;

    procedure ProcessPendingRefunds(
        ShowResultMessage: Boolean): Integer
    var
        RefundEntry: Record "Shopify Refund Entry";
        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        RefundEntry.SetRange(Status, RefundEntry.Status::Pending);

        if RefundEntry.FindSet() then
            repeat
                if ProcessRefund(RefundEntry, false) then
                    SuccessCount += 1
                else
                    ErrorCount += 1;
            until RefundEntry.Next() = 0;

        if ShowResultMessage then
            Message(
                'Shopify refund processing completed.\Successful: %1\Not completed: %2',
                SuccessCount,
                ErrorCount);

        exit(SuccessCount);
    end;

    procedure RetryFailedRefunds()
    var
        RefundEntry: Record "Shopify Refund Entry";
        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        RefundEntry.SetRange(Status, RefundEntry.Status::Error);

        if not RefundEntry.FindSet() then begin
            Message('There are no failed Shopify refunds to retry.');
            exit;
        end;

        repeat
            RefundEntry.Status := RefundEntry.Status::Pending;
            Clear(RefundEntry."Refund Error");
            RefundEntry.Modify(false);

            if ProcessRefund(RefundEntry, false) then
                SuccessCount += 1
            else
                ErrorCount += 1;
        until RefundEntry.Next() = 0;

        Message(
            'Shopify refund retry completed.\Successful: %1\Failed or waiting: %2',
            SuccessCount,
            ErrorCount);
    end;

    procedure ProcessRefund(
        var RefundEntry: Record "Shopify Refund Entry";
        ShowResultMessage: Boolean): Boolean
    var
        PaymentEntry: Record "Shopify Payment Entry";
        Runner: Codeunit "Shopify Refund Runner";
        SyncLogMgt: Codeunit "Shopify Sync Log Mgt.";
        RefundId: Text;
        ErrorText: Text;
        StartedAt: DateTime;
        PreviouslyProcessedRefundAmount: Decimal;
    begin
        if RefundEntry.Status = RefundEntry.Status::Success then begin
            if ShowResultMessage then
                Message(
                    'Shopify refund for order %1 has already been processed.',
                    RefundEntry."Shopify Order Name");
            exit(true);
        end;

        if RefundEntry.Status = RefundEntry.Status::"Manual Review" then begin
            if ShowResultMessage then
                Message(
                    'Shopify refund requires manual review.\%1',
                    RefundEntry."Manual Review Reason");
            exit(false);
        end;

        if RefundEntry.Status = RefundEntry.Status::Skipped then begin
            if ShowResultMessage then
                Message(
                    'Shopify refund is intentionally skipped.\%1',
                    RefundEntry."Result Message");
            exit(false);
        end;

        if not PaymentEntry.Get(RefundEntry."Shopify Order ID") then begin
            SetWaitingForPayment(
                RefundEntry,
                'The original Shopify payment has not yet been recorded in Business Central.');

            if ShowResultMessage then
                Message('%1', RefundEntry."Result Message");

            exit(false);
        end;

        if PaymentEntry.Status <> PaymentEntry.Status::Success then begin
            SetWaitingForPayment(
                RefundEntry,
                StrSubstNo(
                    'The original Shopify payment is not completed. Current payment status: %1.',
                    Format(PaymentEntry.Status)));

            if ShowResultMessage then
                Message('%1', RefundEntry."Result Message");

            exit(false);
        end;

        if (PaymentEntry."Currency Code" <> '') and
           (RefundEntry."Currency Code" <> '') and
           (PaymentEntry."Currency Code" <> RefundEntry."Currency Code")
        then begin
            SetManualReview(
                RefundEntry,
                StrSubstNo(
                    'Refund currency %1 does not match the recorded Shopify payment currency %2.',
                    RefundEntry."Currency Code",
                    PaymentEntry."Currency Code"));

            if ShowResultMessage then
                Message('%1', RefundEntry."Manual Review Reason");

            exit(false);
        end;

        PreviouslyProcessedRefundAmount :=
            GetPreviouslyProcessedRefundAmount(
                RefundEntry."Shopify Refund ID",
                RefundEntry."Shopify Order ID");

        if (PreviouslyProcessedRefundAmount + RefundEntry."Refund Total") >
           (PaymentEntry.Amount + 0.02)
        then begin
            SetManualReview(
                RefundEntry,
                StrSubstNo(
                    'Automatic refund processing would exceed the original recorded Shopify payment. Payment: %1 %2. Previously processed refunds: %3. Current refund: %4.',
                    PaymentEntry.Amount,
                    PaymentEntry."Currency Code",
                    PreviouslyProcessedRefundAmount,
                    RefundEntry."Refund Total"));

            if ShowResultMessage then
                Message('%1', RefundEntry."Manual Review Reason");

            exit(false);
        end;

        RefundId := RefundEntry."Shopify Refund ID";
        RefundEntry.Status := RefundEntry.Status::Pending;
        RefundEntry."Attempt Count" += 1;
        RefundEntry."Last Attempt At" := CurrentDateTime();
        Clear(RefundEntry."Refund Error");
        RefundEntry.Modify(false);

        StartedAt := CurrentDateTime();

        Commit();
        ClearLastError();

        if Runner.Run(RefundEntry) then begin
            RefundEntry.Get(RefundId);

            SyncLogMgt.LogSuccess(
                "Shopify Sync Direction"::Inbound,
                "Shopify Sync Entity"::Refund,
                RefundEntry."Posted Credit Memo No.",
                RefundEntry."Shopify Refund ID",
                StrSubstNo(
                    'Shopify refund was processed. Refund total: %1 %2. Posted credit memo: %3. Customer refund document: %4.',
                    RefundEntry."Refund Total",
                    RefundEntry."Currency Code",
                    RefundEntry."Posted Credit Memo No.",
                    RefundEntry."Refund Journal Document No."),
                CurrentDateTime() - StartedAt);

            if ShowResultMessage then
                Message(
                    'Shopify refund processed successfully.\Posted credit memo: %1\Customer refund document: %2\Amount: %3 %4',
                    RefundEntry."Posted Credit Memo No.",
                    RefundEntry."Refund Journal Document No.",
                    RefundEntry."Refund Total",
                    RefundEntry."Currency Code");

            exit(true);
        end;

        ErrorText := GetLastErrorText();
        if ErrorText = '' then
            ErrorText := 'Unknown error while processing Shopify refund.';

        RefundEntry.Get(RefundId);
        RefundEntry.Status := RefundEntry.Status::Error;
        RefundEntry."Refund Error" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(RefundEntry."Refund Error"));
        RefundEntry."Result Message" :=
            CopyStr(
                'Shopify refund processing failed.',
                1,
                MaxStrLen(RefundEntry."Result Message"));
        RefundEntry.Modify(false);

        SyncLogMgt.LogError(
            "Shopify Sync Direction"::Inbound,
            "Shopify Sync Entity"::Refund,
            RefundEntry."Posted Credit Memo No.",
            RefundEntry."Shopify Refund ID",
            ErrorText,
            CurrentDateTime() - StartedAt);

        if ShowResultMessage then
            Message(
                'Shopify refund processing failed.\%1',
                ErrorText);

        exit(false);
    end;

    procedure ProcessRefundCore(
        var RefundEntry: Record "Shopify Refund Entry")
    var
        ImportRecord: Record "Shopify Order Import";
        ShopifySetup: Record "Shopify Integration Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CreditMemoCustLedgerEntry: Record "Cust. Ledger Entry";
        RefundCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        GetSetup(ShopifySetup);

        if not ImportRecord.Get(RefundEntry."Shopify Order ID") then
            Error(
                'Shopify Order Import %1 does not exist.',
                RefundEntry."Shopify Order ID");

        ImportRecord.TestField("Posted Invoice No.");
        ShopifySetup.TestField("Shopify Clearing G/L Acc. No.");
        ShopifySetup.TestField("Payment Journal Template Name");
        ShopifySetup.TestField("Payment Journal Batch Name");

        if FindExistingPostedCreditMemo(
            RefundEntry,
            SalesCrMemoHeader)
        then begin
            RefundEntry."Posted Credit Memo No." := SalesCrMemoHeader."No.";
            Clear(RefundEntry."BC Credit Memo No.");
            RefundEntry.Modify(false);
        end else begin
            CreateAndPostCreditMemo(
                RefundEntry,
                ImportRecord,
                ShopifySetup,
                SalesCrMemoHeader);
        end;

        GetCreditMemoCustLedgerEntry(
            SalesCrMemoHeader,
            CreditMemoCustLedgerEntry);

        RefundEntry."Credit Memo Ledger Entry No." :=
            CreditMemoCustLedgerEntry."Entry No.";
        RefundEntry.Modify(false);

        if FindExistingRefundCustLedgerEntry(
            RefundEntry,
            SalesCrMemoHeader."Bill-to Customer No.",
            RefundCustLedgerEntry)
        then begin
            RefundEntry."Refund Cust. Ledger Entry No." :=
                RefundCustLedgerEntry."Entry No.";
        end else begin
            PostCustomerRefundAgainstClearing(
                RefundEntry,
                SalesCrMemoHeader,
                ShopifySetup,
                CreditMemoCustLedgerEntry,
                RefundCustLedgerEntry);

            RefundEntry."Refund Cust. Ledger Entry No." :=
                RefundCustLedgerEntry."Entry No.";
        end;

        CreditMemoCustLedgerEntry.Get(
            RefundEntry."Credit Memo Ledger Entry No.");
        CreditMemoCustLedgerEntry.CalcFields("Remaining Amount");

        if CreditMemoCustLedgerEntry.Open and
           (Abs(CreditMemoCustLedgerEntry."Remaining Amount") > 0.02)
        then
            Error(
                'Posted credit memo %1 remains open with amount %2 after Shopify refund posting.',
                SalesCrMemoHeader."No.",
                CreditMemoCustLedgerEntry."Remaining Amount");

        RefundEntry.Status := RefundEntry.Status::Success;
        RefundEntry."Completed At" := CurrentDateTime();
        RefundEntry."Result Message" :=
            CopyStr(
                'Posted sales credit memo and customer refund were created successfully.',
                1,
                MaxStrLen(RefundEntry."Result Message"));
        Clear(RefundEntry."Refund Error");
        RefundEntry.Modify(false);
    end;

    procedure OpenPostedCreditMemo(
        RefundEntry: Record "Shopify Refund Entry")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        RefundEntry.TestField("Posted Credit Memo No.");

        if not SalesCrMemoHeader.Get(
            RefundEntry."Posted Credit Memo No.")
        then
            Error(
                'Posted Sales Credit Memo %1 does not exist.',
                RefundEntry."Posted Credit Memo No.");

        Page.Run(
            Page::"Posted Sales Credit Memo",
            SalesCrMemoHeader);
    end;

    procedure OpenRefundLedgerEntry(
        RefundEntry: Record "Shopify Refund Entry")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if RefundEntry."Refund Cust. Ledger Entry No." = 0 then
            Error('Customer refund ledger entry is not available.');

        CustLedgerEntry.SetRange(
            "Entry No.",
            RefundEntry."Refund Cust. Ledger Entry No.");

        Page.Run(
            Page::"Customer Ledger Entries",
            CustLedgerEntry);
    end;

    local procedure UpsertRefund(
        ImportRecord: Record "Shopify Order Import";
        RefundObject: JsonObject;
        ShopifySetup: Record "Shopify Integration Setup"): Boolean
    var
        RefundEntry: Record "Shopify Refund Entry";
        RefundId: Text;
        RefundJson: Text;
        CurrencyCode: Code[10];
        ProcessedAt: DateTime;
        IsNew: Boolean;
        ManualReason: Text;
        TransactionWaiting: Boolean;
    begin
        RefundId := GetRequiredText(RefundObject, 'id');
        ProcessedAt := GetDateTime(RefundObject, 'processedAt');

        if (ShopifySetup."Import Refunds From" <> 0DT) and
           (ProcessedAt < ShopifySetup."Import Refunds From")
        then
            exit(false);

        IsNew := not RefundEntry.Get(RefundId);

        if not IsNew then
            if RefundEntry.Status = RefundEntry.Status::Success then
                exit(false);

        if IsNew then begin
            RefundEntry.Init();
            RefundEntry."Shopify Refund ID" :=
                CopyStr(RefundId, 1, MaxStrLen(RefundEntry."Shopify Refund ID"));
        end;

        CurrencyCode :=
            CopyStr(
                GetMoneyCurrency(
                    RefundObject,
                    'totalRefundedSet'),
                1,
                MaxStrLen(CurrencyCode));

        RefundEntry."Legacy Resource ID" :=
            CopyStr(
                GetRequiredText(RefundObject, 'legacyResourceId'),
                1,
                MaxStrLen(RefundEntry."Legacy Resource ID"));
        RefundEntry."Shopify Order ID" := ImportRecord."Shopify Order ID";
        RefundEntry."Shopify Order Name" := ImportRecord."Shopify Order Name";
        RefundEntry."Processed At" := ProcessedAt;
        RefundEntry."Currency Code" := CurrencyCode;
        RefundEntry."Refund Total" :=
            GetMoneyAmount(
                RefundObject,
                'totalRefundedSet',
                CurrencyCode);

        RefundObject.WriteTo(RefundJson);
        RefundEntry.SetRawRefundJson(RefundJson);

        if IsNew then
            RefundEntry.Insert(true)
        else
            RefundEntry.Modify(true);

        ParseRefundComponents(
            RefundEntry,
            ImportRecord,
            RefundObject,
            ShopifySetup,
            ManualReason,
            TransactionWaiting);

        if ManualReason <> '' then begin
            RefundEntry.Status := RefundEntry.Status::"Manual Review";
            RefundEntry."Manual Review Reason" :=
                CopyStr(
                    ManualReason,
                    1,
                    MaxStrLen(RefundEntry."Manual Review Reason"));
            RefundEntry."Result Message" :=
                CopyStr(
                    'Refund was imported but requires manual review before Business Central posting.',
                    1,
                    MaxStrLen(RefundEntry."Result Message"));
        end else
            if TransactionWaiting then begin
                RefundEntry.Status := RefundEntry.Status::Waiting;
                Clear(RefundEntry."Manual Review Reason");
                RefundEntry."Result Message" :=
                    CopyStr(
                        'Refund exists in Shopify, but a successful refund transaction has not yet been confirmed.',
                        1,
                        MaxStrLen(RefundEntry."Result Message"));
            end else begin
                RefundEntry.Status := RefundEntry.Status::Pending;
                Clear(RefundEntry."Manual Review Reason");
                RefundEntry."Result Message" :=
                    CopyStr(
                        'Refund is ready for Business Central processing.',
                        1,
                        MaxStrLen(RefundEntry."Result Message"));
            end;

        Clear(RefundEntry."Refund Error");
        RefundEntry.Modify(true);

        exit(true);
    end;

    local procedure ParseRefundComponents(
        var RefundEntry: Record "Shopify Refund Entry";
        ImportRecord: Record "Shopify Order Import";
        RefundObject: JsonObject;
        ShopifySetup: Record "Shopify Integration Setup";
        var ManualReason: Text;
        var TransactionWaiting: Boolean)
    var
        RefundLine: Record "Shopify Refund Line";
        ShopifyClient: Codeunit "Shopify Client";
        RefundLineItemsObject: JsonObject;
        RefundShippingObject: JsonObject;
        AdjustmentsObject: JsonObject;
        TransactionsObject: JsonObject;
        Nodes: JsonArray;
        Token: JsonToken;
        NodeObject: JsonObject;
        LineItemObject: JsonObject;
        LocationObject: JsonObject;
        RestockType: Text;
        LocationId: Text;
        CurrencyCode: Code[10];
        SubtotalAmount: Decimal;
        TaxAmount: Decimal;
        AdjustmentAmount: Decimal;
        AdjustmentTax: Decimal;
        SuccessfulTransactionTotal: Decimal;
        LineRefundTotal: Decimal;
        ShippingRefundTotal: Decimal;
        OrderAdjustmentTotal: Decimal;
        LineNo: Integer;
        I: Integer;
        TransactionKind: Text;
        TransactionStatus: Text;
    begin
        CurrencyCode := RefundEntry."Currency Code";

        RefundLine.SetRange("Shopify Refund ID", RefundEntry."Shopify Refund ID");
        RefundLine.DeleteAll(true);

        RefundLineItemsObject := ShopifyClient.GetObject(RefundObject, 'refundLineItems');
        Nodes := ShopifyClient.GetArray(RefundLineItemsObject, 'nodes');
        LineNo := 0;

        if Nodes.Count() > 0 then
            for I := 0 to Nodes.Count() - 1 do begin
                Nodes.Get(I, Token);
                NodeObject := Token.AsObject();
                LineItemObject := ShopifyClient.GetObject(NodeObject, 'lineItem');

                RestockType := UpperCase(ShopifyClient.GetOptionalText(NodeObject, 'restockType'));
                LocationId := '';
                if ShopifyClient.TryGetObject(NodeObject, 'location', LocationObject) then
                    LocationId := ShopifyClient.GetOptionalText(LocationObject, 'id');

                SubtotalAmount :=
                    GetMoneyAmount(
                        NodeObject,
                        'subtotalSet',
                        CurrencyCode);
                TaxAmount :=
                    GetMoneyAmount(
                        NodeObject,
                        'totalTaxSet',
                        CurrencyCode);

                LineNo += 10000;
                RefundLine.Init();
                RefundLine."Shopify Refund ID" := RefundEntry."Shopify Refund ID";
                RefundLine."Line No." := LineNo;
                RefundLine."Shopify Refund Line ID" :=
                    CopyStr(
                        ShopifyClient.GetText(NodeObject, 'id'),
                        1,
                        MaxStrLen(RefundLine."Shopify Refund Line ID"));
                RefundLine."Shopify Line Item ID" :=
                    CopyStr(
                        ShopifyClient.GetText(LineItemObject, 'id'),
                        1,
                        MaxStrLen(RefundLine."Shopify Line Item ID"));
                RefundLine."Shopify SKU" :=
                    CopyStr(
                        ShopifyClient.GetOptionalText(LineItemObject, 'sku'),
                        1,
                        MaxStrLen(RefundLine."Shopify SKU"));
                RefundLine.Quantity := GetInteger(NodeObject, 'quantity');
                RefundLine."Restock Type" :=
                    CopyStr(RestockType, 1, MaxStrLen(RefundLine."Restock Type"));
                RefundLine."Shopify Location ID" :=
                    CopyStr(LocationId, 1, MaxStrLen(RefundLine."Shopify Location ID"));
                RefundLine."Subtotal Amount" := SubtotalAmount;
                RefundLine."Tax Amount" := TaxAmount;
                RefundLine."Total Amount" := SubtotalAmount + TaxAmount;

                ResolveLineMappingForRefund(
                    ImportRecord,
                    RefundLine);

                RefundLine.Insert(true);

                LineRefundTotal += RefundLine."Total Amount";

                if (RestockType <> 'RETURN') and
                   (RestockType <> 'LEGACY_RESTOCK')
                then
                    AppendManualReason(
                        ManualReason,
                        StrSubstNo(
                            'Refund line %1 uses restock type %2. Automatic Business Central credit memo processing currently supports returned/restocked item lines only.',
                            RefundLine."Shopify SKU",
                            RestockType));

                if ((RestockType = 'RETURN') or
                    (RestockType = 'LEGACY_RESTOCK')) and
                   (LocationId <> '') and
                   (ShopifySetup."Shopify Location ID" <> '') and
                   (LocationId <> ShopifySetup."Shopify Location ID")
                then
                    AppendManualReason(
                        ManualReason,
                        StrSubstNo(
                            'Refund line %1 is restocked to Shopify location %2, while the integration is configured for %3.',
                            RefundLine."Shopify SKU",
                            LocationId,
                            ShopifySetup."Shopify Location ID"));

                if RefundLine."BC Item No." = '' then
                    AppendManualReason(
                        ManualReason,
                        StrSubstNo(
                            'Shopify refund line %1 could not be mapped to a unique posted Business Central invoice line.',
                            RefundLine."Shopify SKU"));
            end;

        RefundShippingObject := ShopifyClient.GetObject(RefundObject, 'refundShippingLines');
        Nodes := ShopifyClient.GetArray(RefundShippingObject, 'nodes');
        if Nodes.Count() > 0 then
            for I := 0 to Nodes.Count() - 1 do begin
                Nodes.Get(I, Token);
                NodeObject := Token.AsObject();

                SubtotalAmount :=
                    GetMoneyAmount(
                        NodeObject,
                        'subtotalAmountSet',
                        CurrencyCode);
                TaxAmount :=
                    GetMoneyAmount(
                        NodeObject,
                        'taxAmountSet',
                        CurrencyCode);

                ShippingRefundTotal += SubtotalAmount + TaxAmount;
            end;

        AdjustmentsObject := ShopifyClient.GetObject(RefundObject, 'orderAdjustments');
        Nodes := ShopifyClient.GetArray(AdjustmentsObject, 'nodes');
        if Nodes.Count() > 0 then
            for I := 0 to Nodes.Count() - 1 do begin
                Nodes.Get(I, Token);
                NodeObject := Token.AsObject();

                AdjustmentAmount :=
                    GetMoneyAmount(
                        NodeObject,
                        'amountSet',
                        CurrencyCode);
                AdjustmentTax :=
                    GetMoneyAmount(
                        NodeObject,
                        'taxAmountSet',
                        CurrencyCode);

                OrderAdjustmentTotal += AdjustmentAmount + AdjustmentTax;
            end;

        if Abs(OrderAdjustmentTotal) > 0.02 then
            AppendManualReason(
                ManualReason,
                StrSubstNo(
                    'The Shopify refund contains order adjustments totaling %1 %2. Automatic posting is intentionally blocked until adjustment accounting is configured.',
                    OrderAdjustmentTotal,
                    CurrencyCode));

        TransactionsObject := ShopifyClient.GetObject(RefundObject, 'transactions');
        Nodes := ShopifyClient.GetArray(TransactionsObject, 'nodes');
        if Nodes.Count() > 0 then
            for I := 0 to Nodes.Count() - 1 do begin
                Nodes.Get(I, Token);
                NodeObject := Token.AsObject();

                TransactionKind := UpperCase(ShopifyClient.GetOptionalText(NodeObject, 'kind'));
                TransactionStatus := UpperCase(ShopifyClient.GetOptionalText(NodeObject, 'status'));

                if (TransactionKind = 'REFUND') and
                   (TransactionStatus = 'SUCCESS')
                then
                    SuccessfulTransactionTotal +=
                        GetMoneyAmount(
                            NodeObject,
                            'amountSet',
                            CurrencyCode);
            end;

        RefundEntry."Line Refund Amount" := LineRefundTotal;
        RefundEntry."Shipping Refund Amount" := ShippingRefundTotal;
        RefundEntry."Order Adjustment Amount" := OrderAdjustmentTotal;
        RefundEntry."Supported Component Total" :=
            LineRefundTotal + ShippingRefundTotal;
        RefundEntry."Successful Transaction Total" :=
            SuccessfulTransactionTotal;
        RefundEntry."Refund Line Count" := LineNo div 10000;

        if (RefundEntry."Refund Line Count" = 0) and
           (Abs(ShippingRefundTotal) <= 0.02)
        then
            AppendManualReason(
                ManualReason,
                'The refund does not contain supported product or shipping refund components.');

        if Abs(
            Round(
                RefundEntry."Supported Component Total" -
                RefundEntry."Refund Total",
                0.01)) > 0.02
        then
            AppendManualReason(
                ManualReason,
                StrSubstNo(
                    'Supported refund components total %1 %2, but Shopify refund total is %3 %2. Duties, additional fees, adjustments, or other refund components require manual review.',
                    RefundEntry."Supported Component Total",
                    CurrencyCode,
                    RefundEntry."Refund Total"));

        TransactionWaiting :=
            Abs(
                Round(
                    SuccessfulTransactionTotal -
                    RefundEntry."Refund Total",
                    0.01)) > 0.02;
    end;

    local procedure ResolveLineMappingForRefund(
        ImportRecord: Record "Shopify Order Import";
        var RefundLine: Record "Shopify Refund Line")
    var
        LineMapping: Record "Shopify Order Line Mapping";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CandidateCount: Integer;
    begin
        if LineMapping.Get(
            ImportRecord."Shopify Order ID",
            RefundLine."Shopify Line Item ID")
        then begin
            EnsurePostedInvoiceLine(
                ImportRecord,
                LineMapping);

            RefundLine."BC Item No." := LineMapping."BC Item No.";
            RefundLine."Posted Invoice No." := LineMapping."Posted Invoice No.";
            RefundLine."Posted Invoice Line No." := LineMapping."Posted Invoice Line No.";
            exit;
        end;

        if RefundLine."Shopify SKU" = '' then
            exit;

        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", ImportRecord."Posted Invoice No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetRange("No.", CopyStr(RefundLine."Shopify SKU", 1, MaxStrLen(SalesInvoiceLine."No.")));

        CandidateCount := SalesInvoiceLine.Count();
        if CandidateCount <> 1 then
            exit;

        if not SalesInvoiceLine.FindFirst() then
            exit;

        RefundLine."BC Item No." := SalesInvoiceLine."No.";
        RefundLine."Posted Invoice No." := SalesInvoiceLine."Document No.";
        RefundLine."Posted Invoice Line No." := SalesInvoiceLine."Line No.";

        LineMapping.Init();
        LineMapping."Shopify Order ID" := ImportRecord."Shopify Order ID";
        LineMapping."Shopify Line Item ID" := RefundLine."Shopify Line Item ID";
        LineMapping."Shopify Order Name" := ImportRecord."Shopify Order Name";
        LineMapping."Shopify SKU" := RefundLine."Shopify SKU";
        LineMapping."BC Order No." := SalesInvoiceLine."Order No.";
        LineMapping."BC Order Line No." := SalesInvoiceLine."Order Line No.";
        LineMapping."BC Item No." := SalesInvoiceLine."No.";
        LineMapping."Original Quantity" := SalesInvoiceLine.Quantity;
        LineMapping."Original Unit Price" := SalesInvoiceLine."Unit Price";
        LineMapping."Original Discount Amount" := SalesInvoiceLine."Line Discount Amount";
        LineMapping."Posted Invoice No." := SalesInvoiceLine."Document No.";
        LineMapping."Posted Invoice Line No." := SalesInvoiceLine."Line No.";
        LineMapping."Created At" := CurrentDateTime();
        LineMapping."Updated At" := CurrentDateTime();
        LineMapping.Insert(true);
    end;

    local procedure EnsurePostedInvoiceLine(
        ImportRecord: Record "Shopify Order Import";
        var LineMapping: Record "Shopify Order Line Mapping")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        if (LineMapping."Posted Invoice No." <> '') and
           (LineMapping."Posted Invoice Line No." <> 0)
        then
            exit;

        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", ImportRecord."Posted Invoice No.");
        SalesInvoiceLine.SetRange("Order No.", LineMapping."BC Order No.");
        SalesInvoiceLine.SetRange("Order Line No.", LineMapping."BC Order Line No.");

        if not SalesInvoiceLine.FindFirst() then
            exit;

        LineMapping."Posted Invoice No." := SalesInvoiceLine."Document No.";
        LineMapping."Posted Invoice Line No." := SalesInvoiceLine."Line No.";
        LineMapping."Updated At" := CurrentDateTime();
        LineMapping.Modify(true);
    end;

    local procedure CreateAndPostCreditMemo(
        var RefundEntry: Record "Shopify Refund Entry";
        ImportRecord: Record "Shopify Order Import";
        ShopifySetup: Record "Shopify Integration Setup";
        var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        ExistingCreditMemo: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
        RefundReference: Code[35];
        CreditMemoNo: Code[20];
    begin
        if not SalesInvoiceHeader.Get(ImportRecord."Posted Invoice No.") then
            Error(
                'Posted Sales Invoice %1 does not exist.',
                ImportRecord."Posted Invoice No.");

        RefundReference := GetRefundReference(RefundEntry);

        ExistingCreditMemo.Reset();
        ExistingCreditMemo.SetRange("Document Type", ExistingCreditMemo."Document Type"::"Credit Memo");
        ExistingCreditMemo.SetRange("External Document No.", RefundReference);
        if ExistingCreditMemo.FindFirst() then
            ExistingCreditMemo.Delete(true);

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader."No." := '';
        SalesHeader.Insert(true);

        SalesHeader.Validate("Sell-to Customer No.", SalesInvoiceHeader."Sell-to Customer No.");
        if SalesInvoiceHeader."Location Code" <> '' then
            SalesHeader.Validate(
                "Location Code",
                SalesInvoiceHeader."Location Code")
        else
            SalesHeader.Validate(
                "Location Code",
                ShopifySetup."BC Location Code");
        SalesHeader.Validate("Currency Code", SalesInvoiceHeader."Currency Code");
        SalesHeader.Validate("Prices Including VAT", SalesInvoiceHeader."Prices Including VAT");
        SalesHeader.Validate("Posting Date", GetRefundPostingDate(RefundEntry));
        SalesHeader.Validate("Document Date", GetRefundPostingDate(RefundEntry));
        SalesHeader.Validate("External Document No.", RefundReference);
        SalesHeader."Your Reference" :=
            CopyStr(
                StrSubstNo('Shopify refund %1', RefundEntry."Shopify Order Name"),
                1,
                MaxStrLen(SalesHeader."Your Reference"));
        SalesHeader.Modify(true);

        CreateRefundCreditMemoLines(
            RefundEntry,
            ImportRecord,
            ShopifySetup,
            SalesHeader,
            SalesInvoiceHeader);

        SalesHeader.CalcFields("Amount Including VAT");

        if Abs(
            Round(
                SalesHeader."Amount Including VAT" -
                RefundEntry."Refund Total",
                0.01)) > 0.02
        then
            Error(
                'Refund credit memo total mismatch. Shopify refund total: %1 %2. Business Central credit memo total: %3 %2.',
                RefundEntry."Refund Total",
                RefundEntry."Currency Code",
                SalesHeader."Amount Including VAT");

        CreditMemoNo := SalesHeader."No.";
        RefundEntry."BC Credit Memo No." := CreditMemoNo;
        RefundEntry.Modify(false);

        SalesPost.Run(SalesHeader);

        SalesCrMemoHeader.Reset();
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", CreditMemoNo);
        SalesCrMemoHeader.SetRange("External Document No.", RefundReference);

        if not SalesCrMemoHeader.FindLast() then
            Error(
                'Posted Sales Credit Memo for Shopify refund %1 could not be found after posting.',
                RefundEntry."Shopify Refund ID");

        RefundEntry."Posted Credit Memo No." := SalesCrMemoHeader."No.";
        Clear(RefundEntry."BC Credit Memo No.");
        RefundEntry.Modify(false);
    end;

    local procedure CreateRefundCreditMemoLines(
        RefundEntry: Record "Shopify Refund Entry";
        ImportRecord: Record "Shopify Order Import";
        ShopifySetup: Record "Shopify Integration Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        RefundLine: Record "Shopify Refund Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        Item: Record Item;
        ShippingSubtotalExclVAT: Decimal;
        ShippingUnitPrice: Decimal;
        PreviouslyRefundedQuantity: Decimal;
        OriginalShippingAmount: Decimal;
        PreviouslyRefundedShippingAmount: Decimal;
        LineNo: Integer;
    begin
        RefundLine.SetRange("Shopify Refund ID", RefundEntry."Shopify Refund ID");

        if RefundLine.FindSet() then
            repeat
                if (UpperCase(RefundLine."Restock Type") <> 'RETURN') and
                   (UpperCase(RefundLine."Restock Type") <> 'LEGACY_RESTOCK')
                then
                    Error(
                        'Refund line %1 has unsupported automatic restock type %2.',
                        RefundLine."Shopify SKU",
                        RefundLine."Restock Type");

                if (RefundLine."Posted Invoice No." = '') or
                   (RefundLine."Posted Invoice Line No." = 0)
                then
                    Error(
                        'Refund line %1 is not mapped to a posted Business Central invoice line.',
                        RefundLine."Shopify SKU");

                if not SalesInvoiceLine.Get(
                    RefundLine."Posted Invoice No.",
                    RefundLine."Posted Invoice Line No.")
                then
                    Error(
                        'Posted invoice line %1/%2 does not exist.',
                        RefundLine."Posted Invoice No.",
                        RefundLine."Posted Invoice Line No.");

                PreviouslyRefundedQuantity :=
                    GetPreviouslyProcessedRefundQuantity(
                        RefundEntry."Shopify Refund ID",
                        RefundLine."Shopify Line Item ID");

                if (PreviouslyRefundedQuantity + RefundLine.Quantity) >
                   SalesInvoiceLine.Quantity
                then
                    Error(
                        'Refund quantity would exceed the originally invoiced quantity for item %1. Invoiced: %2. Previously processed Shopify refunds: %3. Current refund: %4.',
                        SalesInvoiceLine."No.",
                        SalesInvoiceLine.Quantity,
                        PreviouslyRefundedQuantity,
                        RefundLine.Quantity);

                LineNo += 10000;
                SalesLine.Init();
                SalesLine.Validate("Document Type", SalesHeader."Document Type");
                SalesLine.Validate("Document No.", SalesHeader."No.");
                SalesLine.Validate("Line No.", LineNo);
                SalesLine.Validate(Type, SalesLine.Type::Item);
                SalesLine.Validate("No.", SalesInvoiceLine."No.");

                if SalesInvoiceLine."Variant Code" <> '' then
                    SalesLine.Validate("Variant Code", SalesInvoiceLine."Variant Code");

                if SalesInvoiceLine."Unit of Measure Code" <> '' then
                    SalesLine.Validate("Unit of Measure Code", SalesInvoiceLine."Unit of Measure Code");

                if SalesInvoiceLine."Location Code" <> '' then
                    SalesLine.Validate(
                        "Location Code",
                        SalesInvoiceLine."Location Code")
                else
                    SalesLine.Validate(
                        "Location Code",
                        ShopifySetup."BC Location Code");
                SalesLine.Validate(Quantity, RefundLine.Quantity);
                SalesLine.Validate("Unit Price", SalesInvoiceLine."Unit Price");

                if SalesInvoiceLine."Line Discount %" <> 0 then
                    SalesLine.Validate("Line Discount %", SalesInvoiceLine."Line Discount %");

                if Item.Get(SalesInvoiceLine."No.") and
                   (Item.Type = Item.Type::Inventory)
                then begin
                    if (SalesInvoiceLine."Shipment No." = '') or
                       (SalesInvoiceLine."Shipment Line No." = 0)
                    then
                        Error(
                            'Exact cost reversal cannot be established for refunded inventory item %1 because the posted invoice line has no shipment reference.',
                            SalesInvoiceLine."No.");

                    if not SalesShipmentLine.Get(
                        SalesInvoiceLine."Shipment No.",
                        SalesInvoiceLine."Shipment Line No.")
                    then
                        Error(
                            'Posted shipment line %1/%2 for refunded item %3 does not exist.',
                            SalesInvoiceLine."Shipment No.",
                            SalesInvoiceLine."Shipment Line No.",
                            SalesInvoiceLine."No.");

                    if SalesShipmentLine."Item Shpt. Entry No." = 0 then
                        Error(
                            'Posted shipment line %1/%2 has no Item Shipment Entry number required for exact cost reversal.',
                            SalesInvoiceLine."Shipment No.",
                            SalesInvoiceLine."Shipment Line No.");

                    SalesLine.Validate(
                        "Appl.-from Item Entry",
                        SalesShipmentLine."Item Shpt. Entry No.");
                end;

                SalesLine.Insert(true);
            until RefundLine.Next() = 0;

        if RefundEntry."Shipping Refund Amount" > 0.02 then begin
            ShopifySetup.TestField("BC Shipping Item No.");

            OriginalShippingAmount :=
                GetOriginalInvoicedShippingAmount(
                    ImportRecord."Posted Invoice No.",
                    ShopifySetup."BC Shipping Item No.");

            PreviouslyRefundedShippingAmount :=
                GetPreviouslyProcessedShippingRefundAmount(
                    RefundEntry."Shopify Refund ID",
                    RefundEntry."Shopify Order ID");

            if OriginalShippingAmount <= 0.02 then
                Error(
                    'Shopify refund includes shipping, but posted Business Central invoice %1 does not contain the configured shipping item %2.',
                    ImportRecord."Posted Invoice No.",
                    ShopifySetup."BC Shipping Item No.");

            if (PreviouslyRefundedShippingAmount +
                RefundEntry."Shipping Refund Amount") >
               (OriginalShippingAmount + 0.02)
            then
                Error(
                    'Shopify shipping refund would exceed the originally invoiced shipping amount. Invoiced shipping: %1. Previously processed refunds: %2. Current refund: %3.',
                    OriginalShippingAmount,
                    PreviouslyRefundedShippingAmount,
                    RefundEntry."Shipping Refund Amount");

            LineNo += 10000;
            SalesLine.Init();
            SalesLine.Validate("Document Type", SalesHeader."Document Type");
            SalesLine.Validate("Document No.", SalesHeader."No.");
            SalesLine.Validate("Line No.", LineNo);
            SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesLine.Validate("No.", ShopifySetup."BC Shipping Item No.");
            SalesLine.Validate(Quantity, 1);

            if SalesInvoiceHeader."Prices Including VAT" then
                ShippingUnitPrice := RefundEntry."Shipping Refund Amount"
            else begin
                ShippingSubtotalExclVAT := GetRefundShippingSubtotal(RefundEntry);
                ShippingUnitPrice := ShippingSubtotalExclVAT;
            end;

            SalesLine.Validate("Unit Price", ShippingUnitPrice);
            SalesLine.Validate(Description, 'Shopify shipping refund');
            SalesLine.Insert(true);
        end;
    end;

    local procedure GetOriginalInvoicedShippingAmount(
        PostedInvoiceNo: Code[20];
        ShippingItemNo: Code[20]): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        ResultAmount: Decimal;
    begin
        SalesInvoiceLine.SetRange(
            "Document No.",
            PostedInvoiceNo);
        SalesInvoiceLine.SetRange(
            Type,
            SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetRange(
            "No.",
            ShippingItemNo);

        if SalesInvoiceLine.FindSet() then
            repeat
                ResultAmount +=
                    SalesInvoiceLine."Amount Including VAT";
            until SalesInvoiceLine.Next() = 0;

        exit(Abs(ResultAmount));
    end;

    local procedure GetPreviouslyProcessedShippingRefundAmount(
        CurrentRefundId: Text;
        ShopifyOrderId: Text): Decimal
    var
        OtherRefundEntry: Record "Shopify Refund Entry";
        ResultAmount: Decimal;
    begin
        OtherRefundEntry.SetRange(
            "Shopify Order ID",
            ShopifyOrderId);
        OtherRefundEntry.SetRange(
            Status,
            OtherRefundEntry.Status::Success);

        if OtherRefundEntry.FindSet() then
            repeat
                if OtherRefundEntry."Shopify Refund ID" <> CurrentRefundId then
                    ResultAmount +=
                        OtherRefundEntry."Shipping Refund Amount";
            until OtherRefundEntry.Next() = 0;

        exit(ResultAmount);
    end;

    local procedure GetPreviouslyProcessedRefundQuantity(
        CurrentRefundId: Text;
        ShopifyLineItemId: Text): Decimal
    var
        OtherRefundLine: Record "Shopify Refund Line";
        OtherRefundEntry: Record "Shopify Refund Entry";
        ResultQuantity: Decimal;
    begin
        if ShopifyLineItemId = '' then
            exit(0);

        OtherRefundLine.SetRange(
            "Shopify Line Item ID",
            ShopifyLineItemId);

        if OtherRefundLine.FindSet() then
            repeat
                if OtherRefundLine."Shopify Refund ID" <> CurrentRefundId then
                    if OtherRefundEntry.Get(
                        OtherRefundLine."Shopify Refund ID")
                    then
                        if OtherRefundEntry.Status =
                           OtherRefundEntry.Status::Success
                        then
                            ResultQuantity +=
                                OtherRefundLine.Quantity;
            until OtherRefundLine.Next() = 0;

        exit(ResultQuantity);
    end;

    local procedure GetRefundShippingSubtotal(
        RefundEntry: Record "Shopify Refund Entry"): Decimal
    var
        RefundObject: JsonObject;
        ShopifyClient: Codeunit "Shopify Client";
        ShippingObject: JsonObject;
        Nodes: JsonArray;
        Token: JsonToken;
        NodeObject: JsonObject;
        JsonText: Text;
        ResultAmount: Decimal;
        I: Integer;
    begin
        JsonText := RefundEntry.GetRawRefundJson();
        if (JsonText = '') or (not RefundObject.ReadFrom(JsonText)) then
            exit(RefundEntry."Shipping Refund Amount");

        ShippingObject := ShopifyClient.GetObject(RefundObject, 'refundShippingLines');
        Nodes := ShopifyClient.GetArray(ShippingObject, 'nodes');

        if Nodes.Count() > 0 then
            for I := 0 to Nodes.Count() - 1 do begin
                Nodes.Get(I, Token);
                NodeObject := Token.AsObject();
                ResultAmount +=
                    GetMoneyAmount(
                        NodeObject,
                        'subtotalAmountSet',
                        RefundEntry."Currency Code");
            end;

        exit(ResultAmount);
    end;

    local procedure FindExistingPostedCreditMemo(
        RefundEntry: Record "Shopify Refund Entry";
        var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
    var
        RefundReference: Code[35];
    begin
        if RefundEntry."Posted Credit Memo No." <> '' then
            if SalesCrMemoHeader.Get(RefundEntry."Posted Credit Memo No.") then
                exit(true);

        RefundReference := GetRefundReference(RefundEntry);
        SalesCrMemoHeader.Reset();
        SalesCrMemoHeader.SetRange("External Document No.", RefundReference);

        exit(SalesCrMemoHeader.FindLast());
    end;

    local procedure PostCustomerRefundAgainstClearing(
        var RefundEntry: Record "Shopify Refund Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ShopifySetup: Record "Shopify Integration Setup";
        var CreditMemoCustLedgerEntry: Record "Cust. Ledger Entry";
        var RefundCustLedgerEntry: Record "Cust. Ledger Entry")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        RemainingAmount: Decimal;
        RefundDocumentNo: Code[20];
        DescriptionText: Text;
    begin
        CreditMemoCustLedgerEntry.CalcFields("Remaining Amount");
        RemainingAmount := Abs(CreditMemoCustLedgerEntry."Remaining Amount");

        if (not CreditMemoCustLedgerEntry.Open) or
           (RemainingAmount = 0)
        then
            exit;

        if Abs(
            Round(
                RemainingAmount - RefundEntry."Refund Total",
                0.01)) > 0.02
        then
            Error(
                'Posted credit memo remaining amount %1 does not match Shopify refund total %2 %3.',
                RemainingAmount,
                RefundEntry."Refund Total",
                RefundEntry."Currency Code");

        RefundDocumentNo := GetRefundJournalDocumentNo(RefundEntry);
        DescriptionText :=
            StrSubstNo(
                'Shopify refund %1',
                RefundEntry."Shopify Order Name");

        GenJournalLine.Init();
        GenJournalLine.InitNewLine(
            GetRefundPostingDate(RefundEntry),
            GetRefundPostingDate(RefundEntry),
            GetRefundPostingDate(RefundEntry),
            CopyStr(
                DescriptionText,
                1,
                MaxStrLen(GenJournalLine.Description)),
            SalesCrMemoHeader."Shortcut Dimension 1 Code",
            SalesCrMemoHeader."Shortcut Dimension 2 Code",
            SalesCrMemoHeader."Dimension Set ID",
            '');

        GenJournalLine."Journal Template Name" :=
            ShopifySetup."Payment Journal Template Name";
        GenJournalLine."Journal Batch Name" :=
            ShopifySetup."Payment Journal Batch Name";

        if GenJournalTemplate.Get(
            ShopifySetup."Payment Journal Template Name")
        then
            GenJournalLine."Source Code" := GenJournalTemplate."Source Code";

        GenJournalLine.Validate(
            "Document Type",
            GenJournalLine."Document Type"::Refund);
        GenJournalLine.Validate(
            "Account Type",
            GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate(
            "Account No.",
            SalesCrMemoHeader."Bill-to Customer No.");
        GenJournalLine.Validate(
            "Document No.",
            RefundDocumentNo);
        GenJournalLine."External Document No." :=
            CopyStr(
                RefundEntry."Shopify Order Name",
                1,
                MaxStrLen(GenJournalLine."External Document No."));
        GenJournalLine.Validate(
            "Currency Code",
            SalesCrMemoHeader."Currency Code");
        GenJournalLine.Validate(
            Amount,
            RemainingAmount);
        GenJournalLine.Validate(
            "Applies-to Doc. Type",
            GenJournalLine."Applies-to Doc. Type"::"Credit Memo");
        GenJournalLine.Validate(
            "Applies-to Doc. No.",
            SalesCrMemoHeader."No.");
        GenJournalLine.Validate(
            "Bal. Account Type",
            GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate(
            "Bal. Account No.",
            ShopifySetup."Shopify Clearing G/L Acc. No.");
        GenJournalLine."System-Created Entry" := true;

        RefundEntry."Refund Journal Document No." := RefundDocumentNo;
        RefundEntry.Modify(false);

        GenJnlPostLine.RunWithCheck(GenJournalLine);

        if not FindRefundLedgerEntryByDocument(
            SalesCrMemoHeader."Bill-to Customer No.",
            RefundDocumentNo,
            RefundCustLedgerEntry)
        then
            Error(
                'Customer refund ledger entry %1 could not be found after posting.',
                RefundDocumentNo);
    end;

    local procedure GetCreditMemoCustLedgerEntry(
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", SalesCrMemoHeader."Bill-to Customer No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.SetRange("Document No.", SalesCrMemoHeader."No.");

        if not CustLedgerEntry.FindLast() then
            Error(
                'Customer Ledger Entry for posted credit memo %1 could not be found.',
                SalesCrMemoHeader."No.");
    end;

    local procedure FindExistingRefundCustLedgerEntry(
        RefundEntry: Record "Shopify Refund Entry";
        CustomerNo: Code[20];
        var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        if RefundEntry."Refund Journal Document No." = '' then
            exit(false);

        exit(
            FindRefundLedgerEntryByDocument(
                CustomerNo,
                RefundEntry."Refund Journal Document No.",
                CustLedgerEntry));
    end;

    local procedure FindRefundLedgerEntryByDocument(
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Refund);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        exit(CustLedgerEntry.FindLast());
    end;

    local procedure GetPreviouslyProcessedRefundAmount(
        CurrentRefundId: Text;
        ShopifyOrderId: Text): Decimal
    var
        OtherRefundEntry: Record "Shopify Refund Entry";
        ResultAmount: Decimal;
    begin
        OtherRefundEntry.SetRange(
            "Shopify Order ID",
            ShopifyOrderId);
        OtherRefundEntry.SetRange(
            Status,
            OtherRefundEntry.Status::Success);

        if OtherRefundEntry.FindSet() then
            repeat
                if OtherRefundEntry."Shopify Refund ID" <> CurrentRefundId then
                    ResultAmount +=
                        OtherRefundEntry."Refund Total";
            until OtherRefundEntry.Next() = 0;

        exit(ResultAmount);
    end;

    local procedure SetManualReview(
        var RefundEntry: Record "Shopify Refund Entry";
        ReasonText: Text)
    begin
        RefundEntry.Status :=
            RefundEntry.Status::"Manual Review";
        RefundEntry."Manual Review Reason" :=
            CopyStr(
                ReasonText,
                1,
                MaxStrLen(RefundEntry."Manual Review Reason"));
        RefundEntry."Result Message" :=
            CopyStr(
                'Refund requires manual review and was not posted automatically.',
                1,
                MaxStrLen(RefundEntry."Result Message"));
        Clear(RefundEntry."Refund Error");
        RefundEntry.Modify(false);
    end;

    local procedure SetWaitingForPayment(
        var RefundEntry: Record "Shopify Refund Entry";
        MessageText: Text)
    begin
        RefundEntry.Status := RefundEntry.Status::Waiting;
        RefundEntry."Result Message" :=
            CopyStr(
                MessageText,
                1,
                MaxStrLen(RefundEntry."Result Message"));
        Clear(RefundEntry."Refund Error");
        RefundEntry.Modify(false);
    end;

    local procedure GetRefundReference(
        RefundEntry: Record "Shopify Refund Entry"): Code[35]
    var
        ReferenceText: Text;
        ResultCode: Code[35];
    begin
        if RefundEntry."Legacy Resource ID" <> '' then
            ReferenceText := 'SHOPIFY-REFUND-' + RefundEntry."Legacy Resource ID"
        else
            ReferenceText := 'SHOPIFY-REFUND-' + CopyStr(RefundEntry."Shopify Refund ID", 1, 20);

        ResultCode :=
            CopyStr(
                ReferenceText,
                1,
                MaxStrLen(ResultCode));
        exit(ResultCode);
    end;

    local procedure GetRefundJournalDocumentNo(
        RefundEntry: Record "Shopify Refund Entry"): Code[20]
    var
        ReferenceText: Text;
        ResultCode: Code[20];
    begin
        if RefundEntry."Legacy Resource ID" <> '' then
            ReferenceText := 'SHRF-' + RefundEntry."Legacy Resource ID"
        else
            ReferenceText := 'SHRF-' + CopyStr(RefundEntry."Shopify Refund ID", 1, 15);

        ResultCode :=
            CopyStr(
                ReferenceText,
                1,
                MaxStrLen(ResultCode));
        exit(ResultCode);
    end;

    local procedure GetRefundPostingDate(
        RefundEntry: Record "Shopify Refund Entry"): Date
    begin
        if RefundEntry."Processed At" <> 0DT then
            exit(DT2Date(RefundEntry."Processed At"));

        exit(WorkDate());
    end;

    local procedure AppendManualReason(
        var ManualReason: Text;
        NewReason: Text)
    begin
        if NewReason = '' then
            exit;

        if ManualReason <> '' then
            ManualReason += ' | ';

        ManualReason += NewReason;
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
        MoneyBagObject := ShopifyClient.GetObject(ParentObject, PropertyName);
        MoneyObject := ShopifyClient.GetObject(MoneyBagObject, 'presentmentMoney');
        CurrencyText := ShopifyClient.GetText(MoneyObject, 'currencyCode');

        if (ExpectedCurrency <> '') and
           (CurrencyText <> ExpectedCurrency)
        then
            Error(
                'Currency mismatch. Expected %1 but Shopify returned %2.',
                ExpectedCurrency,
                CurrencyText);

        AmountText := ShopifyClient.GetText(MoneyObject, 'amount');

        if not Evaluate(Amount, AmountText, 9) then
            Error(
                'Shopify amount %1 could not be converted to Decimal.',
                AmountText);

        exit(Amount);
    end;

    local procedure GetMoneyCurrency(
        ParentObject: JsonObject;
        PropertyName: Text): Text
    var
        ShopifyClient: Codeunit "Shopify Client";
        MoneyBagObject: JsonObject;
        MoneyObject: JsonObject;
    begin
        MoneyBagObject := ShopifyClient.GetObject(ParentObject, PropertyName);
        MoneyObject := ShopifyClient.GetObject(MoneyBagObject, 'presentmentMoney');
        exit(ShopifyClient.GetText(MoneyObject, 'currencyCode'));
    end;

    local procedure GetRequiredText(
        ParentObject: JsonObject;
        PropertyName: Text): Text
    var
        ShopifyClient: Codeunit "Shopify Client";
    begin
        exit(ShopifyClient.GetText(ParentObject, PropertyName));
    end;

    local procedure GetInteger(
        ParentObject: JsonObject;
        PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if not ParentObject.Get(PropertyName, Token) then
            Error('JSON property %1 was not found.', PropertyName);

        exit(Token.AsValue().AsInteger());
    end;

    local procedure GetDateTime(
        ParentObject: JsonObject;
        PropertyName: Text): DateTime
    var
        Token: JsonToken;
    begin
        if not ParentObject.Get(PropertyName, Token) then
            Error('JSON property %1 was not found.', PropertyName);

        exit(Token.AsValue().AsDateTime());
    end;

    local procedure GetSetup(
        var ShopifySetup: Record "Shopify Integration Setup")
    begin
        if not ShopifySetup.Get('SETUP') then
            Error('Shopify Integration Setup does not exist.');
    end;
}
