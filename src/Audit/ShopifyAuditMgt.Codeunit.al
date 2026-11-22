codeunit 50203 "Shopify Audit Mgt."
{
    procedure CreateSnapshot(
        ShowMessage: Boolean): Integer
    var
        Snapshot:
            Record "Shopify Audit Snapshot";

        ShopifySetup:
            Record "Shopify Integration Setup";

        Mapping:
            Record "Shopify Product Mapping";

        ImportRecord:
            Record "Shopify Order Import";

        PaymentEntry:
            Record "Shopify Payment Entry";

        FulfillmentEntry:
            Record "Shopify Fulfillment Entry";

        PayoutEntry:
            Record "Shopify Payout Entry";

        RefundEntry:
            Record "Shopify Refund Entry";

        CustomerMapping:
            Record "Shopify Customer Mapping";

        LocationMapping:
            Record "Shopify Location Mapping";

        Buffer:
            Record "Shopify Order Buffer";

        RetryBuffer:
            Record "Shopify Order Buffer";

        SyncLog:
            Record "Shopify Sync Log";

        AdminMgt:
            Codeunit "Shopify Admin Mgt.";

        Validator:
            Codeunit "Shopify Integration Validator";

        JobQueueMgt:
            Codeunit "Shopify Job Queue Mgt.";

        ValidationResult: Text;

        JobQueueStatus: Text;
        JobQueueError: Text;

        JobQueueNextRun: DateTime;

        JobQueueInterval: Integer;
        TotalRetryAttempts: Integer;
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist.');

        Snapshot.Init();

        Snapshot."Created At" :=
            CurrentDateTime();

        Snapshot."Created By" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(
                    Snapshot."Created By"));

        Snapshot."Company Name" :=
            CopyStr(
                CompanyName(),
                1,
                MaxStrLen(
                    Snapshot."Company Name"));

        Snapshot."Mapped Products" :=
            Mapping.Count();

        Snapshot."Customer Strategy" :=
            ShopifySetup."Customer Strategy";

        Snapshot."Customer Mapping Count" :=
            CustomerMapping.Count();

        Snapshot."Use Location Mappings" :=
            ShopifySetup."Use Location Mappings";

        LocationMapping.SetRange(Active, true);
        LocationMapping.SetFilter("BC Location Code", '<>%1', '');
        LocationMapping.SetFilter("Shopify Location ID", '<>%1', '');

        Snapshot."Location Mapping Count" :=
            LocationMapping.Count();

        Snapshot."Imported Orders" :=
            ImportRecord.Count();

        Buffer.Reset();
        Buffer.SetRange(
            Status,
            Buffer.Status::Pending);

        Snapshot."Pending Buffers" :=
            Buffer.Count();

        Buffer.Reset();
        Buffer.SetRange(
            Status,
            Buffer.Status::Success);

        Snapshot."Successful Buffers" :=
            Buffer.Count();

        Buffer.Reset();
        Buffer.SetRange(
            Status,
            Buffer.Status::Skipped);

        Snapshot."Skipped Buffers" :=
            Buffer.Count();

        Buffer.Reset();
        Buffer.SetRange(
            Status,
            Buffer.Status::Error);

        Snapshot."Error Buffers" :=
            Buffer.Count();

        TotalRetryAttempts :=
            0;

        RetryBuffer.Reset();

        if RetryBuffer.FindSet() then
            repeat
                TotalRetryAttempts +=
                    RetryBuffer."Retry Count";
            until RetryBuffer.Next() = 0;

        Snapshot."Retry Attempts" :=
            TotalRetryAttempts;

        SyncLog.Reset();
        SyncLog.SetRange(
            Status,
            "Shopify Sync Status"::Success);

        Snapshot."Successful Log Entries" :=
            SyncLog.Count();

        SyncLog.Reset();
        SyncLog.SetRange(
            Status,
            "Shopify Sync Status"::Error);

        Snapshot."Error Log Entries" :=
            SyncLog.Count();

        Snapshot."BC Shopify Sales Orders" :=
            AdminMgt.GetDemoSalesOrderCount();

        ImportRecord.Reset();
        ImportRecord.SetRange(
            "Tag Status",
            ImportRecord."Tag Status"::Success);

        Snapshot."Tagged Orders" :=
            ImportRecord.Count();

        ImportRecord.Reset();
        ImportRecord.SetRange(
            "Tag Status",
            ImportRecord."Tag Status"::Error);

        Snapshot."Tag Errors" :=
            ImportRecord.Count();

        PaymentEntry.Reset();
        PaymentEntry.SetRange(
            Status,
            PaymentEntry.Status::Success);

        Snapshot."Payment Successes" :=
            PaymentEntry.Count();

        PaymentEntry.Reset();
        PaymentEntry.SetRange(
            Status,
            PaymentEntry.Status::Skipped);

        Snapshot."Payment Skipped" :=
            PaymentEntry.Count();

        PaymentEntry.Reset();
        PaymentEntry.SetRange(
            Status,
            PaymentEntry.Status::Error);

        Snapshot."Payment Errors" :=
            PaymentEntry.Count();

        FulfillmentEntry.Reset();
        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::Success);

        Snapshot."Fulfillment Successes" :=
            FulfillmentEntry.Count();

        FulfillmentEntry.Reset();
        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::"Waiting for Tracking");

        Snapshot."Fulfillment Waiting Tracking" :=
            FulfillmentEntry.Count();

        FulfillmentEntry.Reset();
        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::Skipped);

        Snapshot."Fulfillment Skipped" :=
            FulfillmentEntry.Count();

        FulfillmentEntry.Reset();
        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::Error);

        Snapshot."Fulfillment Errors" :=
            FulfillmentEntry.Count();


        RefundEntry.Reset();
        RefundEntry.SetRange(
            Status,
            RefundEntry.Status::Success);

        Snapshot."Refund Successes" :=
            RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(
            Status,
            RefundEntry.Status::Pending);

        Snapshot."Refund Pending" :=
            RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(
            Status,
            RefundEntry.Status::Waiting);

        Snapshot."Refund Waiting" :=
            RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(
            Status,
            RefundEntry.Status::"Manual Review");

        Snapshot."Refund Manual Review" :=
            RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(
            Status,
            RefundEntry.Status::Error);

        Snapshot."Refund Errors" :=
            RefundEntry.Count();

        Snapshot."Auto Import Shopify Refunds" :=
            ShopifySetup."Auto Import Shopify Refunds";

        Snapshot."Auto Process Shopify Refunds" :=
            ShopifySetup."Auto Process Shopify Refunds";


        Snapshot."Import Refunds From" :=
            ShopifySetup."Import Refunds From";

        PayoutEntry.Reset();
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Success);

        Snapshot."Payout Successes" :=
            PayoutEntry.Count();

        PayoutEntry.Reset();
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Waiting);

        Snapshot."Payout Waiting" :=
            PayoutEntry.Count();

        PayoutEntry.Reset();
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Skipped);

        Snapshot."Payout Skipped" :=
            PayoutEntry.Count();

        PayoutEntry.Reset();
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Error);

        Snapshot."Payout Errors" :=
            PayoutEntry.Count();

        Snapshot."Auto Import Shopify Payouts" :=
            ShopifySetup."Auto Import Shopify Payouts";

        Snapshot."Auto Post Paid Payouts" :=
            ShopifySetup."Auto Post Paid Payouts";

        Snapshot."Payout Bank Account No." :=
            ShopifySetup."Shopify Payout Bank Acc. No.";

        Snapshot."Shopify Fee G/L Account No." :=
            ShopifySetup."Shopify Fee G/L Acc. No.";

        Snapshot."Auto Create Fulfillments" :=
            ShopifySetup."Auto Create Fulfillment";

        Snapshot."Auto Record Shopify Payments" :=
            ShopifySetup."Auto Record Shopify Payments";

        Snapshot."Shopify Clearing G/L Acc. No." :=
            ShopifySetup."Shopify Clearing G/L Acc. No.";

        Snapshot."Auto Import Orders" :=
            ShopifySetup."Auto Import Orders";

        Snapshot."Auto Sync Inventory" :=
            ShopifySetup."Auto Sync Inventory";

        Snapshot."Import Orders From" :=
            ShopifySetup."Import Orders From";

        JobQueueMgt.GetJobInfo(
            JobQueueStatus,
            JobQueueNextRun,
            JobQueueInterval,
            JobQueueError);

        Snapshot."Job Queue Status" :=
            CopyStr(
                JobQueueStatus,
                1,
                MaxStrLen(
                    Snapshot."Job Queue Status"));

        Snapshot."Validation Passed" :=
            Validator.ValidateConfiguration(
                ValidationResult);

        Snapshot."Validation Result" :=
            CopyStr(
                ValidationResult,
                1,
                MaxStrLen(
                    Snapshot."Validation Result"));

        Snapshot.Insert(true);

        if ShowMessage then
            Message(
                'Shopify integration audit snapshot %1 was created.\Validation passed: %2',
                Snapshot."Entry No.",
                Snapshot."Validation Passed");

        exit(
            Snapshot."Entry No.");
    end;
}