page 50101 "Shopify Integration Setup"
{
    PageType = Card;
    SourceTable = "Shopify Integration Setup";

    Caption = 'Shopify Integration Setup';
    ApplicationArea = All;
    UsageCategory = Administration;

    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Connection)
            {
                Caption = 'Connection';

                field("Shop Domain"; Rec."Shop Domain")
                {
                    ApplicationArea = All;
                }

                field("Client ID"; Rec."Client ID")
                {
                    ApplicationArea = All;
                }

                field("API Version"; Rec."API Version")
                {
                    ApplicationArea = All;
                }

                field(ClientSecretInput; ClientSecretInput)
                {
                    ApplicationArea = All;
                    Caption = 'Client Secret';
                    ExtendedDatatype = Masked;
                }

                field(SecretConfigured; SecretConfigured)
                {
                    ApplicationArea = All;
                    Caption = 'Client Secret Configured';
                    Editable = false;
                }
            }

            group(Mapping)
            {
                Caption = 'Mapping';

                field("Shopify Location ID"; Rec."Shopify Location ID")
                {
                    ApplicationArea = All;
                }

                field("BC Location Code"; Rec."BC Location Code")
                {
                    ApplicationArea = All;
                }

                field("BC Customer No."; Rec."BC Customer No.")
                {
                    ApplicationArea = All;
                }

                field("BC Shipping Item No."; Rec."BC Shipping Item No.")
                {
                    ApplicationArea = All;
                }
            }

            group(OrderSettings)
            {
                Caption = 'Order Settings';

                field("Import Only Paid Orders"; Rec."Import Only Paid Orders")
                {
                    ApplicationArea = All;
                }

                field("Import Orders From"; Rec."Import Orders From")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies the date and time from which Shopify orders are allowed to be imported. Older orders are ignored.';
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

                    ToolTip =
                        'Specifies the number of minutes between automatic Shopify synchronization runs.';
                }

                field("Last Background Sync"; Rec."Last Background Sync")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Last Background Result"; Rec."Last Background Result")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SaveClientSecret)
            {
                ApplicationArea = All;
                Caption = 'Save Client Secret';

                trigger OnAction()
                var
                    ShopifySetupMgt:
                        Codeunit "Shopify Setup Mgt.";
                begin
                    if ClientSecretInput = '' then
                        Error(
                            'Enter the Client Secret first.');

                    ShopifySetupMgt.SetClientSecret(
                        ClientSecretInput);

                    Clear(
                        ClientSecretInput);

                    SecretConfigured :=
                        true;

                    Message(
                        'Client Secret has been saved securely.');
                end;
            }

            action(TestAuthentication)
            {
                ApplicationArea = All;
                Caption = 'Test Authentication';

                trigger OnAction()
                var
                    ShopifyAuth:
                        Codeunit "Shopify Auth";
                begin
                    Rec.TestField(
                        "Shop Domain");

                    Rec.TestField(
                        "Client ID");

                    if ShopifyAuth.TestAuthentication() then
                        Message(
                            'Shopify authentication was successful.');
                end;
            }

            action(TestShopifyConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Shopify Connection';

                trigger OnAction()
                var
                    ShopifyClient:
                        Codeunit "Shopify Client";

                    ShopName: Text;
                begin
                    ShopName :=
                        ShopifyClient.GetShopName();

                    Message(
                        'Shopify connection successful. Shop: %1',
                        ShopName);
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
                    ShopifyDiagnostics:
                        Codeunit "Shopify Diagnostics";
                begin
                    CurrPage.SaveRecord();

                    ShopifyDiagnostics.RunDiagnostics();
                end;
            }

            action(ImportShopifyOrders)
            {
                ApplicationArea = All;
                Caption = 'Import Shopify Orders';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ShopifyOrderSync:
                        Codeunit "Shopify Order Sync";

                    ImportedCount: Integer;
                begin
                    CurrPage.SaveRecord();

                    ImportedCount :=
                        ShopifyOrderSync.ImportLatestOrders();

                    Message(
                        '%1 Shopify order(s) imported successfully.',
                        ImportedCount);
                end;
            }

            action(SyncMappedInventory)
            {
                ApplicationArea = All;
                Caption = 'Sync All Mapped Inventory';

                trigger OnAction()
                var
                    ShopifyBulkSync:
                        Codeunit "Shopify Bulk Sync";
                begin
                    ShopifyBulkSync.SyncMappedInventory(
                        true);
                end;
            }

            action(OpenProductMappings)
            {
                ApplicationArea = All;
                Caption = 'Product Mappings';

                RunObject =
                    page "Shopify Product Mappings";
            }

            action(OpenImportedOrders)
            {
                ApplicationArea = All;
                Caption = 'Imported Shopify Orders';

                RunObject =
                    page "Shopify Order Imports";
            }

            action(OpenSyncLog)
            {
                ApplicationArea = All;
                Caption = 'Shopify Sync Log';

                RunObject =
                    page "Shopify Sync Log";
            }

            action(OpenJobQueueEntries)
            {
                ApplicationArea = All;
                Caption = 'Job Queue Entries';

                RunObject =
                    page "Job Queue Entries";
            }
        }
    }

    trigger OnOpenPage()
    var
        ShopifySetupMgt:
            Codeunit "Shopify Setup Mgt.";
    begin
        if not Rec.Get('SETUP') then begin
            Rec.Init();

            Rec."Primary Key" :=
                'SETUP';

            Rec."API Version" :=
                '2026-07';

            Rec."Background Sync Interval" :=
                15;

            Rec.Insert();
        end else
            if Rec."Background Sync Interval" <= 0 then begin
                Rec."Background Sync Interval" :=
                    15;

                Rec.Modify(false);
            end;

        SecretConfigured :=
            ShopifySetupMgt.HasClientSecret();
    end;

    var
        ClientSecretInput: Text[215];
        SecretConfigured: Boolean;
}