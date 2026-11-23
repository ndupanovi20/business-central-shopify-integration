#if SHOPIFY_TESTS
codeunit 50322 "Shopify GraphQL Mock"
{
    EventSubscriberInstance = Manual;

    procedure SetRemainingQuantity(Quantity: Integer)
    begin
        RemainingQuantity := Quantity;
    end;

    procedure GetFulfilledQuantity(): Integer
    begin
        exit(FulfilledQuantity);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shopify Client", 'OnBeforeExecuteGraphQL', '', false, false)]
    local procedure OnBeforeExecuteGraphQL(QueryText: Text; Variables: JsonObject; var ResponseJson: JsonObject; var IsHandled: Boolean)
    var
        Client: Codeunit "Shopify Client";
        InputObject: JsonObject;
        OrderInput: JsonObject;
        LineInput: JsonObject;
        Inputs: JsonArray;
        Token: JsonToken;
    begin
        IsHandled := true;
        if StrPos(QueryText, 'ShipmentFulfillmentOrders') > 0 then begin
            ResponseJson.ReadFrom('{"data":{"order":{"fulfillmentOrders":{"nodes":[{"id":"gid://shopify/FulfillmentOrder/1","status":"IN_PROGRESS","assignedLocation":{"location":{"id":"gid://shopify/Location/1"}}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}');
            exit;
        end;
        if StrPos(QueryText, 'ShipmentFulfillmentLines') > 0 then begin
            ResponseJson.ReadFrom(StrSubstNo('{"data":{"node":{"lineItems":{"nodes":[{"id":"gid://shopify/FulfillmentOrderLineItem/1","remainingQuantity":%1,"lineItem":{"id":"gid://shopify/LineItem/1"}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}', RemainingQuantity));
            exit;
        end;
        if StrPos(QueryText, 'mutation CreateFulfillment') > 0 then begin
            InputObject := Client.GetObject(Variables, 'fulfillment');
            Inputs := Client.GetArray(InputObject, 'lineItemsByFulfillmentOrder');
            if Inputs.Count() <> 1 then
                Error('Expected one fulfillment order.');
            Inputs.Get(0, Token);
            OrderInput := Token.AsObject();
            Inputs := Client.GetArray(OrderInput, 'fulfillmentOrderLineItems');
            if Inputs.Count() <> 1 then
                Error('Expected one explicit fulfillment line.');
            Inputs.Get(0, Token);
            LineInput := Token.AsObject();
            if Client.GetText(LineInput, 'id') <> 'gid://shopify/FulfillmentOrderLineItem/1' then
                Error('Unexpected fulfillment order line.');
            LineInput.Get('quantity', Token);
            FulfilledQuantity := Token.AsValue().AsInteger();
            ResponseJson.ReadFrom('{"data":{"fulfillmentCreate":{"fulfillment":{"id":"gid://shopify/Fulfillment/1","status":"SUCCESS"},"userErrors":[]}}}');
            exit;
        end;
        Error('Unexpected GraphQL request in test: %1', QueryText);
    end;

    var
        RemainingQuantity: Integer;
        FulfilledQuantity: Integer;
}
#endif
