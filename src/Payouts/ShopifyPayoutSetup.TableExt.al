tableextension 50258 "Shopify Payout Setup Ext"
    extends "Shopify Integration Setup"
{
    fields
    {
        field(50260; "Auto Import Shopify Payouts"; Boolean)
        {
            Caption = 'Auto Import Shopify Payouts';
            DataClassification = SystemMetadata;
        }

        field(50261; "Auto Post Paid Payouts"; Boolean)
        {
            Caption = 'Auto Post Paid Payouts';
            DataClassification = SystemMetadata;
        }

        field(50262; "Import Payouts From"; DateTime)
        {
            Caption = 'Import Payouts From';
            DataClassification = SystemMetadata;
        }

        field(50263; "Shopify Payout Bank Acc. No."; Code[20])
        {
            Caption = 'Shopify Payout Bank Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Bank Account"."No.";
        }

        field(50264; "Shopify Fee G/L Acc. No."; Code[20])
        {
            Caption = 'Shopify Fee G/L Account No.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }

        field(50265; "Payout Journal Template Name"; Code[10])
        {
            Caption = 'Payout Journal Template Name';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Journal Template".Name;

            trigger OnValidate()
            begin
                if xRec."Payout Journal Template Name" <>
                   "Payout Journal Template Name"
                then
                    Clear(
                        "Payout Journal Batch Name");
            end;
        }

        field(50266; "Payout Journal Batch Name"; Code[10])
        {
            Caption = 'Payout Journal Batch Name';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Payout Journal Template Name"));
        }
    }
}
