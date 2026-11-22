enum 50255 "Shopify Payout Proc. Status"
{
    Extensible = false;

    value(0; Pending)
    {
        Caption = 'Pending';
    }

    value(1; Waiting)
    {
        Caption = 'Waiting';
    }

    value(2; Success)
    {
        Caption = 'Success';
    }

    value(3; Skipped)
    {
        Caption = 'Skipped';
    }

    value(4; Error)
    {
        Caption = 'Error';
    }
}
