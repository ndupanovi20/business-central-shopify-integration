codeunit 50199 "Shopify Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        InitializeSetup();
    end;

    local procedure InitializeSetup()
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        ModifyRequired: Boolean;
    begin
        if not ShopifySetup.Get(
            'SETUP')
        then begin
            ShopifySetup.Init();

            ShopifySetup."Primary Key" :=
                'SETUP';

            ShopifySetup."API Version" :=
                '2026-07';

            ShopifySetup."Background Sync Interval" :=
                15;

            ShopifySetup."Imported Order Tag" :=
                'BC-IMPORTED';

            ShopifySetup."Tag Imported Orders" :=
                false;

            ShopifySetup."Import Only Paid Orders" :=
                false;

            ShopifySetup."Auto Import Orders" :=
                false;

            ShopifySetup."Auto Sync Inventory" :=
                false;

            ShopifySetup.Insert(false);

            exit;
        end;

        if ShopifySetup."API Version" = '' then begin
            ShopifySetup."API Version" :=
                '2026-07';

            ModifyRequired :=
                true;
        end;

        if ShopifySetup."Background Sync Interval" <= 0 then begin
            ShopifySetup."Background Sync Interval" :=
                15;

            ModifyRequired :=
                true;
        end;

        if ShopifySetup."Imported Order Tag" = '' then begin
            ShopifySetup."Imported Order Tag" :=
                'BC-IMPORTED';

            ModifyRequired :=
                true;
        end;

        if ModifyRequired then
            ShopifySetup.Modify(false);
    end;
}