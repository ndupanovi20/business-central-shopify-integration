pageextension 50298 "Shopify Admin Master Data Ext"
    extends "Shopify Administration Center"
{
    layout
    {
        addlast(MasterDataState)
        {
            field(CustomerMappingCount; CustomerMappingCount)
            {
                ApplicationArea = All;
                Caption = 'Customer Mappings';
            }

            field(LocationMappingCount; LocationMappingCount)
            {
                ApplicationArea = All;
                Caption = 'Active Location Mappings';
            }

            field(CustomerStrategyText; CustomerStrategyText)
            {
                ApplicationArea = All;
                Caption = 'Customer Strategy';
            }

            field(LocationMappingMode; LocationMappingMode)
            {
                ApplicationArea = All;
                Caption = 'Location Mapping Mode';
                StyleExpr = LocationMappingStyle;
            }
        }
    }

    actions
    {
        addlast(MasterDataActions)
        {
            action(RefreshShopifyCustomers)
            {
                ApplicationArea = All;
                Caption = 'Refresh Shopify Customers';

                trigger OnAction()
                var
                    CustomerMgt:
                        Codeunit "Shopify Customer Mgt.";
                begin
                    CustomerMgt.RefreshCustomersFromShopify(true);
                    CalculateMasterDataState();
                    CurrPage.Update(false);
                end;
            }

            action(OpenCustomerMappings)
            {
                ApplicationArea = All;
                Caption = 'Customer Mappings';

                trigger OnAction()
                begin
                    Page.Run(
                        Page::"Shopify Customer Mappings");
                end;
            }

            action(RefreshShopifyLocations)
            {
                ApplicationArea = All;
                Caption = 'Refresh Shopify Locations';

                trigger OnAction()
                var
                    LocationMgt:
                        Codeunit "Shopify Location Mgt.";
                begin
                    LocationMgt.RefreshLocationsFromShopify(true);
                    CalculateMasterDataState();
                    CurrPage.Update(false);
                end;
            }

            action(OpenLocationMappings)
            {
                ApplicationArea = All;
                Caption = 'Location Mappings';

                trigger OnAction()
                begin
                    Page.Run(
                        Page::"Shopify Location Mappings");
                end;
            }
        }

        addlast(MasterDataPromoted)
        {
            actionref(RefreshShopifyCustomersPromoted; RefreshShopifyCustomers)
            {
            }

            actionref(OpenCustomerMappingsPromoted; OpenCustomerMappings)
            {
            }

            actionref(RefreshShopifyLocationsPromoted; RefreshShopifyLocations)
            {
            }

            actionref(OpenLocationMappingsPromoted; OpenLocationMappings)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculateMasterDataState();
    end;

    local procedure CalculateMasterDataState()
    var
        CustomerMapping:
            Record "Shopify Customer Mapping";

        LocationMapping:
            Record "Shopify Location Mapping";
    begin
        CustomerMappingCount :=
            CustomerMapping.Count();

        LocationMapping.SetRange(
            Active,
            true);

        LocationMapping.SetFilter(
            "BC Location Code",
            '<>%1',
            '');

        LocationMapping.SetFilter(
            "Shopify Location ID",
            '<>%1',
            '');

        LocationMappingCount :=
            LocationMapping.Count();

        CustomerStrategyText :=
            Format(Rec."Customer Strategy");

        if Rec."Use Location Mappings" then begin
            LocationMappingMode :=
                'Location mapping table';

            if LocationMappingCount > 0 then
                LocationMappingStyle :=
                    'Favorable'
            else
                LocationMappingStyle :=
                    'Unfavorable';
        end else begin
            LocationMappingMode :=
                'Single setup location';

            LocationMappingStyle :=
                'Standard';
        end;
    end;

    var
        CustomerMappingCount: Integer;
        LocationMappingCount: Integer;
        CustomerStrategyText: Text;
        LocationMappingMode: Text;
        LocationMappingStyle: Text;
}