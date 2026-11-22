pageextension 50249 "Shopify Admin Fulfillment Ext"
    extends "Shopify Administration Center"
{
    layout
    {
        addlast(ShopifyOperationsState)
        {
            field(FulfillmentSuccessCount; FulfillmentSuccessCount)
            {
                ApplicationArea = All;
                Caption = 'Successful Shopify Fulfillments';
            }

            field(FulfillmentWaitingCount; FulfillmentWaitingCount)
            {
                ApplicationArea = All;
                Caption = 'Waiting for Tracking';
                Style = Attention;
            }

            field(FulfillmentErrorCount; FulfillmentErrorCount)
            {
                ApplicationArea = All;
                Caption = 'Fulfillment Errors';
                StyleExpr = FulfillmentErrorStyle;
            }
        }

        addlast(DemoReadiness)
        {
            field(FulfillmentSetupReady; FulfillmentSetupReady)
            {
                ApplicationArea = All;
                Caption = 'Fulfillment Setup Ready';
                StyleExpr = FulfillmentSetupStyle;
            }
        }

        addlast(Automation)
        {
            field("Auto Create Fulfillment"; Rec."Auto Create Fulfillment")
            {
                ApplicationArea = All;
                Caption = 'Auto Create Shopify Fulfillment';
            }

            field("Auto Sync Fulfillment Tracking"; Rec."Auto Sync Fulfillment Tracking")
            {
                ApplicationArea = All;
                Caption = 'Auto Sync Fulfillment Tracking';
            }
        }
    }

    actions
    {
        addlast(FulfillmentActions)
        {
            action(ProcessFulfillments)
            {
                ApplicationArea = All;
                Caption = 'Create Eligible Shopify Fulfillments';

                trigger OnAction()
                var
                    FulfillmentMgt:
                        Codeunit "Shopify Fulfillment Mgt.";
                begin
                    FulfillmentMgt.ProcessEligibleFulfillments(
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(ProcessTrackingUpdates)
            {
                ApplicationArea = All;
                Caption = 'Sync Fulfillment Tracking';

                trigger OnAction()
                var
                    FulfillmentMgt:
                        Codeunit "Shopify Fulfillment Mgt.";
                begin
                    FulfillmentMgt.ProcessTrackingUpdates(
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(RetryFulfillmentErrors)
            {
                ApplicationArea = All;
                Caption = 'Retry Fulfillment Errors';

                trigger OnAction()
                var
                    FulfillmentMgt:
                        Codeunit "Shopify Fulfillment Mgt.";
                begin
                    FulfillmentMgt.RetryFailedFulfillments();

                    CurrPage.Update(false);
                end;
            }
        }

        addlast(FulfillmentPromoted)
        {
            actionref(ProcessFulfillmentsPromoted; ProcessFulfillments)
            {
            }

            actionref(ProcessTrackingUpdatesPromoted; ProcessTrackingUpdates)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculateFulfillmentState();
    end;

    local procedure CalculateFulfillmentState()
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
            FulfillmentEntry.Status::Error);

        FulfillmentErrorCount :=
            FulfillmentEntry.Count();

        if FulfillmentErrorCount = 0 then
            FulfillmentErrorStyle :=
                'Favorable'
        else
            FulfillmentErrorStyle :=
                'Unfavorable';

        FulfillmentSetupReady :=
            (not Rec."Auto Create Fulfillment" and
             not Rec."Auto Sync Fulfillment Tracking") or
            ((Rec."Shopify Location ID" <> '') and
             not (Rec."Auto Create Fulfillment" and
                  Rec."Auto Post Imported Orders" and
                  (Rec."Posting Mode" = Rec."Posting Mode"::Invoice)));

        if FulfillmentSetupReady then
            FulfillmentSetupStyle :=
                'Favorable'
        else
            FulfillmentSetupStyle :=
                'Unfavorable';
    end;

    var
        FulfillmentSuccessCount: Integer;
        FulfillmentWaitingCount: Integer;
        FulfillmentErrorCount: Integer;
        FulfillmentErrorStyle: Text;
        FulfillmentSetupReady: Boolean;
        FulfillmentSetupStyle: Text;
}