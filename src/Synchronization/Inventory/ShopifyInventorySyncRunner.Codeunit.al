codeunit 50182 "Shopify Inventory Sync Runner"
{
    TableNo = Item;

    trigger OnRun()
    var
        ShopifyProductSync:
            Codeunit "Shopify Product Sync";
    begin
        ShopifyProductSync.ExecuteInventorySync(
            Rec);
    end;
}