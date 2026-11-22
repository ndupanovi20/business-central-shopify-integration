page 50241 "Shopify Fulfillment Entries"
{
    PageType = List;
    SourceTable = "Shopify Fulfillment Entry";

    Caption = 'Shopify Fulfillment Entries';
    ApplicationArea = All;
    UsageCategory = Lists;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    SourceTableView =
        sorting("Entry No.")
        order(descending);

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Shopify Order Name"; Rec."Shopify Order Name")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }

                field("Posted Shipment No."; Rec."Posted Shipment No.")
                {
                    ApplicationArea = All;
                }

                field("Shopify Fulfillment ID"; Rec."Shopify Fulfillment ID")
                {
                    ApplicationArea = All;
                }

                field("Shopify Location ID"; Rec."Shopify Location ID")
                {
                    ApplicationArea = All;
                }

                field("Tracking No."; Rec."Tracking No.")
                {
                    ApplicationArea = All;
                }

                field("Tracking Company"; Rec."Tracking Company")
                {
                    ApplicationArea = All;
                }

                field("Tracking URL"; Rec."Tracking URL")
                {
                    ApplicationArea = All;
                }

                field("Tracking Synced At"; Rec."Tracking Synced At")
                {
                    ApplicationArea = All;
                }

                field("Notify Customer"; Rec."Notify Customer")
                {
                    ApplicationArea = All;
                }

                field("Attempt Count"; Rec."Attempt Count")
                {
                    ApplicationArea = All;
                }

                field("Last Attempt At"; Rec."Last Attempt At")
                {
                    ApplicationArea = All;
                }

                field("Fulfilled At"; Rec."Fulfilled At")
                {
                    ApplicationArea = All;
                }

                field("Result Message"; Rec."Result Message")
                {
                    ApplicationArea = All;
                }

                field("Fulfillment Error"; Rec."Fulfillment Error")
                {
                    ApplicationArea = All;
                }

                field("Tracking Error"; Rec."Tracking Error")
                {
                    ApplicationArea = All;
                }

                field("Fulfillment Order IDs"; Rec."Fulfillment Order IDs")
                {
                    ApplicationArea = All;
                }

                field("Shopify Order ID"; Rec."Shopify Order ID")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetryFulfillment)
            {
                ApplicationArea = All;
                Caption = 'Retry Fulfillment';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    FulfillmentMgt:
                        Codeunit "Shopify Fulfillment Mgt.";
                begin
                    FulfillmentMgt.RetryFulfillmentEntry(
                        Rec,
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(SyncTracking)
            {
                ApplicationArea = All;
                Caption = 'Sync Tracking';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    FulfillmentMgt:
                        Codeunit "Shopify Fulfillment Mgt.";
                begin
                    FulfillmentMgt.SyncTrackingForEntry(
                        Rec,
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(OpenPostedShipment)
            {
                ApplicationArea = All;
                Caption = 'Open Posted Shipment';

                trigger OnAction()
                var
                    SalesShipmentHeader:
                        Record "Sales Shipment Header";
                begin
                    Rec.TestField(
                        "Posted Shipment No.");

                    if not SalesShipmentHeader.Get(
                        Rec."Posted Shipment No.")
                    then
                        Error(
                            'Posted Sales Shipment %1 does not exist.',
                            Rec."Posted Shipment No.");

                    Page.Run(
                        Page::"Posted Sales Shipment",
                        SalesShipmentHeader);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
    end;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Success:
                StatusStyle :=
                    'Favorable';

            Rec.Status::Error:
                StatusStyle :=
                    'Unfavorable';

            Rec.Status::Skipped:
                StatusStyle :=
                    'Attention';

            Rec.Status::"Waiting for Tracking":
                StatusStyle :=
                    'Attention';

            Rec.Status::Pending:
                StatusStyle :=
                    'Attention';

            else
                StatusStyle :=
                    'Standard';
        end;
    end;

    var
        StatusStyle: Text;
}
