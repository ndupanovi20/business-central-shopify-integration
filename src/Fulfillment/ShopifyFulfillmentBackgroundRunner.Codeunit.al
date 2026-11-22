codeunit 50246 "Shopify Fulfillment BG Runner"
{
    TableNo = "Shopify Background Run Result";

    trigger OnRun()
    var
        FulfillmentMgt:
            Codeunit "Shopify Fulfillment Mgt.";
    begin
        Rec."Result Count" :=
            FulfillmentMgt.ProcessBackgroundFulfillmentWork(
                false);

        Rec.Modify();
    end;
}
