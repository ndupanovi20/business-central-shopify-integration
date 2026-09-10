codeunit 50180 "Shopify Bulk Sync"
{
    procedure SyncSelected(
        var Item: Record Item)
    var
        ShopifyProductSync:
            Codeunit "Shopify Product Sync";

        ErrorText: Text;

        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        if not Item.FindSet() then begin
            Message(
                'No items were selected.');

            exit;
        end;

        repeat
            if ShopifyProductSync.TrySyncItemForBatch(
                Item,
                ErrorText)
            then
                SuccessCount += 1
            else
                ErrorCount += 1;
        until Item.Next() = 0;

        Message(
            'Shopify product synchronization completed.\Successful: %1\Failed: %2',
            SuccessCount,
            ErrorCount);
    end;

    procedure SyncDemoProducts(
        ShowResultMessage: Boolean): Integer
    var
        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        SyncDemoItem(
            'BC-SHOP-001',
            SuccessCount,
            ErrorCount);

        SyncDemoItem(
            'BC-SHOP-002',
            SuccessCount,
            ErrorCount);

        SyncDemoItem(
            'BC-SHOP-003',
            SuccessCount,
            ErrorCount);

        if ShowResultMessage then
            Message(
                'Demo product synchronization completed.\Successful: %1\Failed: %2',
                SuccessCount,
                ErrorCount);

        exit(
            SuccessCount);
    end;

    local procedure SyncDemoItem(
        ItemNo: Code[20];
        var SuccessCount: Integer;
        var ErrorCount: Integer)
    var
        Item:
            Record Item;

        ShopifyProductSync:
            Codeunit "Shopify Product Sync";

        ErrorText: Text;
    begin
        if not Item.Get(
            ItemNo)
        then begin
            ErrorCount += 1;

            exit;
        end;

        if ShopifyProductSync.TrySyncItemForBatch(
            Item,
            ErrorText)
        then
            SuccessCount += 1
        else
            ErrorCount += 1;
    end;

    procedure SyncMappedInventory(
        ShowResultMessage: Boolean): Integer
    var
        Mapping:
            Record "Shopify Product Mapping";

        Item:
            Record Item;

        ShopifyProductSync:
            Codeunit "Shopify Product Sync";

        ErrorText: Text;

        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        if not Mapping.FindSet() then begin
            if ShowResultMessage then
                Message(
                    'There are no mapped Shopify products.');

            exit(0);
        end;

        repeat
            if Item.Get(
                Mapping."Item No.")
            then begin
                if ShopifyProductSync.TrySyncInventoryForBatch(
                    Item,
                    ErrorText)
                then
                    SuccessCount += 1
                else
                    ErrorCount += 1;
            end else
                ErrorCount += 1;

        until Mapping.Next() = 0;

        if ShowResultMessage then
            Message(
                'Shopify inventory synchronization completed.\Successful: %1\Failed: %2',
                SuccessCount,
                ErrorCount);

        exit(
            SuccessCount);
    end;
}