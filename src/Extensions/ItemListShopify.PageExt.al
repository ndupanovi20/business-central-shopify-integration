pageextension 50141 "Item List Shopify Ext"
    extends "Item List"
{
    actions
    {
        addlast(Processing)
        {
            action(SyncSelectedToShopify)
            {
                ApplicationArea = All;

                Caption = 'Sync Selected to Shopify';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SelectedItems:
                        Record Item;

                    ShopifyBulkSync:
                        Codeunit "Shopify Bulk Sync";
                begin
                    CurrPage.SetSelectionFilter(
                        SelectedItems);

                    ShopifyBulkSync.SyncSelected(
                        SelectedItems);
                end;
            }

            action(SyncAllMappedInventory)
            {
                ApplicationArea = All;

                Caption = 'Sync All Shopify Inventory';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ShopifyBulkSync:
                        Codeunit "Shopify Bulk Sync";
                begin
                    ShopifyBulkSync.SyncMappedInventory(
                        true);
                end;
            }
        }
    }
}