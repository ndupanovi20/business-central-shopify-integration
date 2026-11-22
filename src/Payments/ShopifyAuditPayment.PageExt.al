pageextension 50238 "Shopify Audit Payment Page"
    extends "Shopify Audit Snapshots"
{
    layout
    {
        addafter("Tag Errors")
        {
            field("Payment Successes"; Rec."Payment Successes")
            {
                ApplicationArea = All;
            }

            field("Payment Skipped"; Rec."Payment Skipped")
            {
                ApplicationArea = All;
            }

            field("Payment Errors"; Rec."Payment Errors")
            {
                ApplicationArea = All;
                StyleExpr = PaymentErrorStyle;
            }

            field("Auto Record Shopify Payments"; Rec."Auto Record Shopify Payments")
            {
                ApplicationArea = All;
            }

            field("Shopify Clearing G/L Acc. No."; Rec."Shopify Clearing G/L Acc. No.")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Payment Errors" = 0 then
            PaymentErrorStyle :=
                'Favorable'
        else
            PaymentErrorStyle :=
                'Unfavorable';
    end;

    var
        PaymentErrorStyle: Text;
}
