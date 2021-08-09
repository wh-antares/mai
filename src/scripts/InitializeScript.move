address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module InitializeScript {

    use 0x1::Token;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::MAI;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::STCVaultPoolA;

    public(script) fun initialize(sender: signer) {
        MAI::initialize(&sender);
        let max_mint_amount = 2000 * Token::scaling_factor<MAI::MAI>();
        let min_mint_amount = 1 * Token::scaling_factor<MAI::MAI>();
        STCVaultPoolA::initialize(&sender,
            max_mint_amount,
            min_mint_amount,
            350, 8000, 10, 8000);
    }
}
}
    