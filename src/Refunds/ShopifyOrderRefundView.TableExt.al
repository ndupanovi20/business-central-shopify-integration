tableextension 50281 "Shopify Order Refund View"
    extends "Shopify Order Import"
{
    fields
    {
        field(50250; "Refund Count"; Integer)
        {
            Caption = 'Refund Count';
            FieldClass = FlowField;
            CalcFormula = count("Shopify Refund Entry" where("Shopify Order ID" = field("Shopify Order ID")));
            Editable = false;
        }

        field(50251; "Successful Refund Count"; Integer)
        {
            Caption = 'Successful Refund Count';
            FieldClass = FlowField;
            CalcFormula = count("Shopify Refund Entry" where("Shopify Order ID" = field("Shopify Order ID"), Status = const(Success)));
            Editable = false;
        }

        field(50252; "Refund Error Count"; Integer)
        {
            Caption = 'Refund Error Count';
            FieldClass = FlowField;
            CalcFormula = count("Shopify Refund Entry" where("Shopify Order ID" = field("Shopify Order ID"), Status = const(Error)));
            Editable = false;
        }
    }
}
