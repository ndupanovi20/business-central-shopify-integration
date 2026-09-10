codeunit 50190 "Shopify Background Sync"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        ExecuteSynchronization();
    end;

    procedure RunNow()
    begin
        ExecuteSynchronization();

        if GuiAllowed() then
            Message(
                'Shopify background synchronization completed.');
    end;

    local procedure ExecuteSynchronization()
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        OrderRunResult:
            Record "Shopify Background Run Result" temporary;

        InventoryRunResult:
            Record "Shopify Background Run Result" temporary;

        OrderRunner:
            Codeunit "Shopify Order BG Runner";

        InventoryRunner:
            Codeunit "Shopify Inventory BG Runner";

        SyncLogMgt:
            Codeunit "Shopify Sync Log Mgt.";

        StartedAt: DateTime;

        ImportedOrders: Integer;
        SyncedInventory: Integer;

        ResultText: Text;
        OrderErrorText: Text;
        InventoryErrorText: Text;

        HasErrors: Boolean;
    begin
        StartedAt :=
            CurrentDateTime();

        if not ShopifySetup.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist.');

        if not ShopifySetup."Auto Import Orders" and
           not ShopifySetup."Auto Sync Inventory"
        then begin
            ResultText :=
                'No automatic Shopify synchronization options are enabled.';

            UpdateSetupResult(
                ShopifySetup,
                ResultText);

            SyncLogMgt.LogInfo(
                "Shopify Sync Direction"::System,
                "Shopify Sync Entity"::Background,
                '',
                '',
                ResultText);

            exit;
        end;

        if ShopifySetup."Auto Import Orders" then begin
            PrepareRunResult(
                OrderRunResult);

            // Codeunit.Run with Boolean return value starts
            // an isolated execution scope.
            // Any current transaction must be completed first.
            Commit();

            ClearLastError();

            if OrderRunner.Run(
                OrderRunResult)
            then begin
                OrderRunResult.Get(1);

                ImportedOrders :=
                    OrderRunResult."Result Count";

                ResultText :=
                    StrSubstNo(
                        'Orders imported: %1.',
                        ImportedOrders);
            end else begin
                OrderErrorText :=
                    GetLastErrorText();

                if OrderErrorText = '' then
                    OrderErrorText :=
                        'Unknown Shopify order import error.';

                ResultText :=
                    StrSubstNo(
                        'Order import failed: %1',
                        OrderErrorText);

                HasErrors :=
                    true;

                SyncLogMgt.LogError(
                    "Shopify Sync Direction"::Inbound,
                    "Shopify Sync Entity"::Order,
                    '',
                    '',
                    OrderErrorText,
                    CurrentDateTime() - StartedAt);
            end;
        end;

        if ShopifySetup."Auto Sync Inventory" then begin
            PrepareRunResult(
                InventoryRunResult);

            Commit();

            ClearLastError();

            if InventoryRunner.Run(
                InventoryRunResult)
            then begin
                InventoryRunResult.Get(1);

                SyncedInventory :=
                    InventoryRunResult."Result Count";

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Inventory synchronized: %1.',
                        SyncedInventory);
            end else begin
                InventoryErrorText :=
                    GetLastErrorText();

                if InventoryErrorText = '' then
                    InventoryErrorText :=
                        'Unknown Shopify inventory synchronization error.';

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Inventory synchronization failed: %1',
                        InventoryErrorText);

                HasErrors :=
                    true;

                SyncLogMgt.LogError(
                    "Shopify Sync Direction"::Outbound,
                    "Shopify Sync Entity"::Inventory,
                    '',
                    '',
                    InventoryErrorText,
                    CurrentDateTime() - StartedAt);
            end;
        end;

        UpdateSetupResult(
            ShopifySetup,
            ResultText);

        if HasErrors then
            SyncLogMgt.LogError(
                "Shopify Sync Direction"::System,
                "Shopify Sync Entity"::Background,
                '',
                '',
                ResultText,
                CurrentDateTime() - StartedAt)
        else
            SyncLogMgt.LogSuccess(
                "Shopify Sync Direction"::System,
                "Shopify Sync Entity"::Background,
                '',
                '',
                ResultText,
                CurrentDateTime() - StartedAt);
    end;

    local procedure PrepareRunResult(
        var RunResult:
            Record "Shopify Background Run Result" temporary)
    begin
        RunResult.Reset();

        RunResult.DeleteAll();

        RunResult.Init();

        RunResult."Entry No." :=
            1;

        RunResult."Result Count" :=
            0;

        RunResult.Insert();
    end;

    local procedure UpdateSetupResult(
        var ShopifySetup:
            Record "Shopify Integration Setup";
        ResultText: Text)
    begin
        // Reload because the isolated runner used its own
        // transaction and may have updated integration data.
        ShopifySetup.Get(
            'SETUP');

        ShopifySetup."Last Background Sync" :=
            CurrentDateTime();

        ShopifySetup."Last Background Result" :=
            CopyStr(
                ResultText,
                1,
                MaxStrLen(
                    ShopifySetup."Last Background Result"));

        ShopifySetup.Modify(true);
    end;
}