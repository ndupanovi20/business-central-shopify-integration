codeunit 50260 "Shopify Payout Mgt."
{
    procedure TestShopifyPaymentsAccess()
    var
        ShopifyClient: Codeunit "Shopify Client";
        Variables: JsonObject;
        ResponseJson: JsonObject;
        DataObject: JsonObject;
        AccountObject: JsonObject;
        QueryText: Text;
    begin
        QueryText :=
            'query ShopifyPaymentsAccess {' +
            ' shopifyPaymentsAccount {' +
            '  id' +
            '  activated' +
            '  defaultCurrency' +
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

        if not ShopifyClient.TryGetObject(
            DataObject,
            'shopifyPaymentsAccount',
            AccountObject)
        then
            Error(
                'Shopify Payments account is not available for this store or the current app/user does not have access to payouts.');
    end;

    procedure ImportLatestPayouts(
        ShowResultMessage: Boolean): Integer
    var
        ShopifySetup: Record "Shopify Integration Setup";
        ShopifyClient: Codeunit "Shopify Client";
        Variables: JsonObject;
        ResponseJson: JsonObject;
        DataObject: JsonObject;
        AccountObject: JsonObject;
        PayoutsObject: JsonObject;
        PageInfoObject: JsonObject;
        NodesArray: JsonArray;
        NodeToken: JsonToken;
        PayoutObject: JsonObject;
        QueryText: Text;
        EndCursor: Text;
        ImportedCount: Integer;
        I: Integer;
        HasNextPage: Boolean;
        ReachedCutoff: Boolean;
    begin
        GetSetup(
            ShopifySetup);

        ShopifySetup.TestField(
            "Import Payouts From");

        QueryText :=
            'query ShopifyPaymentsPayouts($first: Int!, $after: String) {' +
            ' shopifyPaymentsAccount {' +
            '  payouts(first: $first, after: $after, reverse: true, sortKey: ISSUED_AT) {' +
            '   nodes {' +
            '    id' +
            '    legacyResourceId' +
            '    issuedAt' +
            '    status' +
            '    transactionType' +
            '    net { amount currencyCode }' +
            '    summary {' +
            '     adjustmentsFee { amount currencyCode }' +
            '     adjustmentsGross { amount currencyCode }' +
            '     advanceFees { amount currencyCode }' +
            '     advanceGross { amount currencyCode }' +
            '     chargesFee { amount currencyCode }' +
            '     chargesGross { amount currencyCode }' +
            '     refundsFee { amount currencyCode }' +
            '     refundsFeeGross { amount currencyCode }' +
            '     reservedFundsFee { amount currencyCode }' +
            '     reservedFundsGross { amount currencyCode }' +
            '     retriedPayoutsFee { amount currencyCode }' +
            '     retriedPayoutsGross { amount currencyCode }' +
            '     usdcRebateCreditAmount { amount currencyCode }' +
            '    }' +
            '   }' +
            '   pageInfo { hasNextPage endCursor }' +
            '  }' +
            ' }' +
            '}';

        repeat
            Clear(Variables);
            Variables.Add(
                'first',
                50);

            if EndCursor <> '' then
                Variables.Add(
                    'after',
                    EndCursor);

            ShopifyClient.ExecuteGraphQL(
                QueryText,
                Variables,
                ResponseJson);

            DataObject :=
                ShopifyClient.GetObject(
                    ResponseJson,
                    'data');

            if not ShopifyClient.TryGetObject(
                DataObject,
                'shopifyPaymentsAccount',
                AccountObject)
            then
                Error(
                    'Shopify Payments account is not available for this store or the current app/user does not have access to payouts.');

            PayoutsObject :=
                ShopifyClient.GetObject(
                    AccountObject,
                    'payouts');

            NodesArray :=
                ShopifyClient.GetArray(
                    PayoutsObject,
                    'nodes');

            ReachedCutoff :=
                false;

            for I := 0 to NodesArray.Count() - 1 do begin
                NodesArray.Get(
                    I,
                    NodeToken);

                PayoutObject :=
                    NodeToken.AsObject();

                if ImportPayoutObject(
                    PayoutObject,
                    ShopifySetup."Import Payouts From",
                    ReachedCutoff)
                then
                    ImportedCount += 1;
            end;

            PageInfoObject :=
                ShopifyClient.GetObject(
                    PayoutsObject,
                    'pageInfo');

            HasNextPage :=
                GetBoolean(
                    PageInfoObject,
                    'hasNextPage');

            EndCursor :=
                ShopifyClient.GetOptionalText(
                    PageInfoObject,
                    'endCursor');
        until ReachedCutoff or
              (not HasNextPage) or
              (EndCursor = '');

        if ShowResultMessage then
            Message(
                'Shopify payout import completed.\Imported or refreshed payouts: %1',
                ImportedCount);

        exit(
            ImportedCount);
    end;

    procedure ProcessPendingPayouts(
        ShowResultMessage: Boolean): Integer
    var
        PayoutEntry: Record "Shopify Payout Entry";
        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        PayoutEntry.Reset();
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Pending);

        PayoutEntry.SetRange(
            "Shopify Status",
            'PAID');

        PayoutEntry.SetRange(
            "Transaction Type",
            'DEPOSIT');

        if PayoutEntry.FindSet() then
            repeat
                if PostPayout(
                    PayoutEntry,
                    false)
                then
                    SuccessCount += 1
                else
                    ErrorCount += 1;
            until PayoutEntry.Next() = 0;

        if ShowResultMessage then
            Message(
                'Shopify payout posting completed.\Successful: %1\Failed: %2',
                SuccessCount,
                ErrorCount);

        exit(
            SuccessCount);
    end;

    procedure ProcessBackgroundPayoutWork(
        ShowResultMessage: Boolean): Integer
    var
        ShopifySetup: Record "Shopify Integration Setup";
        ImportedCount: Integer;
        PostedCount: Integer;
    begin
        GetSetup(
            ShopifySetup);

        if ShopifySetup."Auto Import Shopify Payouts" then
            ImportedCount :=
                ImportLatestPayouts(
                    false);

        if ShopifySetup."Auto Post Paid Payouts" then
            PostedCount :=
                ProcessPendingPayouts(
                    false);

        if ShowResultMessage then
            Message(
                'Shopify payout background work completed.\Payouts imported/refreshed: %1\Payouts posted: %2',
                ImportedCount,
                PostedCount);

        exit(
            ImportedCount + PostedCount);
    end;

    procedure RetryFailedPayouts()
    var
        PayoutEntry: Record "Shopify Payout Entry";
        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Error);

        if not PayoutEntry.FindSet() then begin
            Message(
                'There are no failed Shopify payouts to retry.');

            exit;
        end;

        repeat
            if (UpperCase(PayoutEntry."Shopify Status") = 'PAID') and
               (UpperCase(PayoutEntry."Transaction Type") = 'DEPOSIT')
            then begin
                PayoutEntry."Processing Status" :=
                    PayoutEntry."Processing Status"::Pending;

                PayoutEntry.Modify(false);

                if PostPayout(
                    PayoutEntry,
                    false)
                then
                    SuccessCount += 1
                else
                    ErrorCount += 1;
            end else
                ErrorCount += 1;
        until PayoutEntry.Next() = 0;

        Message(
            'Shopify payout retry completed.\Successful: %1\Failed: %2',
            SuccessCount,
            ErrorCount);
    end;

    procedure PostPayout(
        var PayoutEntry: Record "Shopify Payout Entry";
        ShowResultMessage: Boolean): Boolean
    var
        Runner: Codeunit "Shopify Payout Posting Runner";
        SyncLogMgt: Codeunit "Shopify Sync Log Mgt.";
        ErrorText: Text;
        PayoutId: Text;
        StartedAt: DateTime;
    begin
        ValidatePayoutForPosting(
            PayoutEntry);

        if PayoutEntry."Processing Status" =
           PayoutEntry."Processing Status"::Success
        then begin
            if ShowResultMessage then
                Message(
                    'Shopify payout %1 has already been posted as Business Central document %2.',
                    PayoutEntry."Shopify Payout ID",
                    PayoutEntry."BC Document No.");

            exit(true);
        end;

        PayoutId :=
            PayoutEntry."Shopify Payout ID";

        PayoutEntry."Processing Status" :=
            PayoutEntry."Processing Status"::Pending;

        PayoutEntry."Attempt Count" +=
            1;

        PayoutEntry."Last Attempt At" :=
            CurrentDateTime();

        Clear(
            PayoutEntry."Payout Error");

        PayoutEntry.Modify(false);

        StartedAt :=
            CurrentDateTime();

        Commit();

        ClearLastError();

        if Runner.Run(
            PayoutEntry)
        then begin
            PayoutEntry.Get(
                PayoutId);

            SyncLogMgt.LogSuccess(
                "Shopify Sync Direction"::Inbound,
                "Shopify Sync Entity"::Payout,
                PayoutEntry."BC Document No.",
                PayoutEntry."Shopify Payout ID",
                StrSubstNo(
                    'Shopify payout was posted to Business Central. Net: %1 %2. Fees: %3. Clearing settlement: %4. Bank: %5.',
                    PayoutEntry."Net Amount",
                    PayoutEntry."Currency Code",
                    PayoutEntry."Total Fee Amount",
                    PayoutEntry."Clearing Settlement Amount",
                    PayoutEntry."Bank Account No."),
                CurrentDateTime() - StartedAt);

            if ShowResultMessage then
                Message(
                    'Shopify payout was posted successfully.\BC document: %1\Net bank amount: %2 %3\Fees: %4\Clearing settlement: %5',
                    PayoutEntry."BC Document No.",
                    PayoutEntry."Net Amount",
                    PayoutEntry."Currency Code",
                    PayoutEntry."Total Fee Amount",
                    PayoutEntry."Clearing Settlement Amount");

            exit(true);
        end;

        ErrorText :=
            GetLastErrorText();

        if ErrorText = '' then
            ErrorText :=
                'Unknown error while posting Shopify payout.';

        PayoutEntry.Get(
            PayoutId);

        PayoutEntry."Processing Status" :=
            PayoutEntry."Processing Status"::Error;

        PayoutEntry."Payout Error" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(
                    PayoutEntry."Payout Error"));

        PayoutEntry."Result Message" :=
            CopyStr(
                'Shopify payout posting failed.',
                1,
                MaxStrLen(
                    PayoutEntry."Result Message"));

        PayoutEntry.Modify(false);

        SyncLogMgt.LogError(
            "Shopify Sync Direction"::Inbound,
            "Shopify Sync Entity"::Payout,
            PayoutEntry."BC Document No.",
            PayoutEntry."Shopify Payout ID",
            ErrorText,
            CurrentDateTime() - StartedAt);

        if ShowResultMessage then
            Message(
                'Shopify payout posting failed.\%1',
                ErrorText);

        exit(false);
    end;

    procedure PostPayoutCore(
        var PayoutEntry: Record "Shopify Payout Entry")
    var
        ShopifySetup: Record "Shopify Integration Setup";
        BankLine: Record "Gen. Journal Line";
        FeeLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        LastGLEntryNo: Integer;
    begin
        GetSetup(
            ShopifySetup);

        ValidatePayoutForPosting(
            PayoutEntry);

        DocumentNo :=
            GetPayoutDocumentNo(
                PayoutEntry);

        if IsPayoutAlreadyPosted(
            DocumentNo)
        then begin
            PayoutEntry."BC Document No." :=
                DocumentNo;

            PayoutEntry."Processing Status" :=
                PayoutEntry."Processing Status"::Success;

            PayoutEntry."Posted At" :=
                CurrentDateTime();

            PayoutEntry."Result Message" :=
                CopyStr(
                    'Existing Business Central G/L entries were found for this payout document number and linked.',
                    1,
                    MaxStrLen(
                        PayoutEntry."Result Message"));

            Clear(
                PayoutEntry."Payout Error");

            PayoutEntry.Modify(false);
            exit;
        end;

        CurrencyCode :=
            GetJournalCurrencyCode(
                PayoutEntry."Currency Code");

        BuildPayoutJournalLine(
            PayoutEntry,
            ShopifySetup,
            DocumentNo,
            CurrencyCode,
            false,
            BankLine);

        LastGLEntryNo :=
            GenJnlPostLine.RunWithCheck(
                BankLine);

        if Abs(
            PayoutEntry."Total Fee Amount") > 0.00001
        then begin
            BuildPayoutJournalLine(
                PayoutEntry,
                ShopifySetup,
                DocumentNo,
                CurrencyCode,
                true,
                FeeLine);

            LastGLEntryNo :=
                GenJnlPostLine.RunWithCheck(
                    FeeLine);
        end;

        PayoutEntry.Get(
            PayoutEntry."Shopify Payout ID");

        PayoutEntry."BC Document No." :=
            DocumentNo;

        PayoutEntry."Bank Account No." :=
            ShopifySetup."Shopify Payout Bank Acc. No.";

        PayoutEntry."Clearing G/L Account No." :=
            ShopifySetup."Shopify Clearing G/L Acc. No.";

        PayoutEntry."Fee G/L Account No." :=
            ShopifySetup."Shopify Fee G/L Acc. No.";

        PayoutEntry."Last G/L Entry No." :=
            LastGLEntryNo;

        PayoutEntry."Processing Status" :=
            PayoutEntry."Processing Status"::Success;

        PayoutEntry."Posted At" :=
            CurrentDateTime();

        PayoutEntry."Result Message" :=
            CopyStr(
                StrSubstNo(
                    'Payout posted. Bank %1 received %2 %3, fee expense was %4, and clearing settlement was %5.',
                    ShopifySetup."Shopify Payout Bank Acc. No.",
                    PayoutEntry."Net Amount",
                    PayoutEntry."Currency Code",
                    PayoutEntry."Total Fee Amount",
                    PayoutEntry."Clearing Settlement Amount"),
                1,
                MaxStrLen(
                    PayoutEntry."Result Message"));

        Clear(
            PayoutEntry."Payout Error");

        PayoutEntry.Modify(false);
    end;

    local procedure ImportPayoutObject(
        PayoutObject: JsonObject;
        Cutoff: DateTime;
        var ReachedCutoff: Boolean): Boolean
    var
        ShopifyClient: Codeunit "Shopify Client";
        PayoutEntry: Record "Shopify Payout Entry";
        NetObject: JsonObject;
        SummaryObject: JsonObject;
        IssuedAt: DateTime;
        PayoutId: Text;
        ShopifyStatus: Text;
        TransactionType: Text;
        CurrencyCode: Code[10];
        NetAmount: Decimal;
        LegacyResourceId: BigInteger;
        OldProcessingStatus: Enum "Shopify Payout Proc. Status";
        IsNew: Boolean;
    begin
        IssuedAt :=
            GetDateTime(
                PayoutObject,
                'issuedAt');

        if IssuedAt < Cutoff then begin
            ReachedCutoff :=
                true;
            exit(false);
        end;

        PayoutId :=
            ShopifyClient.GetText(
                PayoutObject,
                'id');

        ShopifyStatus :=
            UpperCase(
                ShopifyClient.GetText(
                    PayoutObject,
                    'status'));

        TransactionType :=
            UpperCase(
                ShopifyClient.GetText(
                    PayoutObject,
                    'transactionType'));

        NetObject :=
            ShopifyClient.GetObject(
                PayoutObject,
                'net');

        NetAmount :=
            GetMoneyAmount(
                NetObject);

        CurrencyCode :=
            CopyStr(
                ShopifyClient.GetText(
                    NetObject,
                    'currencyCode'),
                1,
                10);

        LegacyResourceId :=
            GetBigInteger(
                PayoutObject,
                'legacyResourceId');

        IsNew :=
            not PayoutEntry.Get(
                PayoutId);

        if not IsNew then
            OldProcessingStatus :=
                PayoutEntry."Processing Status";

        if IsNew then begin
            PayoutEntry.Init();
            PayoutEntry."Shopify Payout ID" :=
                CopyStr(
                    PayoutId,
                    1,
                    MaxStrLen(
                        PayoutEntry."Shopify Payout ID"));

            PayoutEntry.Source :=
                PayoutEntry.Source::"Shopify Payments API";
        end else
            if PayoutEntry."Processing Status" =
               PayoutEntry."Processing Status"::Success
            then
                exit(false);

        PayoutEntry."Legacy Resource ID" :=
            LegacyResourceId;

        PayoutEntry."Shopify Status" :=
            CopyStr(
                ShopifyStatus,
                1,
                MaxStrLen(
                    PayoutEntry."Shopify Status"));

        PayoutEntry."Transaction Type" :=
            CopyStr(
                TransactionType,
                1,
                MaxStrLen(
                    PayoutEntry."Transaction Type"));

        PayoutEntry."Issued At" :=
            IssuedAt;

        PayoutEntry."Currency Code" :=
            CurrencyCode;

        PayoutEntry."Net Amount" :=
            NetAmount;

        SummaryObject :=
            ShopifyClient.GetObject(
                PayoutObject,
                'summary');

        ReadSummary(
            SummaryObject,
            PayoutEntry);

        PayoutEntry."Total Fee Amount" :=
            PayoutEntry."Charges Fee" +
            PayoutEntry."Refunds Fee" +
            PayoutEntry."Adjustments Fee" +
            PayoutEntry."Other Fee";

        PayoutEntry."Clearing Settlement Amount" :=
            PayoutEntry."Net Amount" +
            PayoutEntry."Total Fee Amount";

        PayoutEntry."Summary Gross Amount" :=
            PayoutEntry."Charges Gross" +
            PayoutEntry."Refunds Gross" +
            PayoutEntry."Adjustments Gross" +
            PayoutEntry."Other Gross";

        PayoutEntry."Summary Difference" :=
            Round(
                PayoutEntry."Clearing Settlement Amount" -
                PayoutEntry."Summary Gross Amount",
                0.01);

        SetLocalProcessingState(
            PayoutEntry);

        if (not IsNew) and
           (OldProcessingStatus = OldProcessingStatus::Error) and
           (PayoutEntry."Processing Status" =
            PayoutEntry."Processing Status"::Pending)
        then
            PayoutEntry."Processing Status" :=
                PayoutEntry."Processing Status"::Error;

        if IsNew then
            PayoutEntry.Insert(false)
        else
            PayoutEntry.Modify(false);

        exit(true);
    end;

    local procedure ReadSummary(
        SummaryObject: JsonObject;
        var PayoutEntry: Record "Shopify Payout Entry")
    var
        AdvanceGross: Decimal;
        AdvanceFee: Decimal;
        ReservedGross: Decimal;
        ReservedFee: Decimal;
        RetriedGross: Decimal;
        RetriedFee: Decimal;
        UsdcRebate: Decimal;
    begin
        PayoutEntry."Adjustments Gross" :=
            GetNestedMoneyAmount(
                SummaryObject,
                'adjustmentsGross');

        PayoutEntry."Adjustments Fee" :=
            GetNestedMoneyAmount(
                SummaryObject,
                'adjustmentsFee');

        PayoutEntry."Charges Gross" :=
            GetNestedMoneyAmount(
                SummaryObject,
                'chargesGross');

        PayoutEntry."Charges Fee" :=
            GetNestedMoneyAmount(
                SummaryObject,
                'chargesFee');

        PayoutEntry."Refunds Gross" :=
            GetNestedMoneyAmount(
                SummaryObject,
                'refundsFeeGross');

        PayoutEntry."Refunds Fee" :=
            GetNestedMoneyAmount(
                SummaryObject,
                'refundsFee');

        AdvanceGross :=
            GetNestedMoneyAmount(
                SummaryObject,
                'advanceGross');

        AdvanceFee :=
            GetNestedMoneyAmount(
                SummaryObject,
                'advanceFees');

        ReservedGross :=
            GetNestedMoneyAmount(
                SummaryObject,
                'reservedFundsGross');

        ReservedFee :=
            GetNestedMoneyAmount(
                SummaryObject,
                'reservedFundsFee');

        RetriedGross :=
            GetNestedMoneyAmount(
                SummaryObject,
                'retriedPayoutsGross');

        RetriedFee :=
            GetNestedMoneyAmount(
                SummaryObject,
                'retriedPayoutsFee');

        UsdcRebate :=
            GetNestedMoneyAmount(
                SummaryObject,
                'usdcRebateCreditAmount');

        PayoutEntry."Other Gross" :=
            AdvanceGross +
            ReservedGross +
            RetriedGross +
            UsdcRebate;

        PayoutEntry."Other Fee" :=
            AdvanceFee +
            ReservedFee +
            RetriedFee;
    end;

    local procedure SetLocalProcessingState(
        var PayoutEntry: Record "Shopify Payout Entry")
    begin
        Clear(
            PayoutEntry."Result Message");

        case UpperCase(
            PayoutEntry."Shopify Status") of
            'PAID':
                begin
                    if UpperCase(
                        PayoutEntry."Transaction Type") = 'DEPOSIT'
                    then begin
                        PayoutEntry."Processing Status" :=
                            PayoutEntry."Processing Status"::Pending;

                        PayoutEntry."Result Message" :=
                            'Paid Shopify deposit is ready for Business Central payout posting.';
                    end else begin
                        PayoutEntry."Processing Status" :=
                            PayoutEntry."Processing Status"::Skipped;

                        PayoutEntry."Result Message" :=
                            'Shopify payout withdrawal is retained for audit but automatic withdrawal posting is deferred until refund/adjustment processing is implemented.';
                    end;
                end;

            'SCHEDULED',
            'IN_TRANSIT':
                begin
                    PayoutEntry."Processing Status" :=
                        PayoutEntry."Processing Status"::Waiting;

                    PayoutEntry."Result Message" :=
                        'Shopify payout has not yet reached PAID status.';
                end;

            'FAILED',
            'CANCELED':
                begin
                    PayoutEntry."Processing Status" :=
                        PayoutEntry."Processing Status"::Skipped;

                    PayoutEntry."Result Message" :=
                        StrSubstNo(
                            'Shopify payout status %1 is not posted to Business Central.',
                            PayoutEntry."Shopify Status");
                end;

            else begin
                PayoutEntry."Processing Status" :=
                    PayoutEntry."Processing Status"::Waiting;

                PayoutEntry."Result Message" :=
                    StrSubstNo(
                        'Shopify payout status %1 is waiting for an explicit processing rule.',
                        PayoutEntry."Shopify Status");
            end;
        end;

        PayoutEntry."Result Message" :=
            CopyStr(
                PayoutEntry."Result Message",
                1,
                MaxStrLen(
                    PayoutEntry."Result Message"));
    end;

    local procedure ValidatePayoutForPosting(
        PayoutEntry: Record "Shopify Payout Entry")
    var
        ShopifySetup: Record "Shopify Integration Setup";
        BankAccount: Record "Bank Account";
        FeeGLAccount: Record "G/L Account";
        ClearingGLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GetSetup(
            ShopifySetup);

        if UpperCase(
            PayoutEntry."Shopify Status") <> 'PAID'
        then
            Error(
                'Only Shopify payouts with PAID status can be posted. Current status: %1.',
                PayoutEntry."Shopify Status");

        if UpperCase(
            PayoutEntry."Transaction Type") <> 'DEPOSIT'
        then
            Error(
                'Automatic payout posting currently supports DEPOSIT payouts only. Current transaction type: %1.',
                PayoutEntry."Transaction Type");

        if PayoutEntry."Net Amount" <= 0 then
            Error(
                'Shopify payout net amount must be greater than zero. Current value: %1.',
                PayoutEntry."Net Amount");

        ShopifySetup.TestField(
            "Shopify Clearing G/L Acc. No.");

        ShopifySetup.TestField(
            "Shopify Payout Bank Acc. No.");

        ShopifySetup.TestField(
            "Shopify Fee G/L Acc. No.");

        ShopifySetup.TestField(
            "Payout Journal Template Name");

        ShopifySetup.TestField(
            "Payout Journal Batch Name");

        if not BankAccount.Get(
            ShopifySetup."Shopify Payout Bank Acc. No.")
        then
            Error(
                'Shopify payout bank account %1 does not exist.',
                ShopifySetup."Shopify Payout Bank Acc. No.");

        if BankAccount.Blocked then
            Error(
                'Shopify payout bank account %1 is blocked.',
                BankAccount."No.");

        if not ClearingGLAccount.Get(
            ShopifySetup."Shopify Clearing G/L Acc. No.")
        then
            Error(
                'Shopify clearing G/L account %1 does not exist.',
                ShopifySetup."Shopify Clearing G/L Acc. No.");

        ValidatePostingGLAccount(
            ClearingGLAccount,
            'Shopify clearing');

        if not FeeGLAccount.Get(
            ShopifySetup."Shopify Fee G/L Acc. No.")
        then
            Error(
                'Shopify fee G/L account %1 does not exist.',
                ShopifySetup."Shopify Fee G/L Acc. No.");

        ValidatePostingGLAccount(
            FeeGLAccount,
            'Shopify fee');

        if not GenJournalTemplate.Get(
            ShopifySetup."Payout Journal Template Name")
        then
            Error(
                'Payout journal template %1 does not exist.',
                ShopifySetup."Payout Journal Template Name");

        if not GenJournalBatch.Get(
            ShopifySetup."Payout Journal Template Name",
            ShopifySetup."Payout Journal Batch Name")
        then
            Error(
                'Payout journal batch %1 / %2 does not exist.',
                ShopifySetup."Payout Journal Template Name",
                ShopifySetup."Payout Journal Batch Name");

        GeneralLedgerSetup.Get();

        if PayoutEntry."Currency Code" <> '' then begin
            if BankAccount."Currency Code" = '' then begin
                if (GeneralLedgerSetup."LCY Code" <> '') and
                   (PayoutEntry."Currency Code" <>
                    GeneralLedgerSetup."LCY Code")
                then
                    Error(
                        'Shopify payout currency %1 does not match local currency %2, while bank account %3 is configured as an LCY bank account.',
                        PayoutEntry."Currency Code",
                        GeneralLedgerSetup."LCY Code",
                        BankAccount."No.");
            end else
                if BankAccount."Currency Code" <>
                   PayoutEntry."Currency Code"
                then
                    Error(
                        'Shopify payout currency %1 does not match bank account %2 currency %3.',
                        PayoutEntry."Currency Code",
                        BankAccount."No.",
                        BankAccount."Currency Code");
        end;

        if Abs(
            PayoutEntry."Summary Difference") > 0.02
        then
            Error(
                'Shopify payout summary does not reconcile. Net plus fees is %1, summary gross is %2, difference is %3.',
                PayoutEntry."Clearing Settlement Amount",
                PayoutEntry."Summary Gross Amount",
                PayoutEntry."Summary Difference");
    end;

    local procedure ValidatePostingGLAccount(
        GLAccount: Record "G/L Account";
        AccountRole: Text)
    begin
        if GLAccount.Blocked then
            Error(
                '%1 G/L account %2 is blocked.',
                AccountRole,
                GLAccount."No.");

        if GLAccount."Account Type" <>
           GLAccount."Account Type"::Posting
        then
            Error(
                '%1 G/L account %2 must be a Posting account.',
                AccountRole,
                GLAccount."No.");

        if not GLAccount."Direct Posting" then
            Error(
                '%1 G/L account %2 must allow Direct Posting.',
                AccountRole,
                GLAccount."No.");
    end;

    local procedure BuildPayoutJournalLine(
        PayoutEntry: Record "Shopify Payout Entry";
        ShopifySetup: Record "Shopify Integration Setup";
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        IsFeeLine: Boolean;
        var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        PostingDate: Date;
        DescriptionText: Text;
        LineAmount: Decimal;
    begin
        PostingDate :=
            DT2Date(
                PayoutEntry."Issued At");

        if PostingDate = 0D then
            PostingDate :=
                WorkDate();

        GenJournalLine.Init();

        if IsFeeLine then begin
            DescriptionText :=
                StrSubstNo(
                    'Shopify payout fee %1',
                    PayoutEntry."Legacy Resource ID");

            LineAmount :=
                PayoutEntry."Total Fee Amount";
        end else begin
            DescriptionText :=
                StrSubstNo(
                    'Shopify payout %1',
                    PayoutEntry."Legacy Resource ID");

            LineAmount :=
                PayoutEntry."Net Amount";
        end;

        GenJournalLine.InitNewLine(
            PostingDate,
            PostingDate,
            PostingDate,
            CopyStr(
                DescriptionText,
                1,
                MaxStrLen(
                    GenJournalLine.Description)),
            '',
            '',
            0,
            '');

        GenJournalLine."Journal Template Name" :=
            ShopifySetup."Payout Journal Template Name";

        GenJournalLine."Journal Batch Name" :=
            ShopifySetup."Payout Journal Batch Name";

        if GenJournalTemplate.Get(
            ShopifySetup."Payout Journal Template Name")
        then
            GenJournalLine."Source Code" :=
                GenJournalTemplate."Source Code";

        GenJournalLine.Validate(
            "Document Type",
            GenJournalLine."Document Type"::Payment);

        GenJournalLine.Validate(
            "Document No.",
            DocumentNo);

        GenJournalLine."External Document No." :=
            CopyStr(
                PayoutEntry."Shopify Payout ID",
                1,
                MaxStrLen(
                    GenJournalLine."External Document No."));

        if IsFeeLine then begin
            GenJournalLine.Validate(
                "Account Type",
                GenJournalLine."Account Type"::"G/L Account");

            GenJournalLine.Validate(
                "Account No.",
                ShopifySetup."Shopify Fee G/L Acc. No.");
        end else begin
            GenJournalLine.Validate(
                "Account Type",
                GenJournalLine."Account Type"::"Bank Account");

            GenJournalLine.Validate(
                "Account No.",
                ShopifySetup."Shopify Payout Bank Acc. No.");
        end;

        if CurrencyCode <> '' then
            GenJournalLine.Validate(
                "Currency Code",
                CurrencyCode);

        GenJournalLine.Validate(
            Amount,
            LineAmount);

        GenJournalLine.Validate(
            "Bal. Account Type",
            GenJournalLine."Bal. Account Type"::"G/L Account");

        GenJournalLine.Validate(
            "Bal. Account No.",
            ShopifySetup."Shopify Clearing G/L Acc. No.");

        GenJournalLine."System-Created Entry" :=
            true;
    end;

    local procedure GetPayoutDocumentNo(
        PayoutEntry: Record "Shopify Payout Entry"): Code[20]
    var
        IdText: Text;
    begin
        if PayoutEntry."Legacy Resource ID" <> 0 then
            IdText :=
                Format(
                    PayoutEntry."Legacy Resource ID",
                    0,
                    9)
        else
            IdText :=
                CopyStr(
                    PayoutEntry."Shopify Payout ID",
                    1,
                    14);

        exit(
            CopyStr(
                'SPOUT-' + IdText,
                1,
                20));
    end;

    local procedure IsPayoutAlreadyPosted(
        DocumentNo: Code[20]): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange(
            "Document No.",
            DocumentNo);

        exit(
            not GLEntry.IsEmpty());
    end;

    local procedure GetJournalCurrencyCode(
        PayoutCurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();

        if (GeneralLedgerSetup."LCY Code" <> '') and
           (PayoutCurrencyCode = GeneralLedgerSetup."LCY Code")
        then
            exit('');

        exit(
            PayoutCurrencyCode);
    end;

    local procedure GetNestedMoneyAmount(
        ParentObject: JsonObject;
        PropertyName: Text): Decimal
    var
        ShopifyClient: Codeunit "Shopify Client";
        MoneyObject: JsonObject;
    begin
        if not ShopifyClient.TryGetObject(
            ParentObject,
            PropertyName,
            MoneyObject)
        then
            exit(0);

        exit(
            GetMoneyAmount(
                MoneyObject));
    end;

    local procedure GetMoneyAmount(
        MoneyObject: JsonObject): Decimal
    var
        ShopifyClient: Codeunit "Shopify Client";
        AmountText: Text;
        Amount: Decimal;
    begin
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
                'Shopify money amount %1 could not be converted to a decimal value.',
                AmountText);

        exit(
            Amount);
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

        if not Token.IsValue() then
            Error(
                'JSON property %1 is not a value.',
                PropertyName);

        exit(
            Token.AsValue().AsDateTime());
    end;

    local procedure GetBigInteger(
        ParentObject: JsonObject;
        PropertyName: Text): BigInteger
    var
        ShopifyClient: Codeunit "Shopify Client";
        ValueText: Text;
        ResultValue: BigInteger;
    begin
        ValueText :=
            ShopifyClient.GetText(
                ParentObject,
                PropertyName);

        if not Evaluate(
            ResultValue,
            ValueText,
            9)
        then
            Error(
                'JSON property %1 value %2 could not be converted to BigInteger.',
                PropertyName,
                ValueText);

        exit(
            ResultValue);
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

        if not Token.IsValue() then
            Error(
                'JSON property %1 is not a value.',
                PropertyName);

        exit(
            Token.AsValue().AsBoolean());
    end;

    local procedure GetSetup(
        var ShopifySetup: Record "Shopify Integration Setup")
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist.');
    end;
}
