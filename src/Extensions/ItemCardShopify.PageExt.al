pageextension 50140 "Item Card Shopify Ext"
    extends "Item Card"
{
    actions
    {
        addlast(Processing)
        {
            action(SyncToShopify)
            {
                ApplicationArea = All;

                Caption = 'Sync to Shopify';

                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    ShopifyProductSync:
                        Codeunit "Shopify Product Sync";
                begin
                    CurrPage.SaveRecord();

                    ShopifyProductSync.SyncItem(
                        Rec);
                end;
            }

            action(SyncInventoryToShopify)
            {
                ApplicationArea = All;

                Caption = 'Sync Shopify Inventory';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ShopifyProductSync:
                        Codeunit "Shopify Product Sync";
                begin
                    CurrPage.SaveRecord();

                    ShopifyProductSync.SyncInventoryOnly(
                        Rec);
                end;
            }

            action(OpenShopifyMapping)
            {
                ApplicationArea = All;

                Caption = 'Shopify Mapping';

                trigger OnAction()
                var
                    Mapping:
                        Record "Shopify Product Mapping";
                begin
                    Mapping.SetRange(
                        "Item No.",
                        Rec."No.");

                    Page.Run(
                        Page::"Shopify Product Mappings",
                        Mapping);
                end;
            }

            action(OpenShopifyItemLogs)
            {
                ApplicationArea = All;

                Caption = 'Shopify Sync Log';

                trigger OnAction()
                var
                    SyncLog:
                        Record "Shopify Sync Log";
                begin
                    SyncLog.SetRange(
                        "BC Key",
                        Rec."No.");

                    Page.Run(
                        Page::"Shopify Sync Log",
                        SyncLog);
                end;
            }
        }
    }
}