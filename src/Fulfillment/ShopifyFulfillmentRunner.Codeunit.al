codeunit 50253 "Shopify Fulfillment Runner"
{
    TableNo = "Shopify Fulfillment Entry";

    trigger OnRun()
    var
        FulfillmentMgt:
            Codeunit "Shopify Fulfillment Mgt.";
    begin
        FulfillmentMgt.CreateFulfillmentCore(
            Rec);
    end;
}
