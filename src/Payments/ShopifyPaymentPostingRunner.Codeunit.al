codeunit 50228 "Shopify Payment Posting Runner"
{
    TableNo = "Shopify Payment Entry";

    trigger OnRun()
    var
        PaymentMgt:
            Codeunit "Shopify Payment Mgt.";
    begin
        PaymentMgt.RecordPaymentCore(
            Rec);
    end;
}
