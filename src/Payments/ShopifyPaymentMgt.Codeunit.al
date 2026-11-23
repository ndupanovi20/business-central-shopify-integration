codeunit 50227 "Shopify Payment Mgt."
{
    procedure PreviewPayment(
        ImportRecord: Record "Shopify Order Import")
    var
        GenJournalLine:
            Record "Gen. Journal Line";

        GenJnlPost:
            Codeunit "Gen. Jnl.-Post";
    begin
        BuildPaymentJournalLine(
            ImportRecord,
            GenJournalLine);

        GenJnlPost.Preview(
            GenJournalLine);
    end;

    procedure RecordPaymentForImport(
        var ImportRecord: Record "Shopify Order Import";
        ShowResultMessage: Boolean): Boolean
    var
        PaymentEntry:
            Record "Shopify Payment Entry";

        Runner:
            Codeunit "Shopify Payment Posting Runner";

        SyncLogMgt:
            Codeunit "Shopify Sync Log Mgt.";

        ShopifyOrderId: Text;
        ErrorText: Text;
        StartedAt: DateTime;
    begin
        ShopifyOrderId :=
            ImportRecord."Shopify Order ID";

        if PaymentEntry.Get(
            ShopifyOrderId)
        then
            if PaymentEntry.Status =
               PaymentEntry.Status::Success
            then begin
                if ShowResultMessage then
                    Message(
                        'Shopify payment for order %1 has already been recorded as %2.',
                        ImportRecord."Shopify Order Name",
                        PaymentEntry."Payment Document No.");

                exit(true);
            end;

        PreparePaymentEntry(
            ImportRecord,
            PaymentEntry);

        StartedAt :=
            CurrentDateTime();

        Commit();

        ClearLastError();

        if Runner.Run(
            PaymentEntry)
        then begin
            PaymentEntry.Get(
                ShopifyOrderId);

            case PaymentEntry.Status of
                PaymentEntry.Status::Success:
                    SyncLogMgt.LogSuccess(
                        "Shopify Sync Direction"::System,
                        "Shopify Sync Entity"::Payment,
                        PaymentEntry."Posted Invoice No.",
                        PaymentEntry."Shopify Order ID",
                        StrSubstNo(
                            'Shopify payment %1 was recorded and applied to posted invoice %2. Amount: %3 %4. Clearing account: %5.',
                            PaymentEntry."Payment Document No.",
                            PaymentEntry."Posted Invoice No.",
                            PaymentEntry.Amount,
                            PaymentEntry."Currency Code",
                            PaymentEntry."Clearing G/L Account No."),
                        CurrentDateTime() - StartedAt);

                PaymentEntry.Status::Skipped:
                    SyncLogMgt.LogInfo(
                        "Shopify Sync Direction"::System,
                        "Shopify Sync Entity"::Payment,
                        PaymentEntry."Posted Invoice No.",
                        PaymentEntry."Shopify Order ID",
                        PaymentEntry."Result Message");
            end;

            if ShowResultMessage then
                Message(
                    'Shopify payment processing completed for order %1.\Status: %2\Payment document: %3\Amount: %4 %5\%6',
                    PaymentEntry."Shopify Order Name",
                    Format(
                        PaymentEntry.Status),
                    PaymentEntry."Payment Document No.",
                    PaymentEntry.Amount,
                    PaymentEntry."Currency Code",
                    PaymentEntry."Result Message");

            exit(
                PaymentEntry.Status =
                PaymentEntry.Status::Success);
        end;

        ErrorText :=
            GetLastErrorText();

        if ErrorText = '' then
            ErrorText :=
                'Unknown error while recording Shopify payment.';

        PaymentEntry.Get(
            ShopifyOrderId);

        PaymentEntry.Status :=
            PaymentEntry.Status::Error;

        PaymentEntry."Payment Error" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(
                    PaymentEntry."Payment Error"));

        PaymentEntry."Result Message" :=
            CopyStr(
                'Payment posting failed.',
                1,
                MaxStrLen(
                    PaymentEntry."Result Message"));

        PaymentEntry.Modify(false);

        SyncLogMgt.LogError(
            "Shopify Sync Direction"::System,
            "Shopify Sync Entity"::Payment,
            PaymentEntry."Posted Invoice No.",
            PaymentEntry."Shopify Order ID",
            ErrorText,
            CurrentDateTime() - StartedAt);

        if ShowResultMessage then
            Message(
                'Shopify payment posting failed for order %1.\%2',
                PaymentEntry."Shopify Order Name",
                ErrorText);

        exit(false);
    end;

    procedure RecordPaymentCore(
        var PaymentEntry: Record "Shopify Payment Entry")
    var
        ImportRecord:
            Record "Shopify Order Import";

        ShopifySetup:
            Record "Shopify Integration Setup";

        SalesInvoiceHeader:
            Record "Sales Invoice Header";

        InvoiceCustLedgerEntry:
            Record "Cust. Ledger Entry";

        PaymentCustLedgerEntry:
            Record "Cust. Ledger Entry";

        GenJournalLine:
            Record "Gen. Journal Line";

        GenJnlPostLine:
            Codeunit "Gen. Jnl.-Post Line";

        RemainingAmount: Decimal;
        EffectiveCurrencyCode: Code[10];
    begin
        if not ImportRecord.Get(
            PaymentEntry."Shopify Order ID")
        then
            Error(
                'Shopify Order Import %1 does not exist.',
                PaymentEntry."Shopify Order ID");

        GetSetup(ShopifySetup);
        ValidateImportForPayment(ImportRecord);

        ImportRecord.TestField(
            "Posted Invoice No.");

        if not SalesInvoiceHeader.Get(
            ImportRecord."Posted Invoice No.")
        then
            Error(
                'Posted Sales Invoice %1 does not exist.',
                ImportRecord."Posted Invoice No.");

        GetInvoiceCustLedgerEntry(
            SalesInvoiceHeader,
            InvoiceCustLedgerEntry);

        PaymentEntry."Invoice Cust. Ledger Entry No." :=
            InvoiceCustLedgerEntry."Entry No.";

        PaymentEntry."Customer No." :=
            SalesInvoiceHeader."Bill-to Customer No.";

        PaymentEntry."Payment Document No." :=
            GetPaymentDocumentNo(
                ImportRecord);

        PaymentEntry.Modify(false);

        if FindExistingPaymentLedgerEntry(
            PaymentEntry,
            PaymentCustLedgerEntry)
        then begin
            InvoiceCustLedgerEntry.CalcFields(
                "Remaining Amount");

            if InvoiceCustLedgerEntry.Open and
               (Abs(
                   InvoiceCustLedgerEntry."Remaining Amount") > 0.02)
            then
                Error(
                    'Existing payment %1 was found, but invoice %2 is still open with remaining amount %3.',
                    PaymentEntry."Payment Document No.",
                    SalesInvoiceHeader."No.",
                    InvoiceCustLedgerEntry."Remaining Amount");

            PaymentEntry."Payment Cust. Ledger Entry No." :=
                PaymentCustLedgerEntry."Entry No.";

            PaymentEntry.Status :=
                PaymentEntry.Status::Success;

            PaymentEntry."Posted At" :=
                CurrentDateTime();

            PaymentEntry."Result Message" :=
                CopyStr(
                    'Existing Business Central payment ledger entry was found and linked.',
                    1,
                    MaxStrLen(
                        PaymentEntry."Result Message"));

            Clear(
                PaymentEntry."Payment Error");

            PaymentEntry.Modify(false);

            exit;
        end;

        InvoiceCustLedgerEntry.CalcFields(
            "Remaining Amount");

        RemainingAmount :=
            Abs(
                InvoiceCustLedgerEntry."Remaining Amount");

        if (not InvoiceCustLedgerEntry.Open) or
           (RemainingAmount = 0)
        then begin
            PaymentEntry.Status :=
                PaymentEntry.Status::Skipped;

            PaymentEntry.Amount :=
                0;

            PaymentEntry."Result Message" :=
                CopyStr(
                    'Posted invoice is already closed. No additional Shopify payment was posted.',
                    1,
                    MaxStrLen(
                        PaymentEntry."Result Message"));

            Clear(
                PaymentEntry."Payment Error");

            PaymentEntry.Modify(false);

            exit;
        end;

        EffectiveCurrencyCode :=
            GetEffectiveCurrencyCode(
                SalesInvoiceHeader."Currency Code");

        if (ImportRecord."Currency Code" <> '') and
           (EffectiveCurrencyCode <>
            ImportRecord."Currency Code")
        then
            Error(
                'Currency mismatch. Shopify order currency is %1, while posted invoice currency is %2.',
                ImportRecord."Currency Code",
                EffectiveCurrencyCode);

        if Abs(
            Round(
                RemainingAmount -
                ImportRecord."Shopify Total",
                0.01)) > 0.02
        then
            Error(
                'Payment amount mismatch. Shopify total is %1 %2, while the posted invoice remaining amount is %3 %2.',
                ImportRecord."Shopify Total",
                EffectiveCurrencyCode,
                RemainingAmount);

        BuildPaymentJournalLine(
            ImportRecord,
            GenJournalLine);

        PaymentEntry.Amount :=
            RemainingAmount;

        PaymentEntry."Currency Code" :=
            EffectiveCurrencyCode;

        PaymentEntry."Customer No." :=
            SalesInvoiceHeader."Bill-to Customer No.";

        PaymentEntry."Clearing G/L Account No." :=
            ShopifySetup."Shopify Clearing G/L Acc. No.";

        PaymentEntry."Payment Document No." :=
            GenJournalLine."Document No.";

        PaymentEntry.Modify(false);

        GenJnlPostLine.RunWithCheck(
            GenJournalLine);

        if not FindPaymentLedgerEntryByDocument(
            SalesInvoiceHeader."Bill-to Customer No.",
            GenJournalLine."Document No.",
            PaymentCustLedgerEntry)
        then
            Error(
                'Payment %1 was posted, but its Customer Ledger Entry could not be found.',
                GenJournalLine."Document No.");

        InvoiceCustLedgerEntry.Get(
            InvoiceCustLedgerEntry."Entry No.");

        InvoiceCustLedgerEntry.CalcFields(
            "Remaining Amount");

        if InvoiceCustLedgerEntry.Open and
           (Abs(
               InvoiceCustLedgerEntry."Remaining Amount") > 0.02)
        then
            Error(
                'Payment %1 was posted, but invoice %2 still has a remaining amount of %3.',
                GenJournalLine."Document No.",
                SalesInvoiceHeader."No.",
                InvoiceCustLedgerEntry."Remaining Amount");

        PaymentEntry.Get(
            PaymentEntry."Shopify Order ID");

        PaymentEntry.Status :=
            PaymentEntry.Status::Success;

        PaymentEntry."Payment Cust. Ledger Entry No." :=
            PaymentCustLedgerEntry."Entry No.";

        PaymentEntry."Invoice Cust. Ledger Entry No." :=
            InvoiceCustLedgerEntry."Entry No.";

        PaymentEntry."Posted At" :=
            CurrentDateTime();

        PaymentEntry."Result Message" :=
            CopyStr(
                StrSubstNo(
                    'Payment was posted to clearing account %1 and applied to invoice %2.',
                    ShopifySetup."Shopify Clearing G/L Acc. No.",
                    SalesInvoiceHeader."No."),
                1,
                MaxStrLen(
                    PaymentEntry."Result Message"));

        Clear(
            PaymentEntry."Payment Error");

        PaymentEntry.Modify(false);
    end;

    procedure ProcessEligiblePayments(
        ShowResultMessage: Boolean): Integer
    var
        ImportRecord:
            Record "Shopify Order Import";

        PaymentEntry:
            Record "Shopify Payment Entry";

        SuccessCount: Integer;
        SkippedCount: Integer;
        ErrorCount: Integer;
    begin
        ImportRecord.Reset();

        ImportRecord.SetRange(
            "Posting Status",
            ImportRecord."Posting Status"::Success);

        ImportRecord.SetRange(
            "Financial Status",
            'PAID');

        if ImportRecord.FindSet() then
            repeat
                if ImportRecord."Posted Invoice No." <> '' then begin
                    if PaymentEntry.Get(
                        ImportRecord."Shopify Order ID")
                    then begin
                        if PaymentEntry.Status =
                           PaymentEntry.Status::Pending
                        then begin
                            RecordPaymentForImport(
                                ImportRecord,
                                false);

                            PaymentEntry.Get(
                                ImportRecord."Shopify Order ID");

                            CountPaymentResult(
                                PaymentEntry,
                                SuccessCount,
                                SkippedCount,
                                ErrorCount);
                        end;
                    end else begin
                        RecordPaymentForImport(
                            ImportRecord,
                            false);

                        if PaymentEntry.Get(
                            ImportRecord."Shopify Order ID")
                        then
                            CountPaymentResult(
                                PaymentEntry,
                                SuccessCount,
                                SkippedCount,
                                ErrorCount)
                        else
                            ErrorCount += 1;
                    end;
                end;
            until ImportRecord.Next() = 0;

        if ShowResultMessage then
            Message(
                'Shopify payment processing completed.\Successful: %1\Skipped: %2\Failed: %3',
                SuccessCount,
                SkippedCount,
                ErrorCount);

        exit(
            SuccessCount);
    end;

    procedure RetryFailedPayments()
    var
        PaymentEntry:
            Record "Shopify Payment Entry";

        ImportRecord:
            Record "Shopify Order Import";

        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        PaymentEntry.SetRange(
            Status,
            PaymentEntry.Status::Error);

        if not PaymentEntry.FindSet() then begin
            Message(
                'There are no failed Shopify payments to retry.');

            exit;
        end;

        repeat
            if ImportRecord.Get(
                PaymentEntry."Shopify Order ID")
            then begin
                if RecordPaymentForImport(
                    ImportRecord,
                    false)
                then
                    SuccessCount += 1
                else
                    ErrorCount += 1;
            end else
                ErrorCount += 1;
        until PaymentEntry.Next() = 0;

        Message(
            'Shopify payment retry completed.\Successful: %1\Failed: %2',
            SuccessCount,
            ErrorCount);
    end;

    procedure RetryPaymentEntry(
        PaymentEntry: Record "Shopify Payment Entry";
        ShowResultMessage: Boolean): Boolean
    var
        ImportRecord:
            Record "Shopify Order Import";
    begin
        if not ImportRecord.Get(
            PaymentEntry."Shopify Order ID")
        then
            Error(
                'Shopify Order Import %1 does not exist.',
                PaymentEntry."Shopify Order ID");

        exit(
            RecordPaymentForImport(
                ImportRecord,
                ShowResultMessage));
    end;

    local procedure CountPaymentResult(
        PaymentEntry: Record "Shopify Payment Entry";
        var SuccessCount: Integer;
        var SkippedCount: Integer;
        var ErrorCount: Integer)
    begin
        case PaymentEntry.Status of
            PaymentEntry.Status::Success:
                SuccessCount += 1;

            PaymentEntry.Status::Skipped:
                SkippedCount += 1;

            PaymentEntry.Status::Error:
                ErrorCount += 1;
        end;
    end;

    local procedure PreparePaymentEntry(
        ImportRecord: Record "Shopify Order Import";
        var PaymentEntry: Record "Shopify Payment Entry")
    var
        ShopifySetup:
            Record "Shopify Integration Setup";
    begin
        GetSetup(
            ShopifySetup);

        if not PaymentEntry.Get(
            ImportRecord."Shopify Order ID")
        then begin
            PaymentEntry.Init();

            PaymentEntry."Shopify Order ID" :=
                CopyStr(
                    ImportRecord."Shopify Order ID",
                    1,
                    MaxStrLen(
                        PaymentEntry."Shopify Order ID"));

            PaymentEntry.Insert(false);
        end;

        PaymentEntry."Shopify Order Name" :=
            ImportRecord."Shopify Order Name";

        PaymentEntry."BC Order No." :=
            ImportRecord."BC Order No.";

        PaymentEntry."Posted Invoice No." :=
            ImportRecord."Posted Invoice No.";

        PaymentEntry."Financial Status" :=
            ImportRecord."Financial Status";

        PaymentEntry."Currency Code" :=
            ImportRecord."Currency Code";

        PaymentEntry.Amount :=
            ImportRecord."Shopify Total";

        PaymentEntry."Clearing G/L Account No." :=
            ShopifySetup."Shopify Clearing G/L Acc. No.";

        PaymentEntry.Status :=
            PaymentEntry.Status::Pending;

        PaymentEntry."Attempt Count" +=
            1;

        PaymentEntry."Last Attempt At" :=
            CurrentDateTime();

        Clear(
            PaymentEntry."Payment Error");

        Clear(
            PaymentEntry."Result Message");

        PaymentEntry.Modify(false);
    end;

    local procedure ValidateImportForPayment(
        ImportRecord: Record "Shopify Order Import")
    var
        ShopifySetup:
            Record "Shopify Integration Setup";
    begin
        GetSetup(
            ShopifySetup);

        ImportRecord.TestField(
            "Shopify Order ID");

        ImportRecord.TestField(
            "Posted Invoice No.");

        if ImportRecord."Posting Status" <>
           ImportRecord."Posting Status"::Success
        then
            Error(
                'Shopify order %1 must be successfully posted before payment can be recorded.',
                ImportRecord."Shopify Order Name");

        if UpperCase(
            ImportRecord."Financial Status") <> 'PAID'
        then
            Error(
                'Shopify order %1 has financial status %2. Only PAID orders can create Shopify clearing payments.',
                ImportRecord."Shopify Order Name",
                ImportRecord."Financial Status");

        ShopifySetup.TestField(
            "Shopify Clearing G/L Acc. No.");

        ShopifySetup.TestField(
            "Payment Journal Template Name");

        ShopifySetup.TestField(
            "Payment Journal Batch Name");

        ValidateClearingAccount(
            ShopifySetup."Shopify Clearing G/L Acc. No.");

        ValidateJournalContext(
            ShopifySetup);
    end;

    local procedure BuildPaymentJournalLine(
        ImportRecord: Record "Shopify Order Import";
        var GenJournalLine: Record "Gen. Journal Line")
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        SalesInvoiceHeader:
            Record "Sales Invoice Header";

        InvoiceCustLedgerEntry:
            Record "Cust. Ledger Entry";

        GenJournalTemplate:
            Record "Gen. Journal Template";

        PostingDate: Date;
        RemainingAmount: Decimal;
        PaymentDocumentNo: Code[20];
        DescriptionText: Text;
    begin
        GetSetup(
            ShopifySetup);

        ValidateImportForPayment(
            ImportRecord);

        if not SalesInvoiceHeader.Get(
            ImportRecord."Posted Invoice No.")
        then
            Error(
                'Posted Sales Invoice %1 does not exist.',
                ImportRecord."Posted Invoice No.");

        GetInvoiceCustLedgerEntry(
            SalesInvoiceHeader,
            InvoiceCustLedgerEntry);

        InvoiceCustLedgerEntry.CalcFields(
            "Remaining Amount");

        RemainingAmount :=
            Abs(
                InvoiceCustLedgerEntry."Remaining Amount");

        if (not InvoiceCustLedgerEntry.Open) or
           (RemainingAmount = 0)
        then
            Error(
                'Posted invoice %1 is already closed and does not require another payment.',
                SalesInvoiceHeader."No.");

        PostingDate :=
            GetPaymentPostingDate(
                ShopifySetup,
                SalesInvoiceHeader);

        PaymentDocumentNo :=
            GetPaymentDocumentNo(
                ImportRecord);

        DescriptionText :=
            StrSubstNo(
                'Shopify payment %1',
                ImportRecord."Shopify Order Name");

        GenJournalLine.Init();

        GenJournalLine.InitNewLine(
            PostingDate,
            PostingDate,
            PostingDate,
            CopyStr(
                DescriptionText,
                1,
                MaxStrLen(
                    GenJournalLine.Description)),
            SalesInvoiceHeader."Shortcut Dimension 1 Code",
            SalesInvoiceHeader."Shortcut Dimension 2 Code",
            SalesInvoiceHeader."Dimension Set ID",
            '');

        GenJournalLine."Journal Template Name" :=
            ShopifySetup."Payment Journal Template Name";

        GenJournalLine."Journal Batch Name" :=
            ShopifySetup."Payment Journal Batch Name";

        if GenJournalTemplate.Get(
            ShopifySetup."Payment Journal Template Name")
        then
            GenJournalLine."Source Code" :=
                GenJournalTemplate."Source Code";

        GenJournalLine.Validate(
            "Document Type",
            GenJournalLine."Document Type"::Payment);

        GenJournalLine.Validate(
            "Account Type",
            GenJournalLine."Account Type"::Customer);

        GenJournalLine.Validate(
            "Account No.",
            SalesInvoiceHeader."Bill-to Customer No.");

        GenJournalLine.Validate(
            "Document No.",
            PaymentDocumentNo);

        GenJournalLine."External Document No." :=
            CopyStr(
                ImportRecord."Shopify Order Name",
                1,
                MaxStrLen(
                    GenJournalLine."External Document No."));

        GenJournalLine.Validate(
            "Currency Code",
            SalesInvoiceHeader."Currency Code");

        GenJournalLine.Validate(
            Amount,
            -RemainingAmount);

        GenJournalLine.Validate(
            "Applies-to Doc. Type",
            GenJournalLine."Applies-to Doc. Type"::Invoice);

        GenJournalLine.Validate(
            "Applies-to Doc. No.",
            SalesInvoiceHeader."No.");

        GenJournalLine.Validate(
            "Bal. Account Type",
            GenJournalLine."Bal. Account Type"::"G/L Account");

        GenJournalLine.Validate(
            "Bal. Account No.",
            ShopifySetup."Shopify Clearing G/L Acc. No.");

        GenJournalLine."System-Created Entry" :=
            true;
    end;

    local procedure GetInvoiceCustLedgerEntry(
        SalesInvoiceHeader: Record "Sales Invoice Header";
        var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.Reset();

        CustLedgerEntry.SetRange(
            "Customer No.",
            SalesInvoiceHeader."Bill-to Customer No.");

        CustLedgerEntry.SetRange(
            "Document Type",
            CustLedgerEntry."Document Type"::Invoice);

        CustLedgerEntry.SetRange(
            "Document No.",
            SalesInvoiceHeader."No.");

        if not CustLedgerEntry.FindLast() then
            Error(
                'Customer Ledger Entry for posted invoice %1 could not be found.',
                SalesInvoiceHeader."No.");
    end;

    local procedure FindExistingPaymentLedgerEntry(
        PaymentEntry: Record "Shopify Payment Entry";
        var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        if PaymentEntry."Payment Document No." = '' then
            exit(false);

        exit(
            FindPaymentLedgerEntryByDocument(
                PaymentEntry."Customer No.",
                PaymentEntry."Payment Document No.",
                CustLedgerEntry));
    end;

    local procedure FindPaymentLedgerEntryByDocument(
        CustomerNo: Code[20];
        PaymentDocumentNo: Code[20];
        var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        CustLedgerEntry.Reset();

        if CustomerNo <> '' then
            CustLedgerEntry.SetRange(
                "Customer No.",
                CustomerNo);

        CustLedgerEntry.SetRange(
            "Document Type",
            CustLedgerEntry."Document Type"::Payment);

        CustLedgerEntry.SetRange(
            "Document No.",
            PaymentDocumentNo);

        exit(
            CustLedgerEntry.FindLast());
    end;

    local procedure ValidateClearingAccount(
        GLAccountNo: Code[20])
    var
        GLAccount:
            Record "G/L Account";
    begin
        if not GLAccount.Get(
            GLAccountNo)
        then
            Error(
                'Shopify clearing G/L account %1 does not exist.',
                GLAccountNo);

        if GLAccount.Blocked then
            Error(
                'Shopify clearing G/L account %1 is blocked.',
                GLAccountNo);

        if GLAccount."Account Type" <>
           GLAccount."Account Type"::Posting
        then
            Error(
                'Shopify clearing G/L account %1 must be a Posting account.',
                GLAccountNo);

        if not GLAccount."Direct Posting" then
            Error(
                'Shopify clearing G/L account %1 must allow Direct Posting.',
                GLAccountNo);

        if GLAccount."Gen. Posting Type" <>
           GLAccount."Gen. Posting Type"::" "
        then
            Error(
                'Shopify clearing G/L account %1 must have a blank Gen. Posting Type.',
                GLAccountNo);
    end;

    local procedure ValidateJournalContext(
        ShopifySetup: Record "Shopify Integration Setup")
    var
        GenJournalTemplate:
            Record "Gen. Journal Template";

        GenJournalBatch:
            Record "Gen. Journal Batch";
    begin
        if not GenJournalTemplate.Get(
            ShopifySetup."Payment Journal Template Name")
        then
            Error(
                'Payment journal template %1 does not exist.',
                ShopifySetup."Payment Journal Template Name");

        if not GenJournalBatch.Get(
            ShopifySetup."Payment Journal Template Name",
            ShopifySetup."Payment Journal Batch Name")
        then
            Error(
                'Payment journal batch %1 / %2 does not exist.',
                ShopifySetup."Payment Journal Template Name",
                ShopifySetup."Payment Journal Batch Name");
    end;

    local procedure GetPaymentPostingDate(
        ShopifySetup: Record "Shopify Integration Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header"): Date
    begin
        case ShopifySetup."Payment Date Source" of
            ShopifySetup."Payment Date Source"::"Work Date":
                exit(
                    WorkDate());
        end;

        exit(
            SalesInvoiceHeader."Posting Date");
    end;

    local procedure GetPaymentDocumentNo(
        ImportRecord: Record "Shopify Order Import"): Code[20]
    var
        CleanOrderName: Text;
        ResultNo: Code[20];
    begin
        CleanOrderName :=
            DelChr(
                ImportRecord."Shopify Order Name",
                '=',
                '# /\\');

        if CleanOrderName = '' then
            CleanOrderName :=
                CopyStr(
                    ImportRecord."BC Order No.",
                    1,
                    14);

        ResultNo :=
            CopyStr(
                'SPPAY-' + CleanOrderName,
                1,
                MaxStrLen(
                    ResultNo));

        exit(
            ResultNo);
    end;

    local procedure GetEffectiveCurrencyCode(
        InvoiceCurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup:
            Record "General Ledger Setup";
    begin
        if InvoiceCurrencyCode <> '' then
            exit(
                InvoiceCurrencyCode);

        GeneralLedgerSetup.Get();

        exit(
            GeneralLedgerSetup."LCY Code");
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
