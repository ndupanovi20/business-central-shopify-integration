codeunit 50229 "Shopify Payment BG Runner"
{
    TableNo = "Shopify Background Run Result";

    trigger OnRun()
    var
        PaymentMgt:
            Codeunit "Shopify Payment Mgt.";
    begin
        Rec."Result Count" :=
            PaymentMgt.ProcessEligiblePayments(
                false);

        Rec.Modify();
    end;
}
