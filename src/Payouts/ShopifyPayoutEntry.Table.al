table 50256 "Shopify Payout Entry"
{
    Caption = 'Shopify Payout Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shopify Payout ID"; Text[100])
        {
            Caption = 'Shopify Payout ID';
            DataClassification = CustomerContent;
        }

        field(10; Source; Enum "Shopify Payout Source")
        {
            Caption = 'Source';
            DataClassification = SystemMetadata;
        }

        field(20; "Legacy Resource ID"; BigInteger)
        {
            Caption = 'Legacy Resource ID';
            DataClassification = SystemMetadata;
        }

        field(30; "Shopify Status"; Text[30])
        {
            Caption = 'Shopify Status';
            DataClassification = SystemMetadata;
        }

        field(40; "Transaction Type"; Text[20])
        {
            Caption = 'Transaction Type';
            DataClassification = SystemMetadata;
        }

        field(50; "Issued At"; DateTime)
        {
            Caption = 'Issued At';
            DataClassification = SystemMetadata;
        }

        field(60; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }

        field(70; "Net Amount"; Decimal)
        {
            Caption = 'Net Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(80; "Charges Gross"; Decimal)
        {
            Caption = 'Charges Gross';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(90; "Charges Fee"; Decimal)
        {
            Caption = 'Charges Fee';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(100; "Refunds Gross"; Decimal)
        {
            Caption = 'Refunds Gross';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(110; "Refunds Fee"; Decimal)
        {
            Caption = 'Refunds Fee';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(120; "Adjustments Gross"; Decimal)
        {
            Caption = 'Adjustments Gross';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(130; "Adjustments Fee"; Decimal)
        {
            Caption = 'Adjustments Fee';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(140; "Other Gross"; Decimal)
        {
            Caption = 'Other Gross';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(150; "Other Fee"; Decimal)
        {
            Caption = 'Other Fee';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(160; "Total Fee Amount"; Decimal)
        {
            Caption = 'Total Fee Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(170; "Clearing Settlement Amount"; Decimal)
        {
            Caption = 'Clearing Settlement Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(180; "Summary Gross Amount"; Decimal)
        {
            Caption = 'Summary Gross Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(190; "Summary Difference"; Decimal)
        {
            Caption = 'Summary Difference';
            DecimalPlaces = 0 : 5;
            DataClassification = SystemMetadata;
        }

        field(200; "Processing Status"; Enum "Shopify Payout Proc. Status")
        {
            Caption = 'Processing Status';
            DataClassification = SystemMetadata;
        }

        field(210; "BC Document No."; Code[20])
        {
            Caption = 'BC Document No.';
            DataClassification = CustomerContent;
        }

        field(220; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Bank Account"."No.";
        }

        field(230; "Clearing G/L Account No."; Code[20])
        {
            Caption = 'Clearing G/L Account No.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }

        field(240; "Fee G/L Account No."; Code[20])
        {
            Caption = 'Fee G/L Account No.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }

        field(250; "Last G/L Entry No."; Integer)
        {
            Caption = 'Last G/L Entry No.';
            DataClassification = SystemMetadata;
        }

        field(260; "Attempt Count"; Integer)
        {
            Caption = 'Attempt Count';
            DataClassification = SystemMetadata;
        }

        field(270; "Last Attempt At"; DateTime)
        {
            Caption = 'Last Attempt At';
            DataClassification = SystemMetadata;
        }

        field(280; "Posted At"; DateTime)
        {
            Caption = 'Posted At';
            DataClassification = SystemMetadata;
        }

        field(290; "Result Message"; Text[250])
        {
            Caption = 'Result Message';
            DataClassification = SystemMetadata;
        }

        field(300; "Payout Error"; Text[2048])
        {
            Caption = 'Payout Error';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Shopify Payout ID")
        {
            Clustered = true;
        }

        key(StatusKey; "Processing Status")
        {
        }

        key(IssuedAt; "Issued At")
        {
        }
    }
}
