codeunit 50183 "Shopify Order Import Runner"
{
    TableNo = "Shopify Order Buffer";

    trigger OnRun()
    var
        ShopifyOrderSync:
            Codeunit "Shopify Order Sync";
    begin
        ShopifyOrderSync.ProcessBufferedOrder(
            Rec);
    end;
}