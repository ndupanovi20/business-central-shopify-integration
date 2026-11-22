pageextension 50232 "Shopify Payment Setup Page"
    extends "Shopify Integration Setup"
{
    layout
    {
        addafter(OrderSettings)
        {
            group(PaymentReconciliation)
            {
                Caption = 'Shopify Payment Reconciliation';

                field("Auto Record Shopify Payments"; Rec."Auto Record Shopify Payments")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies whether successfully posted PAID Shopify orders should automatically create and apply a Business Central customer payment to the Shopify clearing G/L account.';
                }

                field("Shopify Clearing G/L Acc. No."; Rec."Shopify Clearing G/L Acc. No.")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies the G/L account that represents funds collected by Shopify but not yet settled to the bank account.';
                }

                field("Payment Journal Template Name"; Rec."Payment Journal Template Name")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies the Business Central general journal template used as the posting context for Shopify customer payments.';
                }

                field("Payment Journal Batch Name"; Rec."Payment Journal Batch Name")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies the Business Central general journal batch used as the posting context for Shopify customer payments.';
                }

                field("Payment Date Source"; Rec."Payment Date Source")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies whether the Shopify payment uses the posted invoice date or the Business Central work date.';
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(RecordEligiblePayments)
            {
                ApplicationArea = All;
                Caption = 'Record Eligible Shopify Payments';

                trigger OnAction()
                var
                    PaymentMgt:
                        Codeunit "Shopify Payment Mgt.";
                begin
                    CurrPage.SaveRecord();

                    PaymentMgt.ProcessEligiblePayments(
                        true);
                end;
            }

            action(RetryFailedPayments)
            {
                ApplicationArea = All;
                Caption = 'Retry Failed Shopify Payments';

                trigger OnAction()
                var
                    PaymentMgt:
                        Codeunit "Shopify Payment Mgt.";
                begin
                    CurrPage.SaveRecord();

                    PaymentMgt.RetryFailedPayments();
                end;
            }

            action(OpenPaymentEntries)
            {
                ApplicationArea = All;
                Caption = 'Shopify Payment Entries';

                trigger OnAction()
                begin
                    Page.Run(
                        Page::"Shopify Payment Entries");
                end;
            }
        }
    }
}
