pageextension 50283 "Shopify Admin Refund Ext"
    extends "Shopify Administration Center"
{
    layout
    {
        addlast(ShopifyOperationsState)
        {
            field(RefundSuccessCount; RefundSuccessCount)
            {
                ApplicationArea = All;
                Caption = 'Successful Shopify Refunds';
            }

            field(RefundWaitingCount; RefundWaitingCount)
            {
                ApplicationArea = All;
                Caption = 'Waiting Shopify Refunds';
                Style = Attention;
            }

            field(RefundManualReviewCount; RefundManualReviewCount)
            {
                ApplicationArea = All;
                Caption = 'Refunds Requiring Manual Review';
                Style = Unfavorable;
            }

            field(RefundErrorCount; RefundErrorCount)
            {
                ApplicationArea = All;
                Caption = 'Refund Errors';
                StyleExpr = RefundErrorStyle;
            }
        }

        addlast(Automation)
        {
            field("Auto Import Shopify Refunds"; Rec."Auto Import Shopify Refunds")
            {
                ApplicationArea = All;
            }

            field("Auto Process Shopify Refunds"; Rec."Auto Process Shopify Refunds")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addlast(FinanceRefundActions)
        {
            action(RefreshRefundsFromShopify)
            {
                ApplicationArea = All;
                Caption = 'Refresh Shopify Refunds';

                trigger OnAction()
                var
                    RefundMgt:
                        Codeunit "Shopify Refund Mgt.";
                begin
                    RefundMgt.ImportRefundsForImportedOrders(true);
                    CalculateRefundState();
                    CurrPage.Update(false);
                end;
            }

            action(ProcessPendingRefundsAdmin)
            {
                ApplicationArea = All;
                Caption = 'Process Pending Refunds';

                trigger OnAction()
                var
                    RefundMgt:
                        Codeunit "Shopify Refund Mgt.";
                begin
                    RefundMgt.ProcessPendingRefunds(true);
                    CalculateRefundState();
                    CurrPage.Update(false);
                end;
            }

            action(RetryRefundErrorsAdmin)
            {
                ApplicationArea = All;
                Caption = 'Retry Refund Errors';

                trigger OnAction()
                var
                    RefundMgt:
                        Codeunit "Shopify Refund Mgt.";
                begin
                    RefundMgt.RetryFailedRefunds();
                    CalculateRefundState();
                    CurrPage.Update(false);
                end;
            }
        }

        addlast(FinancePromoted)
        {
            actionref(RefreshRefundsFromShopifyPromoted; RefreshRefundsFromShopify)
            {
            }

            actionref(ProcessPendingRefundsAdminPromoted; ProcessPendingRefundsAdmin)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculateRefundState();
    end;

    local procedure CalculateRefundState()
    var
        RefundEntry:
            Record "Shopify Refund Entry";
    begin
        RefundEntry.SetRange(
            Status,
            RefundEntry.Status::Success);

        RefundSuccessCount :=
            RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(
            Status,
            RefundEntry.Status::Waiting);

        RefundWaitingCount :=
            RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(
            Status,
            RefundEntry.Status::"Manual Review");

        RefundManualReviewCount :=
            RefundEntry.Count();

        RefundEntry.Reset();
        RefundEntry.SetRange(
            Status,
            RefundEntry.Status::Error);

        RefundErrorCount :=
            RefundEntry.Count();

        if RefundErrorCount > 0 then
            RefundErrorStyle :=
                'Unfavorable'
        else
            RefundErrorStyle :=
                'Favorable';
    end;

    var
        RefundSuccessCount: Integer;
        RefundWaitingCount: Integer;
        RefundManualReviewCount: Integer;
        RefundErrorCount: Integer;
        RefundErrorStyle: Text;
}