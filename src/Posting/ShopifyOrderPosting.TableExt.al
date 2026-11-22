tableextension 50214 "Shopify Order Posting Ext"
    extends "Shopify Order Import"
{
    fields
    {
        field(50220; "Posting Status"; Enum "Shopify Posting Status")
        {
            Caption = 'Posting Status';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(50221; "Posting Mode Used"; Enum "Shopify Posting Mode")
        {
            Caption = 'Posting Mode Used';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(50222; "Posted At"; DateTime)
        {
            Caption = 'Posted At';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(50223; "Posted Shipment No."; Code[20])
        {
            Caption = 'Posted Shipment No.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50224; "Posted Invoice No."; Code[20])
        {
            Caption = 'Posted Invoice No.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50225; "Posting Attempt Count"; Integer)
        {
            Caption = 'Posting Attempt Count';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(50226; "Last Posting Attempt At"; DateTime)
        {
            Caption = 'Last Posting Attempt At';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(50227; "Posting Error"; Text[2048])
        {
            Caption = 'Posting Error';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PostingStatus; "Posting Status")
        {
        }
    }
}
