tableextension 50242 "Shopify Fulfillment Setup Ext"
    extends "Shopify Integration Setup"
{
    fields
    {
        field(50250; "Auto Create Fulfillment"; Boolean)
        {
            Caption = 'Auto Create Shopify Fulfillment';
            DataClassification = SystemMetadata;
        }

        field(50251; "Notify Customer on Fulfillment"; Boolean)
        {
            Caption = 'Notify Customer on Fulfillment';
            DataClassification = SystemMetadata;
        }

        field(50252; "Require Tracking No."; Boolean)
        {
            Caption = 'Require Tracking No. for Fulfillment';
            DataClassification = SystemMetadata;
        }

        field(50253; "Auto Sync Fulfillment Tracking"; Boolean)
        {
            Caption = 'Auto Sync Fulfillment Tracking';
            DataClassification = SystemMetadata;
        }
    }
}
