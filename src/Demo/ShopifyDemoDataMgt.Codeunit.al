codeunit 50197 "Shopify Demo Data Mgt."
{
    procedure PrepareDemoProducts()
    begin
        EnsureBaseItemExists();

        EnsureItemUnitOfMeasures(
            'BC-SHOP-001');

        EnsureDemoItem(
            'BC-SHOP-002',
            'Mechanical Keyboard',
            59.99);

        EnsureDemoItem(
            'BC-SHOP-003',
            'USB-C Hub',
            24.99);

        Message(
            'Demo products are ready.\' +
            'BC-SHOP-001 - Wireless Mouse\' +
            'BC-SHOP-002 - Mechanical Keyboard\' +
            'BC-SHOP-003 - USB-C Hub');
    end;

    procedure InitializeDemoInventory()
    var
        ShopifyBulkSync:
            Codeunit "Shopify Bulk Sync";

        SyncedCount: Integer;
    begin
        TestDemoItem(
            'BC-SHOP-001');

        TestDemoItem(
            'BC-SHOP-002');

        TestDemoItem(
            'BC-SHOP-003');

        SetInventoryTo(
            'BC-SHOP-001',
            50,
            10000);

        SetInventoryTo(
            'BC-SHOP-002',
            30,
            20000);

        SetInventoryTo(
            'BC-SHOP-003',
            40,
            30000);

        Commit();

        SyncedCount :=
            ShopifyBulkSync.SyncMappedInventory(
                false);

        if SyncedCount = 3 then
            Message(
                'Demo inventory initialized and synchronized successfully.\' +
                'BC-SHOP-001 = 50\' +
                'BC-SHOP-002 = 30\' +
                'BC-SHOP-003 = 40')
        else
            Message(
                'Demo inventory was initialized in Business Central, but only %1 of 3 mapped inventories synchronized successfully. Check Shopify Sync Log.',
                SyncedCount);
    end;

    local procedure EnsureBaseItemExists()
    var
        BaseItem:
            Record Item;
    begin
        if not BaseItem.Get(
            'BC-SHOP-001')
        then
            Error(
                'Base demo item BC-SHOP-001 does not exist. Run Initialize Demo Company first.');
    end;

    local procedure EnsureDemoItem(
        ItemNo: Code[20];
        DescriptionText: Text[100];
        UnitPrice: Decimal)
    var
        BaseItem:
            Record Item;

        DemoItem:
            Record Item;
    begin
        BaseItem.Get(
            'BC-SHOP-001');

        if DemoItem.Get(
            ItemNo)
        then begin
            DemoItem.Validate(
                Description,
                DescriptionText);

            DemoItem.Validate(
                "Unit Price",
                UnitPrice);

            DemoItem.Modify(true);

            EnsureItemUnitOfMeasures(
                ItemNo);

            exit;
        end;

        DemoItem.Init();

        DemoItem.TransferFields(
            BaseItem,
            false);

        DemoItem."No." :=
            ItemNo;

        DemoItem.Validate(
            Description,
            DescriptionText);

        DemoItem.Validate(
            "Unit Price",
            UnitPrice);

        DemoItem.Insert(false);

        EnsureItemUnitOfMeasures(
            ItemNo);
    end;

    local procedure EnsureItemUnitOfMeasures(
        TargetItemNo: Code[20])
    var
        BaseItemUOM:
            Record "Item Unit of Measure";

        TargetItemUOM:
            Record "Item Unit of Measure";
    begin
        BaseItemUOM.SetRange(
            "Item No.",
            'BC-SHOP-001');

        if not BaseItemUOM.FindSet() then
            Error(
                'Item Unit of Measure setup for BC-SHOP-001 is missing.');

        repeat
            if TargetItemNo = 'BC-SHOP-001' then
                exit;

            if not TargetItemUOM.Get(
                TargetItemNo,
                BaseItemUOM.Code)
            then begin
                TargetItemUOM.Init();

                TargetItemUOM.TransferFields(
                    BaseItemUOM,
                    false);

                TargetItemUOM."Item No." :=
                    TargetItemNo;

                TargetItemUOM.Code :=
                    BaseItemUOM.Code;

                TargetItemUOM.Insert(false);
            end;
        until BaseItemUOM.Next() = 0;
    end;

    local procedure TestDemoItem(
        ItemNo: Code[20])
    var
        Item:
            Record Item;
    begin
        if not Item.Get(
            ItemNo)
        then
            Error(
                'Demo item %1 does not exist.',
                ItemNo);

        if Item.Type <>
           Item.Type::Inventory
        then
            Error(
                'Demo item %1 is not an Inventory item.',
                ItemNo);

        Item.TestField(
            "Base Unit of Measure");

        Item.TestField(
            "Gen. Prod. Posting Group");

        Item.TestField(
            "VAT Prod. Posting Group");

        Item.TestField(
            "Inventory Posting Group");
    end;

    local procedure SetInventoryTo(
        ItemNo: Code[20];
        DesiredInventory: Decimal;
        LineNo: Integer)
    var
        Item:
            Record Item;

        InventoryItem:
            Record Item;

        ItemJnlLine:
            Record "Item Journal Line";

        ItemJnlPostLine:
            Codeunit "Item Jnl.-Post Line";

        CurrentInventory: Decimal;
        Difference: Decimal;
    begin
        Item.Get(
            ItemNo);

        InventoryItem.Get(
            ItemNo);

        InventoryItem.SetRange(
            "Location Filter",
            'SHOP');

        InventoryItem.CalcFields(
            Inventory);

        CurrentInventory :=
            InventoryItem.Inventory;

        Difference :=
            DesiredInventory -
            CurrentInventory;

        if Difference = 0 then
            exit;

        Clear(
            ItemJnlLine);

        ItemJnlLine.Init();

        ItemJnlLine."Line No." :=
            LineNo;

        ItemJnlLine.Validate(
            "Posting Date",
            WorkDate());

        ItemJnlLine."Document Date" :=
            WorkDate();

        ItemJnlLine."Document No." :=
            'DEMO-OPENING';

        if Difference > 0 then
            ItemJnlLine.Validate(
                "Entry Type",
                ItemJnlLine."Entry Type"::"Positive Adjmt.")
        else
            ItemJnlLine.Validate(
                "Entry Type",
                ItemJnlLine."Entry Type"::"Negative Adjmt.");

        ItemJnlLine.Validate(
            "Item No.",
            ItemNo);

        ItemJnlLine.Validate(
            "Location Code",
            'SHOP');

        if ItemJnlLine."Unit of Measure Code" = '' then
            ItemJnlLine.Validate(
                "Unit of Measure Code",
                Item."Base Unit of Measure");

        ItemJnlLine.Validate(
            Quantity,
            Abs(Difference));

        if not ItemJnlPostLine.RunWithCheck(
            ItemJnlLine)
        then
            Error(
                'Inventory adjustment for item %1 could not be posted.',
                ItemNo);
    end;
}