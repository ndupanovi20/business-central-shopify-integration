codeunit 50279 "Shopify Refund BG Runner"
{
    TableNo = "Shopify Background Run Result";

    trigger OnRun()
    var
        RefundMgt: Codeunit "Shopify Refund Mgt.";
    begin
        Rec."Result Count" := RefundMgt.ProcessBackgroundRefundWork(false);
        Rec.Modify();
    end;
}
