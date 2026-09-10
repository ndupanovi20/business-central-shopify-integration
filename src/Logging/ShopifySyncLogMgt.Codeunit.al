codeunit 50165 "Shopify Sync Log Mgt."
{
    procedure LogSuccess(
        Direction: Enum "Shopify Sync Direction";
        EntityType: Enum "Shopify Sync Entity";
        BCKey: Text;
        ShopifyId: Text;
        MessageText: Text;
        OperationDuration: Duration)
    begin
        InsertLog(
            Direction,
            EntityType,
            "Shopify Sync Status"::Success,
            BCKey,
            ShopifyId,
            MessageText,
            OperationDuration);
    end;

    procedure LogError(
        Direction: Enum "Shopify Sync Direction";
        EntityType: Enum "Shopify Sync Entity";
        BCKey: Text;
        ShopifyId: Text;
        MessageText: Text;
        OperationDuration: Duration)
    begin
        InsertLog(
            Direction,
            EntityType,
            "Shopify Sync Status"::Error,
            BCKey,
            ShopifyId,
            MessageText,
            OperationDuration);
    end;

    procedure LogInfo(
        Direction: Enum "Shopify Sync Direction";
        EntityType: Enum "Shopify Sync Entity";
        BCKey: Text;
        ShopifyId: Text;
        MessageText: Text)
    begin
        InsertLog(
            Direction,
            EntityType,
            "Shopify Sync Status"::Info,
            BCKey,
            ShopifyId,
            MessageText,
            0);
    end;

    local procedure InsertLog(
        Direction: Enum "Shopify Sync Direction";
        EntityType: Enum "Shopify Sync Entity";
        Status: Enum "Shopify Sync Status";
        BCKey: Text;
        ShopifyId: Text;
        MessageText: Text;
        OperationDuration: Duration)
    var
        SyncLog: Record "Shopify Sync Log";
    begin
        SyncLog.Init();

        SyncLog."Created At" :=
            CurrentDateTime();

        SyncLog.Direction :=
            Direction;

        SyncLog."Entity Type" :=
            EntityType;

        SyncLog.Status :=
            Status;

        SyncLog."BC Key" :=
            CopyStr(
                BCKey,
                1,
                MaxStrLen(SyncLog."BC Key"));

        SyncLog."Shopify ID" :=
            CopyStr(
                ShopifyId,
                1,
                MaxStrLen(SyncLog."Shopify ID"));

        SyncLog.Message :=
            CopyStr(
                MessageText,
                1,
                MaxStrLen(SyncLog.Message));

        SyncLog.Duration :=
            OperationDuration;

        SyncLog.Insert(true);
    end;
}