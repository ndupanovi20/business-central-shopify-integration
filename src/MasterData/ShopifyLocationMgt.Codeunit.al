codeunit 50297 "Shopify Location Mgt."
{
    procedure RefreshLocationsFromShopify(ShowResultMessage: Boolean): Integer
    var
        ShopifyClient: Codeunit "Shopify Client";
        Variables: JsonObject;
        ResponseJson: JsonObject;
        DataObject: JsonObject;
        LocationsObject: JsonObject;
        PageInfoObject: JsonObject;
        NodesArray: JsonArray;
        LocationObject: JsonObject;
        Token: JsonToken;
        QueryText: Text;
        Cursor: Text;
        HasNextPage: Boolean;
        ImportedCount: Integer;
        I: Integer;
    begin
        QueryText :=
            'query GetLocations($first: Int!, $after: String) {' +
            ' locations(first: $first, after: $after) {' +
            '  nodes { id name }' +
            '  pageInfo { hasNextPage endCursor }' +
            ' }' +
            '}';

        Cursor := '';
        HasNextPage := true;

        while HasNextPage do begin
            Clear(Variables);
            Clear(ResponseJson);

            Variables.Add('first', 100);
            if Cursor <> '' then
                Variables.Add('after', Cursor);

            ShopifyClient.ExecuteGraphQL(
                QueryText,
                Variables,
                ResponseJson);

            DataObject := ShopifyClient.GetObject(ResponseJson, 'data');
            LocationsObject := ShopifyClient.GetObject(DataObject, 'locations');
            NodesArray := ShopifyClient.GetArray(LocationsObject, 'nodes');

            if NodesArray.Count() > 0 then
                for I := 0 to NodesArray.Count() - 1 do begin
                    NodesArray.Get(I, Token);
                    LocationObject := Token.AsObject();
                    UpsertLocation(
                        ShopifyClient.GetText(LocationObject, 'id'),
                        ShopifyClient.GetText(LocationObject, 'name'));
                    ImportedCount += 1;
                end;

            PageInfoObject := ShopifyClient.GetObject(LocationsObject, 'pageInfo');
            HasNextPage := GetBoolean(PageInfoObject, 'hasNextPage');

            if HasNextPage then begin
                Cursor := GetOptionalText(PageInfoObject, 'endCursor');
                if Cursor = '' then
                    HasNextPage := false;
            end;
        end;

        SeedLegacyLocationMapping();
        EnsureDefaultForSingleMappedLocation();

        if ShowResultMessage then
            Message(
                'Shopify locations refreshed successfully. Locations returned: %1.',
                ImportedCount);

        exit(ImportedCount);
    end;

    procedure ResolveOrderLocation(
        OrderObject: JsonObject;
        ShopifySetup: Record "Shopify Integration Setup";
        var BCLocationCode: Code[10];
        var ShopifyLocationId: Text)
    var
        UniqueShopifyLocationId: Text;
        MultipleLocations: Boolean;
    begin
        BCLocationCode := '';
        ShopifyLocationId := '';

        if not ShopifySetup."Use Location Mappings" then begin
            ShopifySetup.TestField("BC Location Code");
            ShopifySetup.TestField("Shopify Location ID");

            BCLocationCode := ShopifySetup."BC Location Code";
            ShopifyLocationId := ShopifySetup."Shopify Location ID";
            exit;
        end;

        GetUniqueAssignedShopifyLocation(
            OrderObject,
            UniqueShopifyLocationId,
            MultipleLocations);

        if MultipleLocations then
            Error(
                'Shopify order is assigned to more than one Shopify fulfillment location. The current Sales Order importer supports one Business Central location per order. Split-location orders require line-level location routing.');

        if UniqueShopifyLocationId <> '' then begin
            if not TryGetBCLocationCode(
                UniqueShopifyLocationId,
                BCLocationCode)
            then
                Error(
                    'Shopify order is assigned to location %1, but that Shopify location is not mapped to an active Business Central location.',
                    UniqueShopifyLocationId);

            ShopifyLocationId := UniqueShopifyLocationId;
            exit;
        end;

        GetDefaultOrderLocation(
            BCLocationCode,
            ShopifyLocationId);
    end;

    procedure ResolveShopifyLocationId(
        BCLocationCode: Code[10]): Text
    var
        ShopifySetup: Record "Shopify Integration Setup";
        Mapping: Record "Shopify Location Mapping";
    begin
        GetSetup(ShopifySetup);

        if not ShopifySetup."Use Location Mappings" then begin
            if BCLocationCode <> ShopifySetup."BC Location Code" then
                Error(
                    'Business Central location %1 is not the configured Shopify location %2.',
                    BCLocationCode,
                    ShopifySetup."BC Location Code");

            ShopifySetup.TestField("Shopify Location ID");
            exit(ShopifySetup."Shopify Location ID");
        end;

        Mapping.SetRange("BC Location Code", BCLocationCode);
        Mapping.SetRange(Active, true);

        if not Mapping.FindFirst() then
            Error(
                'Business Central location %1 is not mapped to an active Shopify location.',
                BCLocationCode);

        Mapping.TestField("Shopify Location ID");
        exit(Mapping."Shopify Location ID");
    end;

    procedure SyncInventoryForItem(
        Item: Record Item;
        ShopifyInventoryItemId: Text): Integer
    var
        ShopifySetup: Record "Shopify Integration Setup";
        Mapping: Record "Shopify Location Mapping";
        ShopifyInventorySync: Codeunit "Shopify Inventory Sync";
        ItemAtLocation: Record Item;
        InventoryAtLocation: Decimal;
        SyncedCount: Integer;
    begin
        GetSetup(ShopifySetup);

        if not ShopifySetup."Use Location Mappings" then begin
            ShopifySetup.TestField("BC Location Code");
            ShopifySetup.TestField("Shopify Location ID");

            ItemAtLocation.Get(Item."No.");
            ItemAtLocation.SetRange("Location Filter", ShopifySetup."BC Location Code");
            ItemAtLocation.CalcFields(Inventory);

            ShopifyInventorySync.SyncInventoryAtLocation(
                ShopifyInventoryItemId,
                Item."No.",
                ItemAtLocation.Inventory,
                ShopifySetup."Shopify Location ID");

            exit(1);
        end;

        Mapping.SetRange(Active, true);
        Mapping.SetFilter("BC Location Code", '<>%1', '');
        Mapping.SetFilter("Shopify Location ID", '<>%1', '');

        if not Mapping.FindSet() then
            Error(
                'Use Location Mappings is enabled, but there are no active Shopify Location Mapping records with both BC and Shopify locations.');

        repeat
            ItemAtLocation.Get(Item."No.");
            ItemAtLocation.SetRange("Location Filter", Mapping."BC Location Code");
            ItemAtLocation.CalcFields(Inventory);
            InventoryAtLocation := ItemAtLocation.Inventory;

            ShopifyInventorySync.SyncInventoryAtLocation(
                ShopifyInventoryItemId,
                Item."No.",
                InventoryAtLocation,
                Mapping."Shopify Location ID");

            SyncedCount += 1;
        until Mapping.Next() = 0;

        exit(SyncedCount);
    end;

    procedure ValidateLocationMappings()
    var
        ShopifySetup: Record "Shopify Integration Setup";
        Mapping: Record "Shopify Location Mapping";
        Location: Record Location;
        ActiveMappedCount: Integer;
        DefaultCount: Integer;
    begin
        GetSetup(ShopifySetup);

        if not ShopifySetup."Use Location Mappings" then begin
            ShopifySetup.TestField("BC Location Code");
            ShopifySetup.TestField("Shopify Location ID");
            exit;
        end;

        Mapping.SetRange(Active, true);
        if Mapping.FindSet() then
            repeat
                if (Mapping."BC Location Code" <> '') and
                   (Mapping."Shopify Location ID" <> '')
                then begin
                    ActiveMappedCount += 1;

                    if not Location.Get(Mapping."BC Location Code") then
                        Error(
                            'Business Central location %1 used by Shopify Location Mapping does not exist.',
                            Mapping."BC Location Code");

                    if StrPos(
                        Mapping."Shopify Location ID",
                        'gid://shopify/Location/') <> 1
                    then
                        Error(
                            'Shopify Location ID %1 does not have a valid Shopify Location GID format.',
                            Mapping."Shopify Location ID");

                    if Mapping."Default for Order Imports" then
                        DefaultCount += 1;
                end;
            until Mapping.Next() = 0;

        if ActiveMappedCount = 0 then
            Error(
                'Use Location Mappings is enabled, but no complete active location mapping exists.');

        if DefaultCount = 0 then
            Error(
                'Use Location Mappings is enabled, but no active location mapping is marked Default for Order Imports.');

        if DefaultCount > 1 then
            Error(
                'More than one active Shopify Location Mapping is marked Default for Order Imports.');
    end;

    local procedure GetUniqueAssignedShopifyLocation(
        OrderObject: JsonObject;
        var ShopifyLocationId: Text;
        var MultipleLocations: Boolean)
    var
        FulfillmentOrdersObject: JsonObject;
        FulfillmentOrderObject: JsonObject;
        AssignedLocationObject: JsonObject;
        LocationObject: JsonObject;
        NodesArray: JsonArray;
        Token: JsonToken;
        CurrentLocationId: Text;
        I: Integer;
    begin
        ShopifyLocationId := '';
        MultipleLocations := false;

        if not TryGetObject(
            OrderObject,
            'fulfillmentOrders',
            FulfillmentOrdersObject)
        then
            exit;

        if not TryGetArray(
            FulfillmentOrdersObject,
            'nodes',
            NodesArray)
        then
            exit;

        if NodesArray.Count() = 0 then
            exit;

        for I := 0 to NodesArray.Count() - 1 do begin
            NodesArray.Get(I, Token);
            FulfillmentOrderObject := Token.AsObject();

            if TryGetObject(
                FulfillmentOrderObject,
                'assignedLocation',
                AssignedLocationObject)
            then
                if TryGetObject(
                    AssignedLocationObject,
                    'location',
                    LocationObject)
                then begin
                    CurrentLocationId := GetOptionalText(LocationObject, 'id');

                    if CurrentLocationId <> '' then begin
                        if ShopifyLocationId = '' then
                            ShopifyLocationId := CurrentLocationId
                        else
                            if ShopifyLocationId <> CurrentLocationId then begin
                                MultipleLocations := true;
                                exit;
                            end;
                    end;
                end;
        end;
    end;

    local procedure TryGetBCLocationCode(
        ShopifyLocationId: Text;
        var BCLocationCode: Code[10]): Boolean
    var
        Mapping: Record "Shopify Location Mapping";
    begin
        BCLocationCode := '';

        Mapping.SetRange("Shopify Location ID", ShopifyLocationId);
        Mapping.SetRange(Active, true);

        if not Mapping.FindFirst() then
            exit(false);

        if Mapping."BC Location Code" = '' then
            exit(false);

        BCLocationCode := Mapping."BC Location Code";
        exit(true);
    end;

    local procedure GetDefaultOrderLocation(
        var BCLocationCode: Code[10];
        var ShopifyLocationId: Text)
    var
        Mapping: Record "Shopify Location Mapping";
    begin
        Mapping.SetRange(Active, true);
        Mapping.SetRange("Default for Order Imports", true);

        if not Mapping.FindFirst() then
            Error(
                'No active Shopify Location Mapping is marked Default for Order Imports.');

        Mapping.TestField("BC Location Code");
        Mapping.TestField("Shopify Location ID");

        BCLocationCode := Mapping."BC Location Code";
        ShopifyLocationId := Mapping."Shopify Location ID";
    end;

    local procedure UpsertLocation(
        ShopifyLocationId: Text;
        ShopifyLocationName: Text)
    var
        Mapping: Record "Shopify Location Mapping";
        NewMapping: Boolean;
    begin
        Mapping.SetRange("Shopify Location ID", ShopifyLocationId);
        NewMapping := not Mapping.FindFirst();
        Mapping.SetRange("Shopify Location ID");

        if NewMapping then begin
            Mapping.Init();
            Mapping."Shopify Location ID" :=
                CopyStr(
                    ShopifyLocationId,
                    1,
                    MaxStrLen(Mapping."Shopify Location ID"));
            Mapping.Active := true;
        end;

        Mapping."Shopify Location Name" :=
            CopyStr(
                ShopifyLocationName,
                1,
                MaxStrLen(Mapping."Shopify Location Name"));

        Mapping."Last Refreshed At" := CurrentDateTime();

        if NewMapping then
            Mapping.Insert(true)
        else
            Mapping.Modify(true);
    end;

    local procedure SeedLegacyLocationMapping()
    var
        ShopifySetup: Record "Shopify Integration Setup";
        Mapping: Record "Shopify Location Mapping";
    begin
        GetSetup(ShopifySetup);

        if (ShopifySetup."Shopify Location ID" = '') or
           (ShopifySetup."BC Location Code" = '')
        then
            exit;

        Mapping.SetRange(
            "Shopify Location ID",
            ShopifySetup."Shopify Location ID");

        if not Mapping.FindFirst() then
            exit;

        if Mapping."BC Location Code" = '' then begin
            Mapping.Validate(
                "BC Location Code",
                ShopifySetup."BC Location Code");
            Mapping.Modify(true);
        end;
    end;

    local procedure EnsureDefaultForSingleMappedLocation()
    var
        Mapping: Record "Shopify Location Mapping";
        SingleEntryNo: Integer;
        CompleteCount: Integer;
        ExistingDefaultCount: Integer;
    begin
        Mapping.SetRange(Active, true);
        Mapping.SetFilter("BC Location Code", '<>%1', '');
        Mapping.SetFilter("Shopify Location ID", '<>%1', '');

        if Mapping.FindSet() then
            repeat
                CompleteCount += 1;
                SingleEntryNo := Mapping."Entry No.";

                if Mapping."Default for Order Imports" then
                    ExistingDefaultCount += 1;
            until Mapping.Next() = 0;

        if (CompleteCount <> 1) or
           (ExistingDefaultCount <> 0)
        then
            exit;

        if Mapping.Get(SingleEntryNo) then begin
            Mapping.Validate(
                "Default for Order Imports",
                true);
            Mapping.Modify(true);
        end;
    end;

    local procedure GetSetup(var ShopifySetup: Record "Shopify Integration Setup")
    begin
        if not ShopifySetup.Get('SETUP') then
            Error('Shopify Integration Setup does not exist.');
    end;

    local procedure TryGetObject(
        ParentObject: JsonObject;
        PropertyName: Text;
        var ResultObject: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        Clear(ResultObject);

        if not ParentObject.Get(PropertyName, Token) then
            exit(false);

        if Token.IsValue() then
            if Token.AsValue().IsNull() then
                exit(false);

        if not Token.IsObject() then
            exit(false);

        ResultObject := Token.AsObject();
        exit(true);
    end;

    local procedure TryGetArray(
        ParentObject: JsonObject;
        PropertyName: Text;
        var ResultArray: JsonArray): Boolean
    var
        Token: JsonToken;
    begin
        Clear(ResultArray);

        if not ParentObject.Get(PropertyName, Token) then
            exit(false);

        if not Token.IsArray() then
            exit(false);

        ResultArray := Token.AsArray();
        exit(true);
    end;

    local procedure GetOptionalText(
        ParentObject: JsonObject;
        PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not ParentObject.Get(PropertyName, Token) then
            exit('');

        if not Token.IsValue() then
            exit('');

        if Token.AsValue().IsNull() then
            exit('');

        exit(Token.AsValue().AsText());
    end;

    local procedure GetBoolean(
        ParentObject: JsonObject;
        PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not ParentObject.Get(PropertyName, Token) then
            Error('JSON property %1 was not found.', PropertyName);

        exit(Token.AsValue().AsBoolean());
    end;
}
