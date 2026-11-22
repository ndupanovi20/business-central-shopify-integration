pageextension 50234 "Shopify Admin Payment Ext"
    extends "Shopify Administration Center"
{
    layout
    {
        addlast(ERPProcessingState)
        {
            field(PaymentSuccessCount; PaymentSuccessCount)
            {
                ApplicationArea = All;
                Caption = 'Recorded Shopify Payments';
            }

            field(PaymentErrorCount; PaymentErrorCount)
            {
                ApplicationArea = All;
                Caption = 'Payment Errors';
                StyleExpr = PaymentErrorStyle;
            }
        }

        addlast(Automation)
        {
            field("Auto Record Shopify Payments"; Rec."Auto Record Shopify Payments")
            {
                ApplicationArea = All;
                Caption = 'Auto Record Shopify Payments';
            }
        }

        addlast(DemoReadiness)
        {
            field(PaymentSetupReady; PaymentSetupReady)
            {
                ApplicationArea = All;
                Caption = 'Payment Setup Ready';
                StyleExpr = PaymentSetupStyle;
            }
        }
    }

    actions
    {
        addlast(FinancePaymentActions)
        {
            action(ProcessEligiblePayments)
            {
                ApplicationArea = All;
                Caption = 'Record Eligible Shopify Payments';

                trigger OnAction()
                var
                    PaymentMgt:
                        Codeunit "Shopify Payment Mgt.";
                begin
                    PaymentMgt.ProcessEligiblePayments(
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(RetryPaymentErrors)
            {
                ApplicationArea = All;
                Caption = 'Retry Payment Errors';

                trigger OnAction()
                var
                    PaymentMgt:
                        Codeunit "Shopify Payment Mgt.";
                begin
                    PaymentMgt.RetryFailedPayments();

                    CurrPage.Update(false);
                end;
            }
        }

        addlast(FinancePromoted)
        {
            actionref(ProcessEligiblePaymentsPromoted; ProcessEligiblePayments)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculatePaymentState();
    end;

    local procedure CalculatePaymentState()
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
            PaymentEntry.Status::Error);

        PaymentErrorCount :=
            PaymentEntry.Count();

        if PaymentErrorCount = 0 then
            PaymentErrorStyle :=
                'Favorable'
        else
            PaymentErrorStyle :=
                'Unfavorable';

        PaymentSetupReady :=
            (not Rec."Auto Record Shopify Payments") or
            ((Rec."Shopify Clearing G/L Acc. No." <> '') and
             (Rec."Payment Journal Template Name" <> '') and
             (Rec."Payment Journal Batch Name" <> ''));

        if PaymentSetupReady then
            PaymentSetupStyle :=
                'Favorable'
        else
            PaymentSetupStyle :=
                'Unfavorable';
    end;

    var
        PaymentSuccessCount: Integer;
        PaymentErrorCount: Integer;
        PaymentErrorStyle: Text;
        PaymentSetupReady: Boolean;
        PaymentSetupStyle: Text;
}