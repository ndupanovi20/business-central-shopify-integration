codeunit 50193 "Shopify Admin Mgt."
{
    procedure GetRuntimeCounts(
        var BufferCount: Integer;
        var ImportedOrderCount: Integer;
        var SyncLogCount: Integer;
        var DemoSalesOrderCount: Integer;
        var ErrorBufferCount: Integer)
    var
        Buffer:
            Record "Shopify Order Buffer";

        ImportRecord:
            Record "Shopify Order Import";

        SyncLog:
            Record "Shopify Sync Log";
    begin
        BufferCount :=
            Buffer.Count();

        ImportRecord.Reset();

        ImportedOrderCount :=
            ImportRecord.Count();

        SyncLog.Reset();

        SyncLogCount :=
            SyncLog.Count();

        DemoSalesOrderCount :=
            CountDemoSalesOrders();

        Buffer.Reset();

        Buffer.SetRange(
            Status,
            Buffer.Status::Error);

        ErrorBufferCount :=
            Buffer.Count();
    end;

    procedure SetImportCutoffToNow()
    var
        ShopifySetup:
            Record "Shopify Integration Setup";
    begin
        GetSetup(
            ShopifySetup);

        ShopifySetup."Import Orders From" :=
            CurrentDateTime();

        ShopifySetup.Modify(true);
    end;

    procedure ClearRuntimeHistory()
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        Buffer:
            Record "Shopify Order Buffer";

        ImportRecord:
            Record "Shopify Order Import";

        SyncLog:
            Record "Shopify Sync Log";
    begin
        GetSetup(
            ShopifySetup);

        // Important:
        // Move the cutoff first so old Shopify orders are not
        // imported again after the registry is cleared.
        ShopifySetup."Import Orders From" :=
            CurrentDateTime();

        Clear(
            ShopifySetup."Last Background Sync");

        Clear(
            ShopifySetup."Last Background Result");

        ShopifySetup.Modify(true);

        Buffer.DeleteAll(true);

        ImportRecord.DeleteAll(true);

        SyncLog.DeleteAll(true);
    end;

    procedure DeleteOpenDemoSalesOrders(): Integer
    var
        SalesHeader:
            Record "Sales Header";

        ShopifySetup:
            Record "Shopify Integration Setup";

        DeletedCount: Integer;
    begin
        GetSetup(
            ShopifySetup);

        ShopifySetup.TestField(
            "BC Customer No.");

        SalesHeader.Reset();

        SalesHeader.SetRange(
            "Document Type",
            SalesHeader."Document Type"::Order);

        SalesHeader.SetRange(
            "Sell-to Customer No.",
            ShopifySetup."BC Customer No.");

        SalesHeader.SetRange(
            Status,
            SalesHeader.Status::Open);

        SalesHeader.SetFilter(
            "External Document No.",
            '#*');

        if not SalesHeader.FindSet() then
            exit(0);

        repeat
            if IsShopifySalesOrder(
                SalesHeader)
            then begin
                SalesHeader.Delete(true);

                DeletedCount +=
                    1;
            end;
        until SalesHeader.Next() = 0;

        exit(
            DeletedCount);
    end;

    procedure PrepareFreshDemoSession(
        var DeletedSalesOrders: Integer)
    begin
        // First remove open BC orders created by the integration.
        DeletedSalesOrders :=
            DeleteOpenDemoSalesOrders();

        // Then remove runtime integration history and move cutoff.
        ClearRuntimeHistory();
    end;

    procedure GetDemoSalesOrderCount(): Integer
    begin
        exit(
            CountDemoSalesOrders());
    end;

    local procedure CountDemoSalesOrders(): Integer
    var
        SalesHeader:
            Record "Sales Header";

        ShopifySetup:
            Record "Shopify Integration Setup";

        ResultCount: Integer;
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then
            exit(0);

        if ShopifySetup."BC Customer No." = '' then
            exit(0);

        SalesHeader.Reset();

        SalesHeader.SetRange(
            "Document Type",
            SalesHeader."Document Type"::Order);

        SalesHeader.SetRange(
            "Sell-to Customer No.",
            ShopifySetup."BC Customer No.");

        SalesHeader.SetFilter(
            "External Document No.",
            '#*');

        if not SalesHeader.FindSet() then
            exit(0);

        repeat
            if IsShopifySalesOrder(
                SalesHeader)
            then
                ResultCount +=
                    1;
        until SalesHeader.Next() = 0;

        exit(
            ResultCount);
    end;

    local procedure IsShopifySalesOrder(
        SalesHeader: Record "Sales Header"): Boolean
    begin
        if CopyStr(
            SalesHeader."External Document No.",
            1,
            1) <> '#'
        then
            exit(false);

        if StrPos(
            UpperCase(
                SalesHeader."Your Reference"),
            'SHOPIFY') = 1
        then
            exit(true);

        // Older imported orders may not have Your Reference
        // populated in exactly the same way.
        // External document number beginning with # and the
        // configured Shopify customer are sufficient for demo cleanup.
        exit(true);
    end;

    local procedure GetSetup(
        var ShopifySetup:
            Record "Shopify Integration Setup")
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist.');
    end;
}