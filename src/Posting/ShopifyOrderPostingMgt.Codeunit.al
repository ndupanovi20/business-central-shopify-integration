codeunit 50217 "Shopify Order Posting Mgt."
{
    procedure PreviewPosting(
        ImportRecord: Record "Shopify Order Import")
    var
        SalesHeader: Record "Sales Header";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
    begin
        GetOpenSalesOrder(
            ImportRecord,
            SalesHeader);

        SalesPostYesNo.Preview(
            SalesHeader);
    end;

    procedure PostImportRecord(
        var ImportRecord: Record "Shopify Order Import";
        ShowResultMessage: Boolean): Boolean
    var
        ShopifySetup: Record "Shopify Integration Setup";
    begin
        GetSetup(
            ShopifySetup);

        exit(
            PostImportRecordWithMode(
                ImportRecord,
                ShopifySetup."Posting Mode",
                ShowResultMessage));
    end;

    procedure PostImportRecordWithMode(
        var ImportRecord: Record "Shopify Order Import";
        PostingMode: Enum "Shopify Posting Mode";
        ShowResultMessage: Boolean): Boolean
    var
        Runner: Codeunit "Shopify Sales Posting Runner";
        SyncLogMgt: Codeunit "Shopify Sync Log Mgt.";
        ErrorText: Text;
        StartedAt: DateTime;
        ShopifyOrderId: Text;
    begin
        ImportRecord.TestField(
            "Shopify Order ID");

        ImportRecord.TestField(
            "BC Order No.");

        ShopifyOrderId :=
            ImportRecord."Shopify Order ID";

        ImportRecord."Posting Status" :=
            ImportRecord."Posting Status"::Pending;

        ImportRecord."Posting Mode Used" :=
            PostingMode;

        ImportRecord."Posting Attempt Count" +=
            1;

        ImportRecord."Last Posting Attempt At" :=
            CurrentDateTime();

        Clear(
            ImportRecord."Posting Error");

        ImportRecord.Modify(false);

        StartedAt :=
            CurrentDateTime();

        // The posting runner changes Business Central records.
        // Complete the current transaction before executing it
        // in its own Codeunit.Run scope.
        Commit();

        ClearLastError();

        if Runner.Run(
            ImportRecord)
        then begin
            ImportRecord.Get(
                ShopifyOrderId);

            SyncLogMgt.LogSuccess(
                "Shopify Sync Direction"::System,
                "Shopify Sync Entity"::Posting,
                ImportRecord."BC Order No.",
                ImportRecord."Shopify Order ID",
                StrSubstNo(
                    'Business Central posting completed for Shopify order %1. Mode: %2. Shipment: %3. Invoice: %4.',
                    ImportRecord."Shopify Order Name",
                    Format(ImportRecord."Posting Mode Used"),
                    ImportRecord."Posted Shipment No.",
                    ImportRecord."Posted Invoice No."),
                CurrentDateTime() - StartedAt);

            if ShowResultMessage then
                Message(
                    'Shopify order %1 was posted successfully.\Mode: %2\Posted shipment: %3\Posted invoice: %4',
                    ImportRecord."Shopify Order Name",
                    Format(ImportRecord."Posting Mode Used"),
                    ImportRecord."Posted Shipment No.",
                    ImportRecord."Posted Invoice No.");

            exit(true);
        end;

        ErrorText :=
            GetLastErrorText();

        if ErrorText = '' then
            ErrorText :=
                'Unknown error while posting Shopify Sales Order.';

        ImportRecord.Get(
            ShopifyOrderId);

        ImportRecord."Posting Status" :=
            ImportRecord."Posting Status"::Error;

        ImportRecord."Posting Error" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(
                    ImportRecord."Posting Error"));

        ImportRecord.Modify(false);

        SyncLogMgt.LogError(
            "Shopify Sync Direction"::System,
            "Shopify Sync Entity"::Posting,
            ImportRecord."BC Order No.",
            ImportRecord."Shopify Order ID",
            ErrorText,
            CurrentDateTime() - StartedAt);

        if ShowResultMessage then
            Message(
                'Shopify Sales Order posting failed.\%1',
                ErrorText);

        exit(false);
    end;

    procedure PostImportRecordCore(
        var ImportRecord: Record "Shopify Order Import")
    var
        ShopifySetup: Record "Shopify Integration Setup";
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
        PreviousShipmentNo: Code[20];
        PreviousInvoiceNo: Code[20];
        PostingDate: Date;
        Ship: Boolean;
        Invoice: Boolean;
    begin
        GetSetup(
            ShopifySetup);

        ImportRecord.TestField(
            "BC Order No.");

        GetOpenSalesOrder(
            ImportRecord,
            SalesHeader);

        GetPostingFlags(
            ImportRecord."Posting Mode Used",
            Ship,
            Invoice);

        PostingDate :=
            GetPostingDate(
                ShopifySetup,
                ImportRecord);

        PreviousShipmentNo := ImportRecord."Posted Shipment No.";
        PreviousInvoiceNo := ImportRecord."Posted Invoice No.";
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Ship := Ship;
        SalesHeader.Invoice := Invoice;
        SalesHeader.Modify(true);

        // The outer Boolean Codeunit.Run owns the transaction. A failure must
        // roll back both posting and the integration links, including manual-post events.
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);
        ImportRecord.Get(ImportRecord."Shopify Order ID");

        if Ship and ((ImportRecord."Posted Shipment No." = '') or
                     (ImportRecord."Posted Shipment No." = PreviousShipmentNo)) then
            Error('Sales posting did not create a new shipment.');
        if Invoice and ((ImportRecord."Posted Invoice No." = '') or
                        (ImportRecord."Posted Invoice No." = PreviousInvoiceNo)) then
            Error('Sales posting did not create a new invoice.');

        ImportRecord."Posting Status" :=
            ImportRecord."Posting Status"::Success;

        ImportRecord."Posted At" :=
            CurrentDateTime();

        Clear(
            ImportRecord."Posting Error");

        ImportRecord.Modify(false);
    end;


    procedure ProcessPendingAutoPostings(ShowResultMessage: Boolean): Integer
    var
        ImportRecord: Record "Shopify Order Import";
        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        QueueUnpostedOrders();
        while true do begin
            ImportRecord.Reset();
            ImportRecord.SetRange(
                "Posting Status",
                ImportRecord."Posting Status"::Pending);

            if not ImportRecord.FindFirst() then
                break;

            if PostImportRecordWithMode(
                ImportRecord,
                ImportRecord."Posting Mode Used",
                false)
            then
                SuccessCount += 1
            else
                ErrorCount += 1;
        end;

        if ShowResultMessage then
            Message(
                'Pending Shopify posting completed.\Successful: %1\Failed: %2',
                SuccessCount,
                ErrorCount);

        exit(SuccessCount);
    end;

    procedure RetryFailedPosting()
    var
        ImportRecord: Record "Shopify Order Import";
        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        ImportRecord.SetRange(
            "Posting Status",
            ImportRecord."Posting Status"::Error);

        if not ImportRecord.FindSet() then begin
            Message(
                'There are no failed Shopify posting operations to retry.');

            exit;
        end;

        repeat
            if PostImportRecordWithMode(
                ImportRecord,
                ImportRecord."Posting Mode Used",
                false)
            then
                SuccessCount += 1
            else
                ErrorCount += 1;
        until ImportRecord.Next() = 0;

        Message(
            'Shopify posting retry completed.\Successful: %1\Failed: %2',
            SuccessCount,
            ErrorCount);
    end;

    procedure OpenPostedShipment(
        ImportRecord: Record "Shopify Order Import")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        ImportRecord.TestField(
            "Posted Shipment No.");

        if not SalesShipmentHeader.Get(
            ImportRecord."Posted Shipment No.")
        then
            Error(
                'Posted Sales Shipment %1 does not exist.',
                ImportRecord."Posted Shipment No.");

        Page.Run(
            Page::"Posted Sales Shipment",
            SalesShipmentHeader);
    end;

    procedure OpenPostedInvoice(
        ImportRecord: Record "Shopify Order Import")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        ImportRecord.TestField(
            "Posted Invoice No.");

        if not SalesInvoiceHeader.Get(
            ImportRecord."Posted Invoice No.")
        then
            Error(
                'Posted Sales Invoice %1 does not exist.',
                ImportRecord."Posted Invoice No.");

        Page.Run(
            Page::"Posted Sales Invoice",
            SalesInvoiceHeader);
    end;

    local procedure GetOpenSalesOrder(
        ImportRecord: Record "Shopify Order Import";
        var SalesHeader: Record "Sales Header")
    begin
        if not SalesHeader.Get(
            SalesHeader."Document Type"::Order,
            ImportRecord."BC Order No.")
        then
            Error(
                'Business Central Sales Order %1 does not exist or has already been fully posted.',
                ImportRecord."BC Order No.");
    end;

    local procedure GetPostingFlags(
        PostingMode: Enum "Shopify Posting Mode";
        var Ship: Boolean;
        var Invoice: Boolean)
    begin
        Ship := false;
        Invoice := false;

        case PostingMode of
            "Shopify Posting Mode"::Ship:
                Ship := true;

            "Shopify Posting Mode"::Invoice:
                Invoice := true;

            "Shopify Posting Mode"::"Ship and Invoice":
                begin
                    Ship := true;
                    Invoice := true;
                end;

            else
                Error(
                    'Posting mode None cannot be executed.');
        end;
    end;

    local procedure GetPostingDate(
        ShopifySetup: Record "Shopify Integration Setup";
        ImportRecord: Record "Shopify Order Import"): Date
    begin
        case ShopifySetup."Posting Date Source" of
            ShopifySetup."Posting Date Source"::"Shopify Order Date":
                begin
                    if ImportRecord."Shopify Created At" <> 0DT then
                        exit(
                            DT2Date(
                                ImportRecord."Shopify Created At"));
                end;
        end;

        exit(
            WorkDate());
    end;

    procedure QueueUnpostedOrders()
    var
        ImportRecord: Record "Shopify Order Import";
        SalesHeader: Record "Sales Header";
        ShopifySetup: Record "Shopify Integration Setup";
    begin
        GetSetup(ShopifySetup);
        ImportRecord.SetRange("Posting Status", ImportRecord."Posting Status"::"Not Required");
        if ImportRecord.FindSet(true) then
            repeat
                if SalesHeader.Get(SalesHeader."Document Type"::Order, ImportRecord."BC Order No.") then begin
                    ImportRecord."Posting Status" := ImportRecord."Posting Status"::Pending;
                    ImportRecord."Posting Mode Used" := ShopifySetup."Posting Mode";
                    ImportRecord.Modify(false);
                end;
            until ImportRecord.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(
        var SalesHeader: Record "Sales Header";
        SalesShptHdrNo: Code[20];
        SalesInvHdrNo: Code[20];
        PreviewMode: Boolean)
    var
        ImportRecord: Record "Shopify Order Import";
    begin
        if PreviewMode or SalesHeader.IsTemporary() then
            exit;
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit;
        if (SalesShptHdrNo = '') and (SalesInvHdrNo = '') then
            exit;

        ImportRecord.SetRange("BC Order No.", SalesHeader."No.");
        if not ImportRecord.FindFirst() then
            exit;
        if SalesShptHdrNo <> '' then
            ImportRecord."Posted Shipment No." := SalesShptHdrNo;
        if SalesInvHdrNo <> '' then
            ImportRecord."Posted Invoice No." := SalesInvHdrNo;
        if (SalesShptHdrNo <> '') and (SalesInvHdrNo <> '') then
            ImportRecord."Posting Mode Used" := ImportRecord."Posting Mode Used"::"Ship and Invoice"
        else
            if SalesInvHdrNo <> '' then
                ImportRecord."Posting Mode Used" := ImportRecord."Posting Mode Used"::Invoice
            else
                ImportRecord."Posting Mode Used" := ImportRecord."Posting Mode Used"::Ship;
        ImportRecord."Posting Status" := ImportRecord."Posting Status"::Success;
        ImportRecord."Posted At" := CurrentDateTime();
        Clear(ImportRecord."Posting Error");
        ImportRecord.Modify(false);
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
    [EventSubscriber(
        ObjectType::Table,
        Database::"Shopify Order Import",
        'OnAfterInsertEvent',
        '',
        false,
        false)]
    local procedure OnAfterShopifyOrderImportInsert(
        var Rec: Record "Shopify Order Import";
        RunTrigger: Boolean)
    var
        ShopifySetup: Record "Shopify Integration Setup";
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then
            exit;

        if not ShopifySetup."Auto Post Imported Orders" then
            exit;

        Rec."Posting Status" :=
            Rec."Posting Status"::Pending;

        Rec."Posting Mode Used" :=
            ShopifySetup."Posting Mode";

        Rec.Modify(false);
    end;

}
