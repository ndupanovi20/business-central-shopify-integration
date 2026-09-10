permissionset 50100 "BC SHOPIFY INT"
{
    Assignable = true;
    Caption = 'BC Shopify Integration';

    Permissions =
        tabledata "Shopify Integration Setup" = RIMD,
        tabledata "Shopify Product Mapping" = RIMD,
        tabledata "Shopify Sync Log" = RIMD,
        tabledata "Shopify Order Import" = RIMD,
        tabledata "Shopify Order Buffer" = RIMD,
        tabledata "Shopify Audit Snapshot" = RIMD,

        table "Shopify Integration Setup" = X,
        table "Shopify Product Mapping" = X,
        table "Shopify Sync Log" = X,
        table "Shopify Order Import" = X,
        table "Shopify Order Buffer" = X,
        table "Shopify Audit Snapshot" = X,
        table "Shopify Background Run Result" = X,

        page "Shopify Integration Setup" = X,
        page "Shopify Product Mappings" = X,
        page "Shopify Sync Log" = X,
        page "Shopify Order Imports" = X,
        page "Shopify Order Buffer" = X,
        page "Shopify Integration Status" = X,
        page "Shopify Administration Center" = X,
        page "Shopify Audit Snapshots" = X,

        codeunit "Shopify Setup Mgt." = X,
        codeunit "Shopify Auth" = X,
        codeunit "Shopify Client" = X,
        codeunit "Shopify Product Sync" = X,
        codeunit "Shopify Bulk Sync" = X,
        codeunit "Shopify Order Sync" = X,
        codeunit "Shopify Order Import Runner" = X,
        codeunit "Shopify Sync Log Mgt." = X,
        codeunit "Shopify Diagnostics" = X,
        codeunit "Shopify Order Retry Mgt." = X,
        codeunit "Shopify Background Sync" = X,
        codeunit "Shopify Job Queue Mgt." = X,
        codeunit "Shopify Order Tag Mgt." = X,
        codeunit "Shopify Demo Setup" = X,
        codeunit "Shopify Demo Data Mgt." = X,
        codeunit "Shopify Admin Mgt." = X,
        codeunit "Shopify Integration Validator" = X,
        codeunit "Shopify Audit Mgt." = X,
        codeunit "Shopify Order BG Runner" = X,
        codeunit "Shopify Inventory BG Runner" = X;
}