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

        ClearingGLAccount:
            Record "G/L Account";

        GenJournalTemplate:
            Record "Gen. Journal Template";

        GenJournalBatch:
            Record "Gen. Journal Batch";

        PayoutBankAccount:
            Record "Bank Account";

        PayoutFeeGLAccount:
            Record "G/L Account";

        PayoutJournalTemplate:
            Record "Gen. Journal Template";

        PayoutJournalBatch:
            Record "Gen. Journal Batch";

        Mapping:
            Record "Shopify Product Mapping";

        CustomerMapping:
            Record "Shopify Customer Mapping";

        LocationMapping:
            Record "Shopify Location Mapping";

        Item:
            Record Item;

        IssueCount: Integer;
        MappingCount: Integer;
        CustomerMappingCount: Integer;
        LocationMappingCount: Integer;
        DefaultLocationCount: Integer;
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

        if not ShopifySetup."Use Location Mappings" then begin
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
        end;

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
            else begin
                if Customer.Blocked <>
                   Customer.Blocked::" "
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'BC customer %1 is blocked.',
                            Customer."No."));

                if Customer."Customer Posting Group" = '' then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'BC customer %1 has no Customer Posting Group.',
                            Customer."No."));

                if Customer."Gen. Bus. Posting Group" = '' then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'BC customer %1 has no Gen. Bus. Posting Group.',
                            Customer."No."));

                if Customer."VAT Bus. Posting Group" = '' then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'BC customer %1 has no VAT Bus. Posting Group.',
                            Customer."No."));
            end;

        CustomerMapping.Reset();
        if CustomerMapping.FindSet() then
            repeat
                if CustomerMapping."BC Customer No." <> '' then begin
                    CustomerMappingCount += 1;

                    if not Customer.Get(CustomerMapping."BC Customer No.") then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify customer %1 is mapped to Business Central customer %2, but that customer does not exist.',
                                CustomerMapping."Shopify Customer ID",
                                CustomerMapping."BC Customer No."))
                    else begin
                        if Customer.Blocked <> Customer.Blocked::" " then
                            AddIssue(
                                ResultText,
                                IssueCount,
                                StrSubstNo(
                                    'Business Central customer %1 mapped to Shopify customer %2 is blocked.',
                                    Customer."No.",
                                    CustomerMapping."Shopify Customer ID"));

                        if Customer."Customer Posting Group" = '' then
                            AddIssue(
                                ResultText,
                                IssueCount,
                                StrSubstNo(
                                    'Mapped Business Central customer %1 has no Customer Posting Group.',
                                    Customer."No."));

                        if Customer."Gen. Bus. Posting Group" = '' then
                            AddIssue(
                                ResultText,
                                IssueCount,
                                StrSubstNo(
                                    'Mapped Business Central customer %1 has no Gen. Bus. Posting Group.',
                                    Customer."No."));

                        if Customer."VAT Bus. Posting Group" = '' then
                            AddIssue(
                                ResultText,
                                IssueCount,
                                StrSubstNo(
                                    'Mapped Business Central customer %1 has no VAT Bus. Posting Group.',
                                    Customer."No."));
                    end;
                end else
                    if (ShopifySetup."Customer Strategy" =
                        ShopifySetup."Customer Strategy"::"Mapped Customer") and
                       not ShopifySetup."Fallback to Generic Customer"
                    then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify customer %1 has no Business Central customer assigned and generic fallback is disabled.',
                                CustomerMapping."Shopify Customer ID"));
            until CustomerMapping.Next() = 0;

        if (ShopifySetup."Customer Strategy" =
            ShopifySetup."Customer Strategy"::"Mapped Customer") and
           not ShopifySetup."Fallback to Generic Customer" and
           (CustomerMappingCount = 0)
        then
            AddIssue(
                ResultText,
                IssueCount,
                'Mapped Customer strategy is enabled without generic fallback, but no Shopify customer mapping has a Business Central customer assigned.');

        if not ShopifySetup."Use Location Mappings" then begin
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
        end else begin
            LocationMapping.SetRange(Active, true);

            if LocationMapping.FindSet() then
                repeat
                    if (LocationMapping."BC Location Code" <> '') and
                       (LocationMapping."Shopify Location ID" <> '')
                    then begin
                        LocationMappingCount += 1;

                        if not Location.Get(LocationMapping."BC Location Code") then
                            AddIssue(
                                ResultText,
                                IssueCount,
                                StrSubstNo(
                                    'BC location %1 used by Shopify Location Mapping does not exist.',
                                    LocationMapping."BC Location Code"));

                        if StrPos(
                            LocationMapping."Shopify Location ID",
                            'gid://shopify/Location/') <> 1
                        then
                            AddIssue(
                                ResultText,
                                IssueCount,
                                StrSubstNo(
                                    'Shopify Location ID %1 does not have a valid Shopify Location GID format.',
                                    LocationMapping."Shopify Location ID"));

                        if LocationMapping."Default for Order Imports" then
                            DefaultLocationCount += 1;
                    end;
                until LocationMapping.Next() = 0;

            if LocationMappingCount = 0 then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Use Location Mappings is enabled, but there are no complete active location mappings.');

            if DefaultLocationCount = 0 then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Use Location Mappings is enabled, but no active location mapping is marked Default for Order Imports.');

            if DefaultLocationCount > 1 then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'More than one active location mapping is marked Default for Order Imports.');
        end;

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

                if ShippingItem."Gen. Prod. Posting Group" = '' then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Shipping item %1 has no Gen. Prod. Posting Group.',
                            ShippingItem."No."));

                if ShippingItem."VAT Prod. Posting Group" = '' then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Shipping item %1 has no VAT Prod. Posting Group.',
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

        if ShopifySetup."Auto Post Imported Orders" then
            if ShopifySetup."Posting Mode" =
               ShopifySetup."Posting Mode"::None
            then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Posting Mode must not be None while Auto Post Imported Orders is enabled.');

        if ShopifySetup."Auto Create Fulfillment" and
           ShopifySetup."Auto Post Imported Orders" and
           (ShopifySetup."Posting Mode" =
            ShopifySetup."Posting Mode"::Invoice)
        then
            AddIssue(
                ResultText,
                IssueCount,
                'Automatic Shopify fulfillment requires Sales Order posting mode Ship or Ship and Invoice because a posted shipment is required.');

        if (ShopifySetup."Auto Create Fulfillment" or
            ShopifySetup."Auto Sync Fulfillment Tracking") and
           not ShopifySetup."Use Location Mappings" and
           (ShopifySetup."Shopify Location ID" = '')
        then
            AddIssue(
                ResultText,
                IssueCount,
                'Shopify Location ID is required for Shopify fulfillment synchronization.');

        if ShopifySetup."Auto Import Shopify Refunds" or
           ShopifySetup."Auto Process Shopify Refunds"
        then
            if ShopifySetup."Import Refunds From" = 0DT then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Import Refunds From is not configured while Shopify refund processing is enabled.');

        if ShopifySetup."Auto Record Shopify Payments" or
           ShopifySetup."Auto Process Shopify Refunds"
        then begin
            if ShopifySetup."Shopify Clearing G/L Acc. No." = '' then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Shopify Clearing G/L Account No. is not configured while Shopify payment/refund accounting is enabled.')
            else
                if not ClearingGLAccount.Get(
                    ShopifySetup."Shopify Clearing G/L Acc. No.")
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Shopify clearing G/L account %1 does not exist.',
                            ShopifySetup."Shopify Clearing G/L Acc. No."))
                else begin
                    if ClearingGLAccount.Blocked then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify clearing G/L account %1 is blocked.',
                                ClearingGLAccount."No."));

                    if ClearingGLAccount."Account Type" <>
                       ClearingGLAccount."Account Type"::Posting
                    then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify clearing G/L account %1 must be a Posting account.',
                                ClearingGLAccount."No."));

                    if not ClearingGLAccount."Direct Posting" then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify clearing G/L account %1 must allow Direct Posting.',
                                ClearingGLAccount."No."));

                    if ClearingGLAccount."Gen. Posting Type" <>
                       ClearingGLAccount."Gen. Posting Type"::" "
                    then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify clearing G/L account %1 must have a blank Gen. Posting Type.',
                                ClearingGLAccount."No."));
                end;

            if ShopifySetup."Payment Journal Template Name" = '' then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Payment Journal Template Name is not configured while Shopify payment/refund accounting is enabled.')
            else
                if not GenJournalTemplate.Get(
                    ShopifySetup."Payment Journal Template Name")
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Payment journal template %1 does not exist.',
                            ShopifySetup."Payment Journal Template Name"));

            if ShopifySetup."Payment Journal Batch Name" = '' then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Payment Journal Batch Name is not configured while Shopify payment/refund accounting is enabled.')
            else
                if not GenJournalBatch.Get(
                    ShopifySetup."Payment Journal Template Name",
                    ShopifySetup."Payment Journal Batch Name")
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Payment journal batch %1 / %2 does not exist.',
                            ShopifySetup."Payment Journal Template Name",
                            ShopifySetup."Payment Journal Batch Name"));
        end;

        if ShopifySetup."Auto Import Shopify Payouts" or
           ShopifySetup."Auto Post Paid Payouts"
        then begin
            if ShopifySetup."Import Payouts From" = 0DT then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Import Payouts From is not configured while Shopify payout processing is enabled.');
        end;

        if ShopifySetup."Auto Post Paid Payouts" then begin
            if ShopifySetup."Shopify Payout Bank Acc. No." = '' then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Shopify Payout Bank Account No. is not configured while automatic payout posting is enabled.')
            else
                if not PayoutBankAccount.Get(
                    ShopifySetup."Shopify Payout Bank Acc. No.")
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Shopify payout bank account %1 does not exist.',
                            ShopifySetup."Shopify Payout Bank Acc. No."))
                else
                    if PayoutBankAccount.Blocked then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify payout bank account %1 is blocked.',
                                PayoutBankAccount."No."));

            if ShopifySetup."Shopify Clearing G/L Acc. No." = '' then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Shopify Clearing G/L Account No. is not configured while automatic payout posting is enabled.')
            else
                if not ClearingGLAccount.Get(
                    ShopifySetup."Shopify Clearing G/L Acc. No.")
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Shopify clearing G/L account %1 does not exist.',
                            ShopifySetup."Shopify Clearing G/L Acc. No."))
                else begin
                    if ClearingGLAccount.Blocked then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify clearing G/L account %1 is blocked.',
                                ClearingGLAccount."No."));

                    if ClearingGLAccount."Account Type" <>
                       ClearingGLAccount."Account Type"::Posting
                    then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify clearing G/L account %1 must be a Posting account.',
                                ClearingGLAccount."No."));

                    if not ClearingGLAccount."Direct Posting" then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify clearing G/L account %1 must allow Direct Posting.',
                                ClearingGLAccount."No."));
                end;

            if ShopifySetup."Shopify Fee G/L Acc. No." = '' then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Shopify Fee G/L Account No. is not configured while automatic payout posting is enabled.')
            else
                if not PayoutFeeGLAccount.Get(
                    ShopifySetup."Shopify Fee G/L Acc. No.")
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Shopify fee G/L account %1 does not exist.',
                            ShopifySetup."Shopify Fee G/L Acc. No."))
                else begin
                    if PayoutFeeGLAccount.Blocked then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify fee G/L account %1 is blocked.',
                                PayoutFeeGLAccount."No."));

                    if PayoutFeeGLAccount."Account Type" <>
                       PayoutFeeGLAccount."Account Type"::Posting
                    then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify fee G/L account %1 must be a Posting account.',
                                PayoutFeeGLAccount."No."));

                    if not PayoutFeeGLAccount."Direct Posting" then
                        AddIssue(
                            ResultText,
                            IssueCount,
                            StrSubstNo(
                                'Shopify fee G/L account %1 must allow Direct Posting.',
                                PayoutFeeGLAccount."No."));
                end;

            if ShopifySetup."Payout Journal Template Name" = '' then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Payout Journal Template Name is not configured while automatic payout posting is enabled.')
            else
                if not PayoutJournalTemplate.Get(
                    ShopifySetup."Payout Journal Template Name")
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Payout journal template %1 does not exist.',
                            ShopifySetup."Payout Journal Template Name"));

            if ShopifySetup."Payout Journal Batch Name" = '' then
                AddIssue(
                    ResultText,
                    IssueCount,
                    'Payout Journal Batch Name is not configured while automatic payout posting is enabled.')
            else
                if not PayoutJournalBatch.Get(
                    ShopifySetup."Payout Journal Template Name",
                    ShopifySetup."Payout Journal Batch Name")
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Payout journal batch %1 / %2 does not exist.',
                            ShopifySetup."Payout Journal Template Name",
                            ShopifySetup."Payout Journal Batch Name"));
        end;

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

                        if Item."Inventory Posting Group" <> '' then
                            ValidateInventoryPostingSetupForItem(
                                ShopifySetup,
                                Item,
                                ResultText,
                                IssueCount);
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

    local procedure ValidateInventoryPostingSetupForItem(
        ShopifySetup: Record "Shopify Integration Setup";
        Item: Record Item;
        var ResultText: Text;
        var IssueCount: Integer)
    var
        LocationMapping: Record "Shopify Location Mapping";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if not ShopifySetup."Use Location Mappings" then begin
            if ShopifySetup."BC Location Code" = '' then
                exit;

            if not InventoryPostingSetup.Get(
                ShopifySetup."BC Location Code",
                Item."Inventory Posting Group")
            then
                AddIssue(
                    ResultText,
                    IssueCount,
                    StrSubstNo(
                        'Inventory Posting Setup is missing for BC location %1 and inventory posting group %2 used by item %3.',
                        ShopifySetup."BC Location Code",
                        Item."Inventory Posting Group",
                        Item."No."));

            exit;
        end;

        LocationMapping.SetRange(Active, true);
        LocationMapping.SetFilter("BC Location Code", '<>%1', '');
        LocationMapping.SetFilter("Shopify Location ID", '<>%1', '');

        if LocationMapping.FindSet() then
            repeat
                if not InventoryPostingSetup.Get(
                    LocationMapping."BC Location Code",
                    Item."Inventory Posting Group")
                then
                    AddIssue(
                        ResultText,
                        IssueCount,
                        StrSubstNo(
                            'Inventory Posting Setup is missing for mapped BC location %1 and inventory posting group %2 used by item %3.',
                            LocationMapping."BC Location Code",
                            Item."Inventory Posting Group",
                            Item."No."));
            until LocationMapping.Next() = 0;
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