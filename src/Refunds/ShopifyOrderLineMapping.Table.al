table 50269 "Shopify Order Line Mapping"
{
    Caption = 'Shopify Order Line Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shopify Order ID"; Text[100])
        {
            Caption = 'Shopify Order ID';
            DataClassification = CustomerContent;
        }

        field(10; "Shopify Line Item ID"; Text[100])
        {
            Caption = 'Shopify Line Item ID';
            DataClassification = CustomerContent;
        }

        field(20; "Shopify Order Name"; Text[50])
        {
            Caption = 'Shopify Order Name';
            DataClassification = CustomerContent;
        }

        field(30; "Shopify SKU"; Text[100])
        {
            Caption = 'Shopify SKU';
            DataClassification = CustomerContent;
        }

        field(40; "BC Order No."; Code[20])
        {
            Caption = 'BC Order No.';
            DataClassification = CustomerContent;
        }

        field(50; "BC Order Line No."; Integer)
        {
            Caption = 'BC Order Line No.';
            DataClassification = SystemMetadata;
        }

        field(60; "BC Item No."; Code[20])
        {
            Caption = 'BC Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
        }

        field(70; "Original Quantity"; Decimal)
        {
            Caption = 'Original Quantity';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(80; "Original Unit Price"; Decimal)
        {
            Caption = 'Original Unit Price';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(90; "Original Discount Amount"; Decimal)
        {
            Caption = 'Original Discount Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(100; "Posted Invoice No."; Code[20])
        {
            Caption = 'Posted Invoice No.';
            DataClassification = CustomerContent;
        }

        field(110; "Posted Invoice Line No."; Integer)
        {
            Caption = 'Posted Invoice Line No.';
            DataClassification = SystemMetadata;
        }

        field(120; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }

        field(130; "Updated At"; DateTime)
        {
            Caption = 'Updated At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Shopify Order ID", "Shopify Line Item ID")
        {
            Clustered = true;
        }

        key(BCOrderLine; "BC Order No.", "BC Order Line No.")
        {
        }

        key(PostedInvoiceLine; "Posted Invoice No.", "Posted Invoice Line No.")
        {
        }
    }
}
