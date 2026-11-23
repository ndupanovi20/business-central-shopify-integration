#if SHOPIFY_TESTS
codeunit 50320 "Shopify Regression Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PartialShipmentSendsOnlyItsQuantity()
    var
        Entry: Record "Shopify Fulfillment Entry";
        FulfillmentMgt: Codeunit "Shopify Fulfillment Mgt.";
        Mock: Codeunit "Shopify GraphQL Mock";
    begin
        InitializeSetup();
        CreateShipmentFixture(Entry);
        Mock.SetRemainingQuantity(5);
        BindSubscription(Mock);
        FulfillmentMgt.CreateFulfillmentCore(Entry);
        AssertEqual(2, Mock.GetFulfilledQuantity(), 'A shipment of 2 must not fulfill all 5 ordered units.');
        Entry.Get(Entry."Entry No.");
        if Entry.Status <> Entry.Status::Success then
            Error('Shipment was not marked successful.');
        UnbindSubscription(Mock);
    end;

    [Test]
    procedure UnmatchedShipmentDoesNotSendMutation()
    var
        Entry: Record "Shopify Fulfillment Entry";
        FulfillmentMgt: Codeunit "Shopify Fulfillment Mgt.";
        Mock: Codeunit "Shopify GraphQL Mock";
    begin
        InitializeSetup();
        CreateShipmentFixture(Entry);
        Mock.SetRemainingQuantity(1);
        BindSubscription(Mock);
        asserterror FulfillmentMgt.CreateFulfillmentCore(Entry);
        if StrPos(GetLastErrorText(), 'cannot be matched') = 0 then
            Error('Unexpected validation error: %1', GetLastErrorText());
        AssertEqual(0, Mock.GetFulfilledQuantity(), 'An incomplete match must not send a fulfillment mutation.');
        UnbindSubscription(Mock);
    end;

    [Test]
    procedure ManualProcessingQueuesOrdersWithAutomationOff()
    var
        ImportRecord: Record "Shopify Order Import";
        Header: Record "Sales Header";
        PostingMgt: Codeunit "Shopify Order Posting Mgt.";
    begin
        InitializeSetup();
        Header."Document Type" := Header."Document Type"::Order;
        Header."No." := 'UT-SHOP-ORDER';
        Header.Insert(false);
        ImportRecord."Shopify Order ID" := 'gid://shopify/Order/1';
        ImportRecord."BC Order No." := Header."No.";
        ImportRecord.Insert(false);
        PostingMgt.QueueUnpostedOrders();
        ImportRecord.Get(ImportRecord."Shopify Order ID");
        if ImportRecord."Posting Status" <> ImportRecord."Posting Status"::Pending then
            Error('Explicit processing must queue orders when automation is off.');
        if ImportRecord."Posting Mode Used" <> ImportRecord."Posting Mode Used"::"Ship and Invoice" then
            Error('Queued order did not use the configured posting mode.');
    end;

    [Test]
    procedure RefundLocationUsesActiveMappingInsteadOfLegacyDefault()
    var
        Setup: Record "Shopify Integration Setup";
        Location: Record Location;
        Mapping: Record "Shopify Location Mapping";
        LocationMgt: Codeunit "Shopify Location Mgt.";
        LocationCode: Code[10];
    begin
        InitializeSetup();
        Setup.Get('SETUP');
        Setup."Use Location Mappings" := true;
        Setup.Modify(false);
        Location.Code := 'UT-RETURN';
        Location.Insert(false);
        Mapping."Shopify Location ID" := 'gid://shopify/Location/2';
        Mapping."BC Location Code" := Location.Code;
        Mapping.Active := true;
        Mapping.Insert(false);
        if not LocationMgt.TryResolveBCLocation(Mapping."Shopify Location ID", LocationCode) then
            Error('The active return location mapping was not resolved.');
        if LocationCode <> Location.Code then
            Error('The wrong return location was resolved.');
        if LocationMgt.TryResolveBCLocation('gid://shopify/Location/unknown', LocationCode) then
            Error('An unmapped return location must be rejected.');
    end;

    [Test]
    procedure InvalidPayoutDoesNotBlockFollowingPayout()
    var
        Setup: Record "Shopify Integration Setup";
        FirstPayout: Record "Shopify Payout Entry";
        SecondPayout: Record "Shopify Payout Entry";
        PayoutMgt: Codeunit "Shopify Payout Mgt.";
    begin
        InitializeSetup();
        Setup.Get('SETUP');
        Setup."Shopify Clearing G/L Acc. No." := '';
        Setup.Modify(false);
        FirstPayout."Shopify Payout ID" := 'gid://shopify/ShopifyPaymentsPayout/ut1';
        FirstPayout."Shopify Status" := 'PAID';
        FirstPayout."Transaction Type" := 'DEPOSIT';
        FirstPayout."Net Amount" := 100;
        FirstPayout."Processing Status" := FirstPayout."Processing Status"::Pending;
        FirstPayout.Insert(false);
        SecondPayout := FirstPayout;
        SecondPayout."Shopify Payout ID" := 'gid://shopify/ShopifyPaymentsPayout/ut2';
        SecondPayout.Insert(false);
        AssertEqual(0, PayoutMgt.ProcessPendingPayouts(false), 'Neither invalid payout should be posted.');
        FirstPayout.Get(FirstPayout."Shopify Payout ID");
        SecondPayout.Get(SecondPayout."Shopify Payout ID");
        if (FirstPayout."Processing Status" <> FirstPayout."Processing Status"::Error) or
           (SecondPayout."Processing Status" <> SecondPayout."Processing Status"::Error) then
            Error('Each invalid payout must persist its own error.');
        AssertEqual(1, SecondPayout."Attempt Count", 'Processing must continue after the first payout fails.');
    end;

    [Test]
    procedure InvalidPostingModeIsRecordedPerOrder()
    var
        FirstImport: Record "Shopify Order Import";
        SecondImport: Record "Shopify Order Import";
        Header: Record "Sales Header";
        PostingMgt: Codeunit "Shopify Order Posting Mgt.";
    begin
        InitializeSetup();
        Header."Document Type" := Header."Document Type"::Order;
        Header."No." := 'UT-SHOP-ORDER';
        Header.Insert(false);
        FirstImport."Shopify Order ID" := 'gid://shopify/Order/ut1';
        FirstImport."BC Order No." := Header."No.";
        FirstImport."Posting Status" := FirstImport."Posting Status"::Pending;
        FirstImport."Posting Mode Used" := FirstImport."Posting Mode Used"::None;
        FirstImport.Insert(false);
        SecondImport := FirstImport;
        SecondImport."Shopify Order ID" := 'gid://shopify/Order/ut2';
        SecondImport.Insert(false);
        AssertEqual(0, PostingMgt.ProcessPendingAutoPostings(false), 'Invalid posting modes must not succeed.');
        FirstImport.Get(FirstImport."Shopify Order ID");
        SecondImport.Get(SecondImport."Shopify Order ID");
        if (FirstImport."Posting Status" <> FirstImport."Posting Status"::Error) or
           (SecondImport."Posting Status" <> SecondImport."Posting Status"::Error) then
            Error('Both posting errors must be recorded without aborting the batch.');
        AssertEqual(1, SecondImport."Posting Attempt Count", 'The second invalid order must also be attempted.');
    end;

    local procedure InitializeSetup()
    var
        Setup: Record "Shopify Integration Setup";
    begin
        if not Setup.Get('SETUP') then begin
            Setup."Primary Key" := 'SETUP';
            Setup.Insert(false);
        end;
        Setup."Auto Post Imported Orders" := false;
        Setup."Posting Mode" := Setup."Posting Mode"::"Ship and Invoice";
        Setup."Use Location Mappings" := false;
        Setup."BC Location Code" := 'UT-SHOP';
        Setup."Shopify Location ID" := 'gid://shopify/Location/1';
        Setup."Require Tracking No." := false;
        Setup.Modify(false);
    end;

    local procedure CreateShipmentFixture(var Entry: Record "Shopify Fulfillment Entry")
    var
        ImportRecord: Record "Shopify Order Import";
        Shipment: Record "Sales Shipment Header";
        Line: Record "Sales Shipment Line";
        Mapping: Record "Shopify Order Line Mapping";
    begin
        ImportRecord."Shopify Order ID" := 'gid://shopify/Order/1';
        ImportRecord."BC Order No." := 'UT-SHOP-ORDER';
        ImportRecord."Posting Status" := ImportRecord."Posting Status"::Success;
        // Deliberately point the registry at another shipment. Retries must use Entry.
        ImportRecord."Posted Shipment No." := 'UT-OTHER-SHIPMENT';
        ImportRecord.Insert(false);
        Shipment."No." := 'UT-SHOP-SHIPMENT';
        Shipment."Order No." := ImportRecord."BC Order No.";
        Shipment."Location Code" := 'UT-SHOP';
        Shipment.Insert(false);
        Line."Document No." := Shipment."No.";
        Line."Line No." := 10000;
        Line.Type := Line.Type::Item;
        Line."No." := 'UT-ITEM';
        Line.Quantity := 2;
        Line."Order No." := Shipment."Order No.";
        Line."Order Line No." := 10000;
        Line.Insert(false);
        Mapping."Shopify Order ID" := ImportRecord."Shopify Order ID";
        Mapping."Shopify Line Item ID" := 'gid://shopify/LineItem/1';
        Mapping."BC Order No." := Shipment."Order No.";
        Mapping."BC Order Line No." := 10000;
        Mapping."Original Quantity" := 5;
        Mapping.Insert(false);
        Entry."Shopify Order ID" := ImportRecord."Shopify Order ID";
        Entry."BC Order No." := Shipment."Order No.";
        Entry."Posted Shipment No." := Shipment."No.";
        Entry.Insert(false);
    end;

    local procedure AssertEqual(Expected: Integer; Actual: Integer; FailureMessage: Text)
    begin
        if Expected <> Actual then
            Error('%1 Expected %2, got %3.', FailureMessage, Expected, Actual);
    end;
}
#endif
