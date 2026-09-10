table 50100 "Shopify Integration Setup"
{
    Caption = 'Shopify Integration Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }

        field(10; "Shop Domain"; Text[250])
        {
            Caption = 'Shop Domain';
            DataClassification = CustomerContent;
        }

        field(20; "Client ID"; Text[100])
        {
            Caption = 'Client ID';
            DataClassification = CustomerContent;
        }

        field(30; "API Version"; Code[20])
        {
            Caption = 'API Version';
            DataClassification = CustomerContent;
        }

        field(40; "Shopify Location ID"; Text[100])
        {
            Caption = 'Shopify Location ID';
            DataClassification = CustomerContent;
        }

        field(45; "BC Location Code"; Code[10])
        {
            Caption = 'BC Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }

        field(50; "BC Customer No."; Code[20])
        {
            Caption = 'BC Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer."No.";
        }

        field(55; "BC Shipping Item No."; Code[20])
        {
            Caption = 'BC Shipping Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
        }

        field(60; "Import Only Paid Orders"; Boolean)
        {
            Caption = 'Import Only Paid Orders';
            DataClassification = SystemMetadata;
        }

        field(65; "Import Orders From"; DateTime)
        {
            Caption = 'Import Orders From';
            DataClassification = SystemMetadata;
        }

        field(70; "Auto Import Orders"; Boolean)
        {
            Caption = 'Auto Import Orders';
            DataClassification = SystemMetadata;
        }

        field(80; "Auto Sync Inventory"; Boolean)
        {
            Caption = 'Auto Sync Inventory';
            DataClassification = SystemMetadata;
        }

        field(85; "Background Sync Interval"; Integer)
        {
            Caption = 'Background Sync Interval (Min.)';
            DataClassification = SystemMetadata;
            InitValue = 15;
            MinValue = 1;
        }

        field(90; "Last Background Sync"; DateTime)
        {
            Caption = 'Last Background Sync';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(100; "Last Background Result"; Text[250])
        {
            Caption = 'Last Background Result';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(110; "Tag Imported Orders"; Boolean)
        {
            Caption = 'Tag Imported Orders in Shopify';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if "Tag Imported Orders" and
                   ("Imported Order Tag" = '')
                then
                    "Imported Order Tag" :=
                        'BC-IMPORTED';
            end;
        }

        field(120; "Imported Order Tag"; Text[50])
        {
            Caption = 'Imported Order Tag';
            DataClassification = CustomerContent;
            InitValue = 'BC-IMPORTED';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}