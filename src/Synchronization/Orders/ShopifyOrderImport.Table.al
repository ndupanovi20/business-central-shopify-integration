table 50130 "Shopify Order Import"
{
    Caption = 'Shopify Order Import';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shopify Order ID"; Text[100])
        {
            Caption = 'Shopify Order ID';
            DataClassification = CustomerContent;
        }

        field(10; "Shopify Order Name"; Text[50])
        {
            Caption = 'Shopify Order Name';
            DataClassification = CustomerContent;
        }

        field(20; "BC Order No."; Code[20])
        {
            Caption = 'BC Order No.';
            DataClassification = CustomerContent;
        }

        field(30; "Shopify Created At"; DateTime)
        {
            Caption = 'Shopify Created At';
            DataClassification = SystemMetadata;
        }

        field(40; "Imported At"; DateTime)
        {
            Caption = 'Imported At';
            DataClassification = SystemMetadata;
        }

        field(50; "Financial Status"; Text[30])
        {
            Caption = 'Financial Status';
            DataClassification = SystemMetadata;
        }

        field(60; "Fulfillment Status"; Text[30])
        {
            Caption = 'Fulfillment Status';
            DataClassification = SystemMetadata;
        }

        field(70; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }

        field(80; "Shopify Total"; Decimal)
        {
            Caption = 'Shopify Total';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(90; "BC Total"; Decimal)
        {
            Caption = 'BC Total';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(100; "Total Difference"; Decimal)
        {
            Caption = 'Total Difference';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(110; "Shipping Amount"; Decimal)
        {
            Caption = 'Shipping Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(120; "Discount Amount"; Decimal)
        {
            Caption = 'Discount Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(130; "Line Count"; Integer)
        {
            Caption = 'Line Count';
            DataClassification = SystemMetadata;
        }

        field(140; "Tag Status"; Enum "Shopify Order Tag Status")
        {
            Caption = 'Shopify Tag Status';
            DataClassification = SystemMetadata;
        }

        field(150; "Tagged At"; DateTime)
        {
            Caption = 'Tagged At';
            DataClassification = SystemMetadata;
        }

        field(160; "Tag Retry Count"; Integer)
        {
            Caption = 'Tag Retry Count';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(170; "Tag Error"; Text[2048])
        {
            Caption = 'Tag Error';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Shopify Order ID")
        {
            Clustered = true;
        }

        key(BCOrder; "BC Order No.")
        {
        }

        key(ImportedAt; "Imported At")
        {
        }

        key(TagStatus; "Tag Status")
        {
        }
    }
}