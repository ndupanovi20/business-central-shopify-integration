codeunit 50196 "Shopify Demo Setup"
{
    procedure InitializeDemoCompany()
    var
        SourceCompanyName: Text;
    begin
        FindSourceCompany(
            SourceCompanyName);

        CopyCustomer(
            SourceCompanyName);

        CopyLocation(
            SourceCompanyName);

        CopyItem(
            SourceCompanyName,
            'SHOP-SHIPPING');

        CopyItem(
            SourceCompanyName,
            'BC-SHOP-001');

        CopyRequiredSetup(
            SourceCompanyName);

        CopyCurrency(
            SourceCompanyName,
            'USD');

        CopyCurrencyExchangeRates(
            SourceCompanyName,
            'USD');

        CopyShopifySetup(
            SourceCompanyName);

        CopyProductMapping(
            SourceCompanyName,
            'BC-SHOP-001');

        Message(
            'BC Shopify demo company initialized successfully.\' +
            'Required posting setup and item setup were also checked/copied.\' +
            'Source company: %1',
            SourceCompanyName);
    end;

    local procedure FindSourceCompany(
        var SourceCompanyName: Text)
    var
        Company:
            Record Company;

        SourceSetup:
            Record "Shopify Integration Setup";
    begin
        Company.Reset();

        if Company.FindSet() then
            repeat
                if Company.Name <> CompanyName() then begin
                    SourceSetup.ChangeCompany(
                        Company.Name);

                    if SourceSetup.Get('SETUP') then
                        if
                            (SourceSetup."Shop Domain" <> '') and
                            (SourceSetup."Client ID" <> '')
                        then begin
                            SourceCompanyName :=
                                Company.Name;

                            exit;
                        end;
                end;
            until Company.Next() = 0;

        Error(
            'A previously configured Shopify company could not be found.');
    end;

    local procedure CopyRequiredSetup(
        SourceCompanyName: Text)
    var
        SourceCustomer:
            Record Customer;
    begin
        SourceCustomer.ChangeCompany(
            SourceCompanyName);

        if not SourceCustomer.Get(
            'SHOPIFY')
        then
            Error(
                'Customer SHOPIFY does not exist in source company %1.',
                SourceCompanyName);

        CopyGenBusinessPostingGroup(
            SourceCompanyName,
            SourceCustomer."Gen. Bus. Posting Group");

        CopyVATBusinessPostingGroup(
            SourceCompanyName,
            SourceCustomer."VAT Bus. Posting Group");

        CopyCustomerPostingGroup(
            SourceCompanyName,
            SourceCustomer."Customer Posting Group");

        CopyPaymentTerms(
            SourceCompanyName,
            SourceCustomer."Payment Terms Code");

        CopyPaymentMethod(
            SourceCompanyName,
            SourceCustomer."Payment Method Code");

        CopyItemDependencies(
            SourceCompanyName,
            'BC-SHOP-001',
            SourceCustomer."Gen. Bus. Posting Group",
            SourceCustomer."VAT Bus. Posting Group");

        CopyItemDependencies(
            SourceCompanyName,
            'SHOP-SHIPPING',
            SourceCustomer."Gen. Bus. Posting Group",
            SourceCustomer."VAT Bus. Posting Group");
    end;

    local procedure CopyItemDependencies(
        SourceCompanyName: Text;
        ItemNo: Code[20];
        CustomerGenBusPostingGroup: Code[20];
        CustomerVATBusPostingGroup: Code[20])
    var
        SourceItem:
            Record Item;
    begin
        SourceItem.ChangeCompany(
            SourceCompanyName);

        if not SourceItem.Get(
            ItemNo)
        then
            Error(
                'Item %1 does not exist in source company %2.',
                ItemNo,
                SourceCompanyName);

        CopyUnitOfMeasure(
            SourceCompanyName,
            SourceItem."Base Unit of Measure");

        CopyItemUnitOfMeasures(
            SourceCompanyName,
            ItemNo);

        CopyGenProductPostingGroup(
            SourceCompanyName,
            SourceItem."Gen. Prod. Posting Group");

        CopyVATProductPostingGroup(
            SourceCompanyName,
            SourceItem."VAT Prod. Posting Group");

        CopyGeneralPostingSetup(
            SourceCompanyName,
            CustomerGenBusPostingGroup,
            SourceItem."Gen. Prod. Posting Group");

        CopyBlankGeneralPostingSetup(
            SourceCompanyName,
            CustomerGenBusPostingGroup,
            SourceItem."Gen. Prod. Posting Group");

        CopyVATPostingSetup(
            SourceCompanyName,
            CustomerVATBusPostingGroup,
            SourceItem."VAT Prod. Posting Group");

        if SourceItem.Type =
           SourceItem.Type::Inventory
        then begin
            CopyInventoryPostingGroup(
                SourceCompanyName,
                SourceItem."Inventory Posting Group");

            CopyInventoryPostingSetup(
                SourceCompanyName,
                'SHOP',
                SourceItem."Inventory Posting Group");
        end;
    end;

    local procedure CopyCustomer(
        SourceCompanyName: Text)
    var
        SourceCustomer:
            Record Customer;

        TargetCustomer:
            Record Customer;
    begin
        if TargetCustomer.Get(
            'SHOPIFY')
        then
            exit;

        SourceCustomer.ChangeCompany(
            SourceCompanyName);

        if not SourceCustomer.Get(
            'SHOPIFY')
        then
            Error(
                'Customer SHOPIFY does not exist in source company %1.',
                SourceCompanyName);

        TargetCustomer.Init();

        TargetCustomer.TransferFields(
            SourceCustomer,
            true);

        TargetCustomer.Insert(false);
    end;

    local procedure CopyLocation(
        SourceCompanyName: Text)
    var
        SourceLocation:
            Record Location;

        TargetLocation:
            Record Location;
    begin
        if TargetLocation.Get(
            'SHOP')
        then
            exit;

        SourceLocation.ChangeCompany(
            SourceCompanyName);

        if not SourceLocation.Get(
            'SHOP')
        then
            Error(
                'Location SHOP does not exist in source company %1.',
                SourceCompanyName);

        TargetLocation.Init();

        TargetLocation.TransferFields(
            SourceLocation,
            true);

        TargetLocation.Insert(false);
    end;

    local procedure CopyItem(
        SourceCompanyName: Text;
        ItemNo: Code[20])
    var
        SourceItem:
            Record Item;

        TargetItem:
            Record Item;
    begin
        if TargetItem.Get(
            ItemNo)
        then
            exit;

        SourceItem.ChangeCompany(
            SourceCompanyName);

        if not SourceItem.Get(
            ItemNo)
        then
            Error(
                'Item %1 does not exist in source company %2.',
                ItemNo,
                SourceCompanyName);

        TargetItem.Init();

        TargetItem.TransferFields(
            SourceItem,
            true);

        TargetItem.Insert(false);
    end;

    local procedure CopyGenBusinessPostingGroup(
        SourceCompanyName: Text;
        PostingGroupCode: Code[20])
    var
        SourceGroup:
            Record "Gen. Business Posting Group";

        TargetGroup:
            Record "Gen. Business Posting Group";
    begin
        if PostingGroupCode = '' then
            exit;

        if TargetGroup.Get(
            PostingGroupCode)
        then
            exit;

        SourceGroup.ChangeCompany(
            SourceCompanyName);

        if not SourceGroup.Get(
            PostingGroupCode)
        then
            Error(
                'Gen. Business Posting Group %1 does not exist in source company.',
                PostingGroupCode);

        TargetGroup.Init();

        TargetGroup.TransferFields(
            SourceGroup,
            true);

        TargetGroup.Insert(false);
    end;

    local procedure CopyGenProductPostingGroup(
        SourceCompanyName: Text;
        PostingGroupCode: Code[20])
    var
        SourceGroup:
            Record "Gen. Product Posting Group";

        TargetGroup:
            Record "Gen. Product Posting Group";
    begin
        if PostingGroupCode = '' then
            exit;

        if TargetGroup.Get(
            PostingGroupCode)
        then
            exit;

        SourceGroup.ChangeCompany(
            SourceCompanyName);

        if not SourceGroup.Get(
            PostingGroupCode)
        then
            Error(
                'Gen. Product Posting Group %1 does not exist in source company.',
                PostingGroupCode);

        TargetGroup.Init();

        TargetGroup.TransferFields(
            SourceGroup,
            true);

        TargetGroup.Insert(false);
    end;

    local procedure CopyVATBusinessPostingGroup(
        SourceCompanyName: Text;
        PostingGroupCode: Code[20])
    var
        SourceGroup:
            Record "VAT Business Posting Group";

        TargetGroup:
            Record "VAT Business Posting Group";
    begin
        if PostingGroupCode = '' then
            exit;

        if TargetGroup.Get(
            PostingGroupCode)
        then
            exit;

        SourceGroup.ChangeCompany(
            SourceCompanyName);

        if not SourceGroup.Get(
            PostingGroupCode)
        then
            Error(
                'VAT Business Posting Group %1 does not exist in source company.',
                PostingGroupCode);

        TargetGroup.Init();

        TargetGroup.TransferFields(
            SourceGroup,
            true);

        TargetGroup.Insert(false);
    end;

    local procedure CopyVATProductPostingGroup(
        SourceCompanyName: Text;
        PostingGroupCode: Code[20])
    var
        SourceGroup:
            Record "VAT Product Posting Group";

        TargetGroup:
            Record "VAT Product Posting Group";
    begin
        if PostingGroupCode = '' then
            exit;

        if TargetGroup.Get(
            PostingGroupCode)
        then
            exit;

        SourceGroup.ChangeCompany(
            SourceCompanyName);

        if not SourceGroup.Get(
            PostingGroupCode)
        then
            Error(
                'VAT Product Posting Group %1 does not exist in source company.',
                PostingGroupCode);

        TargetGroup.Init();

        TargetGroup.TransferFields(
            SourceGroup,
            true);

        TargetGroup.Insert(false);
    end;

    local procedure CopyVATPostingSetup(
        SourceCompanyName: Text;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20])
    var
        SourceVATSetup:
            Record "VAT Posting Setup";

        TargetVATSetup:
            Record "VAT Posting Setup";
    begin
        if (VATBusPostingGroup = '') or
           (VATProdPostingGroup = '')
        then
            exit;

        if TargetVATSetup.Get(
            VATBusPostingGroup,
            VATProdPostingGroup)
        then
            exit;

        SourceVATSetup.ChangeCompany(
            SourceCompanyName);

        if not SourceVATSetup.Get(
            VATBusPostingGroup,
            VATProdPostingGroup)
        then
            Error(
                'VAT Posting Setup %1 / %2 does not exist in source company.',
                VATBusPostingGroup,
                VATProdPostingGroup);

        TargetVATSetup.Init();

        TargetVATSetup.TransferFields(
            SourceVATSetup,
            true);

        TargetVATSetup.Insert(false);
    end;

    local procedure CopyGeneralPostingSetup(
        SourceCompanyName: Text;
        GenBusPostingGroup: Code[20];
        GenProdPostingGroup: Code[20])
    var
        SourcePostingSetup:
            Record "General Posting Setup";

        TargetPostingSetup:
            Record "General Posting Setup";
    begin
        if GenProdPostingGroup = '' then
            exit;

        if TargetPostingSetup.Get(
            GenBusPostingGroup,
            GenProdPostingGroup)
        then
            exit;

        SourcePostingSetup.ChangeCompany(
            SourceCompanyName);

        if not SourcePostingSetup.Get(
            GenBusPostingGroup,
            GenProdPostingGroup)
        then
            exit;

        TargetPostingSetup.Init();

        TargetPostingSetup.TransferFields(
            SourcePostingSetup,
            true);

        TargetPostingSetup.Insert(false);
    end;

    local procedure CopyBlankGeneralPostingSetup(
        SourceCompanyName: Text;
        FallbackGenBusPostingGroup: Code[20];
        GenProdPostingGroup: Code[20])
    var
        SourcePostingSetup:
            Record "General Posting Setup";

        TargetPostingSetup:
            Record "General Posting Setup";
    begin
        if GenProdPostingGroup = '' then
            exit;

        if TargetPostingSetup.Get(
            '',
            GenProdPostingGroup)
        then
            exit;

        SourcePostingSetup.ChangeCompany(
            SourceCompanyName);

        if not SourcePostingSetup.Get(
            '',
            GenProdPostingGroup)
        then begin
            SourcePostingSetup.Reset();

            if not SourcePostingSetup.Get(
                FallbackGenBusPostingGroup,
                GenProdPostingGroup)
            then
                exit;
        end;

        TargetPostingSetup.Init();

        TargetPostingSetup.TransferFields(
            SourcePostingSetup,
            true);

        TargetPostingSetup."Gen. Bus. Posting Group" :=
            '';

        TargetPostingSetup."Gen. Prod. Posting Group" :=
            GenProdPostingGroup;

        TargetPostingSetup.Insert(false);
    end;

    local procedure CopyInventoryPostingGroup(
        SourceCompanyName: Text;
        PostingGroupCode: Code[20])
    var
        SourceGroup:
            Record "Inventory Posting Group";

        TargetGroup:
            Record "Inventory Posting Group";
    begin
        if PostingGroupCode = '' then
            exit;

        if TargetGroup.Get(
            PostingGroupCode)
        then
            exit;

        SourceGroup.ChangeCompany(
            SourceCompanyName);

        if not SourceGroup.Get(
            PostingGroupCode)
        then
            Error(
                'Inventory Posting Group %1 does not exist in source company.',
                PostingGroupCode);

        TargetGroup.Init();

        TargetGroup.TransferFields(
            SourceGroup,
            true);

        TargetGroup.Insert(false);
    end;

    local procedure CopyInventoryPostingSetup(
        SourceCompanyName: Text;
        LocationCode: Code[10];
        InventoryPostingGroupCode: Code[20])
    var
        SourcePostingSetup:
            Record "Inventory Posting Setup";

        TargetPostingSetup:
            Record "Inventory Posting Setup";
    begin
        if InventoryPostingGroupCode = '' then
            exit;

        if TargetPostingSetup.Get(
            LocationCode,
            InventoryPostingGroupCode)
        then
            exit;

        SourcePostingSetup.ChangeCompany(
            SourceCompanyName);

        if not SourcePostingSetup.Get(
            LocationCode,
            InventoryPostingGroupCode)
        then begin
            SourcePostingSetup.Reset();

            if not SourcePostingSetup.Get(
                '',
                InventoryPostingGroupCode)
            then
                Error(
                    'Inventory Posting Setup for group %1 does not exist in source company.',
                    InventoryPostingGroupCode);
        end;

        TargetPostingSetup.Init();

        TargetPostingSetup.TransferFields(
            SourcePostingSetup,
            true);

        TargetPostingSetup."Location Code" :=
            LocationCode;

        TargetPostingSetup."Invt. Posting Group Code" :=
            InventoryPostingGroupCode;

        TargetPostingSetup.Insert(false);
    end;

    local procedure CopyCustomerPostingGroup(
        SourceCompanyName: Text;
        PostingGroupCode: Code[20])
    var
        SourceGroup:
            Record "Customer Posting Group";

        TargetGroup:
            Record "Customer Posting Group";
    begin
        if PostingGroupCode = '' then
            exit;

        if TargetGroup.Get(
            PostingGroupCode)
        then
            exit;

        SourceGroup.ChangeCompany(
            SourceCompanyName);

        if not SourceGroup.Get(
            PostingGroupCode)
        then
            exit;

        TargetGroup.Init();

        TargetGroup.TransferFields(
            SourceGroup,
            true);

        TargetGroup.Insert(false);
    end;

    local procedure CopyPaymentTerms(
        SourceCompanyName: Text;
        TermsCode: Code[10])
    var
        SourceTerms:
            Record "Payment Terms";

        TargetTerms:
            Record "Payment Terms";
    begin
        if TermsCode = '' then
            exit;

        if TargetTerms.Get(
            TermsCode)
        then
            exit;

        SourceTerms.ChangeCompany(
            SourceCompanyName);

        if not SourceTerms.Get(
            TermsCode)
        then
            exit;

        TargetTerms.Init();

        TargetTerms.TransferFields(
            SourceTerms,
            true);

        TargetTerms.Insert(false);
    end;

    local procedure CopyPaymentMethod(
        SourceCompanyName: Text;
        MethodCode: Code[10])
    var
        SourceMethod:
            Record "Payment Method";

        TargetMethod:
            Record "Payment Method";
    begin
        if MethodCode = '' then
            exit;

        if TargetMethod.Get(
            MethodCode)
        then
            exit;

        SourceMethod.ChangeCompany(
            SourceCompanyName);

        if not SourceMethod.Get(
            MethodCode)
        then
            exit;

        TargetMethod.Init();

        TargetMethod.TransferFields(
            SourceMethod,
            true);

        TargetMethod.Insert(false);
    end;

    local procedure CopyUnitOfMeasure(
        SourceCompanyName: Text;
        UnitOfMeasureCode: Code[10])
    var
        SourceUOM:
            Record "Unit of Measure";

        TargetUOM:
            Record "Unit of Measure";
    begin
        if UnitOfMeasureCode = '' then
            exit;

        if TargetUOM.Get(
            UnitOfMeasureCode)
        then
            exit;

        SourceUOM.ChangeCompany(
            SourceCompanyName);

        if not SourceUOM.Get(
            UnitOfMeasureCode)
        then
            exit;

        TargetUOM.Init();

        TargetUOM.TransferFields(
            SourceUOM,
            true);

        TargetUOM.Insert(false);
    end;

    local procedure CopyItemUnitOfMeasures(
        SourceCompanyName: Text;
        ItemNo: Code[20])
    var
        SourceItemUOM:
            Record "Item Unit of Measure";

        TargetItemUOM:
            Record "Item Unit of Measure";
    begin
        SourceItemUOM.ChangeCompany(
            SourceCompanyName);

        SourceItemUOM.SetRange(
            "Item No.",
            ItemNo);

        if not SourceItemUOM.FindSet() then
            exit;

        repeat
            if not TargetItemUOM.Get(
                ItemNo,
                SourceItemUOM.Code)
            then begin
                TargetItemUOM.Init();

                TargetItemUOM.TransferFields(
                    SourceItemUOM,
                    true);

                TargetItemUOM.Insert(false);
            end;
        until SourceItemUOM.Next() = 0;
    end;

    local procedure CopyCurrency(
        SourceCompanyName: Text;
        CurrencyCode: Code[10])
    var
        SourceCurrency:
            Record Currency;

        TargetCurrency:
            Record Currency;
    begin
        if TargetCurrency.Get(
            CurrencyCode)
        then
            exit;

        SourceCurrency.ChangeCompany(
            SourceCompanyName);

        if not SourceCurrency.Get(
            CurrencyCode)
        then
            exit;

        TargetCurrency.Init();

        TargetCurrency.TransferFields(
            SourceCurrency,
            true);

        TargetCurrency.Insert(false);
    end;

    local procedure CopyCurrencyExchangeRates(
        SourceCompanyName: Text;
        CurrencyCode: Code[10])
    var
        SourceExchangeRate:
            Record "Currency Exchange Rate";

        TargetExchangeRate:
            Record "Currency Exchange Rate";
    begin
        SourceExchangeRate.ChangeCompany(
            SourceCompanyName);

        SourceExchangeRate.SetRange(
            "Currency Code",
            CurrencyCode);

        if not SourceExchangeRate.FindSet() then
            exit;

        repeat
            if not TargetExchangeRate.Get(
                SourceExchangeRate."Currency Code",
                SourceExchangeRate."Starting Date")
            then begin
                TargetExchangeRate.Init();

                TargetExchangeRate.TransferFields(
                    SourceExchangeRate,
                    true);

                TargetExchangeRate.Insert(false);
            end;
        until SourceExchangeRate.Next() = 0;
    end;

    local procedure CopyShopifySetup(
        SourceCompanyName: Text)
    var
        SourceSetup:
            Record "Shopify Integration Setup";

        TargetSetup:
            Record "Shopify Integration Setup";
    begin
        SourceSetup.ChangeCompany(
            SourceCompanyName);

        if not SourceSetup.Get(
            'SETUP')
        then
            Error(
                'Shopify Integration Setup does not exist in source company %1.',
                SourceCompanyName);

        if not TargetSetup.Get(
            'SETUP')
        then begin
            TargetSetup.Init();

            TargetSetup."Primary Key" :=
                'SETUP';

            TargetSetup.Insert();
        end;

        TargetSetup."Shop Domain" :=
            SourceSetup."Shop Domain";

        TargetSetup."Client ID" :=
            SourceSetup."Client ID";

        TargetSetup."API Version" :=
            SourceSetup."API Version";

        TargetSetup."Shopify Location ID" :=
            SourceSetup."Shopify Location ID";

        TargetSetup."BC Customer No." :=
            'SHOPIFY';

        TargetSetup."BC Location Code" :=
            'SHOP';

        TargetSetup."BC Shipping Item No." :=
            'SHOP-SHIPPING';

        TargetSetup."Customer Strategy" :=
            TargetSetup."Customer Strategy"::"Generic Customer";

        TargetSetup."Apply Shopify Order Addresses" :=
            true;

        TargetSetup."Fallback to Generic Customer" :=
            true;

        TargetSetup."Use Location Mappings" :=
            false;

        TargetSetup."Import Only Paid Orders" :=
            false;

        TargetSetup."Auto Import Orders" :=
            false;

        TargetSetup."Auto Sync Inventory" :=
            false;

        TargetSetup."Auto Post Imported Orders" :=
            false;

        TargetSetup."Auto Record Shopify Payments" :=
            false;

        TargetSetup."Auto Import Shopify Refunds" :=
            false;

        TargetSetup."Auto Process Shopify Refunds" :=
            false;

        TargetSetup."Import Refunds From" :=
            CurrentDateTime();

        TargetSetup."Auto Create Fulfillment" :=
            false;

        TargetSetup."Auto Sync Fulfillment Tracking" :=
            false;

        TargetSetup."Auto Import Shopify Payouts" :=
            false;

        TargetSetup."Auto Post Paid Payouts" :=
            false;

        TargetSetup."Notify Customer on Fulfillment" :=
            false;

        TargetSetup."Require Tracking No." :=
            false;

        Clear(
            TargetSetup."Last Background Sync");

        Clear(
            TargetSetup."Last Background Result");

        TargetSetup.Modify(true);
    end;

    local procedure CopyProductMapping(
        SourceCompanyName: Text;
        ItemNo: Code[20])
    var
        SourceMapping:
            Record "Shopify Product Mapping";

        TargetMapping:
            Record "Shopify Product Mapping";
    begin
        if TargetMapping.Get(
            ItemNo)
        then
            exit;

        SourceMapping.ChangeCompany(
            SourceCompanyName);

        if not SourceMapping.Get(
            ItemNo)
        then
            Error(
                'Product Mapping for item %1 does not exist in source company %2.',
                ItemNo,
                SourceCompanyName);

        TargetMapping.Init();

        TargetMapping.TransferFields(
            SourceMapping,
            true);

        TargetMapping.Insert(false);
    end;
}