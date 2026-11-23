page 50274 "Shopify Refund Lines"
{
    PageType = List;
    SourceTable = "Shopify Refund Line";

    Caption = 'Shopify Refund Lines';
    ApplicationArea = All;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Shopify Refund Line ID"; Rec."Shopify Refund Line ID")
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

                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }

                field("Restock Type"; Rec."Restock Type")
                {
                    ApplicationArea = All;
                }

                field("Shopify Location ID"; Rec."Shopify Location ID")
                {
                    ApplicationArea = All;
                }

                field("Subtotal Amount"; Rec."Subtotal Amount")
                {
                    ApplicationArea = All;
                }

                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = All;
                }

                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                }

                field("BC Item No."; Rec."BC Item No.")
                {
                    ApplicationArea = All;
                }

                field("BC Return Location Code"; Rec."BC Return Location Code")
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
            }
        }
    }
}
