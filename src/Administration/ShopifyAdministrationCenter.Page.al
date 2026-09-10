page 50198 "Shopify Administration Center"
{
    PageType = Card;
    SourceTable = "Shopify Integration Setup";

    Caption = 'Shopify Administration Center';
    ApplicationArea = All;
    UsageCategory = Administration;

    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Environment)
            {
                Caption = 'Environment';

                field(CurrentCompany; CurrentCompany)
                {
                    ApplicationArea = All;
                    Caption = 'Company';
                }

                field("Shop Domain"; Rec."Shop Domain")
                {
                    ApplicationArea = All;
                }

                field("API Version"; Rec."API Version")
                {
                    ApplicationArea = All;
                }

                field("BC Customer No."; Rec."BC Customer No.")
                {
                    ApplicationArea = All;
                }

                field("BC Location Code"; Rec."BC Location Code")
                {
                    ApplicationArea = All;
                }

                field("BC Shipping Item No."; Rec."BC Shipping Item No.")
                {
                    ApplicationArea = All;
                }
            }

            group(RuntimeState)
            {
                Caption = 'Integration Runtime';

                field(MappedProductCount; MappedProductCount)
                {
                    ApplicationArea = All;
                    Caption = 'Mapped Products';
                }

                field(BufferCount; BufferCount)
                {
                    ApplicationArea = All;
                    Caption = 'Order Buffer Records';
                }

                field(ImportedOrderCount; ImportedOrderCount)
                {
                    ApplicationArea = All;
                    Caption = 'Imported Order Registry';
                }

                field(DemoSalesOrderCount; DemoSalesOrderCount)
                {
                    ApplicationArea = All;
                    Caption = 'BC Shopify Sales Orders';
                }

                field(SyncLogCount; SyncLogCount)
                {
                    ApplicationArea = All;
                    Caption = 'Synchronization Log Entries';
                }

                field(ErrorBufferCount; ErrorBufferCount)
                {
                    ApplicationArea = All;
                    Caption = 'Failed Order Buffers';
                    StyleExpr = ErrorStyle;
                }
            }

            group(OrderImport)
            {
                Caption = 'Order Import';

                field("Import Orders From"; Rec."Import Orders From")
                {
                    ApplicationArea = All;
                }

                field("Import Only Paid Orders"; Rec."Import Only Paid Orders")
                {
                    ApplicationArea = All;
                }
            }

            group(Automation)
            {
                Caption = 'Automation';

                field("Auto Import Orders"; Rec."Auto Import Orders")
                {
                    ApplicationArea = All;
                }

                field("Auto Sync Inventory"; Rec."Auto Sync Inventory")
                {
                    ApplicationArea = All;
                }

                field("Background Sync Interval"; Rec."Background Sync Interval")
                {
                    ApplicationArea = All;
                    Caption = 'Background Interval (Min.)';
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

                field("Last Background Sync"; Rec."Last Background Sync")
                {
                    ApplicationArea = All;
                }

                field("Last Background Result"; Rec."Last Background Result")
                {
                    ApplicationArea = All;
                }
            }

            group(Tagging)
            {
                Caption = 'Shopify Order Tagging';

                field("Tag Imported Orders"; Rec."Tag Imported Orders")
                {
                    ApplicationArea = All;
                }

                field("Imported Order Tag"; Rec."Imported Order Tag")
                {
                    ApplicationArea = All;
                }

                field(TaggedOrderCount; TaggedOrderCount)
                {
                    ApplicationArea = All;
                    Caption = 'Successfully Tagged Orders';
                }

                field(TagErrorCount; TagErrorCount)
                {
                    ApplicationArea = All;
                    Caption = 'Tag Errors';
                    StyleExpr = TagErrorStyle;
                }
            }

            group(DemoReadiness)
            {
                Caption = 'Demo Readiness';

                field(ConnectionConfigured; ConnectionConfigured)
                {
                    ApplicationArea = All;
                    Caption = 'Connection Configured';
                    StyleExpr = ConnectionStyle;
                }

                field(MasterDataConfigured; MasterDataConfigured)
                {
                    ApplicationArea = All;
                    Caption = 'Master Data Configured';
                    StyleExpr = MasterDataStyle;
                }

                field(ProductMappingsReady; ProductMappingsReady)
                {
                    ApplicationArea = All;
                    Caption = 'Product Mappings Ready';
                    StyleExpr = ProductMappingStyle;
                }

                field(CutoffConfigured; CutoffConfigured)
                {
                    ApplicationArea = All;
                    Caption = 'Import Cutoff Configured';
                    StyleExpr = CutoffStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.Get(
                        'SETUP');

                    CalculateState();

                    CurrPage.Update(false);
                end;
            }

            action(RunDiagnostics)
            {
                ApplicationArea = All;
                Caption = 'Run Diagnostics';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Diagnostics:
                        Codeunit "Shopify Diagnostics";
                begin
                    Diagnostics.RunDiagnostics();

                    CalculateState();

                    CurrPage.Update(false);
                end;
            }

            action(RunSyncNow)
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

                    CalculateState();

                    CurrPage.Update(false);
                end;
            }

            action(SetCutoffNow)
            {
                ApplicationArea = All;
                Caption = 'Set Import Cutoff to Now';

                trigger OnAction()
                var
                    AdminMgt:
                        Codeunit "Shopify Admin Mgt.";
                begin
                    AdminMgt.SetImportCutoffToNow();

                    Rec.Get(
                        'SETUP');

                    CalculateState();

                    CurrPage.Update(false);

                    Message(
                        'Shopify order import cutoff was set to the current date and time.');
                end;
            }

            action(ClearRuntimeHistory)
            {
                ApplicationArea = All;
                Caption = 'Clear Runtime History';

                trigger OnAction()
                var
                    AdminMgt:
                        Codeunit "Shopify Admin Mgt.";
                begin
                    if not Confirm(
                        'Clear Shopify Order Buffer, Imported Order Registry and Shopify Sync Log? The import cutoff will be moved to the current time. Products, mappings, inventory and setup will remain unchanged.',
                        false)
                    then
                        exit;

                    AdminMgt.ClearRuntimeHistory();

                    Rec.Get(
                        'SETUP');

                    CalculateState();

                    CurrPage.Update(false);

                    Message(
                        'Shopify integration runtime history was cleared successfully.');
                end;
            }

            action(DeleteOpenDemoOrders)
            {
                ApplicationArea = All;
                Caption = 'Delete Open Demo Sales Orders';

                trigger OnAction()
                var
                    AdminMgt:
                        Codeunit "Shopify Admin Mgt.";

                    DeletedCount: Integer;
                begin
                    if not Confirm(
                        'Delete all OPEN Business Central Sales Orders created for the configured Shopify customer? Posted documents are not affected.',
                        false)
                    then
                        exit;

                    DeletedCount :=
                        AdminMgt.DeleteOpenDemoSalesOrders();

                    CalculateState();

                    CurrPage.Update(false);

                    Message(
                        '%1 open Shopify demo Sales Order(s) deleted.',
                        DeletedCount);
                end;
            }

            action(PrepareFreshDemo)
            {
                ApplicationArea = All;
                Caption = 'Prepare Fresh Demo Session';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    AdminMgt:
                        Codeunit "Shopify Admin Mgt.";

                    DeletedSalesOrders: Integer;
                begin
                    if not Confirm(
                        'Prepare a fresh demonstration session?\This will delete OPEN Shopify demo Sales Orders and clear Order Buffer, Order Import Registry and Sync Log. Product mappings, products, inventory, Shopify connection and configuration will remain unchanged. The import cutoff will be moved to now.',
                        false)
                    then
                        exit;

                    AdminMgt.PrepareFreshDemoSession(
                        DeletedSalesOrders);

                    Rec.Get(
                        'SETUP');

                    CalculateState();

                    CurrPage.Update(false);

                    Message(
                        'Fresh demo session prepared successfully.\Deleted BC Sales Orders: %1\Import cutoff: %2',
                        DeletedSalesOrders,
                        Rec."Import Orders From");
                end;
            }

            action(OpenIntegrationSetup)
            {
                ApplicationArea = All;
                Caption = 'Integration Setup';

                RunObject =
                    page "Shopify Integration Setup";
            }

            action(OpenIntegrationStatus)
            {
                ApplicationArea = All;
                Caption = 'Integration Status';

                RunObject =
                    page "Shopify Integration Status";
            }

            action(OpenProductMappings)
            {
                ApplicationArea = All;
                Caption = 'Product Mappings';

                RunObject =
                    page "Shopify Product Mappings";
            }

            action(OpenOrderBuffer)
            {
                ApplicationArea = All;
                Caption = 'Order Buffer';

                RunObject =
                    page "Shopify Order Buffer";
            }

            action(OpenOrderImports)
            {
                ApplicationArea = All;
                Caption = 'Order Imports';

                RunObject =
                    page "Shopify Order Imports";
            }

            action(OpenSyncLog)
            {
                ApplicationArea = All;
                Caption = 'Sync Log';

                RunObject =
                    page "Shopify Sync Log";
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

        CalculateState();
    end;

    local procedure CalculateState()
    var
        AdminMgt:
            Codeunit "Shopify Admin Mgt.";

        SetupMgt:
            Codeunit "Shopify Setup Mgt.";

        JobQueueMgt:
            Codeunit "Shopify Job Queue Mgt.";

        Mapping:
            Record "Shopify Product Mapping";

        ImportRecord:
            Record "Shopify Order Import";

        Customer:
            Record Customer;

        Location:
            Record Location;

        ShippingItem:
            Record Item;

        JobInterval: Integer;

        JobError: Text;
    begin
        CurrentCompany :=
            CompanyName();

        AdminMgt.GetRuntimeCounts(
            BufferCount,
            ImportedOrderCount,
            SyncLogCount,
            DemoSalesOrderCount,
            ErrorBufferCount);

        MappedProductCount :=
            Mapping.Count();

        Clear(
            TaggedOrderCount);

        Clear(
            TagErrorCount);

        ImportRecord.SetRange(
            "Tag Status",
            ImportRecord."Tag Status"::Success);

        TaggedOrderCount :=
            ImportRecord.Count();

        ImportRecord.Reset();

        ImportRecord.SetRange(
            "Tag Status",
            ImportRecord."Tag Status"::Error);

        TagErrorCount :=
            ImportRecord.Count();

        JobQueueMgt.GetJobInfo(
            JobQueueStatus,
            JobQueueNextRun,
            JobInterval,
            JobError);

        ConnectionConfigured :=
            (Rec."Shop Domain" <> '') and
            (Rec."Client ID" <> '') and
            (Rec."API Version" <> '') and
            SetupMgt.HasClientSecret();

        MasterDataConfigured :=
            false;

        if Rec."BC Customer No." <> '' then
            if Customer.Get(
                Rec."BC Customer No.")
            then
                if Rec."BC Location Code" <> '' then
                    if Location.Get(
                        Rec."BC Location Code")
                    then
                        if Rec."BC Shipping Item No." <> '' then
                            if ShippingItem.Get(
                                Rec."BC Shipping Item No.")
                            then
                                MasterDataConfigured :=
                                    true;

        ProductMappingsReady :=
            MappedProductCount > 0;

        CutoffConfigured :=
            Rec."Import Orders From" <> 0DT;

        if ErrorBufferCount > 0 then
            ErrorStyle :=
                'Unfavorable'
        else
            ErrorStyle :=
                'Favorable';

        if TagErrorCount > 0 then
            TagErrorStyle :=
                'Unfavorable'
        else
            TagErrorStyle :=
                'Favorable';

        SetBooleanStyle(
            ConnectionConfigured,
            ConnectionStyle);

        SetBooleanStyle(
            MasterDataConfigured,
            MasterDataStyle);

        SetBooleanStyle(
            ProductMappingsReady,
            ProductMappingStyle);

        SetBooleanStyle(
            CutoffConfigured,
            CutoffStyle);
    end;

    local procedure SetBooleanStyle(
        Value: Boolean;
        var StyleText: Text)
    begin
        if Value then
            StyleText :=
                'Favorable'
        else
            StyleText :=
                'Unfavorable';
    end;

    var
        CurrentCompany: Text;

        MappedProductCount: Integer;
        BufferCount: Integer;
        ImportedOrderCount: Integer;
        DemoSalesOrderCount: Integer;
        SyncLogCount: Integer;
        ErrorBufferCount: Integer;

        TaggedOrderCount: Integer;
        TagErrorCount: Integer;

        JobQueueStatus: Text;
        JobQueueNextRun: DateTime;

        ConnectionConfigured: Boolean;
        MasterDataConfigured: Boolean;
        ProductMappingsReady: Boolean;
        CutoffConfigured: Boolean;

        ErrorStyle: Text;
        TagErrorStyle: Text;

        ConnectionStyle: Text;
        MasterDataStyle: Text;
        ProductMappingStyle: Text;
        CutoffStyle: Text;
}