tableextension 50290 "Shopify Master Data Setup Ext"
    extends "Shopify Integration Setup"
{
    fields
    {
        field(50280; "Customer Strategy"; Enum "Shopify Customer Strategy")
        {
            Caption = 'Customer Strategy';
            DataClassification = SystemMetadata;
            InitValue = "Generic Customer";
        }

        field(50281; "Apply Shopify Order Addresses"; Boolean)
        {
            Caption = 'Apply Shopify Order Addresses';
            DataClassification = SystemMetadata;
            InitValue = true;
        }

        field(50282; "Fallback to Generic Customer"; Boolean)
        {
            Caption = 'Fallback to Generic Customer';
            DataClassification = SystemMetadata;
            InitValue = true;
        }

        field(50283; "Use Location Mappings"; Boolean)
        {
            Caption = 'Use Location Mappings';
            DataClassification = SystemMetadata;
        }
    }
}
