table 50295 "Shopify Location Mapping"
{
    Caption = 'Shopify Location Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(10; "BC Location Code"; Code[10])
        {
            Caption = 'BC Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;

            trigger OnValidate()
            var
                OtherMapping: Record "Shopify Location Mapping";
            begin
                if "BC Location Code" = '' then
                    exit;

                OtherMapping.SetRange("BC Location Code", "BC Location Code");
                OtherMapping.SetFilter("Entry No.", '<>%1', "Entry No.");

                if OtherMapping.FindFirst() then
                    Error(
                        'Business Central location %1 is already mapped to Shopify location %2.',
                        "BC Location Code",
                        OtherMapping."Shopify Location Name");
            end;
        }

        field(20; "Shopify Location ID"; Text[100])
        {
            Caption = 'Shopify Location ID';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(30; "Shopify Location Name"; Text[100])
        {
            Caption = 'Shopify Location Name';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(40; Active; Boolean)
        {
            Caption = 'Active';
            DataClassification = SystemMetadata;
            InitValue = true;
        }

        field(50; "Default for Order Imports"; Boolean)
        {
            Caption = 'Default for Order Imports';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                OtherMapping: Record "Shopify Location Mapping";
            begin
                if not "Default for Order Imports" then
                    exit;

                OtherMapping.SetRange("Default for Order Imports", true);
                OtherMapping.SetFilter("Entry No.", '<>%1', "Entry No.");

                if OtherMapping.FindSet() then
                    repeat
                        OtherMapping."Default for Order Imports" := false;
                        OtherMapping.Modify(false);
                    until OtherMapping.Next() = 0;
            end;
        }

        field(60; "Last Refreshed At"; DateTime)
        {
            Caption = 'Last Refreshed At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(ShopifyLocation; "Shopify Location ID")
        {
            Unique = true;
        }

        key(BCLocation; "BC Location Code")
        {
        }
    }
}
