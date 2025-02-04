address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module TestHelper {
    use 0x1::Token;
    use 0x1::Account;
    use 0x1::Signer;
    use 0x1::STC;
    use 0x1::Timestamp;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::MAI;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Admin;
    //    use 0x1::Debug;

    const PRECISION: u8 = 9;

    public fun init_stdlib(): signer {
        let stdlib = Account::create_genesis_account(@0x1);
        Timestamp::initialize( & stdlib, 1626356267u64);
        Token::register_token<STC::STC>( & stdlib, 9u8);
        stdlib
    }

    public fun init_account_with_stc(account: &signer, amount: u128, stdlib: &signer) {
        let account_address = Signer::address_of(account);
        Account::create_genesis_account(account_address);
        if (amount >0) {
            deposit_stc_to(account, amount, stdlib);
            let stc_balance = Account::balance<STC::STC>(account_address);
            assert(stc_balance == amount, 999);
        };
        if (account_address == Admin::admin_address()) {
            if (!Token::is_registered_in<MAI::MAI>(account_address)) {
                MAI::initialize(account);
            };
        }
    }

    public fun deposit_stc_to(account: &signer, amount: u128, stdlib: &signer) {
        let is_accept_token = Account::is_accepts_token<STC::STC>(Signer::address_of(account));
        if (!is_accept_token) {
            Account::do_accept_token<STC::STC>(account);
        };
        let total_stc = Token::mint<STC::STC>(stdlib, amount);
        Account::deposit<STC::STC>(Signer::address_of(account), total_stc);
    }

    public fun mint_stc_to(amount: u128, stdlib: &signer): Token::Token<STC::STC> {
        Token::mint<STC::STC>(stdlib, amount)
    }


    public fun wrap_to_stc_amount(amount: u128): u128 {
        amount * pow_10(PRECISION)
    }

    public fun pow_10(exp: u8): u128 {
        pow(10, exp)
    }

    public fun pow(base: u64, exp: u8): u128 {
        let result_val = 1u128;
        let i = 0;
        while (i < exp) {
            result_val = result_val * (base as u128);
            i = i + 1;
        };
        result_val
    }
}
}