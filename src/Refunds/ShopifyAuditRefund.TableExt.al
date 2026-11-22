tableextension 50285 "Shopify Audit Refund Ext"
    extends "Shopify Audit Snapshot"
{
    fields
    {
        field(50280; "Auto Import Shopify Refunds"; Boolean)
        {
            Caption = 'Auto Import Shopify Refunds';
            DataClassification = SystemMetadata;
        }

        field(50281; "Auto Process Shopify Refunds"; Boolean)
        {
            Caption = 'Auto Process Shopify Refunds';
            DataClassification = SystemMetadata;
        }

        field(50282; "Refund Successes"; Integer)
        {
            Caption = 'Refund Successes';
            DataClassification = SystemMetadata;
        }

        field(50283; "Refund Pending"; Integer)
        {
            Caption = 'Refund Pending';
            DataClassification = SystemMetadata;
        }

        field(50284; "Refund Waiting"; Integer)
        {
            Caption = 'Refund Waiting';
            DataClassification = SystemMetadata;
        }

        field(50285; "Refund Manual Review"; Integer)
        {
            Caption = 'Refund Manual Review';
            DataClassification = SystemMetadata;
        }

        field(50286; "Refund Errors"; Integer)
        {
            Caption = 'Refund Errors';
            DataClassification = SystemMetadata;
        }

        field(50287; "Import Refunds From"; DateTime)
        {
            Caption = 'Import Refunds From';
            DataClassification = SystemMetadata;
        }
    }
}
