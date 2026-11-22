page 50257 "Shopify Payout Entries"
{
    PageType = List;
    SourceTable = "Shopify Payout Entry";

    Caption = 'Shopify Payout Entries';
    ApplicationArea = All;
    UsageCategory = Lists;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    SourceTableView =
        sorting("Issued At")
        order(descending);

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Issued At"; Rec."Issued At")
                {
                    ApplicationArea = All;
                }

                field("Processing Status"; Rec."Processing Status")
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }

                field("Shopify Status"; Rec."Shopify Status")
                {
                    ApplicationArea = All;
                }

                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = All;
                }

                field("Legacy Resource ID"; Rec."Legacy Resource ID")
                {
                    ApplicationArea = All;
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }

                field("Net Amount"; Rec."Net Amount")
                {
                    ApplicationArea = All;
                }

                field("Total Fee Amount"; Rec."Total Fee Amount")
                {
                    ApplicationArea = All;
                }

                field("Clearing Settlement Amount"; Rec."Clearing Settlement Amount")
                {
                    ApplicationArea = All;
                }

                field("Summary Gross Amount"; Rec."Summary Gross Amount")
                {
                    ApplicationArea = All;
                }

                field("Summary Difference"; Rec."Summary Difference")
                {
                    ApplicationArea = All;
                    StyleExpr = SummaryStyle;
                }

                field("BC Document No."; Rec."BC Document No.")
                {
                    ApplicationArea = All;
                }

                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = All;
                }

                field("Clearing G/L Account No."; Rec."Clearing G/L Account No.")
                {
                    ApplicationArea = All;
                }

                field("Fee G/L Account No."; Rec."Fee G/L Account No.")
                {
                    ApplicationArea = All;
                }

                field("Attempt Count"; Rec."Attempt Count")
                {
                    ApplicationArea = All;
                }

                field("Last Attempt At"; Rec."Last Attempt At")
                {
                    ApplicationArea = All;
                }

                field("Posted At"; Rec."Posted At")
                {
                    ApplicationArea = All;
                }

                field("Result Message"; Rec."Result Message")
                {
                    ApplicationArea = All;
                }

                field("Payout Error"; Rec."Payout Error")
                {
                    ApplicationArea = All;
                }

                field("Shopify Payout ID"; Rec."Shopify Payout ID")
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
                Caption = 'Refresh from Shopify';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PayoutMgt: Codeunit "Shopify Payout Mgt.";
                begin
                    PayoutMgt.ImportLatestPayouts(
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(PostSelectedPayout)
            {
                ApplicationArea = All;
                Caption = 'Post Selected Payout';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PayoutMgt: Codeunit "Shopify Payout Mgt.";
                begin
                    PayoutMgt.PostPayout(
                        Rec,
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(PostAllPendingPayouts)
            {
                ApplicationArea = All;
                Caption = 'Post All Pending Payouts';

                trigger OnAction()
                var
                    PayoutMgt: Codeunit "Shopify Payout Mgt.";
                begin
                    PayoutMgt.ProcessPendingPayouts(
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(RetryFailedPayouts)
            {
                ApplicationArea = All;
                Caption = 'Retry Failed Payouts';

                trigger OnAction()
                var
                    PayoutMgt: Codeunit "Shopify Payout Mgt.";
                begin
                    PayoutMgt.RetryFailedPayouts();
                    CurrPage.Update(false);
                end;
            }

            action(OpenGLEntries)
            {
                ApplicationArea = All;
                Caption = 'Open G/L Entries';

                trigger OnAction()
                var
                    GLEntry: Record "G/L Entry";
                begin
                    Rec.TestField(
                        "BC Document No.");

                    GLEntry.SetRange(
                        "Document No.",
                        Rec."BC Document No.");

                    Page.Run(
                        Page::"General Ledger Entries",
                        GLEntry);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStyles();
    end;

    local procedure SetStyles()
    begin
        case Rec."Processing Status" of
            Rec."Processing Status"::Success:
                StatusStyle :=
                    'Favorable';

            Rec."Processing Status"::Error:
                StatusStyle :=
                    'Unfavorable';

            Rec."Processing Status"::Skipped,
            Rec."Processing Status"::Waiting:
                StatusStyle :=
                    'Attention';

            else
                StatusStyle :=
                    'Standard';
        end;

        if Abs(
            Rec."Summary Difference") > 0.02
        then
            SummaryStyle :=
                'Unfavorable'
        else
            SummaryStyle :=
                'Favorable';
    end;

    var
        StatusStyle: Text;
        SummaryStyle: Text;
}
