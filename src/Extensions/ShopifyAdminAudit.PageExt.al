pageextension 50146 "Shopify Admin Audit Ext"
    extends "Shopify Administration Center"
{
    actions
    {
        addlast(SetupHealthActions)
        {
            action(ValidateLocalConfiguration)
            {
                ApplicationArea = All;
                Caption = 'Validate Configuration';

                trigger OnAction()
                var
                    Validator:
                        Codeunit "Shopify Integration Validator";
                begin
                    Validator.RunValidation();
                end;
            }
        }

        addlast(MonitoringActions)
        {
            action(CreateAuditSnapshot)
            {
                ApplicationArea = All;
                Caption = 'Create Audit Snapshot';

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

        addlast(SetupHealthPromoted)
        {
            actionref(ValidateLocalConfigurationPromoted; ValidateLocalConfiguration)
            {
            }
        }

        addlast(MonitoringPromoted)
        {
            actionref(CreateAuditSnapshotPromoted; CreateAuditSnapshot)
            {
            }

            actionref(OpenAuditSnapshotsPromoted; OpenAuditSnapshots)
            {
            }
        }
    }
}