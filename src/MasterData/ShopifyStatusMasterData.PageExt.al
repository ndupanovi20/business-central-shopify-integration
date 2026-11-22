pageextension 50299 "Shopify Status Master Data Ext"
    extends "Shopify Integration Status"
{
    layout
    {
        addafter(BackgroundSynchronization)
        {
            group(MasterDataMappingStatus)
            {
                Caption = 'Customer and Location Mapping';

                field(CustomerStrategy; Rec."Customer Strategy")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Strategy';
                }

                field(ApplyOrderAddresses; Rec."Apply Shopify Order Addresses")
                {
                    ApplicationArea = All;
                    Caption = 'Apply Shopify Order Addresses';
                }

                field(UseLocationMappings; Rec."Use Location Mappings")
                {
                    ApplicationArea = All;
                    Caption = 'Use Location Mappings';
                }

                field(CustomerMappings; CustomerMappingCount)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Mappings';
                }

                field(ActiveLocationMappings; LocationMappingCount)
                {
                    ApplicationArea = All;
                    Caption = 'Active Location Mappings';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculateMappingStatistics();
    end;

    local procedure CalculateMappingStatistics()
    var
        CustomerMapping: Record "Shopify Customer Mapping";
        LocationMapping: Record "Shopify Location Mapping";
    begin
        CustomerMappingCount := CustomerMapping.Count();

        LocationMapping.SetRange(Active, true);
        LocationMapping.SetFilter("BC Location Code", '<>%1', '');
        LocationMapping.SetFilter("Shopify Location ID", '<>%1', '');
        LocationMappingCount := LocationMapping.Count();
    end;

    var
        CustomerMappingCount: Integer;
        LocationMappingCount: Integer;
}
