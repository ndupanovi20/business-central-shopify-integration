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

        SyncLog:
            Record "Shopify Sync Log";

    begin
        GetSetup(
            ShopifySetup);

        // Important:
        // Move the cutoffs so a new operational/demo window starts now.
        // Durable registries remain preserved.
        ShopifySetup."Import Orders From" :=
            CurrentDateTime();

        ShopifySetup."Import Payouts From" :=
            CurrentDateTime();

        ShopifySetup."Import Refunds From" :=
            CurrentDateTime();

        Clear(
            ShopifySetup."Last Background Sync");

        Clear(
            ShopifySetup."Last Background Result");

        ShopifySetup.Modify(true);

        // Only transient operational history is cleared here.
        // Durable integration registries are intentionally preserved because
        // they are linked to posted Business Central documents and protect
        // against duplicate processing.
        Buffer.DeleteAll(true);
        SyncLog.DeleteAll(true);
    end;

    procedure DeleteOpenDemoSalesOrders(): Integer
    var
        SalesHeader: Record "Sales Header";
        ImportRecordLocal: Record "Shopify Order Import";
        DeletedCount: Integer;
    begin
        ImportRecordLocal.Reset();

        if not ImportRecordLocal.FindSet() then
            exit(0);

        repeat
            if ImportRecordLocal."BC Order No." <> '' then
                if SalesHeader.Get(
                    SalesHeader."Document Type"::Order,
                    ImportRecordLocal."BC Order No.")
                then
                    if SalesHeader.Status = SalesHeader.Status::Open then begin
                        SalesHeader.Delete(true);
                        DeletedCount += 1;
                    end;
        until ImportRecordLocal.Next() = 0;

        exit(DeletedCount);
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
        SalesHeader: Record "Sales Header";
        ImportRecordLocal: Record "Shopify Order Import";
        ResultCount: Integer;
    begin
        ImportRecordLocal.Reset();

        if not ImportRecordLocal.FindSet() then
            exit(0);

        repeat
            if ImportRecordLocal."BC Order No." <> '' then
                if SalesHeader.Get(
                    SalesHeader."Document Type"::Order,
                    ImportRecordLocal."BC Order No.")
                then
                    ResultCount += 1;
        until ImportRecordLocal.Next() = 0;

        exit(ResultCount);
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