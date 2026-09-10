table 50166 "Shopify Order Buffer"
{
    Caption = 'Shopify Order Buffer';
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

        field(30; Status; Enum "Shopify Order Buffer Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }

        field(40; "Financial Status"; Text[30])
        {
            Caption = 'Financial Status';
            DataClassification = SystemMetadata;
        }

        field(50; "Fulfillment Status"; Text[30])
        {
            Caption = 'Fulfillment Status';
            DataClassification = SystemMetadata;
        }

        field(60; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }

        field(70; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            DataClassification = SystemMetadata;
        }

        field(80; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
            DataClassification = SystemMetadata;
        }

        field(90; Payload; Blob)
        {
            Caption = 'Payload';
            SubType = Memo;
            DataClassification = CustomerContent;
        }

        field(100; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(110; "Last Retry At"; DateTime)
        {
            Caption = 'Last Retry At';
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

        key(OrderID; "Shopify Order ID")
        {
        }
    }

    procedure SetPayload(
        PayloadText: Text)
    var
        OutStreamValue:
            OutStream;
    begin
        Clear(
            Payload);

        Payload.CreateOutStream(
            OutStreamValue,
            TextEncoding::UTF8);

        OutStreamValue.WriteText(
            PayloadText);
    end;

    procedure GetPayload(): Text
    var
        InStreamValue:
            InStream;

        PayloadText: Text;
    begin
        CalcFields(
            Payload);

        if not Payload.HasValue() then
            exit('');

        Payload.CreateInStream(
            InStreamValue,
            TextEncoding::UTF8);

        InStreamValue.ReadText(
            PayloadText);

        exit(
            PayloadText);
    end;
}