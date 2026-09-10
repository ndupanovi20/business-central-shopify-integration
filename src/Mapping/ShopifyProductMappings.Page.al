page 50151 "Shopify Product Mappings"
{
    PageType = List;
    SourceTable = "Shopify Product Mapping";

    Caption = 'Shopify Product Mappings';
    ApplicationArea = All;
    UsageCategory = Lists;

    InsertAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }

                field("Shopify Product ID"; Rec."Shopify Product ID")
                {
                    ApplicationArea = All;
                }

                field("Shopify Variant ID"; Rec."Shopify Variant ID")
                {
                    ApplicationArea = All;
                }

                field(
                    "Shopify Inventory Item ID";
                Rec."Shopify Inventory Item ID")
                {
                    ApplicationArea = All;
                }

                field("Last Product Sync"; Rec."Last Product Sync")
                {
                    ApplicationArea = All;
                }

                field("Last Inventory Sync"; Rec."Last Inventory Sync")
                {
                    ApplicationArea = All;
                }

                field("Last Sync Status"; Rec."Last Sync Status")
                {
                    ApplicationArea = All;
                }

                field("Last Error"; Rec."Last Error")
                {
                    ApplicationArea = All;
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }

                field("Modified At"; Rec."Modified At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}