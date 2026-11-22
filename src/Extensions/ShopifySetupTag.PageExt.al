pageextension 50144 "Shopify Setup Tag Ext"
    extends "Shopify Integration Setup"
{
    layout
    {
        addbefore(Automation)
        {
            group(OrderTagging)
            {
                Caption = 'Shopify Order Tagging';

                field(
                    "Tag Imported Orders";
                Rec."Tag Imported Orders")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies whether a successfully imported Shopify order should automatically receive a Shopify tag.';
                }

                field(
                    "Imported Order Tag";
                Rec."Imported Order Tag")
                {
                    ApplicationArea = All;

                    ToolTip =
                        'Specifies the Shopify tag added after a successful Business Central order import. The default value is BC-IMPORTED.';
                }
            }
        }
    }
}