page 50167 "Shopify Order Buffer"
{
    PageType = List;
    SourceTable = "Shopify Order Buffer";

    Caption = 'Shopify Order Buffer';
    ApplicationArea = All;
    UsageCategory = Lists;

    InsertAllowed = false;
    Editable = false;

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

                field("Shopify Order Name"; Rec."Shopify Order Name")
                {
                    ApplicationArea = All;
                }

                field("Shopify Order ID"; Rec."Shopify Order ID")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }

                field("Financial Status"; Rec."Financial Status")
                {
                    ApplicationArea = All;
                }

                field("Fulfillment Status"; Rec."Fulfillment Status")
                {
                    ApplicationArea = All;
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }

                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = All;
                }

                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                }

                field("Last Retry At"; Rec."Last Retry At")
                {
                    ApplicationArea = All;
                }

                field("Last Error"; Rec."Last Error")
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
            action(RetrySelected)
            {
                ApplicationArea = All;
                Caption = 'Retry Selected';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SelectedBuffer:
                        Record "Shopify Order Buffer";

                    RetryMgt:
                        Codeunit "Shopify Order Retry Mgt.";
                begin
                    CurrPage.SetSelectionFilter(
                        SelectedBuffer);

                    RetryMgt.RetrySelected(
                        SelectedBuffer);

                    CurrPage.Update(false);
                end;
            }

            action(RetryAllErrors)
            {
                ApplicationArea = All;
                Caption = 'Retry All Errors';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    RetryMgt:
                        Codeunit "Shopify Order Retry Mgt.";
                begin
                    RetryMgt.RetryAllErrors();

                    CurrPage.Update(false);
                end;
            }

            action(OpenSalesOrder)
            {
                ApplicationArea = All;
                Caption = 'Open BC Sales Order';

                trigger OnAction()
                var
                    ImportRecord:
                        Record "Shopify Order Import";

                    SalesHeader:
                        Record "Sales Header";
                begin
                    if not ImportRecord.Get(
                        Rec."Shopify Order ID")
                    then
                        Error(
                            'This Shopify order has not been imported into Business Central.');

                    if not SalesHeader.Get(
                        SalesHeader."Document Type"::Order,
                        ImportRecord."BC Order No.")
                    then
                        Error(
                            'Business Central Sales Order %1 does not exist.',
                            ImportRecord."BC Order No.");

                    Page.Run(
                        Page::"Sales Order",
                        SalesHeader);
                end;
            }

            action(OpenOrderLog)
            {
                ApplicationArea = All;
                Caption = 'Open Sync Log';

                trigger OnAction()
                var
                    SyncLog:
                        Record "Shopify Sync Log";
                begin
                    SyncLog.SetRange(
                        "Shopify ID",
                        Rec."Shopify Order ID");

                    Page.Run(
                        Page::"Shopify Sync Log",
                        SyncLog);
                end;
            }

            action(DeleteSuccessful)
            {
                ApplicationArea = All;
                Caption = 'Delete Successful Buffers';

                trigger OnAction()
                var
                    Buffer:
                        Record "Shopify Order Buffer";
                begin
                    Buffer.SetRange(
                        Status,
                        Buffer.Status::Success);

                    if Buffer.IsEmpty() then begin
                        Message(
                            'There are no successful buffers to delete.');

                        exit;
                    end;

                    if not Confirm(
                        'Delete all successful Shopify order buffers? Imported order history will remain available.',
                        false)
                    then
                        exit;

                    Buffer.DeleteAll();

                    Message(
                        'Successful Shopify order buffers were deleted.');

                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
    end;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Success:
                StatusStyle :=
                    'Favorable';

            Rec.Status::Error:
                StatusStyle :=
                    'Unfavorable';

            Rec.Status::Skipped:
                StatusStyle :=
                    'Attention';

            Rec.Status::Pending:
                StatusStyle :=
                    'Ambiguous';
        end;
    end;

    var
        StatusStyle: Text;
}