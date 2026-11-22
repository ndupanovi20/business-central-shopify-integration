tableextension 50251 "Shopify Audit Fulfillment Ext"
    extends "Shopify Audit Snapshot"
{
    fields
    {
        field(50260; "Auto Create Fulfillments"; Boolean)
        {
            Caption = 'Auto Create Fulfillments';
            DataClassification = SystemMetadata;
        }

        field(50261; "Fulfillment Successes"; Integer)
        {
            Caption = 'Fulfillment Successes';
            DataClassification = SystemMetadata;
        }

        field(50262; "Fulfillment Waiting Tracking"; Integer)
        {
            Caption = 'Fulfillment Waiting Tracking';
            DataClassification = SystemMetadata;
        }

        field(50263; "Fulfillment Skipped"; Integer)
        {
            Caption = 'Fulfillment Skipped';
            DataClassification = SystemMetadata;
        }

        field(50264; "Fulfillment Errors"; Integer)
        {
            Caption = 'Fulfillment Errors';
            DataClassification = SystemMetadata;
        }
    }
}
