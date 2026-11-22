pageextension 50264 "Shopify Admin Payout Ext"
    extends "Shopify Administration Center"
{
    layout
    {
        addlast(ShopifyOperationsState)
        {
            field(PayoutSuccessCount; PayoutSuccessCount)
            {
                ApplicationArea = All;
                Caption = 'Posted Shopify Payouts';
            }

            field(PayoutWaitingCount; PayoutWaitingCount)
            {
                ApplicationArea = All;
                Caption = 'Waiting Shopify Payouts';
                Style = Attention;
            }

            field(PayoutErrorCount; PayoutErrorCount)
            {
                ApplicationArea = All;
                Caption = 'Payout Errors';
                StyleExpr = PayoutErrorStyle;
            }
        }

        addlast(Automation)
        {
            field("Auto Import Shopify Payouts"; Rec."Auto Import Shopify Payouts")
            {
                ApplicationArea = All;
                Caption = 'Auto Import Shopify Payouts';
            }

            field("Auto Post Paid Payouts"; Rec."Auto Post Paid Payouts")
            {
                ApplicationArea = All;
                Caption = 'Auto Post Paid Payouts';
            }
        }

        addlast(DemoReadiness)
        {
            field(PayoutSetupReady; PayoutSetupReady)
            {
                ApplicationArea = All;
                Caption = 'Payout Setup Ready';
                StyleExpr = PayoutSetupStyle;
            }
        }
    }

    actions
    {
        addlast(FinancePayoutActions)
        {
            action(ImportPayouts)
            {
                ApplicationArea = All;
                Caption = 'Import Shopify Payouts';

                trigger OnAction()
                var
                    PayoutMgt:
                        Codeunit "Shopify Payout Mgt.";
                begin
                    PayoutMgt.ImportLatestPayouts(
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(PostPayouts)
            {
                ApplicationArea = All;
                Caption = 'Post Pending Shopify Payouts';

                trigger OnAction()
                var
                    PayoutMgt:
                        Codeunit "Shopify Payout Mgt.";
                begin
                    PayoutMgt.ProcessPendingPayouts(
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(RetryPayoutErrors)
            {
                ApplicationArea = All;
                Caption = 'Retry Payout Errors';

                trigger OnAction()
                var
                    PayoutMgt:
                        Codeunit "Shopify Payout Mgt.";
                begin
                    PayoutMgt.RetryFailedPayouts();
                    CurrPage.Update(false);
                end;
            }
        }

        addlast(FinancePromoted)
        {
            actionref(ImportPayoutsPromoted; ImportPayouts)
            {
            }

            actionref(PostPayoutsPromoted; PostPayouts)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculatePayoutState();
    end;

    local procedure CalculatePayoutState()
    var
        PayoutEntry:
            Record "Shopify Payout Entry";
    begin
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Success);

        PayoutSuccessCount :=
            PayoutEntry.Count();

        PayoutEntry.Reset();
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Waiting);

        PayoutWaitingCount :=
            PayoutEntry.Count();

        PayoutEntry.Reset();
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Error);

        PayoutErrorCount :=
            PayoutEntry.Count();

        if PayoutErrorCount = 0 then
            PayoutErrorStyle :=
                'Favorable'
        else
            PayoutErrorStyle :=
                'Unfavorable';

        PayoutSetupReady :=
            true;

        if Rec."Auto Import Shopify Payouts" or
           Rec."Auto Post Paid Payouts"
        then
            PayoutSetupReady :=
                Rec."Import Payouts From" <> 0DT;

        if PayoutSetupReady and
           Rec."Auto Post Paid Payouts"
        then
            PayoutSetupReady :=
                (Rec."Shopify Payout Bank Acc. No." <> '') and
                (Rec."Shopify Fee G/L Acc. No." <> '') and
                (Rec."Shopify Clearing G/L Acc. No." <> '') and
                (Rec."Payout Journal Template Name" <> '') and
                (Rec."Payout Journal Batch Name" <> '');

        if PayoutSetupReady then
            PayoutSetupStyle :=
                'Favorable'
        else
            PayoutSetupStyle :=
                'Unfavorable';
    end;

    var
        PayoutSuccessCount: Integer;
        PayoutWaitingCount: Integer;
        PayoutErrorCount: Integer;
        PayoutErrorStyle: Text;
        PayoutSetupReady: Boolean;
        PayoutSetupStyle: Text;
}