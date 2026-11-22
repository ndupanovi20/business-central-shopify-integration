codeunit 50278 "Shopify Refund Runner"
{
    TableNo = "Shopify Refund Entry";

    trigger OnRun()
    var
        RefundMgt: Codeunit "Shopify Refund Mgt.";
    begin
        RefundMgt.ProcessRefundCore(Rec);
    end;
}
