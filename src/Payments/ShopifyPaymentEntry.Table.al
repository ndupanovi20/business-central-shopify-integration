table 50225 "Shopify Payment Entry"
{
    Caption = 'Shopify Payment Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shopify Order ID"; Text[100])
        {
            Caption = 'Shopify Order ID';
            DataClassification = CustomerContent;
        }

        field(10; "Shopify Order Name"; Text[50])
        {
            Caption = 'Shopify Order Name';
            DataClassification = CustomerContent;
        }

        field(20; "BC Order No."; Code[20])
        {
            Caption = 'BC Order No.';
            DataClassification = CustomerContent;
        }

        field(30; "Posted Invoice No."; Code[20])
        {
            Caption = 'Posted Invoice No.';
            DataClassification = CustomerContent;
        }

        field(40; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer."No.";
        }

        field(50; "Financial Status"; Text[30])
        {
            Caption = 'Financial Status';
            DataClassification = SystemMetadata;
        }

        field(60; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }

        field(70; Amount; Decimal)
        {
            Caption = 'Amount';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        field(80; "Clearing G/L Account No."; Code[20])
        {
            Caption = 'Clearing G/L Account No.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }

        field(90; Status; Enum "Shopify Payment Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }

        field(100; "Payment Document No."; Code[20])
        {
            Caption = 'Payment Document No.';
            DataClassification = CustomerContent;
        }

        field(110; "Invoice Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Invoice Cust. Ledger Entry No.';
            DataClassification = SystemMetadata;
        }

        field(120; "Payment Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Payment Cust. Ledger Entry No.';
            DataClassification = SystemMetadata;
        }

        field(130; "Attempt Count"; Integer)
        {
            Caption = 'Attempt Count';
            DataClassification = SystemMetadata;
        }

        field(140; "Last Attempt At"; DateTime)
        {
            Caption = 'Last Attempt At';
            DataClassification = SystemMetadata;
        }

        field(150; "Posted At"; DateTime)
        {
            Caption = 'Posted At';
            DataClassification = SystemMetadata;
        }

        field(160; "Result Message"; Text[250])
        {
            Caption = 'Result Message';
            DataClassification = SystemMetadata;
        }

        field(170; "Payment Error"; Text[2048])
        {
            Caption = 'Payment Error';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Shopify Order ID")
        {
            Clustered = true;
        }

        key(StatusKey; Status)
        {
        }

        key(PostedAt; "Posted At")
        {
        }

        key(PaymentDocument; "Payment Document No.")
        {
        }
    }
}
