table 50150 "Shopify Product Mapping"
{
    Caption = 'Shopify Product Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
        }

        field(10; "Shopify Product ID"; Text[100])
        {
            Caption = 'Shopify Product ID';
            DataClassification = CustomerContent;
        }

        field(20; "Shopify Variant ID"; Text[100])
        {
            Caption = 'Shopify Variant ID';
            DataClassification = CustomerContent;
        }

        field(30; "Shopify Inventory Item ID"; Text[100])
        {
            Caption = 'Shopify Inventory Item ID';
            DataClassification = CustomerContent;
        }

        field(40; "Last Product Sync"; DateTime)
        {
            Caption = 'Last Product Sync';
            DataClassification = SystemMetadata;
        }

        field(50; "Last Inventory Sync"; DateTime)
        {
            Caption = 'Last Inventory Sync';
            DataClassification = SystemMetadata;
        }

        field(60; "Last Sync Status"; Enum "Shopify Sync Status")
        {
            Caption = 'Last Sync Status';
            DataClassification = SystemMetadata;
        }

        field(70; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
            DataClassification = SystemMetadata;
        }

        field(80; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }

        field(90; "Modified At"; DateTime)
        {
            Caption = 'Modified At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Item No.")
        {
            Clustered = true;
        }

        key(ShopifyProduct; "Shopify Product ID")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();

        "Modified At" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        "Modified At" := CurrentDateTime();
    end;
}