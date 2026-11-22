pageextension 50265 "Shopify Status Payout Ext"
    extends "Shopify Integration Status"
{
    layout
    {
        addafter(OrderStatistics)
        {
            group(PayoutStatistics)
            {
                Caption = 'Shopify Payouts';

                field(AutoImportPayouts; Rec."Auto Import Shopify Payouts")
                {
                    ApplicationArea = All;
                    Caption = 'Auto Import Shopify Payouts';
                }

                field(AutoPostPayouts; Rec."Auto Post Paid Payouts")
                {
                    ApplicationArea = All;
                    Caption = 'Auto Post Paid Payouts';
                }

                field(PayoutBankAccount; Rec."Shopify Payout Bank Acc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'Payout Bank Account';
                }

                field(PayoutFeeAccount; Rec."Shopify Fee G/L Acc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'Shopify Fee G/L Account';
                }

                field(PayoutPendingCount; PayoutPendingCount)
                {
                    ApplicationArea = All;
                    Caption = 'Pending Payouts';
                    Style = Attention;
                }

                field(PayoutWaitingCount; PayoutWaitingCount)
                {
                    ApplicationArea = All;
                    Caption = 'Waiting Payouts';
                    Style = Attention;
                }

                field(PayoutSuccessCount; PayoutSuccessCount)
                {
                    ApplicationArea = All;
                    Caption = 'Posted Payouts';
                }

                field(PayoutSkippedCount; PayoutSkippedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Skipped Payouts';
                    Style = Attention;
                }

                field(PayoutErrorCount; PayoutErrorCount)
                {
                    ApplicationArea = All;
                    Caption = 'Payout Errors';
                    Style = Unfavorable;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(OpenPayoutEntries)
            {
                ApplicationArea = All;
                Caption = 'Shopify Payout Entries';

                trigger OnAction()
                begin
                    Page.Run(
                        Page::"Shopify Payout Entries");
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculatePayoutStatistics();
    end;

    local procedure CalculatePayoutStatistics()
    var
        PayoutEntry: Record "Shopify Payout Entry";
    begin
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Pending);

        PayoutPendingCount :=
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
            PayoutEntry."Processing Status"::Success);

        PayoutSuccessCount :=
            PayoutEntry.Count();

        PayoutEntry.Reset();
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Skipped);

        PayoutSkippedCount :=
            PayoutEntry.Count();

        PayoutEntry.Reset();
        PayoutEntry.SetRange(
            "Processing Status",
            PayoutEntry."Processing Status"::Error);

        PayoutErrorCount :=
            PayoutEntry.Count();
    end;

    var
        PayoutPendingCount: Integer;
        PayoutWaitingCount: Integer;
        PayoutSuccessCount: Integer;
        PayoutSkippedCount: Integer;
        PayoutErrorCount: Integer;
}
