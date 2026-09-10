page 50201 "Shopify Audit Snapshots"
{
    PageType = List;
    SourceTable = "Shopify Audit Snapshot";

    Caption = 'Shopify Audit Snapshots';
    ApplicationArea = All;
    UsageCategory = Lists;

    Editable = false;
    InsertAllowed = false;

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

                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                }

                field("Validation Passed"; Rec."Validation Passed")
                {
                    ApplicationArea = All;
                    StyleExpr = ValidationStyle;
                }

                field("Mapped Products"; Rec."Mapped Products")
                {
                    ApplicationArea = All;
                }

                field("Imported Orders"; Rec."Imported Orders")
                {
                    ApplicationArea = All;
                }

                field("Successful Buffers"; Rec."Successful Buffers")
                {
                    ApplicationArea = All;
                }

                field("Skipped Buffers"; Rec."Skipped Buffers")
                {
                    ApplicationArea = All;
                }

                field("Error Buffers"; Rec."Error Buffers")
                {
                    ApplicationArea = All;
                    StyleExpr = ErrorStyle;
                }

                field("Retry Attempts"; Rec."Retry Attempts")
                {
                    ApplicationArea = All;
                }

                field("Successful Log Entries"; Rec."Successful Log Entries")
                {
                    ApplicationArea = All;
                }

                field("Error Log Entries"; Rec."Error Log Entries")
                {
                    ApplicationArea = All;
                    StyleExpr = LogErrorStyle;
                }

                field("BC Shopify Sales Orders"; Rec."BC Shopify Sales Orders")
                {
                    ApplicationArea = All;
                }

                field("Tagged Orders"; Rec."Tagged Orders")
                {
                    ApplicationArea = All;
                }

                field("Tag Errors"; Rec."Tag Errors")
                {
                    ApplicationArea = All;
                    StyleExpr = TagErrorStyle;
                }

                field("Job Queue Status"; Rec."Job Queue Status")
                {
                    ApplicationArea = All;
                }

                field("Validation Result"; Rec."Validation Result")
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
            action(CreateSnapshot)
            {
                ApplicationArea = All;
                Caption = 'Create Snapshot';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    AuditMgt:
                        Codeunit "Shopify Audit Mgt.";
                begin
                    AuditMgt.CreateSnapshot(
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(DeleteSnapshots)
            {
                ApplicationArea = All;
                Caption = 'Delete All Snapshots';

                trigger OnAction()
                var
                    Snapshot:
                        Record "Shopify Audit Snapshot";
                begin
                    if not Confirm(
                        'Delete all Shopify integration audit snapshots?',
                        false)
                    then
                        exit;

                    Snapshot.DeleteAll(true);

                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Validation Passed" then
            ValidationStyle :=
                'Favorable'
        else
            ValidationStyle :=
                'Unfavorable';

        if Rec."Error Buffers" = 0 then
            ErrorStyle :=
                'Favorable'
        else
            ErrorStyle :=
                'Unfavorable';

        if Rec."Error Log Entries" = 0 then
            LogErrorStyle :=
                'Favorable'
        else
            LogErrorStyle :=
                'Unfavorable';

        if Rec."Tag Errors" = 0 then
            TagErrorStyle :=
                'Favorable'
        else
            TagErrorStyle :=
                'Unfavorable';
    end;

    var
        ValidationStyle: Text;
        ErrorStyle: Text;
        LogErrorStyle: Text;
        TagErrorStyle: Text;
}