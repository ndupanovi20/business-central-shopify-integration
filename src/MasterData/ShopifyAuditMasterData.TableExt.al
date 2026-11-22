tableextension 50301 "Shopify Audit Master Data Ext"
    extends "Shopify Audit Snapshot"
{
    fields
    {
        field(50290; "Customer Strategy"; Enum "Shopify Customer Strategy")
        {
            Caption = 'Customer Strategy';
            DataClassification = SystemMetadata;
        }

        field(50291; "Customer Mapping Count"; Integer)
        {
            Caption = 'Customer Mapping Count';
            DataClassification = SystemMetadata;
        }

        field(50292; "Use Location Mappings"; Boolean)
        {
            Caption = 'Use Location Mappings';
            DataClassification = SystemMetadata;
        }

        field(50293; "Location Mapping Count"; Integer)
        {
            Caption = 'Location Mapping Count';
            DataClassification = SystemMetadata;
        }
    }
}
