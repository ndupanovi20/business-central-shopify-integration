codeunit 50205 "Shopify Order BG Runner"
{
    TableNo = "Shopify Background Run Result";

    trigger OnRun()
    var
        ShopifyOrderSync:
            Codeunit "Shopify Order Sync";

        ImportedCount: Integer;
    begin
        ImportedCount :=
            ShopifyOrderSync.ImportLatestOrders();

        Rec."Result Count" :=
            ImportedCount;

        Rec.Modify();
    end;
}