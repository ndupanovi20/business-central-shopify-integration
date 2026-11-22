codeunit 50245 "Shopify Fulfillment Mgt."
{
    procedure ProcessBackgroundFulfillmentWork(
        ShowResultMessage: Boolean): Integer
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        CreatedCount: Integer;
        TrackingUpdateCount: Integer;
    begin
        GetSetup(
            ShopifySetup);

        if ShopifySetup."Auto Create Fulfillment" then
            CreatedCount :=
                ProcessEligibleFulfillments(
                    false);

        if ShopifySetup."Auto Sync Fulfillment Tracking" then
            TrackingUpdateCount :=
                ProcessTrackingUpdates(
                    false);

        if ShowResultMessage then
            Message(
                'Shopify fulfillment background work completed.\Fulfillments created: %1\Tracking updates synchronized: %2',
                CreatedCount,
                TrackingUpdateCount);

        exit(
            CreatedCount + TrackingUpdateCount);
    end;

    procedure ProcessEligibleFulfillments(
        ShowResultMessage: Boolean): Integer
    var
        ImportRecord:
            Record "Shopify Order Import";

        FulfillmentEntry:
            Record "Shopify Fulfillment Entry";

        CreatedCount: Integer;
        WaitingCount: Integer;
        ExistingCount: Integer;
        ErrorCount: Integer;
    begin
        ImportRecord.Reset();

        ImportRecord.SetRange(
            "Posting Status",
            ImportRecord."Posting Status"::Success);

        ImportRecord.SetFilter(
            "Posted Shipment No.",
            '<>%1',
            '');

        if ImportRecord.FindSet() then
            repeat
                if FindFulfillmentEntry(
                    ImportRecord."Shopify Order ID",
                    ImportRecord."Posted Shipment No.",
                    FulfillmentEntry)
                then begin
                    case FulfillmentEntry.Status of
                        FulfillmentEntry.Status::Success,
                        FulfillmentEntry.Status::Skipped:
                            ExistingCount += 1;

                        FulfillmentEntry.Status::Error:
                            ErrorCount += 1;

                        FulfillmentEntry.Status::Pending,
                        FulfillmentEntry.Status::"Waiting for Tracking":
                            begin
                                if CreateFulfillmentForImport(
                                    ImportRecord,
                                    false)
                                then
                                    CreatedCount += 1
                                else begin
                                    FulfillmentEntry.Get(
                                        FulfillmentEntry."Entry No.");

                                    if FulfillmentEntry.Status =
                                       FulfillmentEntry.Status::"Waiting for Tracking"
                                    then
                                        WaitingCount += 1
                                    else
                                        if FulfillmentEntry.Status =
                                           FulfillmentEntry.Status::Error
                                        then
                                            ErrorCount += 1;
                                end;
                            end;
                    end;
                end else begin
                    if CreateFulfillmentForImport(
                        ImportRecord,
                        false)
                    then
                        CreatedCount += 1
                    else begin
                        if FindFulfillmentEntry(
                            ImportRecord."Shopify Order ID",
                            ImportRecord."Posted Shipment No.",
                            FulfillmentEntry)
                        then begin
                            if FulfillmentEntry.Status =
                               FulfillmentEntry.Status::"Waiting for Tracking"
                            then
                                WaitingCount += 1
                            else
                                if FulfillmentEntry.Status =
                                   FulfillmentEntry.Status::Error
                                then
                                    ErrorCount += 1;
                        end;
                    end;
                end;
            until ImportRecord.Next() = 0;

        if ShowResultMessage then
            Message(
                'Shopify fulfillment processing completed.\Created: %1\Waiting for tracking: %2\Already completed/skipped: %3\Errors requiring retry: %4',
                CreatedCount,
                WaitingCount,
                ExistingCount,
                ErrorCount);

        exit(
            CreatedCount);
    end;

    procedure CreateFulfillmentForImport(
        ImportRecord: Record "Shopify Order Import";
        ShowResultMessage: Boolean): Boolean
    var
        FulfillmentEntry:
            Record "Shopify Fulfillment Entry";

        Runner:
            Codeunit "Shopify Fulfillment Runner";

        SyncLogMgt:
            Codeunit "Shopify Sync Log Mgt.";

        StartedAt: DateTime;
        ErrorText: Text;
        EntryNo: Integer;
    begin
        ValidateImportForFulfillment(
            ImportRecord);

        PrepareFulfillmentEntry(
            ImportRecord,
            FulfillmentEntry);

        if FulfillmentEntry.Status =
           FulfillmentEntry.Status::Success
        then begin
            if ShowResultMessage then
                Message(
                    'Shopify fulfillment already exists for order %1 and posted shipment %2.',
                    ImportRecord."Shopify Order Name",
                    ImportRecord."Posted Shipment No.");

            exit(true);
        end;

        if FulfillmentEntry.Status =
           FulfillmentEntry.Status::Skipped
        then begin
            if ShowResultMessage then
                Message(
                    'Shopify fulfillment for order %1 is marked as skipped.\%2',
                    ImportRecord."Shopify Order Name",
                    FulfillmentEntry."Result Message");

            exit(false);
        end;

        FulfillmentEntry.Status :=
            FulfillmentEntry.Status::Pending;

        FulfillmentEntry."Attempt Count" +=
            1;

        FulfillmentEntry."Last Attempt At" :=
            CurrentDateTime();

        Clear(
            FulfillmentEntry."Fulfillment Error");

        FulfillmentEntry.Modify(false);

        EntryNo :=
            FulfillmentEntry."Entry No.";

        StartedAt :=
            CurrentDateTime();

        Commit();

        ClearLastError();

        if Runner.Run(
            FulfillmentEntry)
        then begin
            FulfillmentEntry.Get(
                EntryNo);

            case FulfillmentEntry.Status of
                FulfillmentEntry.Status::Success:
                    begin
                        SyncLogMgt.LogSuccess(
                            "Shopify Sync Direction"::Outbound,
                            "Shopify Sync Entity"::Fulfillment,
                            FulfillmentEntry."Posted Shipment No.",
                            FulfillmentEntry."Shopify Order ID",
                            StrSubstNo(
                                'Shopify fulfillment %1 created for order %2 from Business Central posted shipment %3.',
                                FulfillmentEntry."Shopify Fulfillment ID",
                                FulfillmentEntry."Shopify Order Name",
                                FulfillmentEntry."Posted Shipment No."),
                            CurrentDateTime() - StartedAt);

                        if ShowResultMessage then
                            Message(
                                'Shopify fulfillment was created successfully.\Order: %1\Posted shipment: %2\Shopify fulfillment: %3',
                                FulfillmentEntry."Shopify Order Name",
                                FulfillmentEntry."Posted Shipment No.",
                                FulfillmentEntry."Shopify Fulfillment ID");

                        exit(true);
                    end;

                FulfillmentEntry.Status::"Waiting for Tracking":
                    begin
                        SyncLogMgt.LogInfo(
                            "Shopify Sync Direction"::System,
                            "Shopify Sync Entity"::Fulfillment,
                            FulfillmentEntry."Posted Shipment No.",
                            FulfillmentEntry."Shopify Order ID",
                            FulfillmentEntry."Result Message");

                        if ShowResultMessage then
                            Message(
                                'Shopify fulfillment is waiting for tracking information.\%1',
                                FulfillmentEntry."Result Message");

                        exit(false);
                    end;

                FulfillmentEntry.Status::Skipped:
                    begin
                        SyncLogMgt.LogInfo(
                            "Shopify Sync Direction"::System,
                            "Shopify Sync Entity"::Fulfillment,
                            FulfillmentEntry."Posted Shipment No.",
                            FulfillmentEntry."Shopify Order ID",
                            FulfillmentEntry."Result Message");

                        if ShowResultMessage then
                            Message(
                                'Shopify fulfillment was skipped.\%1',
                                FulfillmentEntry."Result Message");

                        exit(false);
                    end;
            end;

            exit(false);
        end;

        ErrorText :=
            GetLastErrorText();

        if ErrorText = '' then
            ErrorText :=
                'Unknown error while creating Shopify fulfillment.';

        FulfillmentEntry.Get(
            EntryNo);

        FulfillmentEntry.Status :=
            FulfillmentEntry.Status::Error;

        FulfillmentEntry."Fulfillment Error" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(
                    FulfillmentEntry."Fulfillment Error"));

        FulfillmentEntry."Result Message" :=
            CopyStr(
                'Shopify fulfillment creation failed.',
                1,
                MaxStrLen(
                    FulfillmentEntry."Result Message"));

        FulfillmentEntry.Modify(false);

        SyncLogMgt.LogError(
            "Shopify Sync Direction"::Outbound,
            "Shopify Sync Entity"::Fulfillment,
            FulfillmentEntry."Posted Shipment No.",
            FulfillmentEntry."Shopify Order ID",
            ErrorText,
            CurrentDateTime() - StartedAt);

        if ShowResultMessage then
            Message(
                'Shopify fulfillment creation failed for order %1.\%2',
                FulfillmentEntry."Shopify Order Name",
                ErrorText);

        exit(false);
    end;

    procedure CreateFulfillmentCore(
        var FulfillmentEntry: Record "Shopify Fulfillment Entry")
    var
        ImportRecord:
            Record "Shopify Order Import";

        ShopifySetup:
            Record "Shopify Integration Setup";

        SalesShipmentHeader:
            Record "Sales Shipment Header";

        LocationMgt:
            Codeunit "Shopify Location Mgt.";

        LineItemsByFulfillmentOrder:
            JsonArray;

        TrackingNo: Text;
        TrackingCompany: Text;
        TrackingUrl: Text;
        FulfillmentOrderIdsText: Text;
        ShopifyFulfillmentId: Text;
        ShopifyFulfillmentStatus: Text;
        ShopifyLocationId: Text;

        AlreadyClosed: Boolean;
    begin
        GetSetup(
            ShopifySetup);

        if not ImportRecord.Get(
            FulfillmentEntry."Shopify Order ID")
        then
            Error(
                'Shopify Order Import %1 does not exist.',
                FulfillmentEntry."Shopify Order ID");

        ValidateImportForFulfillment(
            ImportRecord);

        if not SalesShipmentHeader.Get(
            ImportRecord."Posted Shipment No.")
        then
            Error(
                'Posted Sales Shipment %1 does not exist.',
                ImportRecord."Posted Shipment No.");

        ShopifyLocationId :=
            LocationMgt.ResolveShopifyLocationId(
                SalesShipmentHeader."Location Code");

        GetTrackingFromShipment(
            SalesShipmentHeader,
            TrackingNo,
            TrackingCompany,
            TrackingUrl);

        if ShopifySetup."Require Tracking No." and
           (TrackingNo = '')
        then begin
            FulfillmentEntry.Status :=
                FulfillmentEntry.Status::"Waiting for Tracking";

            FulfillmentEntry."Result Message" :=
                CopyStr(
                    StrSubstNo(
                        'Posted shipment %1 has no Package Tracking No. Fulfillment will be created after tracking is entered.',
                        SalesShipmentHeader."No."),
                    1,
                    MaxStrLen(
                        FulfillmentEntry."Result Message"));

            Clear(
                FulfillmentEntry."Fulfillment Error");

            FulfillmentEntry.Modify(false);

            exit;
        end;

        GetOpenFulfillmentOrders(
            FulfillmentEntry."Shopify Order ID",
            ShopifyLocationId,
            LineItemsByFulfillmentOrder,
            FulfillmentOrderIdsText,
            AlreadyClosed);

        if AlreadyClosed then begin
            FulfillmentEntry.Status :=
                FulfillmentEntry.Status::Skipped;

            FulfillmentEntry."Result Message" :=
                CopyStr(
                    'Shopify fulfillment order is already closed. No additional fulfillment was created.',
                    1,
                    MaxStrLen(
                        FulfillmentEntry."Result Message"));

            FulfillmentEntry."Fulfillment Order IDs" :=
                CopyStr(
                    FulfillmentOrderIdsText,
                    1,
                    MaxStrLen(
                        FulfillmentEntry."Fulfillment Order IDs"));

            Clear(
                FulfillmentEntry."Fulfillment Error");

            FulfillmentEntry.Modify(false);

            exit;
        end;

        CreateShopifyFulfillment(
            LineItemsByFulfillmentOrder,
            TrackingNo,
            TrackingCompany,
            TrackingUrl,
            ShopifySetup."Notify Customer on Fulfillment",
            ShopifyFulfillmentId,
            ShopifyFulfillmentStatus);

        if ShopifyFulfillmentId = '' then
            Error(
                'Shopify fulfillment was created without returning a fulfillment ID.');

        if (ShopifyFulfillmentStatus = 'ERROR') or
           (ShopifyFulfillmentStatus = 'FAILURE') or
           (ShopifyFulfillmentStatus = 'CANCELLED')
        then
            Error(
                'Shopify fulfillment returned status %1.',
                ShopifyFulfillmentStatus);

        FulfillmentEntry."Shopify Fulfillment ID" :=
            CopyStr(
                ShopifyFulfillmentId,
                1,
                MaxStrLen(
                    FulfillmentEntry."Shopify Fulfillment ID"));

        FulfillmentEntry."Fulfillment Order IDs" :=
            CopyStr(
                FulfillmentOrderIdsText,
                1,
                MaxStrLen(
                    FulfillmentEntry."Fulfillment Order IDs"));

        FulfillmentEntry."Shopify Location ID" :=
            CopyStr(
                ShopifyLocationId,
                1,
                MaxStrLen(
                    FulfillmentEntry."Shopify Location ID"));

        FulfillmentEntry.Status :=
            FulfillmentEntry.Status::Success;

        FulfillmentEntry."Fulfilled At" :=
            CurrentDateTime();

        FulfillmentEntry."Notify Customer" :=
            ShopifySetup."Notify Customer on Fulfillment";

        FulfillmentEntry."Tracking No." :=
            CopyStr(
                TrackingNo,
                1,
                MaxStrLen(
                    FulfillmentEntry."Tracking No."));

        FulfillmentEntry."Tracking Company" :=
            CopyStr(
                TrackingCompany,
                1,
                MaxStrLen(
                    FulfillmentEntry."Tracking Company"));

        FulfillmentEntry."Tracking URL" :=
            CopyStr(
                TrackingUrl,
                1,
                MaxStrLen(
                    FulfillmentEntry."Tracking URL"));

        if TrackingNo <> '' then
            FulfillmentEntry."Tracking Synced At" :=
                CurrentDateTime();

        FulfillmentEntry."Result Message" :=
            CopyStr(
                StrSubstNo(
                    'Shopify fulfillment %1 created successfully with status %2.',
                    ShopifyFulfillmentId,
                    ShopifyFulfillmentStatus),
                1,
                MaxStrLen(
                    FulfillmentEntry."Result Message"));

        Clear(
            FulfillmentEntry."Fulfillment Error");

        Clear(
            FulfillmentEntry."Tracking Error");

        FulfillmentEntry.Modify(false);
    end;

    procedure RetryFailedFulfillments()
    var
        FulfillmentEntry:
            Record "Shopify Fulfillment Entry";

        ImportRecord:
            Record "Shopify Order Import";

        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::Error);

        if not FulfillmentEntry.FindSet() then begin
            Message(
                'There are no failed Shopify fulfillment entries to retry.');

            exit;
        end;

        repeat
            if ImportRecord.Get(
                FulfillmentEntry."Shopify Order ID")
            then begin
                if CreateFulfillmentForImport(
                    ImportRecord,
                    false)
                then
                    SuccessCount += 1
                else
                    ErrorCount += 1;
            end else
                ErrorCount += 1;
        until FulfillmentEntry.Next() = 0;

        Message(
            'Shopify fulfillment retry completed.\Successful: %1\Failed: %2',
            SuccessCount,
            ErrorCount);
    end;

    procedure RetryFulfillmentEntry(
        var FulfillmentEntry: Record "Shopify Fulfillment Entry";
        ShowResultMessage: Boolean): Boolean
    var
        ImportRecord:
            Record "Shopify Order Import";
    begin
        if not ImportRecord.Get(
            FulfillmentEntry."Shopify Order ID")
        then
            Error(
                'Shopify Order Import %1 does not exist.',
                FulfillmentEntry."Shopify Order ID");

        exit(
            CreateFulfillmentForImport(
                ImportRecord,
                ShowResultMessage));
    end;

    procedure ProcessTrackingUpdates(
        ShowResultMessage: Boolean): Integer
    var
        FulfillmentEntry:
            Record "Shopify Fulfillment Entry";

        UpdatedCount: Integer;
        ErrorCount: Integer;
    begin
        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::Success);

        FulfillmentEntry.SetFilter(
            "Shopify Fulfillment ID",
            '<>%1',
            '');

        if FulfillmentEntry.FindSet() then
            repeat
                if TrackingNeedsUpdate(
                    FulfillmentEntry)
                then begin
                    if SyncTrackingForEntry(
                        FulfillmentEntry,
                        false)
                    then
                        UpdatedCount += 1
                    else
                        ErrorCount += 1;
                end;
            until FulfillmentEntry.Next() = 0;

        if ShowResultMessage then
            Message(
                'Shopify fulfillment tracking synchronization completed.\Updated: %1\Errors: %2',
                UpdatedCount,
                ErrorCount);

        exit(
            UpdatedCount);
    end;

    procedure SyncTrackingForImport(
        ImportRecord: Record "Shopify Order Import";
        ShowResultMessage: Boolean): Boolean
    var
        FulfillmentEntry:
            Record "Shopify Fulfillment Entry";

        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        FulfillmentEntry.SetRange(
            "Shopify Order ID",
            ImportRecord."Shopify Order ID");

        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::Success);

        if not FulfillmentEntry.FindSet() then
            Error(
                'No successful Shopify fulfillment entry exists for order %1.',
                ImportRecord."Shopify Order Name");

        repeat
            if SyncTrackingForEntry(
                FulfillmentEntry,
                false)
            then
                SuccessCount += 1
            else
                ErrorCount += 1;
        until FulfillmentEntry.Next() = 0;

        if ShowResultMessage then
            Message(
                'Shopify tracking synchronization completed for order %1.\Successful: %2\Failed or unchanged: %3',
                ImportRecord."Shopify Order Name",
                SuccessCount,
                ErrorCount);

        exit(
            SuccessCount > 0);
    end;

    procedure SyncTrackingForEntry(
        var FulfillmentEntry: Record "Shopify Fulfillment Entry";
        ShowResultMessage: Boolean): Boolean
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        SalesShipmentHeader:
            Record "Sales Shipment Header";

        SyncLogMgt:
            Codeunit "Shopify Sync Log Mgt.";

        TrackingNo: Text;
        TrackingCompany: Text;
        TrackingUrl: Text;
        ErrorText: Text;
        StartedAt: DateTime;
    begin
        GetSetup(
            ShopifySetup);

        FulfillmentEntry.TestField(
            "Shopify Fulfillment ID");

        FulfillmentEntry.TestField(
            "Posted Shipment No.");

        if not SalesShipmentHeader.Get(
            FulfillmentEntry."Posted Shipment No.")
        then
            Error(
                'Posted Sales Shipment %1 does not exist.',
                FulfillmentEntry."Posted Shipment No.");

        GetTrackingFromShipment(
            SalesShipmentHeader,
            TrackingNo,
            TrackingCompany,
            TrackingUrl);

        if TrackingNo = '' then begin
            if ShowResultMessage then
                Message(
                    'Posted shipment %1 has no Package Tracking No. There is no tracking information to send to Shopify.',
                    SalesShipmentHeader."No.");

            exit(false);
        end;

        if TrackingMatchesEntry(
            FulfillmentEntry,
            TrackingNo,
            TrackingCompany,
            TrackingUrl)
        then begin
            if ShowResultMessage then
                Message(
                    'Shopify tracking information is already synchronized for posted shipment %1.',
                    SalesShipmentHeader."No.");

            exit(false);
        end;

        StartedAt :=
            CurrentDateTime();

        ClearLastError();

        if TryUpdateTrackingRemote(
            FulfillmentEntry."Shopify Fulfillment ID",
            TrackingNo,
            TrackingCompany,
            TrackingUrl,
            ShopifySetup."Notify Customer on Fulfillment")
        then begin
            FulfillmentEntry."Tracking No." :=
                CopyStr(
                    TrackingNo,
                    1,
                    MaxStrLen(
                        FulfillmentEntry."Tracking No."));

            FulfillmentEntry."Tracking Company" :=
                CopyStr(
                    TrackingCompany,
                    1,
                    MaxStrLen(
                        FulfillmentEntry."Tracking Company"));

            FulfillmentEntry."Tracking URL" :=
                CopyStr(
                    TrackingUrl,
                    1,
                    MaxStrLen(
                        FulfillmentEntry."Tracking URL"));

            FulfillmentEntry."Tracking Synced At" :=
                CurrentDateTime();

            FulfillmentEntry."Notify Customer" :=
                ShopifySetup."Notify Customer on Fulfillment";

            Clear(
                FulfillmentEntry."Tracking Error");

            FulfillmentEntry.Modify(false);

            SyncLogMgt.LogSuccess(
                "Shopify Sync Direction"::Outbound,
                "Shopify Sync Entity"::Fulfillment,
                FulfillmentEntry."Posted Shipment No.",
                FulfillmentEntry."Shopify Fulfillment ID",
                StrSubstNo(
                    'Tracking %1 synchronized to Shopify fulfillment %2.',
                    TrackingNo,
                    FulfillmentEntry."Shopify Fulfillment ID"),
                CurrentDateTime() - StartedAt);

            if ShowResultMessage then
                Message(
                    'Tracking information was synchronized to Shopify successfully.\Tracking No.: %1\Company: %2',
                    TrackingNo,
                    TrackingCompany);

            exit(true);
        end;

        ErrorText :=
            GetLastErrorText();

        if ErrorText = '' then
            ErrorText :=
                'Unknown error while updating Shopify fulfillment tracking.';

        FulfillmentEntry."Tracking Error" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(
                    FulfillmentEntry."Tracking Error"));

        FulfillmentEntry.Modify(false);

        SyncLogMgt.LogError(
            "Shopify Sync Direction"::Outbound,
            "Shopify Sync Entity"::Fulfillment,
            FulfillmentEntry."Posted Shipment No.",
            FulfillmentEntry."Shopify Fulfillment ID",
            ErrorText,
            CurrentDateTime() - StartedAt);

        if ShowResultMessage then
            Message(
                'Shopify tracking synchronization failed.\%1',
                ErrorText);

        exit(false);
    end;

    local procedure PrepareFulfillmentEntry(
        ImportRecord: Record "Shopify Order Import";
        var FulfillmentEntry: Record "Shopify Fulfillment Entry")
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        SalesShipmentHeader:
            Record "Sales Shipment Header";

        LocationMgt:
            Codeunit "Shopify Location Mgt.";

        ShopifyLocationId: Text;
    begin
        GetSetup(
            ShopifySetup);

        if FindFulfillmentEntry(
            ImportRecord."Shopify Order ID",
            ImportRecord."Posted Shipment No.",
            FulfillmentEntry)
        then
            exit;

        if not SalesShipmentHeader.Get(
            ImportRecord."Posted Shipment No.")
        then
            Error(
                'Posted Sales Shipment %1 does not exist.',
                ImportRecord."Posted Shipment No.");

        ShopifyLocationId :=
            LocationMgt.ResolveShopifyLocationId(
                SalesShipmentHeader."Location Code");

        FulfillmentEntry.Init();

        FulfillmentEntry."Shopify Order ID" :=
            ImportRecord."Shopify Order ID";

        FulfillmentEntry."Shopify Order Name" :=
            ImportRecord."Shopify Order Name";

        FulfillmentEntry."BC Order No." :=
            ImportRecord."BC Order No.";

        FulfillmentEntry."Posted Shipment No." :=
            ImportRecord."Posted Shipment No.";

        FulfillmentEntry."Shopify Location ID" :=
            CopyStr(
                ShopifyLocationId,
                1,
                MaxStrLen(
                    FulfillmentEntry."Shopify Location ID"));

        FulfillmentEntry.Status :=
            FulfillmentEntry.Status::Pending;

        FulfillmentEntry."Notify Customer" :=
            ShopifySetup."Notify Customer on Fulfillment";

        FulfillmentEntry.Insert(true);
    end;

    local procedure ValidateImportForFulfillment(
        ImportRecord: Record "Shopify Order Import")
    begin
        ImportRecord.TestField(
            "Shopify Order ID");

        ImportRecord.TestField(
            "Posted Shipment No.");

        if ImportRecord."Posting Status" <>
           ImportRecord."Posting Status"::Success
        then
            Error(
                'Shopify order %1 has not completed Business Central posting successfully.',
                ImportRecord."Shopify Order Name");

        if StrPos(
            ImportRecord."Shopify Order ID",
            'gid://shopify/Order/') <> 1
        then
            Error(
                'Shopify Order ID %1 is not a valid Shopify Order GID.',
                ImportRecord."Shopify Order ID");
    end;

    local procedure FindFulfillmentEntry(
        ShopifyOrderId: Text;
        PostedShipmentNo: Code[20];
        var FulfillmentEntry: Record "Shopify Fulfillment Entry"): Boolean
    begin
        FulfillmentEntry.Reset();

        FulfillmentEntry.SetRange(
            "Shopify Order ID",
            ShopifyOrderId);

        FulfillmentEntry.SetRange(
            "Posted Shipment No.",
            PostedShipmentNo);

        exit(
            FulfillmentEntry.FindFirst());
    end;

    local procedure GetOpenFulfillmentOrders(
        ShopifyOrderId: Text;
        ShopifyLocationId: Text;
        var LineItemsByFulfillmentOrder: JsonArray;
        var FulfillmentOrderIdsText: Text;
        var AlreadyClosed: Boolean)
    var
        ShopifyClient:
            Codeunit "Shopify Client";

        Variables:
            JsonObject;

        ResponseJson:
            JsonObject;

        DataObject:
            JsonObject;

        OrderObject:
            JsonObject;

        FulfillmentOrdersObject:
            JsonObject;

        FulfillmentOrderObject:
            JsonObject;

        AssignedLocationObject:
            JsonObject;

        LocationObject:
            JsonObject;

        FulfillmentOrderInput:
            JsonObject;

        NodesArray:
            JsonArray;

        Token:
            JsonToken;

        QueryText: Text;
        FulfillmentOrderId: Text;
        StatusText: Text;
        LocationId: Text;
        BlockingStatuses: Text;

        I: Integer;
        MatchingLocationCount: Integer;
        ClosedCount: Integer;
        OtherLocationCount: Integer;
    begin
        Clear(
            LineItemsByFulfillmentOrder);

        FulfillmentOrderIdsText :=
            '';

        AlreadyClosed :=
            false;

        Variables.Add(
            'id',
            ShopifyOrderId);

        QueryText :=
            'query GetOrderFulfillmentOrders($id: ID!) {' +
            ' order(id: $id) {' +
            '  id' +
            '  fulfillmentOrders(first: 50) {' +
            '   nodes {' +
            '    id' +
            '    status' +
            '    assignedLocation {' +
            '     location { id }' +
            '    }' +
            '   }' +
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

        OrderObject :=
            ShopifyClient.GetObject(
                DataObject,
                'order');

        FulfillmentOrdersObject :=
            ShopifyClient.GetObject(
                OrderObject,
                'fulfillmentOrders');

        NodesArray :=
            ShopifyClient.GetArray(
                FulfillmentOrdersObject,
                'nodes');

        if NodesArray.Count() = 0 then
            Error(
                'Shopify order has no fulfillment orders.');

        for I := 0 to NodesArray.Count() - 1 do begin
            NodesArray.Get(
                I,
                Token);

            FulfillmentOrderObject :=
                Token.AsObject();

            FulfillmentOrderId :=
                ShopifyClient.GetText(
                    FulfillmentOrderObject,
                    'id');

            StatusText :=
                UpperCase(
                    ShopifyClient.GetText(
                        FulfillmentOrderObject,
                        'status'));

            AssignedLocationObject :=
                ShopifyClient.GetObject(
                    FulfillmentOrderObject,
                    'assignedLocation');

            LocationObject :=
                ShopifyClient.GetObject(
                    AssignedLocationObject,
                    'location');

            LocationId :=
                ShopifyClient.GetText(
                    LocationObject,
                    'id');

            if LocationId = ShopifyLocationId then begin
                MatchingLocationCount += 1;

                case StatusText of
                    'OPEN':
                        begin
                            AddFulfillmentOrderIdToText(
                                FulfillmentOrderIdsText,
                                FulfillmentOrderId);

                            Clear(
                                FulfillmentOrderInput);

                            FulfillmentOrderInput.Add(
                                'fulfillmentOrderId',
                                FulfillmentOrderId);

                            LineItemsByFulfillmentOrder.Add(
                                FulfillmentOrderInput);
                        end;

                    'CLOSED':
                        ClosedCount += 1;

                    else begin
                        if BlockingStatuses <> '' then
                            BlockingStatuses +=
                                ', ';

                        BlockingStatuses +=
                            StatusText;
                    end;
                end;
            end else
                OtherLocationCount += 1;
        end;

        if LineItemsByFulfillmentOrder.Count() > 0 then
            exit;

        if (MatchingLocationCount = 0) and
           (OtherLocationCount > 0)
        then
            Error(
                'Shopify fulfillment orders exist, but none are assigned to configured Shopify Location ID %1.',
                ShopifyLocationId);

        if MatchingLocationCount = 0 then
            Error(
                'No Shopify fulfillment order was found for configured location %1.',
                ShopifyLocationId);

        if ClosedCount = MatchingLocationCount then begin
            AlreadyClosed :=
                true;

            exit;
        end;

        if BlockingStatuses <> '' then
            Error(
                'Shopify fulfillment orders at configured location are not ready for fulfillment. Current status(es): %1.',
                BlockingStatuses);

        Error(
            'No OPEN Shopify fulfillment order is available for fulfillment.');
    end;

    local procedure CreateShopifyFulfillment(
        LineItemsByFulfillmentOrder: JsonArray;
        TrackingNo: Text;
        TrackingCompany: Text;
        TrackingUrl: Text;
        NotifyCustomer: Boolean;
        var ShopifyFulfillmentId: Text;
        var ShopifyFulfillmentStatus: Text)
    var
        ShopifyClient:
            Codeunit "Shopify Client";

        Variables:
            JsonObject;

        FulfillmentInput:
            JsonObject;

        TrackingInput:
            JsonObject;

        ResponseJson:
            JsonObject;

        DataObject:
            JsonObject;

        PayloadObject:
            JsonObject;

        FulfillmentObject:
            JsonObject;

        QueryText: Text;
    begin
        ShopifyFulfillmentId :=
            '';

        ShopifyFulfillmentStatus :=
            '';

        FulfillmentInput.Add(
            'lineItemsByFulfillmentOrder',
            LineItemsByFulfillmentOrder);

        FulfillmentInput.Add(
            'notifyCustomer',
            NotifyCustomer);

        if TrackingNo <> '' then begin
            TrackingInput.Add(
                'number',
                TrackingNo);

            if TrackingCompany <> '' then
                TrackingInput.Add(
                    'company',
                    TrackingCompany);

            if TrackingUrl <> '' then
                TrackingInput.Add(
                    'url',
                    TrackingUrl);

            FulfillmentInput.Add(
                'trackingInfo',
                TrackingInput);
        end;

        Variables.Add(
            'fulfillment',
            FulfillmentInput);

        QueryText :=
            'mutation CreateFulfillment($fulfillment: FulfillmentInput!) {' +
            ' fulfillmentCreate(fulfillment: $fulfillment) {' +
            '  fulfillment {' +
            '   id' +
            '   status' +
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
                'fulfillmentCreate');

        ShopifyClient.CheckUserErrors(
            PayloadObject);

        FulfillmentObject :=
            ShopifyClient.GetObject(
                PayloadObject,
                'fulfillment');

        ShopifyFulfillmentId :=
            ShopifyClient.GetText(
                FulfillmentObject,
                'id');

        ShopifyFulfillmentStatus :=
            UpperCase(
                ShopifyClient.GetText(
                    FulfillmentObject,
                    'status'));
    end;

    [TryFunction]
    local procedure TryUpdateTrackingRemote(
        ShopifyFulfillmentId: Text;
        TrackingNo: Text;
        TrackingCompany: Text;
        TrackingUrl: Text;
        NotifyCustomer: Boolean)
    var
        ShopifyClient:
            Codeunit "Shopify Client";

        Variables:
            JsonObject;

        TrackingInput:
            JsonObject;

        ResponseJson:
            JsonObject;

        DataObject:
            JsonObject;

        PayloadObject:
            JsonObject;

        QueryText: Text;
    begin
        TrackingInput.Add(
            'number',
            TrackingNo);

        if TrackingCompany <> '' then
            TrackingInput.Add(
                'company',
                TrackingCompany);

        if TrackingUrl <> '' then
            TrackingInput.Add(
                'url',
                TrackingUrl);

        Variables.Add(
            'fulfillmentId',
            ShopifyFulfillmentId);

        Variables.Add(
            'notifyCustomer',
            NotifyCustomer);

        Variables.Add(
            'trackingInfoInput',
            TrackingInput);

        QueryText :=
            'mutation UpdateFulfillmentTracking(' +
            '$fulfillmentId: ID!, ' +
            '$notifyCustomer: Boolean, ' +
            '$trackingInfoInput: FulfillmentTrackingInput!) {' +
            ' fulfillmentTrackingInfoUpdate(' +
            '  fulfillmentId: $fulfillmentId, ' +
            '  notifyCustomer: $notifyCustomer, ' +
            '  trackingInfoInput: $trackingInfoInput) {' +
            '  fulfillment { id status }' +
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
                'fulfillmentTrackingInfoUpdate');

        ShopifyClient.CheckUserErrors(
            PayloadObject);
    end;

    local procedure GetTrackingFromShipment(
        SalesShipmentHeader: Record "Sales Shipment Header";
        var TrackingNo: Text;
        var TrackingCompany: Text;
        var TrackingUrl: Text)
    var
        ShippingAgent:
            Record "Shipping Agent";

        TrackingNo50: Text[50];
    begin
        TrackingNo :=
            SalesShipmentHeader."Package Tracking No.";

        TrackingCompany :=
            '';

        TrackingUrl :=
            '';

        if SalesShipmentHeader."Shipping Agent Code" = '' then
            exit;

        if ShippingAgent.Get(
            SalesShipmentHeader."Shipping Agent Code")
        then begin
            if ShippingAgent.Name <> '' then
                TrackingCompany :=
                    ShippingAgent.Name
            else
                TrackingCompany :=
                    ShippingAgent.Code;

            if TrackingNo <> '' then begin
                TrackingNo50 :=
                    CopyStr(
                        TrackingNo,
                        1,
                        MaxStrLen(
                            TrackingNo50));

                TrackingUrl :=
                    ShippingAgent.GetTrackingInternetAddr(
                        TrackingNo50);
            end;
        end else
            TrackingCompany :=
                SalesShipmentHeader."Shipping Agent Code";
    end;

    local procedure TrackingNeedsUpdate(
        FulfillmentEntry: Record "Shopify Fulfillment Entry"): Boolean
    var
        SalesShipmentHeader:
            Record "Sales Shipment Header";

        TrackingNo: Text;
        TrackingCompany: Text;
        TrackingUrl: Text;
    begin
        if FulfillmentEntry."Posted Shipment No." = '' then
            exit(false);

        if FulfillmentEntry."Shopify Fulfillment ID" = '' then
            exit(false);

        if not SalesShipmentHeader.Get(
            FulfillmentEntry."Posted Shipment No.")
        then
            exit(false);

        GetTrackingFromShipment(
            SalesShipmentHeader,
            TrackingNo,
            TrackingCompany,
            TrackingUrl);

        if TrackingNo = '' then
            exit(false);

        exit(
            not TrackingMatchesEntry(
                FulfillmentEntry,
                TrackingNo,
                TrackingCompany,
                TrackingUrl));
    end;

    local procedure TrackingMatchesEntry(
        FulfillmentEntry: Record "Shopify Fulfillment Entry";
        TrackingNo: Text;
        TrackingCompany: Text;
        TrackingUrl: Text): Boolean
    begin
        exit(
            (FulfillmentEntry."Tracking No." = TrackingNo) and
            (FulfillmentEntry."Tracking Company" = TrackingCompany) and
            (FulfillmentEntry."Tracking URL" = TrackingUrl) and
            (FulfillmentEntry."Tracking Error" = ''));
    end;

    local procedure AddFulfillmentOrderIdToText(
        var FulfillmentOrderIdsText: Text;
        FulfillmentOrderId: Text)
    begin
        if FulfillmentOrderIdsText <> '' then
            FulfillmentOrderIdsText +=
                '; ';

        FulfillmentOrderIdsText +=
            FulfillmentOrderId;
    end;

    local procedure GetSetup(
        var ShopifySetup: Record "Shopify Integration Setup")
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist.');

        ShopifySetup.TestField(
            "Shopify Location ID");
    end;
}
