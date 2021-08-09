address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module MAI {
    use 0x1::Account;
    use 0x1::Token ;
    use 0x1::Treasury;

    struct MAI has copy, drop, store {}

    const MAI_PRECISION: u8 = 9;

    struct SharedMintCapability has key, store {
        cap: Token::MintCapability<MAI>,
    }

    struct SharedBurnCapability has key, store {
        cap: Token::BurnCapability<MAI>,
    }

    struct SharedTreasuryWithdrawCapability has key, store {
        cap: Treasury::WithdrawCapability<MAI>,
    }

    public fun initialize(account: &signer) {
        Token::register_token<MAI>(account, MAI_PRECISION);
        Account::do_accept_token<MAI>(account);
        let mint_cap = Token::remove_mint_capability<MAI>(account);
        move_to(account, SharedMintCapability { cap: mint_cap });
        let burn_cap = Token::remove_burn_capability<MAI>(account);
        move_to(account, SharedBurnCapability { cap: burn_cap });

        let withdraw_cap = Treasury::initialize<MAI>(account, Token::zero<MAI>());
        move_to(account, SharedTreasuryWithdrawCapability { cap: withdraw_cap });
    }

    public fun mint(amount: u128): Token::Token<MAI>
    acquires SharedMintCapability {
        let cap = borrow_global<SharedMintCapability>( Token::token_address< MAI>());
        Token::mint_with_capability<MAI>(
            &cap.cap,
            amount
        )
    }

    public fun burn(amount: Token::Token<MAI>)
    acquires SharedBurnCapability {
        let cap = borrow_global<SharedBurnCapability>(Token::token_address< MAI>());
        Token::burn_with_capability<MAI>(
            &cap.cap,
            amount
        )
    }

    public fun deposit_to_treasury(amount: Token::Token<MAI>) {
        Treasury::deposit<MAI>(amount)
    }

    public fun treasury_balance(): u128 {
        Treasury::balance<MAI>()
    }
}
}
