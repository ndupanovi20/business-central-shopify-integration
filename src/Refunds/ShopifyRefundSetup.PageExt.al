pageextension 50276 "Shopify Refund Setup Page"
    extends "Shopify Integration Setup"
{
    layout
    {
        addbefore(Automation)
        {
            group(RefundProcessing)
            {
                Caption = 'Shopify Refund Processing';

                field("Auto Import Shopify Refunds"; Rec."Auto Import Shopify Refunds")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether refunds for already imported Shopify orders are fetched automatically.';
                }

                field("Auto Process Shopify Refunds"; Rec."Auto Process Shopify Refunds")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether supported Shopify refunds are converted to posted Business Central sales credit memos and customer refund entries automatically.';
                }

                field("Import Refunds From"; Rec."Import Refunds From")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date and time from which Shopify refunds are allowed to be imported.';
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(SetRefundCutoffNow)
            {
                ApplicationArea = All;
                Caption = 'Set Refund Cutoff to Now';

                trigger OnAction()
                begin
                    Rec."Import Refunds From" := CurrentDateTime();
                    Rec.Modify(true);
                    Message('Shopify refund import cutoff was set to the current date and time.');
                end;
            }

            action(ImportShopifyRefunds)
            {
                ApplicationArea = All;
                Caption = 'Import Shopify Refunds';

                trigger OnAction()
                var
                    RefundMgt: Codeunit "Shopify Refund Mgt.";
                begin
                    CurrPage.SaveRecord();
                    RefundMgt.ImportRefundsForImportedOrders(true);
                end;
            }

            action(ProcessShopifyRefunds)
            {
                ApplicationArea = All;
                Caption = 'Process Pending Shopify Refunds';

                trigger OnAction()
                var
                    RefundMgt: Codeunit "Shopify Refund Mgt.";
                begin
                    CurrPage.SaveRecord();
                    RefundMgt.ProcessPendingRefunds(true);
                end;
            }

            action(OpenShopifyRefundEntries)
            {
                ApplicationArea = All;
                Caption = 'Shopify Refund Entries';

                trigger OnAction()
                begin
                    Page.Run(Page::"Shopify Refund Entries");
                end;
            }

            action(OpenOrderLineMappings)
            {
                ApplicationArea = All;
                Caption = 'Shopify Order Line Mappings';

                trigger OnAction()
                begin
                    Page.Run(Page::"Shopify Order Line Mappings");
                end;
            }
        }
    }
}
