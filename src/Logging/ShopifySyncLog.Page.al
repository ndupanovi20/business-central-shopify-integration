page 50164 "Shopify Sync Log"
{
    PageType = List;
    SourceTable = "Shopify Sync Log";

    Caption = 'Shopify Sync Log';
    ApplicationArea = All;
    UsageCategory = Lists;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = true;

    SourceTableView =
        sorting("Entry No.")
        order(descending);

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }

                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                }

                field("Entity Type"; Rec."Entity Type")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }

                field("BC Key"; Rec."BC Key")
                {
                    ApplicationArea = All;
                }

                field("Shopify ID"; Rec."Shopify ID")
                {
                    ApplicationArea = All;
                }

                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                }

                field(Duration; Rec.Duration)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteOldLogs)
            {
                ApplicationArea = All;
                Caption = 'Delete Logs Older Than 30 Days';

                trigger OnAction()
                var
                    SyncLog: Record "Shopify Sync Log";
                    LimitDateTime: DateTime;
                begin
                    LimitDateTime :=
                        CreateDateTime(
                            Today() - 30,
                            000000T);

                    SyncLog.SetFilter(
                        "Created At",
                        '<%1',
                        LimitDateTime);

                    if SyncLog.IsEmpty() then begin
                        Message('There are no old log entries to delete.');
                        exit;
                    end;

                    SyncLog.DeleteAll();

                    Message(
                        'Log entries older than 30 days were deleted.');
                end;
            }
        }
    }
}