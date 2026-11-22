enum 50239 "Shopify Fulfillment Status"
{
    Extensible = false;

    value(0; "Not Required")
    {
        Caption = 'Not Required';
    }

    value(1; Pending)
    {
        Caption = 'Pending';
    }

    value(2; "Waiting for Tracking")
    {
        Caption = 'Waiting for Tracking';
    }

    value(3; Success)
    {
        Caption = 'Success';
    }

    value(4; Skipped)
    {
        Caption = 'Skipped';
    }

    value(5; Error)
    {
        Caption = 'Error';
    }
}
