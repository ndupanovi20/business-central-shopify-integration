enum 50223 "Shopify Payment Status"
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
