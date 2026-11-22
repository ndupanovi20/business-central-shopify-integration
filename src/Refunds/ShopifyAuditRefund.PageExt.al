pageextension 50286 "Shopify Audit Refund Ext"
    extends "Shopify Audit Snapshots"
{
    layout
    {
        addlast(General)
        {
            field("Auto Import Shopify Refunds"; Rec."Auto Import Shopify Refunds")
            {
                ApplicationArea = All;
            }

            field("Auto Process Shopify Refunds"; Rec."Auto Process Shopify Refunds")
            {
                ApplicationArea = All;
            }

            field("Refund Successes"; Rec."Refund Successes")
            {
                ApplicationArea = All;
            }

            field("Refund Pending"; Rec."Refund Pending")
            {
                ApplicationArea = All;
            }

            field("Refund Waiting"; Rec."Refund Waiting")
            {
                ApplicationArea = All;
            }

            field("Refund Manual Review"; Rec."Refund Manual Review")
            {
                ApplicationArea = All;
            }

            field("Refund Errors"; Rec."Refund Errors")
            {
                ApplicationArea = All;
            }


            field("Import Refunds From"; Rec."Import Refunds From")
            {
                ApplicationArea = All;
            }
        }
    }
}
