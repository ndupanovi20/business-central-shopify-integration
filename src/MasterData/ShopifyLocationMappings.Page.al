page 50296 "Shopify Location Mappings"
{
    PageType = List;
    SourceTable = "Shopify Location Mapping";

    Caption = 'Shopify Location Mappings';
    ApplicationArea = All;
    UsageCategory = Lists;

    InsertAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Shopify Location Name"; Rec."Shopify Location Name")
                {
                    ApplicationArea = All;
                }

                field("Shopify Location ID"; Rec."Shopify Location ID")
                {
                    ApplicationArea = All;
                }

                field("BC Location Code"; Rec."BC Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Business Central location corresponding to this Shopify location.';
                }

                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                }

                field("Default for Order Imports"; Rec."Default for Order Imports")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the fallback Business Central location for Shopify orders when no unique assigned Shopify location can be resolved.';
                }

                field("Last Refreshed At"; Rec."Last Refreshed At")
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
            action(RefreshFromShopify)
            {
                ApplicationArea = All;
                Caption = 'Refresh Shopify Locations';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    LocationMgt: Codeunit "Shopify Location Mgt.";
                begin
                    LocationMgt.RefreshLocationsFromShopify(true);
                    CurrPage.Update(false);
                end;
            }

            action(OpenBCLocation)
            {
                ApplicationArea = All;
                Caption = 'Open BC Location';

                trigger OnAction()
                var
                    Location: Record Location;
                begin
                    Rec.TestField("BC Location Code");

                    if not Location.Get(Rec."BC Location Code") then
                        Error('Business Central location %1 does not exist.', Rec."BC Location Code");

                    Page.Run(Page::"Location Card", Location);
                end;
            }
        }
    }
}
