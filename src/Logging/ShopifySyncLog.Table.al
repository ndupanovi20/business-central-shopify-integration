table 50163 "Shopify Sync Log"
{
    Caption = 'Shopify Sync Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }

        field(10; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }

        field(20; Direction; Enum "Shopify Sync Direction")
        {
            Caption = 'Direction';
            DataClassification = SystemMetadata;
        }

        field(30; "Entity Type"; Enum "Shopify Sync Entity")
        {
            Caption = 'Entity Type';
            DataClassification = SystemMetadata;
        }

        field(40; Status; Enum "Shopify Sync Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }

        field(50; "BC Key"; Text[100])
        {
            Caption = 'BC Key';
            DataClassification = CustomerContent;
        }

        field(60; "Shopify ID"; Text[100])
        {
            Caption = 'Shopify ID';
            DataClassification = CustomerContent;
        }

        field(70; Message; Text[2048])
        {
            Caption = 'Message';
            DataClassification = SystemMetadata;
        }

        field(80; Duration; Duration)
        {
            Caption = 'Duration';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(DateKey; "Created At")
        {
        }

        key(BCKey; "BC Key")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;
}