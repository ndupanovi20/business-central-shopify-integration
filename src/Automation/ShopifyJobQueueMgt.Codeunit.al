codeunit 50191 "Shopify Job Queue Mgt."
{
    procedure CreateOrUpdateAndStart()
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        JobQueueEntry:
            Record "Job Queue Entry";
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist.');

        if not ShopifySetup."Auto Import Orders" and
           not ShopifySetup."Auto Sync Inventory" and
           not ShopifySetup."Auto Post Imported Orders" and
           not ShopifySetup."Auto Create Fulfillment" and
           not ShopifySetup."Auto Sync Fulfillment Tracking" and
           not ShopifySetup."Auto Record Shopify Payments" and
           not ShopifySetup."Auto Import Shopify Refunds" and
           not ShopifySetup."Auto Process Shopify Refunds" and
           not ShopifySetup."Auto Import Shopify Payouts" and
           not ShopifySetup."Auto Post Paid Payouts"
        then
            Error(
                'Enable at least one Shopify automation option before starting the background job.');

        if ShopifySetup."Background Sync Interval" <= 0 then
            Error(
                'Background Sync Interval must be greater than zero.');

        if FindBackgroundJob(
            JobQueueEntry)
        then
            UpdateExistingJob(
                JobQueueEntry,
                ShopifySetup."Background Sync Interval")
        else
            CreateNewJob(
                JobQueueEntry,
                ShopifySetup."Background Sync Interval");

        Message(
            'Shopify background job is ready.\Interval: %1 minute(s).',
            ShopifySetup."Background Sync Interval");
    end;

    procedure PutOnHold()
    var
        JobQueueEntry:
            Record "Job Queue Entry";
    begin
        if not FindBackgroundJob(
            JobQueueEntry)
        then begin
            Message(
                'Shopify background job is not configured.');

            exit;
        end;

        if JobQueueEntry.Status =
           JobQueueEntry.Status::"In Process"
        then
            Error(
                'The Shopify background job is currently running. Try again after the current run finishes.');

        if JobQueueEntry.Status =
           JobQueueEntry.Status::"On Hold"
        then begin
            Message(
                'Shopify background job is already on hold.');

            exit;
        end;

        JobQueueEntry.SetStatus(
            JobQueueEntry.Status::"On Hold");

        Message(
            'Shopify background job was put on hold.');
    end;

    procedure DeleteBackgroundJob()
    var
        JobQueueEntry:
            Record "Job Queue Entry";
    begin
        if not FindBackgroundJob(
            JobQueueEntry)
        then begin
            Message(
                'Shopify background job is not configured.');

            exit;
        end;

        if JobQueueEntry.Status =
           JobQueueEntry.Status::"In Process"
        then
            Error(
                'The Shopify background job is currently running and cannot be deleted.');

        if not Confirm(
            'Delete the Shopify background Job Queue Entry?',
            false)
        then
            exit;

        JobQueueEntry.Delete(true);

        Message(
            'Shopify background job was deleted.');
    end;

    procedure GetJobInfo(
        var StatusText: Text;
        var NextRunAt: DateTime;
        var IntervalMinutes: Integer;
        var ErrorText: Text): Boolean
    var
        JobQueueEntry:
            Record "Job Queue Entry";
    begin
        Clear(
            StatusText);

        Clear(
            NextRunAt);

        Clear(
            IntervalMinutes);

        Clear(
            ErrorText);

        if not FindBackgroundJob(
            JobQueueEntry)
        then begin
            StatusText :=
                'Not configured';

            exit(false);
        end;

        StatusText :=
            Format(
                JobQueueEntry.Status);

        NextRunAt :=
            JobQueueEntry."Earliest Start Date/Time";

        IntervalMinutes :=
            JobQueueEntry."No. of Minutes between Runs";

        ErrorText :=
            JobQueueEntry."Error Message";

        exit(true);
    end;

    procedure OpenBackgroundJob()
    var
        JobQueueEntry:
            Record "Job Queue Entry";
    begin
        if not FindBackgroundJob(
            JobQueueEntry)
        then
            Error(
                'Shopify background job is not configured.');

        Page.Run(
            Page::"Job Queue Entries",
            JobQueueEntry);
    end;

    local procedure CreateNewJob(
        var JobQueueEntry:
            Record "Job Queue Entry";
        IntervalMinutes: Integer)
    begin
        JobQueueEntry.InitRecurringJob(
            IntervalMinutes);

        JobQueueEntry.Validate(
            "Object Type to Run",
            JobQueueEntry."Object Type to Run"::Codeunit);

        JobQueueEntry.Validate(
            "Object ID to Run",
            Codeunit::"Shopify Background Sync");

        JobQueueEntry.Description :=
            'BC Shopify Background Sync';

        JobQueueEntry."Maximum No. of Attempts to Run" :=
            3;

        JobQueueEntry."Rerun Delay (sec.)" :=
            60;

        // Insert as On Hold first.
        // After insertion SetStatus(Ready) schedules the task.
        JobQueueEntry.Status :=
            JobQueueEntry.Status::"On Hold";

        JobQueueEntry.Insert(true);

        JobQueueEntry.SetStatus(
            JobQueueEntry.Status::Ready);
    end;

    local procedure UpdateExistingJob(
        var JobQueueEntry:
            Record "Job Queue Entry";
        IntervalMinutes: Integer)
    begin
        if JobQueueEntry.Status =
           JobQueueEntry.Status::"In Process"
        then
            Error(
                'The Shopify background job is currently running. Try updating it after the current run finishes.');

        if JobQueueEntry.Status <>
           JobQueueEntry.Status::"On Hold"
        then
            JobQueueEntry.SetStatus(
                JobQueueEntry.Status::"On Hold");

        JobQueueEntry."Recurring Job" :=
            true;

        JobQueueEntry."Run on Mondays" :=
            true;

        JobQueueEntry."Run on Tuesdays" :=
            true;

        JobQueueEntry."Run on Wednesdays" :=
            true;

        JobQueueEntry."Run on Thursdays" :=
            true;

        JobQueueEntry."Run on Fridays" :=
            true;

        JobQueueEntry."Run on Saturdays" :=
            true;

        JobQueueEntry."Run on Sundays" :=
            true;

        JobQueueEntry.Validate(
            "No. of Minutes between Runs",
            IntervalMinutes);

        JobQueueEntry.Description :=
            'BC Shopify Background Sync';

        JobQueueEntry."Maximum No. of Attempts to Run" :=
            3;

        JobQueueEntry."Rerun Delay (sec.)" :=
            60;

        JobQueueEntry.Modify(true);

        JobQueueEntry.SetStatus(
            JobQueueEntry.Status::Ready);
    end;

    local procedure FindBackgroundJob(
        var JobQueueEntry:
            Record "Job Queue Entry"): Boolean
    begin
        JobQueueEntry.Reset();

        JobQueueEntry.SetRange(
            "Object Type to Run",
            JobQueueEntry."Object Type to Run"::Codeunit);

        JobQueueEntry.SetRange(
            "Object ID to Run",
            Codeunit::"Shopify Background Sync");

        JobQueueEntry.SetFilter(
            Status,
            '<>%1',
            JobQueueEntry.Status::Finished);

        exit(
            JobQueueEntry.FindFirst());
    end;
}