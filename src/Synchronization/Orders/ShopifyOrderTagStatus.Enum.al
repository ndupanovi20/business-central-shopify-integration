enum 50168 "Shopify Order Tag Status"
{
    Extensible = true;

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

    value(3; Error)
    {
        Caption = 'Error';
    }
}