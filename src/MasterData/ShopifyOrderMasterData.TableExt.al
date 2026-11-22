tableextension 50293 "Shopify Order Master Data Ext"
    extends "Shopify Order Import"
{
    fields
    {
        field(50270; "Shopify Customer ID"; Text[100])
        {
            Caption = 'Shopify Customer ID';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50271; "BC Customer No. Used"; Code[20])
        {
            Caption = 'BC Customer No. Used';
            DataClassification = CustomerContent;
            TableRelation = Customer."No.";
            Editable = false;
        }

        field(50272; "Shopify Customer Name"; Text[100])
        {
            Caption = 'Shopify Customer Name';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50273; "Shopify Customer E-Mail"; Text[100])
        {
            Caption = 'Shopify Customer E-Mail';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50274; "BC Location Code Used"; Code[10])
        {
            Caption = 'BC Location Code Used';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
            Editable = false;
        }

        field(50275; "Shopify Location ID Used"; Text[100])
        {
            Caption = 'Shopify Location ID Used';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
