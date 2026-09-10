enum 50169 "Shopify Order Buffer Status"
{
    Extensible = true;

    value(0; Pending)
    {
        Caption = 'Pending';
    }

    value(1; Success)
    {
        Caption = 'Success';
    }

    value(2; Error)
    {
        Caption = 'Error';
    }

    value(3; Skipped)
    {
        Caption = 'Skipped';
    }
}