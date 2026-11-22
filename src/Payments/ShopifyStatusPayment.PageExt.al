pageextension 50235 "Shopify Status Payment Ext"
    extends "Shopify Integration Status"
{
    layout
    {
        addafter(OrderStatistics)
        {
            group(PaymentStatistics)
            {
                Caption = 'Shopify Payments';

                field(AutoRecordPayments; Rec."Auto Record Shopify Payments")
                {
                    ApplicationArea = All;
                    Caption = 'Auto Record Shopify Payments';
                }

                field(ClearingGLAccount; Rec."Shopify Clearing G/L Acc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'Shopify Clearing G/L Account';
                }

                field(PaymentSuccessCount; PaymentSuccessCount)
                {
                    ApplicationArea = All;
                    Caption = 'Successful Payments';
                }

                field(PaymentSkippedCount; PaymentSkippedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Skipped Payments';
                    Style = Attention;
                }

                field(PaymentErrorCount; PaymentErrorCount)
                {
                    ApplicationArea = All;
                    Caption = 'Payment Errors';
                    Style = Unfavorable;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(OpenPaymentEntries)
            {
                ApplicationArea = All;
                Caption = 'Shopify Payment Entries';

                trigger OnAction()
                begin
                    Page.Run(
                        Page::"Shopify Payment Entries");
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculatePaymentStatistics();
    end;

    local procedure CalculatePaymentStatistics()
    var
        PaymentEntry:
            Record "Shopify Payment Entry";
    begin
        PaymentEntry.SetRange(
            Status,
            PaymentEntry.Status::Success);

        PaymentSuccessCount :=
            PaymentEntry.Count();

        PaymentEntry.Reset();

        PaymentEntry.SetRange(
            Status,
            PaymentEntry.Status::Skipped);

        PaymentSkippedCount :=
            PaymentEntry.Count();

        PaymentEntry.Reset();

        PaymentEntry.SetRange(
            Status,
            PaymentEntry.Status::Error);

        PaymentErrorCount :=
            PaymentEntry.Count();
    end;

    var
        PaymentSuccessCount: Integer;
        PaymentSkippedCount: Integer;
        PaymentErrorCount: Integer;
}
