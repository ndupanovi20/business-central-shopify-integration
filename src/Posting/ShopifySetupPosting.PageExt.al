pageextension 50215 "Shopify Setup Posting Page"
    extends "Shopify Integration Setup"
{
    layout
    {
        addafter(OrderSettings)
        {
            group(Posting)
            {
                Caption = 'Sales Order Posting';

                field("Auto Post Imported Orders"; Rec."Auto Post Imported Orders")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether successfully imported Shopify Sales Orders should be posted automatically.';
                }

                field("Posting Mode"; Rec."Posting Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Shopify Sales Orders are posted as shipment, invoice, or shipment and invoice.';
                }

                field("Posting Date Source"; Rec."Posting Date Source")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether posting uses the Business Central work date or the Shopify order creation date.';
                }
            }
        }
    }
    actions
    {
        addlast(Processing)
        {
            action(ImportAndPostOrders)
            {
                ApplicationArea = All;
                Caption = 'Import and Post Shopify Orders';

                trigger OnAction()
                var
                    ShopifyOrderSync: Codeunit "Shopify Order Sync";
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                    ImportedCount: Integer;
                    PostedCount: Integer;
                begin
                    CurrPage.SaveRecord();

                    ImportedCount :=
                        ShopifyOrderSync.ImportLatestOrders();

                    PostedCount :=
                        PostingMgt.ProcessPendingAutoPostings(false);

                    Message(
                        'Shopify import and posting completed.\Imported orders: %1\Posted orders: %2',
                        ImportedCount,
                        PostedCount);
                end;
            }

            action(PostAllPendingOrders)
            {
                ApplicationArea = All;
                Caption = 'Post All Pending Orders';

                trigger OnAction()
                var
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.ProcessPendingAutoPostings(true);
                end;
            }
        }
    }

}
