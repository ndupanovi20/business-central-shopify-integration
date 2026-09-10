codeunit 50192 "Shopify Order Tag Mgt."
{
    procedure TagImportRecord(
        var ImportRecord: Record "Shopify Order Import";
        ShowResultMessage: Boolean): Boolean
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        SyncLogMgt:
            Codeunit "Shopify Sync Log Mgt.";

        ErrorText: Text;
        TagText: Text;

        StartedAt: DateTime;
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist.');

        TagText :=
            ShopifySetup."Imported Order Tag";

        if TagText = '' then
            TagText :=
                'BC-IMPORTED';

        ImportRecord.TestField(
            "Shopify Order ID");

        StartedAt :=
            CurrentDateTime();

        ClearLastError();

        if TryAddTag(
            ImportRecord."Shopify Order ID",
            TagText)
        then begin
            ImportRecord."Tag Status" :=
                ImportRecord."Tag Status"::Success;

            ImportRecord."Tagged At" :=
                CurrentDateTime();

            Clear(
                ImportRecord."Tag Error");

            ImportRecord.Modify(false);

            SyncLogMgt.LogSuccess(
                "Shopify Sync Direction"::Outbound,
                "Shopify Sync Entity"::"Order Tag",
                ImportRecord."BC Order No.",
                ImportRecord."Shopify Order ID",
                StrSubstNo(
                    'Tag %1 added to Shopify order %2.',
                    TagText,
                    ImportRecord."Shopify Order Name"),
                CurrentDateTime() - StartedAt);

            if ShowResultMessage then
                Message(
                    'Shopify order %1 was tagged with %2 successfully.',
                    ImportRecord."Shopify Order Name",
                    TagText);

            exit(true);
        end;

        ErrorText :=
            GetLastErrorText();

        if ErrorText = '' then
            ErrorText :=
                'Unknown error while tagging Shopify order.';

        ImportRecord."Tag Status" :=
            ImportRecord."Tag Status"::Error;

        Clear(
            ImportRecord."Tagged At");

        ImportRecord."Tag Error" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(
                    ImportRecord."Tag Error"));

        ImportRecord.Modify(false);

        SyncLogMgt.LogError(
            "Shopify Sync Direction"::Outbound,
            "Shopify Sync Entity"::"Order Tag",
            ImportRecord."BC Order No.",
            ImportRecord."Shopify Order ID",
            ErrorText,
            CurrentDateTime() - StartedAt);

        if ShowResultMessage then
            Message(
                'Shopify order tag failed.\%1',
                ErrorText);

        exit(false);
    end;

    procedure RetryFailedTags()
    var
        ImportRecord:
            Record "Shopify Order Import";

        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        ImportRecord.SetRange(
            "Tag Status",
            ImportRecord."Tag Status"::Error);

        if not ImportRecord.FindSet() then begin
            Message(
                'There are no failed Shopify order tags to retry.');

            exit;
        end;

        repeat
            ImportRecord."Tag Retry Count" +=
                1;

            ImportRecord.Modify(false);

            if TagImportRecord(
                ImportRecord,
                false)
            then
                SuccessCount +=
                    1
            else
                ErrorCount +=
                    1;

        until ImportRecord.Next() = 0;

        Message(
            'Shopify order tag retry completed.\Successful: %1\Failed: %2',
            SuccessCount,
            ErrorCount);
    end;

    procedure TagAllUntagged()
    var
        ImportRecord:
            Record "Shopify Order Import";

        SuccessCount: Integer;
        ErrorCount: Integer;
    begin
        ImportRecord.SetFilter(
            "Tag Status",
            '%1|%2',
            ImportRecord."Tag Status"::"Not Required",
            ImportRecord."Tag Status"::Error);

        if not ImportRecord.FindSet() then begin
            Message(
                'There are no untagged Shopify order imports.');

            exit;
        end;

        repeat
            if ImportRecord."Tag Status" =
               ImportRecord."Tag Status"::Error
            then begin
                ImportRecord."Tag Retry Count" +=
                    1;

                ImportRecord.Modify(false);
            end;

            if TagImportRecord(
                ImportRecord,
                false)
            then
                SuccessCount +=
                    1
            else
                ErrorCount +=
                    1;

        until ImportRecord.Next() = 0;

        Message(
            'Shopify order tagging completed.\Successful: %1\Failed: %2',
            SuccessCount,
            ErrorCount);
    end;

    [TryFunction]
    local procedure TryAddTag(
        ShopifyOrderId: Text;
        TagText: Text)
    var
        ShopifyClient:
            Codeunit "Shopify Client";

        Variables:
            JsonObject;

        ResponseJson:
            JsonObject;

        DataObject:
            JsonObject;

        PayloadObject:
            JsonObject;

        TagsArray:
            JsonArray;

        QueryText: Text;
    begin
        if StrPos(
            ShopifyOrderId,
            'gid://shopify/Order/')
           <> 1
        then
            Error(
                'Shopify Order ID %1 is not a valid Order GID.',
                ShopifyOrderId);

        if TagText = '' then
            Error(
                'Shopify order tag cannot be empty.');

        TagsArray.Add(
            TagText);

        Variables.Add(
            'id',
            ShopifyOrderId);

        Variables.Add(
            'tags',
            TagsArray);

        QueryText :=
            'mutation AddOrderTags($id: ID!, $tags: [String!]!) {' +
            ' tagsAdd(id: $id, tags: $tags) {' +
            '  node { id }' +
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
                'tagsAdd');

        ShopifyClient.CheckUserErrors(
            PayloadObject);
    end;

    [EventSubscriber(
        ObjectType::Table,
        Database::"Shopify Order Import",
        'OnAfterInsertEvent',
        '',
        false,
        false)]
    local procedure OnAfterShopifyOrderImportInsert(
        var Rec: Record "Shopify Order Import";
        RunTrigger: Boolean)
    var
        ShopifySetup:
            Record "Shopify Integration Setup";
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then
            exit;

        if not ShopifySetup."Tag Imported Orders" then
            exit;

        Rec."Tag Status" :=
            Rec."Tag Status"::Pending;

        Rec.Modify(false);

        // Intentionally non-fatal.
        // A tag failure must not invalidate an already created BC order.
        TagImportRecord(
            Rec,
            false);
    end;
}