codeunit 50181 "Shopify Product Sync Runner"
{
    TableNo = Item;

    trigger OnRun()
    var
        ShopifyProductSync:
            Codeunit "Shopify Product Sync";
    begin
        ShopifyProductSync.ExecuteFullSync(
            Rec);
    end;
}