tableextension 50243 "Shopify Order Fulfillment View"
    extends "Shopify Order Import"
{
    fields
    {
        field(50260; "Fulfillment Entry Count"; Integer)
        {
            Caption = 'Fulfillment Entry Count';
            FieldClass = FlowField;
            CalcFormula = count(
                "Shopify Fulfillment Entry"
                where("Shopify Order ID" = field("Shopify Order ID")));
            Editable = false;
        }

        field(50261; "Successful Fulfillment Count"; Integer)
        {
            Caption = 'Successful Fulfillment Count';
            FieldClass = FlowField;
            CalcFormula = count(
                "Shopify Fulfillment Entry"
                where(
                    "Shopify Order ID" = field("Shopify Order ID"),
                    Status = const(Success)));
            Editable = false;
        }
    }
}
