table 50204 "Shopify Background Run Result"
{
    Caption = 'Shopify Background Run Result';
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }

        field(10; "Result Count"; Integer)
        {
            Caption = 'Result Count';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}