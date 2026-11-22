page 50289 "Shopify Customer Mappings"
{
    PageType = List;
    SourceTable = "Shopify Customer Mapping";

    Caption = 'Shopify Customer Mappings';
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
                field("Shopify Customer ID"; Rec."Shopify Customer ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Shopify Customer Name"; Rec."Shopify Customer Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Shopify E-Mail"; Rec."Shopify E-Mail")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Shopify Phone No."; Rec."Shopify Phone No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("BC Customer No."; Rec."BC Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Business Central customer linked to this Shopify customer.';
                }

                field("Created Automatically"; Rec."Created Automatically")
                {
                    ApplicationArea = All;
                }

                field("Last Shopify Order Name"; Rec."Last Shopify Order Name")
                {
                    ApplicationArea = All;
                }

                field("Last Used At"; Rec."Last Used At")
                {
                    ApplicationArea = All;
                }

                field("Created At"; Rec."Created At")
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
                Caption = 'Refresh Shopify Customers';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    CustomerMgt: Codeunit "Shopify Customer Mgt.";
                begin
                    CustomerMgt.RefreshCustomersFromShopify(true);
                    CurrPage.Update(false);
                end;
            }

            action(OpenBCCustomer)
            {
                ApplicationArea = All;
                Caption = 'Open BC Customer';

                trigger OnAction()
                var
                    Customer: Record Customer;
                begin
                    Rec.TestField("BC Customer No.");

                    if not Customer.Get(Rec."BC Customer No.") then
                        Error('Business Central customer %1 does not exist.', Rec."BC Customer No.");

                    Page.Run(Page::"Customer Card", Customer);
                end;
            }
        }
    }
}
