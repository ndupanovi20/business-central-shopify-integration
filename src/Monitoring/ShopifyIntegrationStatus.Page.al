page 50195 "Shopify Integration Status"
{
    PageType = Card;
    SourceTable = "Shopify Integration Setup";

    Caption = 'Shopify Integration Status';
    ApplicationArea = All;
    UsageCategory = Administration;

    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Connection)
            {
                Caption = 'Connection';

                field(ShopDomain; Rec."Shop Domain")
                {
                    ApplicationArea = All;
                    Caption = 'Shop Domain';
                }

                field(APIVersion; Rec."API Version")
                {
                    ApplicationArea = All;
                    Caption = 'API Version';
                }

                field(BCLocation; Rec."BC Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'BC Location';
                }

                field(BCCustomer; Rec."BC Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'BC Customer';
                }
            }

            group(ProductStatistics)
            {
                Caption = 'Products';

                field(MappedProductCount; MappedProductCount)
                {
                    ApplicationArea = All;
                    Caption = 'Mapped Products';
                }

                field(ProductSuccessCount; ProductSuccessCount)
                {
                    ApplicationArea = All;
                    Caption = 'Successful Product Syncs';
                }

                field(ProductErrorCount; ProductErrorCount)
                {
                    ApplicationArea = All;
                    Caption = 'Product Sync Errors';
                    Style = Unfavorable;
                }
            }

            group(OrderStatistics)
            {
                Caption = 'Orders';

                field(ImportOrdersFrom; Rec."Import Orders From")
                {
                    ApplicationArea = All;
                    Caption = 'Import Orders From';
                }

                field(ImportOnlyPaidOrders; Rec."Import Only Paid Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Import Only Paid Orders';
                }

                field(ImportedOrderCount; ImportedOrderCount)
                {
                    ApplicationArea = All;
                    Caption = 'Imported Orders';
                }

                field(PendingOrderCount; PendingOrderCount)
                {
                    ApplicationArea = All;
                    Caption = 'Pending Orders';
                }

                field(ErrorOrderCount; ErrorOrderCount)
                {
                    ApplicationArea = All;
                    Caption = 'Failed Orders';
                    Style = Unfavorable;
                }

                field(SkippedOrderCount; SkippedOrderCount)
                {
                    ApplicationArea = All;
                    Caption = 'Skipped Orders';
                    Style = Attention;
                }

                field(TotalRetryCount; TotalRetryCount)
                {
                    ApplicationArea = All;
                    Caption = 'Total Retry Attempts';
                }
            }

            group(LogStatistics)
            {
                Caption = 'Synchronization Log';

                field(SuccessLogCount; SuccessLogCount)
                {
                    ApplicationArea = All;
                    Caption = 'Successful Operations';
                }

                field(ErrorLogCount; ErrorLogCount)
                {
                    ApplicationArea = All;
                    Caption = 'Errors';
                    Style = Unfavorable;
                }
            }

            group(BackgroundSynchronization)
            {
                Caption = 'Background Synchronization';

                field(AutoImportOrders; Rec."Auto Import Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Auto Import Orders';
                }

                field(AutoSyncInventory; Rec."Auto Sync Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Auto Sync Inventory';
                }

                field(BackgroundInterval; Rec."Background Sync Interval")
                {
                    ApplicationArea = All;
                    Caption = 'Configured Interval (Min.)';
                }

                field(JobQueueStatus; JobQueueStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Job Queue Status';
                }

                field(JobQueueNextRun; JobQueueNextRun)
                {
                    ApplicationArea = All;
                    Caption = 'Next Job Queue Run';
                }

                field(JobQueueInterval; JobQueueInterval)
                {
                    ApplicationArea = All;
                    Caption = 'Job Queue Interval (Min.)';
                }

                field(JobQueueError; JobQueueError)
                {
                    ApplicationArea = All;
                    Caption = 'Job Queue Error';
                    Style = Unfavorable;
                }

                field(LastBackgroundSync; Rec."Last Background Sync")
                {
                    ApplicationArea = All;
                    Caption = 'Last Background Sync';
                }

                field(LastBackgroundResult; Rec."Last Background Result")
                {
                    ApplicationArea = All;
                    Caption = 'Last Background Result';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshStatistics)
            {
                ApplicationArea = All;
                Caption = 'Refresh';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.Get(
                        'SETUP');

                    CalculateStatistics();

                    CurrPage.Update(false);
                end;
            }

            action(RunBackgroundSync)
            {
                ApplicationArea = All;
                Caption = 'Run Synchronization Now';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    BackgroundSync:
                        Codeunit "Shopify Background Sync";
                begin
                    BackgroundSync.RunNow();

                    Rec.Get(
                        'SETUP');

                    CalculateStatistics();

                    CurrPage.Update(false);
                end;
            }

            action(StartBackgroundJob)
            {
                ApplicationArea = All;
                Caption = 'Create / Update Background Job';

                trigger OnAction()
                var
                    JobQueueMgt:
                        Codeunit "Shopify Job Queue Mgt.";
                begin
                    JobQueueMgt.CreateOrUpdateAndStart();

                    CalculateStatistics();

                    CurrPage.Update(false);
                end;
            }

            action(HoldBackgroundJob)
            {
                ApplicationArea = All;
                Caption = 'Put Background Job On Hold';

                trigger OnAction()
                var
                    JobQueueMgt:
                        Codeunit "Shopify Job Queue Mgt.";
                begin
                    JobQueueMgt.PutOnHold();

                    CalculateStatistics();

                    CurrPage.Update(false);
                end;
            }

            action(OpenMappings)
            {
                ApplicationArea = All;
                Caption = 'Product Mappings';

                RunObject =
                    page "Shopify Product Mappings";
            }

            action(OpenImports)
            {
                ApplicationArea = All;
                Caption = 'Order Imports';

                RunObject =
                    page "Shopify Order Imports";
            }

            action(OpenBuffer)
            {
                ApplicationArea = All;
                Caption = 'Order Buffer';

                RunObject =
                    page "Shopify Order Buffer";
            }

            action(OpenSyncLog)
            {
                ApplicationArea = All;
                Caption = 'Sync Log';

                RunObject =
                    page "Shopify Sync Log";
            }

            action(OpenSetup)
            {
                ApplicationArea = All;
                Caption = 'Integration Setup';

                RunObject =
                    page "Shopify Integration Setup";
            }

            action(OpenJobQueue)
            {
                ApplicationArea = All;
                Caption = 'Job Queue Entries';

                RunObject =
                    page "Job Queue Entries";
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist.');

        CalculateStatistics();
    end;

    local procedure CalculateStatistics()
    var
        Mapping:
            Record "Shopify Product Mapping";

        ImportRecord:
            Record "Shopify Order Import";

        Buffer:
            Record "Shopify Order Buffer";

        RetryBuffer:
            Record "Shopify Order Buffer";

        SyncLog:
            Record "Shopify Sync Log";

        JobQueueMgt:
            Codeunit "Shopify Job Queue Mgt.";
    begin
        MappedProductCount :=
            Mapping.Count();

        Mapping.SetRange(
            "Last Sync Status",
            "Shopify Sync Status"::Success);

        ProductSuccessCount :=
            Mapping.Count();

        Mapping.Reset();

        Mapping.SetRange(
            "Last Sync Status",
            "Shopify Sync Status"::Error);

        ProductErrorCount :=
            Mapping.Count();

        ImportedOrderCount :=
            ImportRecord.Count();

        Buffer.SetRange(
            Status,
            Buffer.Status::Pending);

        PendingOrderCount :=
            Buffer.Count();

        Buffer.Reset();

        Buffer.SetRange(
            Status,
            Buffer.Status::Error);

        ErrorOrderCount :=
            Buffer.Count();

        Buffer.Reset();

        Buffer.SetRange(
            Status,
            Buffer.Status::Skipped);

        SkippedOrderCount :=
            Buffer.Count();

        TotalRetryCount :=
            0;

        if RetryBuffer.FindSet() then
            repeat
                TotalRetryCount +=
                    RetryBuffer."Retry Count";
            until RetryBuffer.Next() = 0;

        SyncLog.SetRange(
            Status,
            "Shopify Sync Status"::Success);

        SuccessLogCount :=
            SyncLog.Count();

        SyncLog.Reset();

        SyncLog.SetRange(
            Status,
            "Shopify Sync Status"::Error);

        ErrorLogCount :=
            SyncLog.Count();

        JobQueueMgt.GetJobInfo(
            JobQueueStatus,
            JobQueueNextRun,
            JobQueueInterval,
            JobQueueError);
    end;

    var
        MappedProductCount: Integer;
        ProductSuccessCount: Integer;
        ProductErrorCount: Integer;

        ImportedOrderCount: Integer;
        PendingOrderCount: Integer;
        ErrorOrderCount: Integer;
        SkippedOrderCount: Integer;
        TotalRetryCount: Integer;

        SuccessLogCount: Integer;
        ErrorLogCount: Integer;

        JobQueueStatus: Text;
        JobQueueNextRun: DateTime;
        JobQueueInterval: Integer;
        JobQueueError: Text;
}