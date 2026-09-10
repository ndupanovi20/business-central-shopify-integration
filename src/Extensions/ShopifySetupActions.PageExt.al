pageextension 50142 "Shopify Setup Actions Ext"
    extends "Shopify Integration Setup"
{
    actions
    {
        addlast(Processing)
        {
            action(InitializeDemoCompany)
            {
                ApplicationArea = All;
                Caption = 'Initialize Demo Company';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    DemoSetup:
                        Codeunit "Shopify Demo Setup";
                begin
                    CurrPage.SaveRecord();

                    DemoSetup.InitializeDemoCompany();

                    Rec.Get(
                        'SETUP');

                    CurrPage.Update(false);
                end;
            }

            action(PrepareDemoProducts)
            {
                ApplicationArea = All;
                Caption = 'Prepare Demo Products';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    DemoDataMgt:
                        Codeunit "Shopify Demo Data Mgt.";
                begin
                    DemoDataMgt.PrepareDemoProducts();
                end;
            }

            action(InitializeDemoInventory)
            {
                ApplicationArea = All;
                Caption = 'Initialize Demo Inventory';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    DemoDataMgt:
                        Codeunit "Shopify Demo Data Mgt.";
                begin
                    DemoDataMgt.InitializeDemoInventory();
                end;
            }

            action(SyncDemoProducts)
            {
                ApplicationArea = All;
                Caption = 'Sync Demo Products';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ShopifyBulkSync:
                        Codeunit "Shopify Bulk Sync";
                begin
                    ShopifyBulkSync.SyncDemoProducts(
                        true);
                end;
            }

            action(OpenDemoProducts)
            {
                ApplicationArea = All;
                Caption = 'Open Demo Products';

                trigger OnAction()
                var
                    DemoItem:
                        Record Item;
                begin
                    DemoItem.SetFilter(
                        "No.",
                        'BC-SHOP-*');

                    Page.Run(
                        Page::"Item List",
                        DemoItem);
                end;
            }

            action(SetImportCutoffNow)
            {
                ApplicationArea = All;
                Caption = 'Set Import Cutoff to Now';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();

                    Rec."Import Orders From" :=
                        CurrentDateTime();

                    Rec.Modify(true);

                    CurrPage.Update(false);

                    Message(
                        'Shopify order import cutoff was set to %1. Orders created before this time will be ignored.',
                        Rec."Import Orders From");
                end;
            }

            action(CreateUpdateBackgroundJob)
            {
                ApplicationArea = All;
                Caption = 'Create / Update Background Job';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    JobQueueMgt:
                        Codeunit "Shopify Job Queue Mgt.";
                begin
                    CurrPage.SaveRecord();

                    JobQueueMgt.CreateOrUpdateAndStart();

                    CurrPage.Update(false);
                end;
            }

            action(PutBackgroundJobOnHold)
            {
                ApplicationArea = All;
                Caption = 'Put Background Job On Hold';

                trigger OnAction()
                var
                    JobQueueMgt:
                        Codeunit "Shopify Job Queue Mgt.";
                begin
                    JobQueueMgt.PutOnHold();
                end;
            }

            action(DeleteBackgroundJob)
            {
                ApplicationArea = All;
                Caption = 'Delete Background Job';

                trigger OnAction()
                var
                    JobQueueMgt:
                        Codeunit "Shopify Job Queue Mgt.";
                begin
                    JobQueueMgt.DeleteBackgroundJob();
                end;
            }

            action(OpenBackgroundJob)
            {
                ApplicationArea = All;
                Caption = 'Open Background Job';

                trigger OnAction()
                var
                    JobQueueMgt:
                        Codeunit "Shopify Job Queue Mgt.";
                begin
                    JobQueueMgt.OpenBackgroundJob();
                end;
            }

            action(OpenIntegrationStatus)
            {
                ApplicationArea = All;
                Caption = 'Integration Status';

                Promoted = true;
                PromotedCategory = Process;

                RunObject =
                    page "Shopify Integration Status";
            }

            action(OpenOrderBuffer)
            {
                ApplicationArea = All;
                Caption = 'Order Buffer';

                RunObject =
                    page "Shopify Order Buffer";
            }

            action(RunBackgroundSyncNow)
            {
                ApplicationArea = All;
                Caption = 'Run Sync Now';

                trigger OnAction()
                var
                    BackgroundSync:
                        Codeunit "Shopify Background Sync";
                begin
                    CurrPage.SaveRecord();

                    BackgroundSync.RunNow();

                    Rec.Get(
                        'SETUP');

                    CurrPage.Update(false);
                end;
            }
        }
    }
}