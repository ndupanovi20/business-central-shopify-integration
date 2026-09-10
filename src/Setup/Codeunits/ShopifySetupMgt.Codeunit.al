codeunit 50102 "Shopify Setup Mgt."
{
    procedure SetClientSecret(ClientSecretText: Text)
    var
        ClientSecret: SecretText;
    begin
        if ClientSecretText = '' then
            Error('Client Secret cannot be empty.');

        ClientSecret := ClientSecretText;

        if not IsolatedStorage.SetEncrypted(
            ClientSecretKeyLbl,
            ClientSecret,
            DataScope::Module)
        then
            Error('Client Secret could not be saved.');
    end;

    procedure GetClientSecret(var ClientSecret: SecretText)
    begin
        if not IsolatedStorage.Get(
            ClientSecretKeyLbl,
            DataScope::Module,
            ClientSecret)
        then
            Error('Client Secret has not been configured.');
    end;

    procedure HasClientSecret(): Boolean
    var
        ClientSecret: SecretText;
    begin
        exit(
            IsolatedStorage.Get(
                ClientSecretKeyLbl,
                DataScope::Module,
                ClientSecret));
    end;

    var
        ClientSecretKeyLbl: Label 'BCSHOPIFY_CLIENT_SECRET', Locked = true;
}