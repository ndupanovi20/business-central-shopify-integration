pageextension 50259 "Shopify Payout Setup Page"
    extends "Shopify Integration Setup"
{
    layout
    {
        addbefore(Automation)
        {
            group(PayoutReconciliation)
            {
                Caption = 'Shopify Payout Reconciliation';

                field("Auto Import Shopify Payouts"; Rec."Auto Import Shopify Payouts")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies whether Shopify Payments payouts should be imported automatically through the Shopify Admin GraphQL API.';
                }

                field("Auto Post Paid Payouts"; Rec."Auto Post Paid Payouts")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies whether imported PAID DEPOSIT payouts should automatically post the bank amount and Shopify fees against the Shopify clearing account.';
                }

                field("Import Payouts From"; Rec."Import Payouts From")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies the earliest Shopify Payments payout issue date and time that the integration should import.';
                }

                field("Shopify Payout Bank Acc. No."; Rec."Shopify Payout Bank Acc. No.")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies the Business Central bank account that receives Shopify Payments payouts.';
                }

                field("Shopify Fee G/L Acc. No."; Rec."Shopify Fee G/L Acc. No.")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies the G/L expense account used to post Shopify payout fees.';
                }

                field("Payout Journal Template Name"; Rec."Payout Journal Template Name")
                {
                    ApplicationArea = All;
                }

                field("Payout Journal Batch Name"; Rec."Payout Journal Batch Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ImportShopifyPayouts)
            {
                ApplicationArea = All;
                Caption = 'Import Shopify Payouts';

                trigger OnAction()
                var
                    PayoutMgt: Codeunit "Shopify Payout Mgt.";
                begin
                    CurrPage.SaveRecord();

                    PayoutMgt.ImportLatestPayouts(
                        true);
                end;
            }

            action(PostPendingPayouts)
            {
                ApplicationArea = All;
                Caption = 'Post Pending Shopify Payouts';

                trigger OnAction()
                var
                    PayoutMgt: Codeunit "Shopify Payout Mgt.";
                begin
                    CurrPage.SaveRecord();

                    PayoutMgt.ProcessPendingPayouts(
                        true);
                end;
            }

            action(RetryPayoutErrors)
            {
                ApplicationArea = All;
                Caption = 'Retry Shopify Payout Errors';

                trigger OnAction()
                var
                    PayoutMgt: Codeunit "Shopify Payout Mgt.";
                begin
                    CurrPage.SaveRecord();

                    PayoutMgt.RetryFailedPayouts();
                end;
            }

            action(OpenPayoutEntries)
            {
                ApplicationArea = All;
                Caption = 'Shopify Payout Entries';

                trigger OnAction()
                begin
                    Page.Run(
                        Page::"Shopify Payout Entries");
                end;
            }
        }
    }
}
