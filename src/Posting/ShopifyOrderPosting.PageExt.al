pageextension 50216 "Shopify Order Posting Page"
    extends "Shopify Order Imports"
{
    layout
    {
        addafter("Line Count")
        {
            field("Posting Status"; Rec."Posting Status")
            {
                ApplicationArea = All;
                StyleExpr = PostingStatusStyle;
            }

            field("Posting Mode Used"; Rec."Posting Mode Used")
            {
                ApplicationArea = All;
            }

            field("Posted Shipment No."; Rec."Posted Shipment No.")
            {
                ApplicationArea = All;
            }

            field("Posted Invoice No."; Rec."Posted Invoice No.")
            {
                ApplicationArea = All;
            }

            field("Posted At"; Rec."Posted At")
            {
                ApplicationArea = All;
            }

            field("Posting Attempt Count"; Rec."Posting Attempt Count")
            {
                ApplicationArea = All;
            }

            field("Last Posting Attempt At"; Rec."Last Posting Attempt At")
            {
                ApplicationArea = All;
            }

            field("Posting Error"; Rec."Posting Error")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(PreviewPosting)
            {
                ApplicationArea = All;
                Caption = 'Preview Posting';

                trigger OnAction()
                var
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.PreviewPosting(Rec);
                end;
            }

            action(PostUsingSetup)
            {
                ApplicationArea = All;
                Caption = 'Post Using Setup';

                trigger OnAction()
                var
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.PostImportRecord(Rec, true);
                    CurrPage.Update(false);
                end;
            }

            action(PostShipment)
            {
                ApplicationArea = All;
                Caption = 'Post Shipment';

                trigger OnAction()
                var
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.PostImportRecordWithMode(
                        Rec,
                        "Shopify Posting Mode"::Ship,
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(PostInvoice)
            {
                ApplicationArea = All;
                Caption = 'Post Invoice';

                trigger OnAction()
                var
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.PostImportRecordWithMode(
                        Rec,
                        "Shopify Posting Mode"::Invoice,
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(PostShipAndInvoice)
            {
                ApplicationArea = All;
                Caption = 'Post Ship and Invoice';

                trigger OnAction()
                var
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.PostImportRecordWithMode(
                        Rec,
                        "Shopify Posting Mode"::"Ship and Invoice",
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(PostAllPending)
            {
                ApplicationArea = All;
                Caption = 'Post All Pending';

                trigger OnAction()
                var
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.ProcessPendingAutoPostings(true);
                    CurrPage.Update(false);
                end;
            }

            action(RetryFailedPosting)
            {
                ApplicationArea = All;
                Caption = 'Retry Failed Posting';

                trigger OnAction()
                var
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.RetryFailedPosting();
                    CurrPage.Update(false);
                end;
            }

            action(OpenPostedShipment)
            {
                ApplicationArea = All;
                Caption = 'Open Posted Shipment';

                trigger OnAction()
                var
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.OpenPostedShipment(Rec);
                end;
            }

            action(OpenPostedInvoice)
            {
                ApplicationArea = All;
                Caption = 'Open Posted Invoice';

                trigger OnAction()
                var
                    PostingMgt: Codeunit "Shopify Order Posting Mgt.";
                begin
                    PostingMgt.OpenPostedInvoice(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetPostingStatusStyle();
    end;

    local procedure SetPostingStatusStyle()
    begin
        case Rec."Posting Status" of
            Rec."Posting Status"::Success:
                PostingStatusStyle := 'Favorable';

            Rec."Posting Status"::Error:
                PostingStatusStyle := 'Unfavorable';

            Rec."Posting Status"::Pending:
                PostingStatusStyle := 'Attention';

            else
                PostingStatusStyle := 'Standard';
        end;
    end;

    var
        PostingStatusStyle: Text;
}
