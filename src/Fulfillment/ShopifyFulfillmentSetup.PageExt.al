pageextension 50244 "Shopify Fulfillment Setup Page"
    extends "Shopify Integration Setup"
{
    layout
    {
        addbefore(Automation)
        {
            group(Fulfillment)
            {
                Caption = 'Shopify Fulfillment and Tracking';

                field("Auto Create Fulfillment"; Rec."Auto Create Fulfillment")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies whether posted Business Central sales shipments are automatically sent to Shopify as fulfillments.';
                }

                field("Notify Customer on Fulfillment"; Rec."Notify Customer on Fulfillment")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies whether Shopify should notify the customer when a fulfillment or tracking update is sent.';
                }

                field("Require Tracking No."; Rec."Require Tracking No.")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies whether a posted Business Central shipment must contain a package tracking number before Shopify fulfillment is created.';
                }

                field("Auto Sync Fulfillment Tracking"; Rec."Auto Sync Fulfillment Tracking")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies whether tracking changes on posted Business Central shipments should be synchronized to existing Shopify fulfillments.';
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ProcessEligibleFulfillments)
            {
                ApplicationArea = All;
                Caption = 'Create Eligible Shopify Fulfillments';

                trigger OnAction()
                var
                    FulfillmentMgt:
                        Codeunit "Shopify Fulfillment Mgt.";
                begin
                    CurrPage.SaveRecord();

                    FulfillmentMgt.ProcessEligibleFulfillments(
                        true);
                end;
            }

            action(SyncFulfillmentTracking)
            {
                ApplicationArea = All;
                Caption = 'Sync Fulfillment Tracking';

                trigger OnAction()
                var
                    FulfillmentMgt:
                        Codeunit "Shopify Fulfillment Mgt.";
                begin
                    CurrPage.SaveRecord();

                    FulfillmentMgt.ProcessTrackingUpdates(
                        true);
                end;
            }

            action(RetryFailedFulfillments)
            {
                ApplicationArea = All;
                Caption = 'Retry Failed Fulfillments';

                trigger OnAction()
                var
                    FulfillmentMgt:
                        Codeunit "Shopify Fulfillment Mgt.";
                begin
                    CurrPage.SaveRecord();

                    FulfillmentMgt.RetryFailedFulfillments();
                end;
            }

            action(OpenFulfillmentEntries)
            {
                ApplicationArea = All;
                Caption = 'Shopify Fulfillment Entries';

                trigger OnAction()
                begin
                    Page.Run(
                        Page::"Shopify Fulfillment Entries");
                end;
            }
        }
    }
}
