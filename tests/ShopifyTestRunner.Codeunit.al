#if SHOPIFY_TESTS
codeunit 50321 "Shopify Test Runner"
{
    Subtype = TestRunner;
    TestIsolation = Function;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"Shopify Regression Tests");
    end;
}
#endif
