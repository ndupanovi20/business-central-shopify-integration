table 50240 "Shopify Fulfillment Entry"
{
    Caption = 'Shopify Fulfillment Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }

        field(10; "Shopify Order ID"; Text[100])
        {
            Caption = 'Shopify Order ID';
            DataClassification = CustomerContent;
        }

        field(20; "Shopify Order Name"; Text[50])
        {
            Caption = 'Shopify Order Name';
            DataClassification = CustomerContent;
        }

        field(30; "BC Order No."; Code[20])
        {
            Caption = 'BC Order No.';
            DataClassification = CustomerContent;
        }

        field(40; "Posted Shipment No."; Code[20])
        {
            Caption = 'Posted Shipment No.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Shipment Header"."No.";
        }

        field(50; "Shopify Fulfillment ID"; Text[100])
        {
            Caption = 'Shopify Fulfillment ID';
            DataClassification = CustomerContent;
        }

        field(60; "Fulfillment Order IDs"; Text[2048])
        {
            Caption = 'Fulfillment Order IDs';
            DataClassification = CustomerContent;
        }

        field(70; "Shopify Location ID"; Text[100])
        {
            Caption = 'Shopify Location ID';
            DataClassification = CustomerContent;
        }

        field(80; Status; Enum "Shopify Fulfillment Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }

        field(90; "Attempt Count"; Integer)
        {
            Caption = 'Attempt Count';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(100; "Last Attempt At"; DateTime)
        {
            Caption = 'Last Attempt At';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(110; "Fulfilled At"; DateTime)
        {
            Caption = 'Fulfilled At';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(120; "Tracking No."; Text[50])
        {
            Caption = 'Tracking No.';
            DataClassification = CustomerContent;
        }

        field(130; "Tracking Company"; Text[50])
        {
            Caption = 'Tracking Company';
            DataClassification = CustomerContent;
        }

        field(140; "Tracking URL"; Text[250])
        {
            Caption = 'Tracking URL';
            DataClassification = CustomerContent;
        }

        field(150; "Tracking Synced At"; DateTime)
        {
            Caption = 'Tracking Synced At';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(160; "Notify Customer"; Boolean)
        {
            Caption = 'Notify Customer';
            DataClassification = SystemMetadata;
        }

        field(170; "Result Message"; Text[250])
        {
            Caption = 'Result Message';
            DataClassification = SystemMetadata;
        }

        field(180; "Fulfillment Error"; Text[2048])
        {
            Caption = 'Fulfillment Error';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(190; "Tracking Error"; Text[2048])
        {
            Caption = 'Tracking Error';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(OrderShipment; "Shopify Order ID", "Posted Shipment No.")
        {
            Unique = true;
        }

        key(StatusKey; Status)
        {
        }

        key(FulfillmentId; "Shopify Fulfillment ID")
        {
        }
    }
}
