pageextension 50252 "Shopify Audit Fulfillment Ext"
    extends "Shopify Audit Snapshots"
{
    layout
    {
        addlast(General)
        {
            field("Auto Create Fulfillments"; Rec."Auto Create Fulfillments")
            {
                ApplicationArea = All;
            }

            field("Fulfillment Successes"; Rec."Fulfillment Successes")
            {
                ApplicationArea = All;
            }

            field("Fulfillment Waiting Tracking"; Rec."Fulfillment Waiting Tracking")
            {
                ApplicationArea = All;
            }

            field("Fulfillment Skipped"; Rec."Fulfillment Skipped")
            {
                ApplicationArea = All;
            }

            field("Fulfillment Errors"; Rec."Fulfillment Errors")
            {
                ApplicationArea = All;
            }
        }
    }
}
