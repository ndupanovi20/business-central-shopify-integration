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