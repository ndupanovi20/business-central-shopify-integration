codeunit 50121 "Shopify Inventory Sync"
{
    procedure SyncInventory(
        InventoryItemId: Text;
        ItemNo: Code[20];
        InventoryDecimal: Decimal)
    var
        ShopifySetup: Record "Shopify Integration Setup";
        Quantity: Integer;
    begin
        if not ShopifySetup.Get('SETUP') then
            Error('Shopify Integration Setup does not exist.');

        ShopifySetup.TestField("Shopify Location ID");

        Quantity :=
            Round(
                InventoryDecimal,
                1,
                '=');

        if Quantity < 0 then
            Quantity := 0;

        EnsureInventoryTracked(
            InventoryItemId,
            ItemNo);

        if not IsInventoryActivated(
            InventoryItemId,
            ShopifySetup."Shopify Location ID")
        then
            ActivateInventory(
                InventoryItemId,
                ShopifySetup."Shopify Location ID");

        SetOnHandQuantity(
            InventoryItemId,
            ShopifySetup."Shopify Location ID",
            Quantity,
            ItemNo);
    end;

    local procedure EnsureInventoryTracked(
        InventoryItemId: Text;
        ItemNo: Code[20])
    var
        ShopifyClient: Codeunit "Shopify Client";

        Variables: JsonObject;
        InputObject: JsonObject;
        ResponseJson: JsonObject;

        DataObject: JsonObject;
        PayloadObject: JsonObject;

        QueryText: Text;
    begin
        InputObject.Add(
            'sku',
            ItemNo);

        InputObject.Add(
            'tracked',
            true);

        Variables.Add(
            'id',
            InventoryItemId);

        Variables.Add(
            'input',
            InputObject);

        QueryText :=
            'mutation UpdateInventoryItem(' +
            '$id: ID!, $input: InventoryItemInput!) {' +
            ' inventoryItemUpdate(id: $id, input: $input) {' +
            '  inventoryItem {' +
            '   id' +
            '   sku' +
            '   tracked' +
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
                'inventoryItemUpdate');

        ShopifyClient.CheckUserErrors(
            PayloadObject);
    end;

    local procedure IsInventoryActivated(
        InventoryItemId: Text;
        LocationId: Text): Boolean
    var
        ShopifyClient: Codeunit "Shopify Client";

        Variables: JsonObject;
        ResponseJson: JsonObject;

        DataObject: JsonObject;
        InventoryItemObject: JsonObject;

        Token: JsonToken;
        QueryText: Text;
    begin
        Variables.Add(
            'id',
            InventoryItemId);

        Variables.Add(
            'locationId',
            LocationId);

        QueryText :=
            'query CheckInventoryLevel(' +
            '$id: ID!, $locationId: ID!) {' +
            ' inventoryItem(id: $id) {' +
            '  inventoryLevel(locationId: $locationId) {' +
            '   id' +
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

        InventoryItemObject :=
            ShopifyClient.GetObject(
                DataObject,
                'inventoryItem');

        if not InventoryItemObject.Get(
            'inventoryLevel',
            Token)
        then
            exit(false);

        if Token.IsValue() then
            if Token.AsValue().IsNull() then
                exit(false);

        exit(Token.IsObject());
    end;

    local procedure ActivateInventory(
        InventoryItemId: Text;
        LocationId: Text)
    var
        ShopifyClient: Codeunit "Shopify Client";

        Variables: JsonObject;
        ResponseJson: JsonObject;

        DataObject: JsonObject;
        PayloadObject: JsonObject;

        QueryText: Text;
        IdempotencyKey: Text;
    begin
        IdempotencyKey :=
            DelChr(
                Format(CreateGuid()),
                '=',
                '{}');

        Variables.Add(
            'inventoryItemId',
            InventoryItemId);

        Variables.Add(
            'locationId',
            LocationId);

        Variables.Add(
            'available',
            0);

        Variables.Add(
            'idempotencyKey',
            IdempotencyKey);

        QueryText :=
            'mutation ActivateInventoryItem(' +
            '$inventoryItemId: ID!, ' +
            '$locationId: ID!, ' +
            '$available: Int, ' +
            '$idempotencyKey: String!) {' +
            ' inventoryActivate(' +
            '  inventoryItemId: $inventoryItemId, ' +
            '  locationId: $locationId, ' +
            '  available: $available' +
            ' ) @idempotent(key: $idempotencyKey) {' +
            '  inventoryLevel {' +
            '   id' +
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
                'inventoryActivate');

        ShopifyClient.CheckUserErrors(
            PayloadObject);
    end;

    local procedure SetOnHandQuantity(
        InventoryItemId: Text;
        LocationId: Text;
        Quantity: Integer;
        ItemNo: Code[20])
    var
        ShopifyClient: Codeunit "Shopify Client";

        Variables: JsonObject;
        InputObject: JsonObject;
        QuantityObject: JsonObject;

        QuantitiesArray: JsonArray;
        NullValue: JsonValue;

        ResponseJson: JsonObject;
        DataObject: JsonObject;
        PayloadObject: JsonObject;

        QueryText: Text;
        IdempotencyKey: Text;
    begin
        NullValue.SetValueToNull();

        IdempotencyKey :=
            DelChr(
                Format(CreateGuid()),
                '=',
                '{}');

        QuantityObject.Add(
            'inventoryItemId',
            InventoryItemId);

        QuantityObject.Add(
            'locationId',
            LocationId);

        QuantityObject.Add(
            'quantity',
            Quantity);

        QuantityObject.Add(
            'changeFromQuantity',
            NullValue);

        QuantitiesArray.Add(
            QuantityObject);

        InputObject.Add(
            'reason',
            'correction');

        InputObject.Add(
            'referenceDocumentUri',
            StrSubstNo(
                'gid://bc-shopify-integration/Item/%1',
                ItemNo));

        InputObject.Add(
            'setQuantities',
            QuantitiesArray);

        Variables.Add(
            'input',
            InputObject);

        Variables.Add(
            'idempotencyKey',
            IdempotencyKey);

        QueryText :=
            'mutation SetOnHandInventory(' +
            '$input: InventorySetOnHandQuantitiesInput!, ' +
            '$idempotencyKey: String!) {' +
            ' inventorySetOnHandQuantities(input: $input) ' +
            ' @idempotent(key: $idempotencyKey) {' +
            '  inventoryAdjustmentGroup {' +
            '   reason' +
            '   referenceDocumentUri' +
            '   changes {' +
            '    name' +
            '    delta' +
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
                'inventorySetOnHandQuantities');

        ShopifyClient.CheckUserErrors(
            PayloadObject);
    end;
}