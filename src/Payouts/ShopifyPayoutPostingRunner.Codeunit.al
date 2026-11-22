codeunit 50261 "Shopify Payout Posting Runner"
{
    TableNo = "Shopify Payout Entry";

    trigger OnRun()
    var
        PayoutMgt: Codeunit "Shopify Payout Mgt.";
    begin
        PayoutMgt.PostPayoutCore(
            Rec);
    end;
}
