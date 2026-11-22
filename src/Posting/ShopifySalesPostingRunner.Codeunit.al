codeunit 50218 "Shopify Sales Posting Runner"
{
    TableNo = "Shopify Order Import";

    trigger OnRun()
    var
        PostingMgt: Codeunit "Shopify Order Posting Mgt.";
    begin
        PostingMgt.PostImportRecordCore(
            Rec);
    end;
}
