codeunit 50221 "Shopify Posting BG Runner"
{
    TableNo = "Shopify Background Run Result";

    trigger OnRun()
    var
        PostingMgt: Codeunit "Shopify Order Posting Mgt.";
    begin
        Rec."Result Count" :=
            PostingMgt.ProcessPendingAutoPostings(false);

        Rec.Modify();
    end;
}
