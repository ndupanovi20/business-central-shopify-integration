tableextension 50266 "Shopify Audit Payout Ext"
    extends "Shopify Audit Snapshot"
{
    fields
    {
        field(50270; "Auto Import Shopify Payouts"; Boolean)
        {
            Caption = 'Auto Import Shopify Payouts';
            DataClassification = SystemMetadata;
        }

        field(50271; "Auto Post Paid Payouts"; Boolean)
        {
            Caption = 'Auto Post Paid Payouts';
            DataClassification = SystemMetadata;
        }

        field(50272; "Payout Successes"; Integer)
        {
            Caption = 'Payout Successes';
            DataClassification = SystemMetadata;
        }

        field(50273; "Payout Waiting"; Integer)
        {
            Caption = 'Payout Waiting';
            DataClassification = SystemMetadata;
        }

        field(50274; "Payout Skipped"; Integer)
        {
            Caption = 'Payout Skipped';
            DataClassification = SystemMetadata;
        }

        field(50275; "Payout Errors"; Integer)
        {
            Caption = 'Payout Errors';
            DataClassification = SystemMetadata;
        }

        field(50276; "Payout Bank Account No."; Code[20])
        {
            Caption = 'Payout Bank Account No.';
            DataClassification = CustomerContent;
        }

        field(50277; "Shopify Fee G/L Account No."; Code[20])
        {
            Caption = 'Shopify Fee G/L Account No.';
            DataClassification = CustomerContent;
        }
    }
}
