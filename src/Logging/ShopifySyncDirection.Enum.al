enum 50160 "Shopify Sync Direction"
{
    Extensible = true;

    value(0; Outbound)
    {
        Caption = 'BC to Shopify';
    }

    value(1; Inbound)
    {
        Caption = 'Shopify to BC';
    }

    value(2; System)
    {
        Caption = 'System';
    }
}