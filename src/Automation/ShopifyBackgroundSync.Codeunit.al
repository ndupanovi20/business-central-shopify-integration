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

        PostingRunResult:
            Record "Shopify Background Run Result" temporary;

        FulfillmentRunResult:
            Record "Shopify Background Run Result" temporary;

        PaymentRunResult:
            Record "Shopify Background Run Result" temporary;

        RefundRunResult:
            Record "Shopify Background Run Result" temporary;

        PayoutRunResult:
            Record "Shopify Background Run Result" temporary;

        OrderRunner:
            Codeunit "Shopify Order BG Runner";

        InventoryRunner:
            Codeunit "Shopify Inventory BG Runner";

        PostingRunner:
            Codeunit "Shopify Posting BG Runner";

        FulfillmentRunner:
            Codeunit "Shopify Fulfillment BG Runner";

        PaymentRunner:
            Codeunit "Shopify Payment BG Runner";

        RefundRunner:
            Codeunit "Shopify Refund BG Runner";

        PayoutRunner:
            Codeunit "Shopify Payout BG Runner";

        SyncLogMgt:
            Codeunit "Shopify Sync Log Mgt.";

        StartedAt: DateTime;

        ImportedOrders: Integer;
        SyncedInventory: Integer;
        PostedOrders: Integer;
        FulfillmentActions: Integer;
        RecordedPayments: Integer;
        RefundActions: Integer;
        PayoutActions: Integer;

        ResultText: Text;
        OrderErrorText: Text;
        InventoryErrorText: Text;
        PostingErrorText: Text;
        FulfillmentErrorText: Text;
        PaymentErrorText: Text;
        RefundErrorText: Text;
        PayoutErrorText: Text;

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
           not ShopifySetup."Auto Sync Inventory" and
           not ShopifySetup."Auto Post Imported Orders" and
           not ShopifySetup."Auto Create Fulfillment" and
           not ShopifySetup."Auto Sync Fulfillment Tracking" and
           not ShopifySetup."Auto Record Shopify Payments" and
           not ShopifySetup."Auto Import Shopify Refunds" and
           not ShopifySetup."Auto Process Shopify Refunds" and
           not ShopifySetup."Auto Import Shopify Payouts" and
           not ShopifySetup."Auto Post Paid Payouts"
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

        if ShopifySetup."Auto Post Imported Orders" then begin
            PrepareRunResult(
                PostingRunResult);

            Commit();

            ClearLastError();

            if PostingRunner.Run(
                PostingRunResult)
            then begin
                PostingRunResult.Get(1);

                PostedOrders :=
                    PostingRunResult."Result Count";

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Orders posted: %1.',
                        PostedOrders);
            end else begin
                PostingErrorText :=
                    GetLastErrorText();

                if PostingErrorText = '' then
                    PostingErrorText :=
                        'Unknown Business Central sales posting error.';

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Sales posting failed: %1',
                        PostingErrorText);

                HasErrors :=
                    true;

                SyncLogMgt.LogError(
                    "Shopify Sync Direction"::System,
                    "Shopify Sync Entity"::Posting,
                    '',
                    '',
                    PostingErrorText,
                    CurrentDateTime() - StartedAt);
            end;
        end;

        if ShopifySetup."Auto Create Fulfillment" or
           ShopifySetup."Auto Sync Fulfillment Tracking"
        then begin
            PrepareRunResult(
                FulfillmentRunResult);

            Commit();

            ClearLastError();

            if FulfillmentRunner.Run(
                FulfillmentRunResult)
            then begin
                FulfillmentRunResult.Get(1);

                FulfillmentActions :=
                    FulfillmentRunResult."Result Count";

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Fulfillment actions completed: %1.',
                        FulfillmentActions);
            end else begin
                FulfillmentErrorText :=
                    GetLastErrorText();

                if FulfillmentErrorText = '' then
                    FulfillmentErrorText :=
                        'Unknown Shopify fulfillment synchronization error.';

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Fulfillment synchronization failed: %1',
                        FulfillmentErrorText);

                HasErrors :=
                    true;

                SyncLogMgt.LogError(
                    "Shopify Sync Direction"::Outbound,
                    "Shopify Sync Entity"::Fulfillment,
                    '',
                    '',
                    FulfillmentErrorText,
                    CurrentDateTime() - StartedAt);
            end;
        end;

        if ShopifySetup."Auto Record Shopify Payments" then begin
            PrepareRunResult(
                PaymentRunResult);

            Commit();

            ClearLastError();

            if PaymentRunner.Run(
                PaymentRunResult)
            then begin
                PaymentRunResult.Get(1);

                RecordedPayments :=
                    PaymentRunResult."Result Count";

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Payments recorded: %1.',
                        RecordedPayments);
            end else begin
                PaymentErrorText :=
                    GetLastErrorText();

                if PaymentErrorText = '' then
                    PaymentErrorText :=
                        'Unknown Shopify payment posting error.';

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Payment posting failed: %1',
                        PaymentErrorText);

                HasErrors :=
                    true;

                SyncLogMgt.LogError(
                    "Shopify Sync Direction"::System,
                    "Shopify Sync Entity"::Payment,
                    '',
                    '',
                    PaymentErrorText,
                    CurrentDateTime() - StartedAt);
            end;
        end;

        if ShopifySetup."Auto Import Shopify Refunds" or
           ShopifySetup."Auto Process Shopify Refunds"
        then begin
            PrepareRunResult(
                RefundRunResult);

            Commit();

            ClearLastError();

            if RefundRunner.Run(
                RefundRunResult)
            then begin
                RefundRunResult.Get(1);

                RefundActions :=
                    RefundRunResult."Result Count";

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Refund actions completed: %1.',
                        RefundActions);
            end else begin
                RefundErrorText :=
                    GetLastErrorText();

                if RefundErrorText = '' then
                    RefundErrorText :=
                        'Unknown Shopify refund synchronization error.';

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Refund synchronization failed: %1',
                        RefundErrorText);

                HasErrors :=
                    true;

                SyncLogMgt.LogError(
                    "Shopify Sync Direction"::Inbound,
                    "Shopify Sync Entity"::Refund,
                    '',
                    '',
                    RefundErrorText,
                    CurrentDateTime() - StartedAt);
            end;
        end;

        if ShopifySetup."Auto Import Shopify Payouts" or
           ShopifySetup."Auto Post Paid Payouts"
        then begin
            PrepareRunResult(
                PayoutRunResult);

            Commit();

            ClearLastError();

            if PayoutRunner.Run(
                PayoutRunResult)
            then begin
                PayoutRunResult.Get(1);

                PayoutActions :=
                    PayoutRunResult."Result Count";

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Payout actions completed: %1.',
                        PayoutActions);
            end else begin
                PayoutErrorText :=
                    GetLastErrorText();

                if PayoutErrorText = '' then
                    PayoutErrorText :=
                        'Unknown Shopify payout synchronization error.';

                if ResultText <> '' then
                    ResultText +=
                        ' ';

                ResultText +=
                    StrSubstNo(
                        'Payout synchronization failed: %1',
                        PayoutErrorText);

                HasErrors :=
                    true;

                SyncLogMgt.LogError(
                    "Shopify Sync Direction"::Inbound,
                    "Shopify Sync Entity"::Payout,
                    '',
                    '',
                    PayoutErrorText,
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