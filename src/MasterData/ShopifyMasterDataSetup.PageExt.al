pageextension 50291 "Shopify Master Data Setup Page"
    extends "Shopify Integration Setup"
{
    layout
    {
        addafter(Mapping)
        {
            group(CustomerAndLocationMapping)
            {
                Caption = 'Customer and Location Mapping';

                field("Customer Strategy"; Rec."Customer Strategy")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Shopify orders use the configured generic customer, an existing customer mapping, or automatically create and map Business Central customers.';
                }

                field("Apply Shopify Order Addresses"; Rec."Apply Shopify Order Addresses")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Shopify billing and shipping address snapshots are copied to the Business Central Sales Order.';
                }

                field("Fallback to Generic Customer"; Rec."Fallback to Generic Customer")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether an order without a usable Shopify customer mapping can fall back to the configured BC Customer No.';
                }

                field("Use Location Mappings"; Rec."Use Location Mappings")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether inventory, order routing and fulfillment use the Shopify Location Mapping table instead of the single legacy location pair in Setup.';
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(RefreshShopifyCustomers)
            {
                ApplicationArea = All;
                Caption = 'Refresh Shopify Customers';

                trigger OnAction()
                var
                    CustomerMgt: Codeunit "Shopify Customer Mgt.";
                begin
                    CurrPage.SaveRecord();
                    CustomerMgt.RefreshCustomersFromShopify(true);
                end;
            }

            action(OpenCustomerMappings)
            {
                ApplicationArea = All;
                Caption = 'Shopify Customer Mappings';

                trigger OnAction()
                begin
                    Page.Run(Page::"Shopify Customer Mappings");
                end;
            }

            action(OpenLocationMappings)
            {
                ApplicationArea = All;
                Caption = 'Shopify Location Mappings';

                trigger OnAction()
                begin
                    Page.Run(Page::"Shopify Location Mappings");
                end;
            }

            action(RefreshShopifyLocations)
            {
                ApplicationArea = All;
                Caption = 'Refresh Shopify Locations';

                trigger OnAction()
                var
                    LocationMgt: Codeunit "Shopify Location Mgt.";
                begin
                    CurrPage.SaveRecord();
                    LocationMgt.RefreshLocationsFromShopify(true);
                end;
            }
        }
    }
}
