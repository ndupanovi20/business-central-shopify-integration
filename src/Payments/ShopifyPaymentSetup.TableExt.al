tableextension 50231 "Shopify Payment Setup Ext"
    extends "Shopify Integration Setup"
{
    fields
    {
        field(50230; "Auto Record Shopify Payments"; Boolean)
        {
            Caption = 'Auto Record Shopify Payments';
            DataClassification = SystemMetadata;
        }

        field(50231; "Shopify Clearing G/L Acc. No."; Code[20])
        {
            Caption = 'Shopify Clearing G/L Account No.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }

        field(50232; "Payment Journal Template Name"; Code[10])
        {
            Caption = 'Payment Journal Template Name';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Journal Template".Name;

            trigger OnValidate()
            begin
                if xRec."Payment Journal Template Name" <>
                   "Payment Journal Template Name"
                then
                    Clear(
                        "Payment Journal Batch Name");
            end;
        }

        field(50233; "Payment Journal Batch Name"; Code[10])
        {
            Caption = 'Payment Journal Batch Name';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Payment Journal Template Name"));
        }

        field(50234; "Payment Date Source"; Enum "Shopify Payment Date Source")
        {
            Caption = 'Payment Date Source';
            DataClassification = SystemMetadata;
            InitValue = "Posted Invoice Date";
        }
    }
}
