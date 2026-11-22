pageextension 50248 "Shopify Order Imports Fulfill."
    extends "Shopify Order Imports"
{
    layout
    {
        addafter("Line Count")
        {
            field("Fulfillment Entry Count"; Rec."Fulfillment Entry Count")
            {
                ApplicationArea = All;
            }

            field("Successful Fulfillment Count"; Rec."Successful Fulfillment Count")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(CreateShopifyFulfillment)
            {
                ApplicationArea = All;
                Caption = 'Create Shopify Fulfillment';

                trigger OnAction()
                var
                    FulfillmentMgt:
                        Codeunit "Shopify Fulfillment Mgt.";
                begin
                    FulfillmentMgt.CreateFulfillmentForImport(
                        Rec,
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(OpenShopifyFulfillments)
            {
                ApplicationArea = All;
                Caption = 'Open Shopify Fulfillments';

                trigger OnAction()
                var
                    FulfillmentEntry:
                        Record "Shopify Fulfillment Entry";
                begin
                    FulfillmentEntry.SetRange(
                        "Shopify Order ID",
                        Rec."Shopify Order ID");

                    Page.Run(
                        Page::"Shopify Fulfillment Entries",
                        FulfillmentEntry);
                end;
            }

            action(SyncShopifyTracking)
            {
                ApplicationArea = All;
                Caption = 'Sync Shopify Tracking';

                trigger OnAction()
                var
                    FulfillmentMgt:
                        Codeunit "Shopify Fulfillment Mgt.";
                begin
                    FulfillmentMgt.SyncTrackingForImport(
                        Rec,
                        true);

                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(
            "Fulfillment Entry Count",
            "Successful Fulfillment Count");
    end;
}
