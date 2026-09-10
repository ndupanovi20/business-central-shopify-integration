codeunit 50184 "Shopify Order Retry Mgt."
{
    procedure RetrySelected(
        var Buffer: Record "Shopify Order Buffer")
    var
        SuccessCount: Integer;
        ErrorCount: Integer;
        IgnoredCount: Integer;
    begin
        if not Buffer.FindSet() then begin
            Message(
                'No Shopify order buffers were selected.');

            exit;
        end;

        repeat
            case Buffer.Status of
                Buffer.Status::Error,
                Buffer.Status::Pending:
                    begin
                        if RetrySingle(
                            Buffer)
                        then
                            SuccessCount += 1
                        else
                            ErrorCount += 1;
                    end;

                else
                    IgnoredCount += 1;
            end;
        until Buffer.Next() = 0;

        Message(
            'Retry completed.\Successful: %1\Failed: %2\Ignored: %3',
            SuccessCount,
            ErrorCount,
            IgnoredCount);
    end;

    procedure RetryAllErrors()
    var
        Buffer:
            Record "Shopify Order Buffer";

        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        Buffer.SetRange(
            Status,
            Buffer.Status::Error);

        if not Buffer.FindSet() then begin
            Message(
                'There are no failed Shopify orders to retry.');

            exit;
        end;

        repeat
            if RetrySingle(
                Buffer)
            then
                SuccessCount += 1
            else
                ErrorCount += 1;
        until Buffer.Next() = 0;

        Message(
            'Retry of failed Shopify orders completed.\Successful: %1\Failed: %2',
            SuccessCount,
            ErrorCount);
    end;

    procedure RetrySingle(
        var Buffer: Record "Shopify Order Buffer"): Boolean
    var
        Runner:
            Codeunit "Shopify Order Import Runner";

        SyncLogMgt:
            Codeunit "Shopify Sync Log Mgt.";

        ImportRecord:
            Record "Shopify Order Import";

        StartedAt: DateTime;

        ErrorText: Text;

        BCOrderNo: Code[20];
    begin
        if not (
            Buffer.Status in
            [
                Buffer.Status::Error,
                Buffer.Status::Pending
            ])
        then
            exit(false);

        Buffer."Retry Count" +=
            1;

        Buffer."Last Retry At" :=
            CurrentDateTime();

        Buffer.Modify(true);

        if ImportRecord.Get(
            Buffer."Shopify Order ID")
        then begin
            Buffer.Status :=
                Buffer.Status::Success;

            Buffer."Processed At" :=
                CurrentDateTime();

            Clear(
                Buffer."Last Error");

            Buffer.Modify(true);

            exit(true);
        end;

        StartedAt :=
            CurrentDateTime();

        Commit();

        ClearLastError();

        if Runner.Run(
            Buffer)
        then begin
            if ImportRecord.Get(
                Buffer."Shopify Order ID")
            then
                BCOrderNo :=
                    ImportRecord."BC Order No.";

            Buffer.Status :=
                Buffer.Status::Success;

            Buffer."Processed At" :=
                CurrentDateTime();

            Clear(
                Buffer."Last Error");

            Buffer.Modify(true);

            SyncLogMgt.LogSuccess(
                "Shopify Sync Direction"::Inbound,
                "Shopify Sync Entity"::Order,
                BCOrderNo,
                Buffer."Shopify Order ID",
                StrSubstNo(
                    'Shopify order %1 was successfully reprocessed on retry %2.',
                    Buffer."Shopify Order Name",
                    Buffer."Retry Count"),
                CurrentDateTime() - StartedAt);

            exit(true);
        end;

        ErrorText :=
            GetLastErrorText();

        if ErrorText = '' then
            ErrorText :=
                'Unknown error while retrying Shopify order.';

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
            Buffer."Shopify Order ID",
            StrSubstNo(
                'Retry %1 failed. %2',
                Buffer."Retry Count",
                ErrorText),
            CurrentDateTime() - StartedAt);

        exit(false);
    end;
}