table 50272 "Shopify Refund Line"
{
    Caption = 'Shopify Refund Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shopify Refund ID"; Text[100])
        {
            Caption = 'Shopify Refund ID';
            DataClassification = CustomerContent;
        }

        field(10; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }

        field(20; "Shopify Refund Line ID"; Text[100])
        {
            Caption = 'Shopify Refund Line ID';
            DataClassification = CustomerContent;
        }

        field(30; "Shopify Line Item ID"; Text[100])
        {
            Caption = 'Shopify Line Item ID';
            DataClassification = CustomerContent;
        }

        field(40; "Shopify SKU"; Text[100])
        {
            Caption = 'Shopify SKU';
            DataClassification = CustomerContent;
        }

        field(50; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(60; "Restock Type"; Text[30])
        {
            Caption = 'Restock Type';
            DataClassification = SystemMetadata;
        }

        field(70; "Shopify Location ID"; Text[100])
        {
            Caption = 'Shopify Location ID';
            DataClassification = CustomerContent;
        }

        field(80; "Subtotal Amount"; Decimal)
        {
            Caption = 'Subtotal Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(90; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(100; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(110; "BC Item No."; Code[20])
        {
            Caption = 'BC Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
        }

        field(120; "Posted Invoice No."; Code[20])
        {
            Caption = 'Posted Invoice No.';
            DataClassification = CustomerContent;
        }

        field(130; "Posted Invoice Line No."; Integer)
        {
            Caption = 'Posted Invoice Line No.';
            DataClassification = SystemMetadata;
        }
        field(140; "BC Return Location Code"; Code[10])
        {
            Caption = 'BC Return Location Code';
            TableRelation = Location.Code;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Shopify Refund ID", "Line No.")
        {
            Clustered = true;
        }

        key(ShopifyLineItem; "Shopify Line Item ID")
        {
        }
    }
}
