page 50226 "Shopify Payment Entries"
{
    PageType = List;
    SourceTable = "Shopify Payment Entry";

    Caption = 'Shopify Payment Entries';
    ApplicationArea = All;
    UsageCategory = Lists;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    SourceTableView =
        sorting("Posted At")
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

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }

                field("Posted Invoice No."; Rec."Posted Invoice No.")
                {
                    ApplicationArea = All;
                }

                field("Payment Document No."; Rec."Payment Document No.")
                {
                    ApplicationArea = All;
                }

                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }

                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }

                field("Clearing G/L Account No."; Rec."Clearing G/L Account No.")
                {
                    ApplicationArea = All;
                }

                field("Invoice Cust. Ledger Entry No."; Rec."Invoice Cust. Ledger Entry No.")
                {
                    ApplicationArea = All;
                }

                field("Payment Cust. Ledger Entry No."; Rec."Payment Cust. Ledger Entry No.")
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

                field("Payment Error"; Rec."Payment Error")
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
            action(RetryPayment)
            {
                ApplicationArea = All;
                Caption = 'Retry Payment';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PaymentMgt:
                        Codeunit "Shopify Payment Mgt.";
                begin
                    PaymentMgt.RetryPaymentEntry(
                        Rec,
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(OpenPostedInvoice)
            {
                ApplicationArea = All;
                Caption = 'Open Posted Invoice';

                trigger OnAction()
                var
                    SalesInvoiceHeader:
                        Record "Sales Invoice Header";
                begin
                    Rec.TestField(
                        "Posted Invoice No.");

                    if not SalesInvoiceHeader.Get(
                        Rec."Posted Invoice No.")
                    then
                        Error(
                            'Posted Sales Invoice %1 does not exist.',
                            Rec."Posted Invoice No.");

                    Page.Run(
                        Page::"Posted Sales Invoice",
                        SalesInvoiceHeader);
                end;
            }

            action(OpenInvoiceLedgerEntry)
            {
                ApplicationArea = All;
                Caption = 'Open Invoice Ledger Entry';

                trigger OnAction()
                var
                    CustLedgerEntry:
                        Record "Cust. Ledger Entry";
                begin
                    if Rec."Invoice Cust. Ledger Entry No." = 0 then
                        Error(
                            'Invoice Customer Ledger Entry is not available.');

                    CustLedgerEntry.SetRange(
                        "Entry No.",
                        Rec."Invoice Cust. Ledger Entry No.");

                    Page.Run(
                        Page::"Customer Ledger Entries",
                        CustLedgerEntry);
                end;
            }

            action(OpenPaymentLedgerEntry)
            {
                ApplicationArea = All;
                Caption = 'Open Payment Ledger Entry';

                trigger OnAction()
                var
                    CustLedgerEntry:
                        Record "Cust. Ledger Entry";
                begin
                    if Rec."Payment Cust. Ledger Entry No." = 0 then
                        Error(
                            'Payment Customer Ledger Entry is not available.');

                    CustLedgerEntry.SetRange(
                        "Entry No.",
                        Rec."Payment Cust. Ledger Entry No.");

                    Page.Run(
                        Page::"Customer Ledger Entries",
                        CustLedgerEntry);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
    end;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Success:
                StatusStyle :=
                    'Favorable';

            Rec.Status::Error:
                StatusStyle :=
                    'Unfavorable';

            Rec.Status::Skipped:
                StatusStyle :=
                    'Attention';

            Rec.Status::Pending:
                StatusStyle :=
                    'Attention';

            else
                StatusStyle :=
                    'Standard';
        end;
    end;

    var
        StatusStyle: Text;
}
