tableextension 50213 "Shopify Setup Posting Ext"
    extends "Shopify Integration Setup"
{
    fields
    {
        field(50210; "Auto Post Imported Orders"; Boolean)
        {
            Caption = 'Auto Post Imported Orders';
            DataClassification = SystemMetadata;
        }

        field(50211; "Posting Mode"; Enum "Shopify Posting Mode")
        {
            Caption = 'Posting Mode';
            DataClassification = SystemMetadata;
            InitValue = "Ship and Invoice";
        }

        field(50212; "Posting Date Source"; Enum "Shopify Posting Date Source")
        {
            Caption = 'Posting Date Source';
            DataClassification = SystemMetadata;
            InitValue = "Work Date";
        }
    }
}
