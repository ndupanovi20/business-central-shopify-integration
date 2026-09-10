pageextension 50145 "Shopify Integration Tag Status"
    extends "Shopify Integration Status"
{
    layout
    {
        addlast(Content)
        {
            group(OrderTagStatistics)
            {
                Caption = 'Shopify Order Tagging';

                field(TaggingEnabled; TaggingEnabled)
                {
                    ApplicationArea = All;
                    Caption = 'Automatic Tagging Enabled';
                    Editable = false;
                }

                field(ConfiguredTag; ConfiguredTag)
                {
                    ApplicationArea = All;
                    Caption = 'Configured Tag';
                    Editable = false;
                }

                field(SuccessfullyTaggedOrders; SuccessfullyTaggedOrders)
                {
                    ApplicationArea = All;
                    Caption = 'Successfully Tagged Orders';
                    Editable = false;
                }

                field(TagErrorCount; TagErrorCount)
                {
                    ApplicationArea = All;
                    Caption = 'Tag Errors';
                    Editable = false;
                    Style = Unfavorable;
                }

                field(UntaggedOrderCount; UntaggedOrderCount)
                {
                    ApplicationArea = All;
                    Caption = 'Not Tagged / Not Required';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(RetryTagErrors)
            {
                ApplicationArea = All;
                Caption = 'Retry Tag Errors';

                trigger OnAction()
                var
                    TagMgt:
                        Codeunit "Shopify Order Tag Mgt.";
                begin
                    TagMgt.RetryFailedTags();

                    CalculateTagStatistics();

                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CalculateTagStatistics();
    end;

    trigger OnAfterGetRecord()
    begin
        CalculateTagStatistics();
    end;

    local procedure CalculateTagStatistics()
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        ImportRecord:
            Record "Shopify Order Import";
    begin
        Clear(
            SuccessfullyTaggedOrders);

        Clear(
            TagErrorCount);

        Clear(
            UntaggedOrderCount);

        if ShopifySetup.Get(
            'SETUP')
        then begin
            TaggingEnabled :=
                ShopifySetup."Tag Imported Orders";

            ConfiguredTag :=
                ShopifySetup."Imported Order Tag";
        end;

        ImportRecord.SetRange(
            "Tag Status",
            ImportRecord."Tag Status"::Success);

        SuccessfullyTaggedOrders :=
            ImportRecord.Count();

        ImportRecord.Reset();

        ImportRecord.SetRange(
            "Tag Status",
            ImportRecord."Tag Status"::Error);

        TagErrorCount :=
            ImportRecord.Count();

        ImportRecord.Reset();

        ImportRecord.SetRange(
            "Tag Status",
            ImportRecord."Tag Status"::"Not Required");

        UntaggedOrderCount :=
            ImportRecord.Count();
    end;

    var
        TaggingEnabled: Boolean;
        ConfiguredTag: Text[50];

        SuccessfullyTaggedOrders: Integer;
        TagErrorCount: Integer;
        UntaggedOrderCount: Integer;
}