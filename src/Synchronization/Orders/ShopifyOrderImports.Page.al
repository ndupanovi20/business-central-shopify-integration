page 50131 "Shopify Order Imports"
{
    PageType = List;
    SourceTable = "Shopify Order Import";

    Caption = 'Shopify Order Imports';
    ApplicationArea = All;
    UsageCategory = Lists;

    Editable = false;
    InsertAllowed = false;

    SourceTableView =
        sorting("Imported At")
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

                field("BC Order No."; Rec."BC Order No.")
                {
                    ApplicationArea = All;
                }

                field("Financial Status"; Rec."Financial Status")
                {
                    ApplicationArea = All;
                }

                field("Fulfillment Status"; Rec."Fulfillment Status")
                {
                    ApplicationArea = All;
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }

                field("Shopify Total"; Rec."Shopify Total")
                {
                    ApplicationArea = All;
                }

                field("BC Total"; Rec."BC Total")
                {
                    ApplicationArea = All;
                }

                field("Total Difference"; Rec."Total Difference")
                {
                    ApplicationArea = All;
                }

                field("Discount Amount"; Rec."Discount Amount")
                {
                    ApplicationArea = All;
                }

                field("Shipping Amount"; Rec."Shipping Amount")
                {
                    ApplicationArea = All;
                }

                field("Line Count"; Rec."Line Count")
                {
                    ApplicationArea = All;
                }

                field("Shopify Created At"; Rec."Shopify Created At")
                {
                    ApplicationArea = All;
                }

                field("Imported At"; Rec."Imported At")
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
            action(OpenSalesOrder)
            {
                ApplicationArea = All;
                Caption = 'Open BC Sales Order';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    if Rec."BC Order No." = '' then
                        exit;

                    if not SalesHeader.Get(
                        SalesHeader."Document Type"::Order,
                        Rec."BC Order No.")
                    then
                        Error(
                            'Business Central Sales Order %1 does not exist.',
                            Rec."BC Order No.");

                    Page.Run(
                        Page::"Sales Order",
                        SalesHeader);
                end;
            }
        }
    }
}