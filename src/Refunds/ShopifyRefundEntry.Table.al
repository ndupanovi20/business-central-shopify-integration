table 50271 "Shopify Refund Entry"
{
    Caption = 'Shopify Refund Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shopify Refund ID"; Text[100])
        {
            Caption = 'Shopify Refund ID';
            DataClassification = CustomerContent;
        }

        field(10; "Legacy Resource ID"; Text[30])
        {
            Caption = 'Legacy Resource ID';
            DataClassification = SystemMetadata;
        }

        field(20; "Shopify Order ID"; Text[100])
        {
            Caption = 'Shopify Order ID';
            DataClassification = CustomerContent;
        }

        field(30; "Shopify Order Name"; Text[50])
        {
            Caption = 'Shopify Order Name';
            DataClassification = CustomerContent;
        }

        field(40; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            DataClassification = SystemMetadata;
        }

        field(50; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }

        field(60; "Refund Total"; Decimal)
        {
            Caption = 'Refund Total';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(70; "Successful Transaction Total"; Decimal)
        {
            Caption = 'Successful Transaction Total';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(80; "Supported Component Total"; Decimal)
        {
            Caption = 'Supported Component Total';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(90; "Shipping Refund Amount"; Decimal)
        {
            Caption = 'Shipping Refund Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(100; "Line Refund Amount"; Decimal)
        {
            Caption = 'Line Refund Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(110; "Order Adjustment Amount"; Decimal)
        {
            Caption = 'Order Adjustment Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(120; "Refund Line Count"; Integer)
        {
            Caption = 'Refund Line Count';
            DataClassification = SystemMetadata;
        }

        field(130; Status; Enum "Shopify Refund Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }

        field(140; "Manual Review Reason"; Text[1024])
        {
            Caption = 'Manual Review Reason';
            DataClassification = SystemMetadata;
        }

        field(150; "BC Credit Memo No."; Code[20])
        {
            Caption = 'BC Credit Memo No.';
            DataClassification = CustomerContent;
        }

        field(160; "Posted Credit Memo No."; Code[20])
        {
            Caption = 'Posted Credit Memo No.';
            DataClassification = CustomerContent;
        }

        field(170; "Refund Journal Document No."; Code[20])
        {
            Caption = 'Refund Journal Document No.';
            DataClassification = CustomerContent;
        }

        field(180; "Credit Memo Ledger Entry No."; Integer)
        {
            Caption = 'Credit Memo Ledger Entry No.';
            DataClassification = SystemMetadata;
        }

        field(190; "Refund Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Refund Cust. Ledger Entry No.';
            DataClassification = SystemMetadata;
        }

        field(200; "Attempt Count"; Integer)
        {
            Caption = 'Attempt Count';
            DataClassification = SystemMetadata;
        }

        field(210; "Last Attempt At"; DateTime)
        {
            Caption = 'Last Attempt At';
            DataClassification = SystemMetadata;
        }

        field(220; "Completed At"; DateTime)
        {
            Caption = 'Completed At';
            DataClassification = SystemMetadata;
        }

        field(230; "Result Message"; Text[250])
        {
            Caption = 'Result Message';
            DataClassification = SystemMetadata;
        }

        field(240; "Refund Error"; Text[2048])
        {
            Caption = 'Refund Error';
            DataClassification = SystemMetadata;
        }

        field(250; "Raw Refund JSON"; Blob)
        {
            Caption = 'Raw Refund JSON';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Shopify Refund ID")
        {
            Clustered = true;
        }

        key(OrderKey; "Shopify Order ID")
        {
        }

        key(StatusKey; Status)
        {
        }

        key(ProcessedAt; "Processed At")
        {
        }
    }

    procedure SetRawRefundJson(JsonText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Raw Refund JSON");
        "Raw Refund JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(JsonText);
    end;

    procedure GetRawRefundJson(): Text
    var
        InStr: InStream;
        ResultText: Text;
    begin
        CalcFields("Raw Refund JSON");

        if not "Raw Refund JSON".HasValue then
            exit('');

        "Raw Refund JSON".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(ResultText);
        exit(ResultText);
    end;
}
