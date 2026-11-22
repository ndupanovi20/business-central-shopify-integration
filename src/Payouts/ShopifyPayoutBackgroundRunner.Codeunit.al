codeunit 50262 "Shopify Payout BG Runner"
{
    TableNo = "Shopify Background Run Result";

    trigger OnRun()
    var
        PayoutMgt: Codeunit "Shopify Payout Mgt.";
    begin
        Rec."Result Count" :=
            PayoutMgt.ProcessBackgroundPayoutWork(
                false);

        Rec.Modify();
    end;
}
