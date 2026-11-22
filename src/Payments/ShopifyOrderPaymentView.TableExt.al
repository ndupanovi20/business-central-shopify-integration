tableextension 50236 "Shopify Order Payment View"
    extends "Shopify Order Import"
{
    fields
    {
        field(50240; "Payment Status"; Enum "Shopify Payment Status")
        {
            Caption = 'Payment Status';
            FieldClass = FlowField;
            CalcFormula = lookup("Shopify Payment Entry".Status where("Shopify Order ID" = field("Shopify Order ID")));
            Editable = false;
        }

        field(50241; "Payment Document No."; Code[20])
        {
            Caption = 'Payment Document No.';
            FieldClass = FlowField;
            CalcFormula = lookup("Shopify Payment Entry"."Payment Document No." where("Shopify Order ID" = field("Shopify Order ID")));
            Editable = false;
        }

        field(50242; "Payment Amount"; Decimal)
        {
            Caption = 'Payment Amount';
            FieldClass = FlowField;
            CalcFormula = lookup("Shopify Payment Entry".Amount where("Shopify Order ID" = field("Shopify Order ID")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }
}
