pageextension 50294 "Shopify Order Imports Master"
    extends "Shopify Order Imports"
{
    layout
    {
        addafter("Shopify Order Name")
        {
            field("BC Customer No. Used"; Rec."BC Customer No. Used")
            {
                ApplicationArea = All;
            }

            field("Shopify Customer Name"; Rec."Shopify Customer Name")
            {
                ApplicationArea = All;
            }

            field("Shopify Customer E-Mail"; Rec."Shopify Customer E-Mail")
            {
                ApplicationArea = All;
            }

            field("BC Location Code Used"; Rec."BC Location Code Used")
            {
                ApplicationArea = All;
            }

            field("Shopify Location ID Used"; Rec."Shopify Location ID Used")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(OpenMappedCustomer)
            {
                ApplicationArea = All;
                Caption = 'Open BC Customer';

                trigger OnAction()
                var
                    Customer: Record Customer;
                begin
                    Rec.TestField("BC Customer No. Used");

                    if not Customer.Get(Rec."BC Customer No. Used") then
                        Error('Business Central customer %1 does not exist.', Rec."BC Customer No. Used");

                    Page.Run(Page::"Customer Card", Customer);
                end;
            }
        }
    }
}
