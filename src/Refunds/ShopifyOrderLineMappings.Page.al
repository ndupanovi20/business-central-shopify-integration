page 50270 "Shopify Order Line Mappings"
{
    PageType = List;
    SourceTable = "Shopify Order Line Mapping";

    Caption = 'Shopify Order Line Mappings';
    ApplicationArea = All;
    UsageCategory = Lists;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Shopify Order Name"; Rec."Shopify Order Name")
                {
                    ApplicationArea = All;
                }

                field("Shopify Line Item ID"; Rec."Shopify Line Item ID")
                {
                    ApplicationArea = All;
                }

                field("Shopify SKU"; Rec."Shopify SKU")
                {
                    ApplicationArea = All;
                }

                field("BC Order No."; Rec."BC Order No.")
                {
                    ApplicationArea = All;
                }

                field("BC Order Line No."; Rec."BC Order Line No.")
                {
                    ApplicationArea = All;
                }

                field("BC Item No."; Rec."BC Item No.")
                {
                    ApplicationArea = All;
                }

                field("Original Quantity"; Rec."Original Quantity")
                {
                    ApplicationArea = All;
                }

                field("Original Unit Price"; Rec."Original Unit Price")
                {
                    ApplicationArea = All;
                }

                field("Original Discount Amount"; Rec."Original Discount Amount")
                {
                    ApplicationArea = All;
                }

                field("Posted Invoice No."; Rec."Posted Invoice No.")
                {
                    ApplicationArea = All;
                }

                field("Posted Invoice Line No."; Rec."Posted Invoice Line No.")
                {
                    ApplicationArea = All;
                }

                field("Updated At"; Rec."Updated At")
                {
                    ApplicationArea = All;
                }

                field("Shopify Order ID"; Rec."Shopify Order ID")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
