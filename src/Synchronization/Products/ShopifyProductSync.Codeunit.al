codeunit 50120 "Shopify Product Sync"
{
    procedure SyncItem(
        var Item: Record Item)
    var
        ErrorText: Text;
    begin
        if TrySyncItemForBatch(
            Item,
            ErrorText)
        then begin
            Message(
                'Item %1 - %2 was synchronized to Shopify successfully.',
                Item."No.",
                Item.Description);

            exit;
        end;

        // Sačuvaj error log prije nego korisniku bacimo Error.
        Commit();

        Error(ErrorText);
    end;

    procedure SyncItemSilent(
        var Item: Record Item)
    var
        ErrorText: Text;
    begin
        if TrySyncItemForBatch(
            Item,
            ErrorText)
        then
            exit;

        Commit();

        Error(ErrorText);
    end;

    procedure TrySyncItemForBatch(
        var Item: Record Item;
        var ErrorText: Text): Boolean
    var
        Mapping:
            Record "Shopify Product Mapping";

        ProductSyncRunner:
            Codeunit "Shopify Product Sync Runner";

        SyncLogMgt:
            Codeunit "Shopify Sync Log Mgt.";

        StartedAt: DateTime;
        OperationDuration: Duration;

        ShopifyId: Text;
    begin
        StartedAt :=
            CurrentDateTime();

        // Codeunit.Run s Boolean rezultatom mora krenuti
        // izvan postojeće write transakcije.
        Commit();

        ClearLastError();

        if ProductSyncRunner.Run(Item) then begin
            OperationDuration :=
                CurrentDateTime() - StartedAt;

            if Mapping.Get(Item."No.") then
                ShopifyId :=
                    Mapping."Shopify Product ID";

            SyncLogMgt.LogSuccess(
                "Shopify Sync Direction"::Outbound,
                "Shopify Sync Entity"::Product,
                Item."No.",
                ShopifyId,
                StrSubstNo(
                    'Product %1 synchronized successfully.',
                    Item."No."),
                OperationDuration);

            ErrorText := '';

            exit(true);
        end;

        ErrorText :=
            GetLastErrorText();

        if ErrorText = '' then
            ErrorText :=
                'An unknown error occurred while synchronizing the product.';

        OperationDuration :=
            CurrentDateTime() - StartedAt;

        UpdateMappingError(
            Item."No.",
            ErrorText);

        if Mapping.Get(Item."No.") then
            ShopifyId :=
                Mapping."Shopify Product ID";

        SyncLogMgt.LogError(
            "Shopify Sync Direction"::Outbound,
            "Shopify Sync Entity"::Product,
            Item."No.",
            ShopifyId,
            ErrorText,
            OperationDuration);

        exit(false);
    end;

    procedure SyncInventoryOnly(
        var Item: Record Item)
    var
        ErrorText: Text;
    begin
        if TrySyncInventoryForBatch(
            Item,
            ErrorText)
        then begin
            Message(
                'Inventory for item %1 was synchronized to Shopify successfully.',
                Item."No.");

            exit;
        end;

        Commit();

        Error(ErrorText);
    end;

    procedure TrySyncInventoryForBatch(
        var Item: Record Item;
        var ErrorText: Text): Boolean
    var
        Mapping:
            Record "Shopify Product Mapping";

        InventorySyncRunner:
            Codeunit "Shopify Inventory Sync Runner";

        SyncLogMgt:
            Codeunit "Shopify Sync Log Mgt.";

        StartedAt: DateTime;
        OperationDuration: Duration;

        ShopifyId: Text;
    begin
        StartedAt :=
            CurrentDateTime();

        Commit();

        ClearLastError();

        if InventorySyncRunner.Run(Item) then begin
            OperationDuration :=
                CurrentDateTime() - StartedAt;

            if Mapping.Get(Item."No.") then
                ShopifyId :=
                    Mapping."Shopify Inventory Item ID";

            SyncLogMgt.LogSuccess(
                "Shopify Sync Direction"::Outbound,
                "Shopify Sync Entity"::Inventory,
                Item."No.",
                ShopifyId,
                StrSubstNo(
                    'Inventory for item %1 synchronized successfully.',
                    Item."No."),
                OperationDuration);

            ErrorText := '';

            exit(true);
        end;

        ErrorText :=
            GetLastErrorText();

        if ErrorText = '' then
            ErrorText :=
                'An unknown error occurred while synchronizing inventory.';

        OperationDuration :=
            CurrentDateTime() - StartedAt;

        UpdateMappingError(
            Item."No.",
            ErrorText);

        if Mapping.Get(Item."No.") then
            ShopifyId :=
                Mapping."Shopify Inventory Item ID";

        SyncLogMgt.LogError(
            "Shopify Sync Direction"::Outbound,
            "Shopify Sync Entity"::Inventory,
            Item."No.",
            ShopifyId,
            ErrorText,
            OperationDuration);

        exit(false);
    end;

    procedure ExecuteFullSync(
        var Item: Record Item)
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        Mapping:
            Record "Shopify Product Mapping";

        ShopifyClient:
            Codeunit "Shopify Client";

        ShopifyInventorySync:
            Codeunit "Shopify Inventory Sync";

        ItemForInventory:
            Record Item;

        ProductId: Text;
        VariantId: Text;
        InventoryItemId: Text;

        InventoryAtLocation: Decimal;
    begin
        ValidateItem(
            Item);

        if not ShopifySetup.Get('SETUP') then
            Error(
                'Shopify Integration Setup does not exist.');

        ShopifySetup.TestField(
            "BC Location Code");

        ShopifySetup.TestField(
            "Shopify Location ID");

        ItemForInventory.Get(
            Item."No.");

        ItemForInventory.SetRange(
            "Location Filter",
            ShopifySetup."BC Location Code");

        ItemForInventory.CalcFields(
            Inventory);

        InventoryAtLocation :=
            ItemForInventory.Inventory;

        if Mapping.Get(Item."No.") then begin
            Mapping.TestField(
                "Shopify Product ID");

            Mapping.TestField(
                "Shopify Variant ID");

            Mapping.TestField(
                "Shopify Inventory Item ID");

            ProductId :=
                Mapping."Shopify Product ID";

            VariantId :=
                Mapping."Shopify Variant ID";

            InventoryItemId :=
                Mapping."Shopify Inventory Item ID";
        end else begin
            if ShopifyClient.FindVariantBySku(
                Item."No.",
                ProductId,
                VariantId,
                InventoryItemId)
            then begin
                SaveMapping(
                    Item."No.",
                    ProductId,
                    VariantId,
                    InventoryItemId);
            end else begin
                CreateProduct(
                    Item,
                    ProductId,
                    VariantId,
                    InventoryItemId);

                SaveMapping(
                    Item."No.",
                    ProductId,
                    VariantId,
                    InventoryItemId);
            end;
        end;

        UpdateProduct(
            Item,
            ProductId);

        UpdateVariant(
            Item,
            ProductId,
            VariantId);

        ShopifyInventorySync.SyncInventory(
            InventoryItemId,
            Item."No.",
            InventoryAtLocation);

        UpdateMappingSuccess(
            Item."No.",
            true,
            true);
    end;

    procedure ExecuteInventorySync(
        var Item: Record Item)
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        Mapping:
            Record "Shopify Product Mapping";

        ShopifyInventorySync:
            Codeunit "Shopify Inventory Sync";

        ItemForInventory:
            Record Item;

        InventoryAtLocation: Decimal;
    begin
        ValidateItem(
            Item);

        if not ShopifySetup.Get('SETUP') then
            Error(
                'Shopify Integration Setup does not exist.');

        ShopifySetup.TestField(
            "BC Location Code");

        ShopifySetup.TestField(
            "Shopify Location ID");

        if not Mapping.Get(
            Item."No.")
        then
            Error(
                'Item %1 is not mapped to Shopify. Run a full Shopify sync first.',
                Item."No.");

        Mapping.TestField(
            "Shopify Inventory Item ID");

        ItemForInventory.Get(
            Item."No.");

        ItemForInventory.SetRange(
            "Location Filter",
            ShopifySetup."BC Location Code");

        ItemForInventory.CalcFields(
            Inventory);

        InventoryAtLocation :=
            ItemForInventory.Inventory;

        ShopifyInventorySync.SyncInventory(
            Mapping."Shopify Inventory Item ID",
            Item."No.",
            InventoryAtLocation);

        UpdateMappingSuccess(
            Item."No.",
            false,
            true);
    end;

    local procedure ValidateItem(
        Item: Record Item)
    begin
        Item.TestField(
            "No.");

        Item.TestField(
            Description);

        if Item.Type <> Item.Type::Inventory then
            Error(
                'Only Inventory items can be synchronized as Shopify products.');

        if Item."Unit Price" < 0 then
            Error(
                'Item %1 has an invalid negative Unit Price.',
                Item."No.");
    end;

    local procedure SaveMapping(
        ItemNo: Code[20];
        ProductId: Text;
        VariantId: Text;
        InventoryItemId: Text)
    var
        Mapping:
            Record "Shopify Product Mapping";

        NewMapping: Boolean;
    begin
        NewMapping :=
            not Mapping.Get(ItemNo);

        if NewMapping then begin
            Mapping.Init();

            Mapping."Item No." :=
                ItemNo;

            Mapping."Created At" :=
                CurrentDateTime();
        end;

        Mapping."Shopify Product ID" :=
            CopyStr(
                ProductId,
                1,
                MaxStrLen(
                    Mapping."Shopify Product ID"));

        Mapping."Shopify Variant ID" :=
            CopyStr(
                VariantId,
                1,
                MaxStrLen(
                    Mapping."Shopify Variant ID"));

        Mapping."Shopify Inventory Item ID" :=
            CopyStr(
                InventoryItemId,
                1,
                MaxStrLen(
                    Mapping."Shopify Inventory Item ID"));

        Mapping."Modified At" :=
            CurrentDateTime();

        if NewMapping then
            Mapping.Insert(true)
        else
            Mapping.Modify(true);
    end;

    local procedure UpdateMappingSuccess(
        ItemNo: Code[20];
        ProductSynced: Boolean;
        InventorySynced: Boolean)
    var
        Mapping:
            Record "Shopify Product Mapping";
    begin
        if not Mapping.Get(ItemNo) then
            exit;

        if ProductSynced then
            Mapping."Last Product Sync" :=
                CurrentDateTime();

        if InventorySynced then
            Mapping."Last Inventory Sync" :=
                CurrentDateTime();

        Mapping."Last Sync Status" :=
            "Shopify Sync Status"::Success;

        Clear(
            Mapping."Last Error");

        Mapping.Modify(true);
    end;

    local procedure UpdateMappingError(
        ItemNo: Code[20];
        ErrorText: Text)
    var
        Mapping:
            Record "Shopify Product Mapping";
    begin
        if not Mapping.Get(ItemNo) then
            exit;

        Mapping."Last Sync Status" :=
            "Shopify Sync Status"::Error;

        Mapping."Last Error" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(
                    Mapping."Last Error"));

        Mapping.Modify(true);
    end;

    local procedure CreateProduct(
        Item: Record Item;
        var ProductId: Text;
        var VariantId: Text;
        var InventoryItemId: Text)
    var
        ShopifyClient:
            Codeunit "Shopify Client";

        Variables: JsonObject;
        ProductInput: JsonObject;
        ResponseJson: JsonObject;

        DataObject: JsonObject;
        PayloadObject: JsonObject;
        ProductObject: JsonObject;
        VariantsObject: JsonObject;
        VariantObject: JsonObject;
        InventoryItemObject: JsonObject;

        NodesArray: JsonArray;
        Token: JsonToken;

        QueryText: Text;
    begin
        ProductInput.Add(
            'title',
            Item.Description);

        ProductInput.Add(
            'vendor',
            'Business Central');

        ProductInput.Add(
            'status',
            'ACTIVE');

        Variables.Add(
            'product',
            ProductInput);

        QueryText :=
            'mutation CreateProduct(' +
            '$product: ProductCreateInput!) {' +
            ' productCreate(product: $product) {' +
            '  product {' +
            '   id' +
            '   title' +
            '   variants(first: 1) {' +
            '    nodes {' +
            '     id' +
            '     inventoryItem { id }' +
            '    }' +
            '   }' +
            '  }' +
            '  userErrors { field message }' +
            ' }' +
            '}';

        ShopifyClient.ExecuteGraphQL(
            QueryText,
            Variables,
            ResponseJson);

        DataObject :=
            ShopifyClient.GetObject(
                ResponseJson,
                'data');

        PayloadObject :=
            ShopifyClient.GetObject(
                DataObject,
                'productCreate');

        ShopifyClient.CheckUserErrors(
            PayloadObject);

        ProductObject :=
            ShopifyClient.GetObject(
                PayloadObject,
                'product');

        ProductId :=
            ShopifyClient.GetText(
                ProductObject,
                'id');

        VariantsObject :=
            ShopifyClient.GetObject(
                ProductObject,
                'variants');

        NodesArray :=
            ShopifyClient.GetArray(
                VariantsObject,
                'nodes');

        if NodesArray.Count() = 0 then
            Error(
                'Shopify created the product without an initial variant.');

        NodesArray.Get(
            0,
            Token);

        VariantObject :=
            Token.AsObject();

        VariantId :=
            ShopifyClient.GetText(
                VariantObject,
                'id');

        InventoryItemObject :=
            ShopifyClient.GetObject(
                VariantObject,
                'inventoryItem');

        InventoryItemId :=
            ShopifyClient.GetText(
                InventoryItemObject,
                'id');
    end;

    local procedure UpdateProduct(
        Item: Record Item;
        ProductId: Text)
    var
        ShopifyClient:
            Codeunit "Shopify Client";

        Variables: JsonObject;
        ProductInput: JsonObject;
        ResponseJson: JsonObject;

        DataObject: JsonObject;
        PayloadObject: JsonObject;

        QueryText: Text;
    begin
        ProductInput.Add(
            'id',
            ProductId);

        ProductInput.Add(
            'title',
            Item.Description);

        ProductInput.Add(
            'vendor',
            'Business Central');

        ProductInput.Add(
            'status',
            'ACTIVE');

        Variables.Add(
            'product',
            ProductInput);

        QueryText :=
            'mutation UpdateProduct(' +
            '$product: ProductUpdateInput!) {' +
            ' productUpdate(product: $product) {' +
            '  product {' +
            '   id' +
            '   title' +
            '  }' +
            '  userErrors {' +
            '   field' +
            '   message' +
            '  }' +
            ' }' +
            '}';

        ShopifyClient.ExecuteGraphQL(
            QueryText,
            Variables,
            ResponseJson);

        DataObject :=
            ShopifyClient.GetObject(
                ResponseJson,
                'data');

        PayloadObject :=
            ShopifyClient.GetObject(
                DataObject,
                'productUpdate');

        ShopifyClient.CheckUserErrors(
            PayloadObject);
    end;

    local procedure UpdateVariant(
        Item: Record Item;
        ProductId: Text;
        VariantId: Text)
    var
        ShopifyClient:
            Codeunit "Shopify Client";

        Variables: JsonObject;
        VariantInput: JsonObject;
        InventoryItemInput: JsonObject;

        VariantsArray: JsonArray;

        ResponseJson: JsonObject;
        DataObject: JsonObject;
        PayloadObject: JsonObject;

        QueryText: Text;
    begin
        VariantInput.Add(
            'id',
            VariantId);

        VariantInput.Add(
            'price',
            Item."Unit Price");

        InventoryItemInput.Add(
            'sku',
            Item."No.");

        InventoryItemInput.Add(
            'tracked',
            true);

        VariantInput.Add(
            'inventoryItem',
            InventoryItemInput);

        VariantsArray.Add(
            VariantInput);

        Variables.Add(
            'productId',
            ProductId);

        Variables.Add(
            'variants',
            VariantsArray);

        QueryText :=
            'mutation UpdateVariants(' +
            '$productId: ID!, ' +
            '$variants: [ProductVariantsBulkInput!]!) {' +
            ' productVariantsBulkUpdate(' +
            '  productId: $productId, ' +
            '  variants: $variants' +
            ' ) {' +
            '  productVariants {' +
            '   id' +
            '   price' +
            '   inventoryItem {' +
            '    id' +
            '    sku' +
            '    tracked' +
            '   }' +
            '  }' +
            '  userErrors {' +
            '   field' +
            '   message' +
            '  }' +
            ' }' +
            '}';

        ShopifyClient.ExecuteGraphQL(
            QueryText,
            Variables,
            ResponseJson);

        DataObject :=
            ShopifyClient.GetObject(
                ResponseJson,
                'data');

        PayloadObject :=
            ShopifyClient.GetObject(
                DataObject,
                'productVariantsBulkUpdate');

        ShopifyClient.CheckUserErrors(
            PayloadObject);
    end;
}