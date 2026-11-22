pageextension 50302 "Shopify Audit Master Data Ext"
    extends "Shopify Audit Snapshots"
{
    layout
    {
        addlast(General)
        {
            field("Customer Strategy"; Rec."Customer Strategy")
            {
                ApplicationArea = All;
            }

            field("Customer Mapping Count"; Rec."Customer Mapping Count")
            {
                ApplicationArea = All;
            }

            field("Use Location Mappings"; Rec."Use Location Mappings")
            {
                ApplicationArea = All;
            }

            field("Location Mapping Count"; Rec."Location Mapping Count")
            {
                ApplicationArea = All;
            }
        }
    }
}
