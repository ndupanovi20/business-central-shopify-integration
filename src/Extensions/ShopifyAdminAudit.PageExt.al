pageextension 50146 "Shopify Admin Audit Ext"
    extends "Shopify Administration Center"
{
    actions
    {
        addlast(Processing)
        {
            action(ValidateLocalConfiguration)
            {
                ApplicationArea = All;
                Caption = 'Validate Configuration';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Validator:
                        Codeunit "Shopify Integration Validator";
                begin
                    Validator.RunValidation();
                end;
            }

            action(CreateAuditSnapshot)
            {
                ApplicationArea = All;
                Caption = 'Create Audit Snapshot';

                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    AuditMgt:
                        Codeunit "Shopify Audit Mgt.";
                begin
                    AuditMgt.CreateSnapshot(
                        true);
                end;
            }

            action(OpenAuditSnapshots)
            {
                ApplicationArea = All;
                Caption = 'Audit Snapshots';

                RunObject =
                    page "Shopify Audit Snapshots";
            }
        }
    }
}