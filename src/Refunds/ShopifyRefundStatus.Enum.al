enum 50268 "Shopify Refund Status"
{
    Extensible = false;

    value(0; "Not Required")
    {
        Caption = 'Not Required';
    }

    value(1; Waiting)
    {
        Caption = 'Waiting';
    }

    value(2; Pending)
    {
        Caption = 'Pending';
    }

    value(3; "Manual Review")
    {
        Caption = 'Manual Review';
    }

    value(4; Success)
    {
        Caption = 'Success';
    }

    value(5; Skipped)
    {
        Caption = 'Skipped';
    }

    value(6; Error)
    {
        Caption = 'Error';
    }
}
