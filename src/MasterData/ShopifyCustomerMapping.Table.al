table 50288 "Shopify Customer Mapping"
{
    Caption = 'Shopify Customer Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shopify Customer ID"; Text[100])
        {
            Caption = 'Shopify Customer ID';
            DataClassification = CustomerContent;
        }

        field(10; "Shopify Customer Name"; Text[100])
        {
            Caption = 'Shopify Customer Name';
            DataClassification = CustomerContent;
        }

        field(20; "Shopify E-Mail"; Text[100])
        {
            Caption = 'Shopify E-Mail';
            DataClassification = CustomerContent;
        }

        field(30; "Shopify Phone No."; Text[50])
        {
            Caption = 'Shopify Phone No.';
            DataClassification = CustomerContent;
        }

        field(40; "BC Customer No."; Code[20])
        {
            Caption = 'BC Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer."No.";
        }

        field(50; "Created Automatically"; Boolean)
        {
            Caption = 'Created Automatically';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(60; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(70; "Last Used At"; DateTime)
        {
            Caption = 'Last Used At';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(80; "Last Shopify Order Name"; Text[50])
        {
            Caption = 'Last Shopify Order Name';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Shopify Customer ID")
        {
            Clustered = true;
        }

        key(BCCustomer; "BC Customer No.")
        {
        }
    }
}
