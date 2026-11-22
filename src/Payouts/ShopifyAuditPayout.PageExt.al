pageextension 50267 "Shopify Audit Payout Page"
    extends "Shopify Audit Snapshots"
{
    layout
    {
        addlast(General)
        {
            field("Payout Successes"; Rec."Payout Successes")
            {
                ApplicationArea = All;
            }

            field("Payout Waiting"; Rec."Payout Waiting")
            {
                ApplicationArea = All;
            }

            field("Payout Skipped"; Rec."Payout Skipped")
            {
                ApplicationArea = All;
            }

            field("Payout Errors"; Rec."Payout Errors")
            {
                ApplicationArea = All;
                StyleExpr = PayoutErrorStyle;
            }

            field("Auto Import Shopify Payouts"; Rec."Auto Import Shopify Payouts")
            {
                ApplicationArea = All;
            }

            field("Auto Post Paid Payouts"; Rec."Auto Post Paid Payouts")
            {
                ApplicationArea = All;
            }

            field("Payout Bank Account No."; Rec."Payout Bank Account No.")
            {
                ApplicationArea = All;
            }

            field("Shopify Fee G/L Account No."; Rec."Shopify Fee G/L Account No.")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Payout Errors" = 0 then
            PayoutErrorStyle :=
                'Favorable'
        else
            PayoutErrorStyle :=
                'Unfavorable';
    end;

    var
        PayoutErrorStyle: Text;
}
