codeunit 50202 "Shopify Integration Validator"
{
    procedure ValidateConfiguration(
        var ResultText: Text): Boolean
    var
        ShopifySetup:
            Record "Shopify Integration Setup";

        ShopifySetupMgt:
            Codeunit "Shopify Setup Mgt.";

        Customer:
            Record Customer;

        Location:
            Record Location;

        ShippingItem:
            Record Item;

        Mapping:
            Record "Shopify Product Mapping";

        Item:
            Record Item;

        IssueCount: Integer;
        MappingCount: Integer;
    begin
        Clear(ResultText);
        IssueCount := 0;

        if not ShopifySetup.Get('SETUP') then begin
            AddIssue(
                ResultText,
                IssueCount,
                'Shopify Integration Setup does not exist.');

            exit(false);
        end;

        if ShopifySetup."Shop Domain" = '' then
            AddIssue(
                ResultText,
                IssueCount,
                'Shop Domain is not configured.');

        if ShopifySetup."Client ID" = '' then
            AddIssue(
                ResultText,
                IssueCount,
                'Client ID is not configured.');

        if ShopifySetup."API Version" = '' then
            AddIssue(
                ResultText,
                IssueCount,
                'API Version is not configured.');

        if not ShopifySetupMgt.HasClientSecret() then
            AddIssue(
                ResultText,
                IssueCount,
                'Client Secret is not configured.');

        if ShopifySetup."Shopify Location ID" = '' then
            AddIssue(
                ResultText,
                IssueCount,
                'Shopify Location ID is not configured.')
        else
            if StrPos(
                ShopifySetup."Shopify Location ID",
                'gid://shopify/Location/') <> 1
            then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Shopify Location ID does not have a valid Shopify Location GID format.');

        if ShopifySetup."BC Customer No." = '' then
            AddIssue(
                ResultText,
                IssueCount,
                'BC Customer No. is not configured.')
        else
            if not Customer.Get(
                ShopifySetup."BC Customer No.")
            then
                AddIssue(
                    ResultText,
                    IssueCount,
                    StrSubstNo(
                        'BC customer %1 does not exist.',
                        ShopifySetup."BC Customer No."))
            else
                if Customer.Blocked <>
                   Customer.Blocked::" "
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'BC customer %1 is blocked.',
                            Customer."No."));

        if ShopifySetup."BC Location Code" = '' then
            AddIssue(
                ResultText,
                IssueCount,
                'BC Location Code is not configured.')
        else
            if not Location.Get(
                ShopifySetup."BC Location Code")
            then
                AddIssue(
                    ResultText,
                    IssueCount,
                    StrSubstNo(
                        'BC location %1 does not exist.',
                        ShopifySetup."BC Location Code"));

        if ShopifySetup."BC Shipping Item No." = '' then
            AddIssue(
                ResultText,
                IssueCount,
                'BC Shipping Item No. is not configured.')
        else
            if not ShippingItem.Get(
                ShopifySetup."BC Shipping Item No.")
            then
                AddIssue(
                    ResultText,
                    IssueCount,
                    StrSubstNo(
                        'Shipping item %1 does not exist.',
                        ShopifySetup."BC Shipping Item No."))
            else begin
                if ShippingItem.Blocked then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Shipping item %1 is blocked.',
                            ShippingItem."No."));

                if ShippingItem.Type <>
                   ShippingItem.Type::Service
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Shipping item %1 is not a Service item.',
                            ShippingItem."No."));
            end;

        if ShopifySetup."Import Orders From" = 0DT then
            AddIssue(
                ResultText,
                IssueCount,
                'Import Orders From cutoff is not configured.');

        if ShopifySetup."Background Sync Interval" <= 0 then
            AddIssue(
                ResultText,
                IssueCount,
                'Background Sync Interval must be greater than zero.');

        if ShopifySetup."Tag Imported Orders" then
            if ShopifySetup."Imported Order Tag" = '' then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Imported Order Tag is empty while automatic tagging is enabled.');

        Mapping.Reset();
        MappingCount :=
            Mapping.Count();

        if MappingCount = 0 then
            AddIssue(
                ResultText,
                IssueCount,
                'No Shopify product mappings exist.');

        if Mapping.FindSet() then
            repeat
                if not Item.Get(
                    Mapping."Item No.")
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Mapped BC item %1 does not exist.',
                            Mapping."Item No."))
                else begin
                    if Item.Blocked then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Mapped BC item %1 is blocked.',
                                Item."No."));

                    if Item."Base Unit of Measure" = '' then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Mapped BC item %1 has no Base Unit of Measure.',
                                Item."No."));

                    if Item.Type =
                       Item.Type::Inventory
                    then begin
                        if Item."Inventory Posting Group" = '' then
                            AddIssue(
                                ResultText,
                                IssueCount,
                                StrSubstNo(
                                    'Mapped inventory item %1 has no Inventory Posting Group.',
                                    Item."No."));

                        if Item."Gen. Prod. Posting Group" = '' then
                            AddIssue(
                                ResultText,
                                IssueCount,
                                StrSubstNo(
                                    'Mapped inventory item %1 has no Gen. Prod. Posting Group.',
                                    Item."No."));

                        if Item."VAT Prod. Posting Group" = '' then
                            AddIssue(
                                ResultText,
                                IssueCount,
                                StrSubstNo(
                                    'Mapped inventory item %1 has no VAT Prod. Posting Group.',
                                    Item."No."));
                    end;
                end;
            until Mapping.Next() = 0;

        if IssueCount = 0 then begin
            ResultText :=
                StrSubstNo(
                    'Validation passed. Connection configuration, master data, import cutoff and %1 product mapping(s) are ready.',
                    MappingCount);

            exit(true);
        end;

        ResultText :=
            StrSubstNo(
                'Validation failed with %1 issue(s): %2',
                IssueCount,
                ResultText);

        exit(false);
    end;

    procedure RunValidation()
    var
        ResultText: Text;
    begin
        if ValidateConfiguration(
            ResultText)
        then
            Message(
                'BC Shopify integration validation passed.\%1',
                ResultText)
        else
            Error(
                'BC Shopify integration validation failed.\%1',
                ResultText);
    end;

    local procedure AddIssue(
        var ResultText: Text;
        var IssueCount: Integer;
        IssueText: Text)
    begin
        IssueCount += 1;

        if ResultText <> '' then
            ResultText +=
                ' | ';

        ResultText +=
            StrSubstNo(
                '%1. %2',
                IssueCount,
                IssueText);
    end;
}