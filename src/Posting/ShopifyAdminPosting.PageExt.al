pageextension 50219 "Shopify Admin Posting Ext"
    extends "Shopify Administration Center"
{
    layout
    {
        addlast(ERPProcessingState)
        {
            field(PostedOrderCount; PostedOrderCount)
            {
                ApplicationArea = All;
                Caption = 'Successfully Posted Orders';
            }

            field(PostingErrorCount; PostingErrorCount)
            {
                ApplicationArea = All;
                Caption = 'Posting Errors';
                StyleExpr = PostingErrorStyle;
            }
        }

        addlast(Automation)
        {
            field("Auto Post Imported Orders"; Rec."Auto Post Imported Orders")
            {
                ApplicationArea = All;
                Caption = 'Auto Post Imported Orders';
            }

            field("Posting Mode"; Rec."Posting Mode")
            {
                ApplicationArea = All;
                Caption = 'Posting Mode';
            }
        }
    }

    actions
    {
        addlast(OrderProcessingActions)
        {
            action(ProcessPendingPostings)
            {
                ApplicationArea = All;
                Caption = 'Process Pending Postings';

                trigger OnAction()
                var
                    PostingMgt:
                        Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.ProcessPendingAutoPostings(true);
                    CurrPage.Update(false);
                end;
            }

            action(RetryPostingErrors)
            {
                ApplicationArea = All;
                Caption = 'Retry Posting Errors';

                trigger OnAction()
                var
                    PostingMgt:
                        Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.RetryFailedPosting();
                    CurrPage.Update(false);
                end;
            }
        }

        addlast(OrderProcessingPromoted)
        {
            actionref(ProcessPendingPostingsPromoted; ProcessPendingPostings)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculatePostingState();
    end;

    local procedure CalculatePostingState()
    var
        ImportRecord:
            Record "Shopify Order Import";
    begin
        ImportRecord.Reset();
        ImportRecord.SetRange(
            "Posting Status",
            ImportRecord."Posting Status"::Success);

        PostedOrderCount :=
            ImportRecord.Count();

        ImportRecord.Reset();
        ImportRecord.SetRange(
            "Posting Status",
            ImportRecord."Posting Status"::Error);

        PostingErrorCount :=
            ImportRecord.Count();

        if PostingErrorCount > 0 then
            PostingErrorStyle :=
                'Unfavorable'
        else
            PostingErrorStyle :=
                'Favorable';
    end;

    var
        PostedOrderCount: Integer;
        PostingErrorCount: Integer;
        PostingErrorStyle: Text;
}