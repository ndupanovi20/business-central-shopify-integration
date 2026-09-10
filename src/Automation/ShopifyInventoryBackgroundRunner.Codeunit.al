codeunit 50206 "Shopify Inventory BG Runner"
{
    TableNo = "Shopify Background Run Result";

    trigger OnRun()
    var
        ShopifyBulkSync:
            Codeunit "Shopify Bulk Sync";

        SyncedCount: Integer;
    begin
        SyncedCount :=
            ShopifyBulkSync.SyncMappedInventory(
                false);

        Rec."Result Count" :=
            SyncedCount;

        Rec.Modify();
    end;
}