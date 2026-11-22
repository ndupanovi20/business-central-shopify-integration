pageextension 50222 "Shopify Status Posting Ext"
    extends "Shopify Integration Status"
{
    layout
    {
        addafter(OrderStatistics)
        {
            group(PostingStatistics)
            {
                Caption = 'Sales Order Posting';

                field(AutoPostImportedOrders; Rec."Auto Post Imported Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Auto Post Imported Orders';
                }

                field(PostingMode; Rec."Posting Mode")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Mode';
                }

                field(PostingDateSource; Rec."Posting Date Source")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date Source';
                }

                field(PostingSuccessCount; PostingSuccessCount)
                {
                    ApplicationArea = All;
                    Caption = 'Successful Postings';
                }

                field(PostingPendingCount; PostingPendingCount)
                {
                    ApplicationArea = All;
                    Caption = 'Pending Postings';
                    Style = Attention;
                }

                field(PostingErrorCount; PostingErrorCount)
                {
                    ApplicationArea = All;
                    Caption = 'Posting Errors';
                    Style = Unfavorable;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculatePostingStatistics();
    end;

    local procedure CalculatePostingStatistics()
    var
        ImportRecord: Record "Shopify Order Import";
    begin
        ImportRecord.SetRange(
            "Posting Status",
            ImportRecord."Posting Status"::Success);

        PostingSuccessCount :=
            ImportRecord.Count();

        ImportRecord.Reset();
        ImportRecord.SetRange(
            "Posting Status",
            ImportRecord."Posting Status"::Pending);

        PostingPendingCount :=
            ImportRecord.Count();

        ImportRecord.Reset();
        ImportRecord.SetRange(
            "Posting Status",
            ImportRecord."Posting Status"::Error);

        PostingErrorCount :=
            ImportRecord.Count();
    end;

    var
        PostingSuccessCount: Integer;
        PostingPendingCount: Integer;
        PostingErrorCount: Integer;
}
