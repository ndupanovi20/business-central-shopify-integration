pageextension 50143 "Shopify Order Imports Tag Ext"
    extends "Shopify Order Imports"
{
    layout
    {
        addafter("Imported At")
        {
            field("Tag Status"; Rec."Tag Status")
            {
                ApplicationArea = All;
            }

            field("Tagged At"; Rec."Tagged At")
            {
                ApplicationArea = All;
            }

            field("Tag Retry Count"; Rec."Tag Retry Count")
            {
                ApplicationArea = All;
            }

            field("Tag Error"; Rec."Tag Error")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(TagSelectedOrder)
            {
                ApplicationArea = All;
                Caption = 'Tag Selected Order';

                trigger OnAction()
                var
                    TagMgt:
                        Codeunit "Shopify Order Tag Mgt.";
                begin
                    TagMgt.TagImportRecord(
                        Rec,
                        true);

                    CurrPage.Update(false);
                end;
            }

            action(RetryFailedTags)
            {
                ApplicationArea = All;
                Caption = 'Retry Failed Tags';

                trigger OnAction()
                var
                    TagMgt:
                        Codeunit "Shopify Order Tag Mgt.";
                begin
                    TagMgt.RetryFailedTags();

                    CurrPage.Update(false);
                end;
            }

            action(TagAllUntagged)
            {
                ApplicationArea = All;
                Caption = 'Tag All Untagged Orders';

                trigger OnAction()
                var
                    TagMgt:
                        Codeunit "Shopify Order Tag Mgt.";
                begin
                    if not Confirm(
                        'Tag all previously imported Shopify orders that are not currently tagged?',
                        false)
                    then
                        exit;

                    TagMgt.TagAllUntagged();

                    CurrPage.Update(false);
                end;
            }
        }
    }
}