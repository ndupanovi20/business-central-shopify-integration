tableextension 50237 "Shopify Audit Payment Ext"
    extends "Shopify Audit Snapshot"
{
    fields
    {
        field(50250; "Auto Record Shopify Payments"; Boolean)
        {
            Caption = 'Auto Record Shopify Payments';
            DataClassification = SystemMetadata;
        }

        field(50251; "Payment Successes"; Integer)
        {
            Caption = 'Payment Successes';
            DataClassification = SystemMetadata;
        }

        field(50252; "Payment Skipped"; Integer)
        {
            Caption = 'Payment Skipped';
            DataClassification = SystemMetadata;
        }

        field(50253; "Payment Errors"; Integer)
        {
            Caption = 'Payment Errors';
            DataClassification = SystemMetadata;
        }

        field(50254; "Shopify Clearing G/L Acc. No."; Code[20])
        {
            Caption = 'Shopify Clearing G/L Account No.';
            DataClassification = CustomerContent;
        }
    }
}
