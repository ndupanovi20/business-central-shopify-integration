pageextension 50233 "Shopify Order Imports Payment"
    extends "Shopify Order Imports"
{
    layout
    {
        addafter("Line Count")
        {
            field("Payment Status"; Rec."Payment Status")
            {
                ApplicationArea = All;
                StyleExpr = PaymentStatusStyle;
            }

            field("Payment Document No."; Rec."Payment Document No.")
            {
                ApplicationArea = All;
            }

            field("Payment Amount"; Rec."Payment Amount")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(PreviewShopifyPayment)
            {
                ApplicationArea = All;
                Caption = 'Preview Shopify Payment';

                trigger OnAction()
                var
                    PaymentMgt:
                        Codeunit "Shopify Payment Mgt.";
                begin
                    PaymentMgt.PreviewPayment(
                        Rec);
                end;
            }

            action(RecordShopifyPayment)
            {
                ApplicationArea = All;
                Caption = 'Record Shopify Payment';

                trigger OnAction()
                var
                    PaymentMgt:
                        Codeunit "Shopify Payment Mgt.";
                begin
                    PaymentMgt.RecordPaymentForImport(
                        Rec,
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(OpenShopifyPaymentEntry)
            {
                ApplicationArea = All;
                Caption = 'Open Shopify Payment Entry';

                trigger OnAction()
                var
                    PaymentEntry:
                        Record "Shopify Payment Entry";
                begin
                    if not PaymentEntry.Get(
                        Rec."Shopify Order ID")
                    then
                        Error(
                            'Shopify payment entry does not exist for order %1.',
                            Rec."Shopify Order Name");

                    PaymentEntry.SetRecFilter();

                    Page.Run(
                        Page::"Shopify Payment Entries",
                        PaymentEntry);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(
            "Payment Status",
            "Payment Document No.",
            "Payment Amount");

        SetPaymentStatusStyle();
    end;

    local procedure SetPaymentStatusStyle()
    begin
        case Rec."Payment Status" of
            Rec."Payment Status"::Success:
                PaymentStatusStyle :=
                    'Favorable';

            Rec."Payment Status"::Error:
                PaymentStatusStyle :=
                    'Unfavorable';

            Rec."Payment Status"::Skipped:
                PaymentStatusStyle :=
                    'Attention';

            Rec."Payment Status"::Pending:
                PaymentStatusStyle :=
                    'Attention';

            else
                PaymentStatusStyle :=
                    'Standard';
        end;
    end;

    var
        PaymentStatusStyle: Text;
}
