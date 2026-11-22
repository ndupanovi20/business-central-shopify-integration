page 50273 "Shopify Refund Entries"
{
    PageType = List;
    SourceTable = "Shopify Refund Entry";

    Caption = 'Shopify Refund Entries';
    ApplicationArea = All;
    UsageCategory = Lists;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    SourceTableView = sorting("Processed At") order(descending);

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Shopify Order Name"; Rec."Shopify Order Name")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }

                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = All;
                }

                field("Refund Total"; Rec."Refund Total")
                {
                    ApplicationArea = All;
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }

                field("Line Refund Amount"; Rec."Line Refund Amount")
                {
                    ApplicationArea = All;
                }

                field("Shipping Refund Amount"; Rec."Shipping Refund Amount")
                {
                    ApplicationArea = All;
                }

                field("Supported Component Total"; Rec."Supported Component Total")
                {
                    ApplicationArea = All;
                }

                field("Successful Transaction Total"; Rec."Successful Transaction Total")
                {
                    ApplicationArea = All;
                }

                field("BC Credit Memo No."; Rec."BC Credit Memo No.")
                {
                    ApplicationArea = All;
                }

                field("Posted Credit Memo No."; Rec."Posted Credit Memo No.")
                {
                    ApplicationArea = All;
                }

                field("Refund Journal Document No."; Rec."Refund Journal Document No.")
                {
                    ApplicationArea = All;
                }

                field("Attempt Count"; Rec."Attempt Count")
                {
                    ApplicationArea = All;
                }

                field("Manual Review Reason"; Rec."Manual Review Reason")
                {
                    ApplicationArea = All;
                }

                field("Result Message"; Rec."Result Message")
                {
                    ApplicationArea = All;
                }

                field("Refund Error"; Rec."Refund Error")
                {
                    ApplicationArea = All;
                }

                field("Shopify Refund ID"; Rec."Shopify Refund ID")
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
            action(RefreshRefunds)
            {
                ApplicationArea = All;
                Caption = 'Refresh Refunds from Shopify';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    RefundMgt: Codeunit "Shopify Refund Mgt.";
                begin
                    RefundMgt.ImportRefundsForImportedOrders(true);
                    CurrPage.Update(false);
                end;
            }

            action(ProcessSelectedRefund)
            {
                ApplicationArea = All;
                Caption = 'Process Selected Refund';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    RefundMgt: Codeunit "Shopify Refund Mgt.";
                begin
                    RefundMgt.ProcessRefund(Rec, true);
                    CurrPage.Update(false);
                end;
            }

            action(ProcessPendingRefunds)
            {
                ApplicationArea = All;
                Caption = 'Process Pending Refunds';

                trigger OnAction()
                var
                    RefundMgt: Codeunit "Shopify Refund Mgt.";
                begin
                    RefundMgt.ProcessPendingRefunds(true);
                    CurrPage.Update(false);
                end;
            }

            action(RetryFailedRefunds)
            {
                ApplicationArea = All;
                Caption = 'Retry Failed Refunds';

                trigger OnAction()
                var
                    RefundMgt: Codeunit "Shopify Refund Mgt.";
                begin
                    RefundMgt.RetryFailedRefunds();
                    CurrPage.Update(false);
                end;
            }

            action(OpenRefundLines)
            {
                ApplicationArea = All;
                Caption = 'Refund Lines';

                trigger OnAction()
                var
                    RefundLine: Record "Shopify Refund Line";
                begin
                    RefundLine.SetRange("Shopify Refund ID", Rec."Shopify Refund ID");
                    Page.Run(Page::"Shopify Refund Lines", RefundLine);
                end;
            }

            action(OpenCreditMemo)
            {
                ApplicationArea = All;
                Caption = 'Open Posted Credit Memo';

                trigger OnAction()
                var
                    RefundMgt: Codeunit "Shopify Refund Mgt.";
                begin
                    RefundMgt.OpenPostedCreditMemo(Rec);
                end;
            }

            action(OpenRefundLedgerEntry)
            {
                ApplicationArea = All;
                Caption = 'Open Refund Ledger Entry';

                trigger OnAction()
                var
                    RefundMgt: Codeunit "Shopify Refund Mgt.";
                begin
                    RefundMgt.OpenRefundLedgerEntry(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Success:
                StatusStyle := 'Favorable';
            Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status::"Manual Review":
                StatusStyle := 'Unfavorable';
            Rec.Status::Waiting:
                StatusStyle := 'Attention';
            Rec.Status::Pending:
                StatusStyle := 'Attention';
            Rec.Status::Skipped:
                StatusStyle := 'Attention';
            else
                StatusStyle := 'Standard';
        end;
    end;

    var
        StatusStyle: Text;
}
