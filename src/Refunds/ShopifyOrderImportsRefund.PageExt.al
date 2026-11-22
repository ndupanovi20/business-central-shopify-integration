pageextension 50282 "Shopify Order Imports Refund"
    extends "Shopify Order Imports"
{
    layout
    {
        addafter("Line Count")
        {
            field("Refund Count"; Rec."Refund Count")
            {
                ApplicationArea = All;
            }

            field("Successful Refund Count"; Rec."Successful Refund Count")
            {
                ApplicationArea = All;
            }

            field("Refund Error Count"; Rec."Refund Error Count")
            {
                ApplicationArea = All;
                Style = Unfavorable;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(RefreshOrderRefunds)
            {
                ApplicationArea = All;
                Caption = 'Refresh Shopify Refunds';

                trigger OnAction()
                var
                    RefundMgt: Codeunit "Shopify Refund Mgt.";
                begin
                    RefundMgt.ImportRefundsForOrder(Rec, true);
                    CurrPage.Update(false);
                end;
            }

            action(OpenOrderRefunds)
            {
                ApplicationArea = All;
                Caption = 'Shopify Refunds';

                trigger OnAction()
                var
                    RefundEntry: Record "Shopify Refund Entry";
                begin
                    RefundEntry.SetRange("Shopify Order ID", Rec."Shopify Order ID");
                    Page.Run(Page::"Shopify Refund Entries", RefundEntry);
                end;
            }
        }
    }
}
