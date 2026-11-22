tableextension 50275 "Shopify Refund Setup Ext"
    extends "Shopify Integration Setup"
{
    fields
    {
        field(50270; "Auto Import Shopify Refunds"; Boolean)
        {
            Caption = 'Auto Import Shopify Refunds';
            DataClassification = SystemMetadata;
        }

        field(50271; "Auto Process Shopify Refunds"; Boolean)
        {
            Caption = 'Auto Process Shopify Refunds';
            DataClassification = SystemMetadata;
        }

        field(50272; "Import Refunds From"; DateTime)
        {
            Caption = 'Import Refunds From';
            DataClassification = SystemMetadata;
        }
    }
}
