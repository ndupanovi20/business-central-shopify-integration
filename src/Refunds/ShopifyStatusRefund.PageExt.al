pageextension 50284 "Shopify Status Refund Ext"
    extends "Shopify Integration Status"
{
    layout
    {
        addlast(Content)
        {
            group(RefundStatistics)
            {
                Caption = 'Shopify Refunds';

                field(AutoImportRefunds; Rec."Auto Import Shopify Refunds")
                {
                    ApplicationArea = All;
                    Caption = 'Auto Import Shopify Refunds';
                }

                field(AutoProcessRefunds; Rec."Auto Process Shopify Refunds")
                {
                    ApplicationArea = All;
                    Caption = 'Auto Process Shopify Refunds';
                }

                field(RefundSuccessCount; RefundSuccessCount)
                {
                    ApplicationArea = All;
                    Caption = 'Successful Refunds';
                }

                field(RefundPendingCount; RefundPendingCount)
                {
                    ApplicationArea = All;
                    Caption = 'Pending Refunds';
                    Style = Attention;
                }

                field(RefundWaitingCount; RefundWaitingCount)
                {
                    ApplicationArea = All;
                    Caption = 'Waiting Refunds';
                    Style = Attention;
                }

                field(RefundManualReviewCount; RefundManualReviewCount)
                {
                    ApplicationArea = All;
                    Caption = 'Manual Review';
                    Style = Unfavorable;
                }

                field(RefundErrorCount; RefundErrorCount)
                {
                    ApplicationArea = All;
                    Caption = 'Refund Errors';
                    Style = Unfavorable;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculateRefundStatistics();
    end;

    local procedure CalculateRefundStatistics()
    var
        RefundEntry: Record "Shopify Refund Entry";
    begin
        RefundEntry.SetRange(Status, RefundEntry.Status::Success);
        RefundSuccessCount := RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(Status, RefundEntry.Status::Pending);
        RefundPendingCount := RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(Status, RefundEntry.Status::Waiting);
        RefundWaitingCount := RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(Status, RefundEntry.Status::"Manual Review");
        RefundManualReviewCount := RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(Status, RefundEntry.Status::Error);
        RefundErrorCount := RefundEntry.Count();
    end;

    var
        RefundSuccessCount: Integer;
        RefundPendingCount: Integer;
        RefundWaitingCount: Integer;
        RefundManualReviewCount: Integer;
        RefundErrorCount: Integer;
}
