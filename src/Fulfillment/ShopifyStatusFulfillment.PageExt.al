pageextension 50250 "Shopify Status Fulfillment Ext"
    extends "Shopify Integration Status"
{
    layout
    {
        addafter(OrderStatistics)
        {
            group(FulfillmentStatistics)
            {
                Caption = 'Shopify Fulfillment';

                field(AutoCreateFulfillment; Rec."Auto Create Fulfillment")
                {
                    ApplicationArea = All;
                    Caption = 'Auto Create Shopify Fulfillment';
                }

                field(AutoSyncTracking; Rec."Auto Sync Fulfillment Tracking")
                {
                    ApplicationArea = All;
                    Caption = 'Auto Sync Fulfillment Tracking';
                }

                field(NotifyCustomer; Rec."Notify Customer on Fulfillment")
                {
                    ApplicationArea = All;
                    Caption = 'Notify Customer';
                }

                field(RequireTracking; Rec."Require Tracking No.")
                {
                    ApplicationArea = All;
                    Caption = 'Require Tracking No.';
                }

                field(FulfillmentSuccessCount; FulfillmentSuccessCount)
                {
                    ApplicationArea = All;
                    Caption = 'Successful Fulfillments';
                }

                field(FulfillmentWaitingCount; FulfillmentWaitingCount)
                {
                    ApplicationArea = All;
                    Caption = 'Waiting for Tracking';
                    Style = Attention;
                }

                field(FulfillmentSkippedCount; FulfillmentSkippedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Skipped Fulfillments';
                    Style = Attention;
                }

                field(FulfillmentErrorCount; FulfillmentErrorCount)
                {
                    ApplicationArea = All;
                    Caption = 'Fulfillment Errors';
                    Style = Unfavorable;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
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

    trigger OnAfterGetRecord()
    begin
        CalculateFulfillmentStatistics();
    end;

    local procedure CalculateFulfillmentStatistics()
    var
        FulfillmentEntry:
            Record "Shopify Fulfillment Entry";
    begin
        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::Success);

        FulfillmentSuccessCount :=
            FulfillmentEntry.Count();

        FulfillmentEntry.Reset();
        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::"Waiting for Tracking");

        FulfillmentWaitingCount :=
            FulfillmentEntry.Count();

        FulfillmentEntry.Reset();
        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::Skipped);

        FulfillmentSkippedCount :=
            FulfillmentEntry.Count();

        FulfillmentEntry.Reset();
        FulfillmentEntry.SetRange(
            Status,
            FulfillmentEntry.Status::Error);

        FulfillmentErrorCount :=
            FulfillmentEntry.Count();
    end;

    var
        FulfillmentSuccessCount: Integer;
        FulfillmentWaitingCount: Integer;
        FulfillmentSkippedCount: Integer;
        FulfillmentErrorCount: Integer;
}
