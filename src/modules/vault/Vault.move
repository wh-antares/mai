address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module Vault {

    use 0x1::Token ;
    use 0x1::Errors;
    use 0x1::Signer;
    use 0x1::Account;
    use 0x1::Timestamp;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::MAI;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Liquidation;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Rate;

    const VAULT_EXISTS: u64 = 101;
    const VAULT_NOT_EXISTS: u64 = 102;
    const NOT_SAME_TOKEN: u64 = 103;
    const U128_MAX: u128 = 340282366920938463463374607431768211455u128;
    const INSUFFICIENT_BALANCE: u64 = 204;
    const WRONG_AMOUNT: u64 = 205;

    struct Vault<VaultPoolType: store, TokenType: store> has key, store {
        debt_mai_amount: u128,
        unpay_stability_fee: u128,
        token: Token::Token<TokenType>,
        id: u64,
        last_update_at: u64,
    }

    public fun create_vault<VaultPoolType: store, TokenType: store>(account: &signer, guid: u64) {
        assert(
            !vault_exist<VaultPoolType, TokenType>(Signer::address_of(account)),
            Errors::invalid_state(VAULT_EXISTS)
        );
        let vault = Vault<VaultPoolType, TokenType> {
            debt_mai_amount: 0u128,
            unpay_stability_fee: 0u128,
            token: Token::zero<TokenType>(),
            id: guid,
            last_update_at: Timestamp::now_seconds()
        };
        move_to(account, vault);
    }

    public fun vault_exist<VaultPoolType: store, TokenType: store>(address: address): bool {
        exists<Vault<VaultPoolType, TokenType>>(address)
    }


    public fun deposit<VaultPoolType: store, TokenType: store>(account: &signer, amount: u128): u128
    acquires Vault {
        assert(
            vault_exist<VaultPoolType, TokenType>(Signer::address_of(account)),
            Errors::invalid_argument(VAULT_NOT_EXISTS)
        );
        let vault = borrow_global_mut<Vault<VaultPoolType, TokenType>>(Signer::address_of(account));
        let tokens = Account::withdraw<TokenType>(account, amount);
        Token::deposit<TokenType>(&mut vault.token, tokens);
        balance<VaultPoolType, TokenType>(Signer::address_of(account))
    }

    public fun balance<VaultPoolType: store, TokenType: store>(address: address): u128
    acquires Vault {
        let vault = borrow_global<Vault<VaultPoolType, TokenType>>(address);
        balance_for(vault)
    }

    public fun last_update_at<VaultPoolType: store, TokenType: store>(account: &address): u64
    acquires Vault {
        let vault = borrow_global<Vault<VaultPoolType, TokenType>>(*account);
        vault.last_update_at
    }

    fun balance_for<VaultPoolType: store, TokenType: store>
    (vault: &Vault<VaultPoolType, TokenType>): u128 {
        Token::value<TokenType>(&vault.token)
    }

    public fun info<VaultPoolType: store + drop + copy, TokenType: store>
    (address: address): (u64, u128, u128, u128, u64) acquires Vault {
        let vault = borrow_global<Vault<VaultPoolType, TokenType>>(address);
        let stability_fee = Rate::stability_fee<VaultPoolType>(vault.debt_mai_amount, vault.unpay_stability_fee, vault.last_update_at);
        (vault.id,
            vault.debt_mai_amount,
            vault.unpay_stability_fee + stability_fee,
            balance_for<VaultPoolType, TokenType>(vault),
            Timestamp::now_seconds())
    }

    public fun withdraw<VaultPoolType: store + drop + copy, TokenType: store>(account: &signer, amount: u128): u128 acquires Vault {
        assert(
            vault_exist<VaultPoolType, TokenType>(Signer::address_of(account)),
            Errors::invalid_argument(VAULT_NOT_EXISTS)
        );
        let vault = borrow_global_mut<Vault<VaultPoolType, TokenType>>(Signer::address_of(account));

        let balance = balance_for(vault);
        Liquidation::check_health_factor<VaultPoolType, TokenType>(amount, vault.unpay_stability_fee, vault.debt_mai_amount, balance - amount);
        let tokens = Token::withdraw<TokenType>(&mut vault.token, amount);
        Account::deposit_to_self<TokenType>(account, tokens);
        amount
    }


    public fun borrow_mai<VaultPoolType: store + drop + copy, TokenType: store>
    (account: &signer, amount: u128): u128
    acquires Vault {
        assert(
            vault_exist<VaultPoolType, TokenType>(Signer::address_of(account)),
            Errors::invalid_argument(VAULT_NOT_EXISTS)
        );
        let vault = borrow_global_mut<Vault<VaultPoolType, TokenType>>(Signer::address_of(account));
        Liquidation::check_health_factor<VaultPoolType, TokenType>(amount, vault.unpay_stability_fee, vault.debt_mai_amount, balance_for(vault));

        let tokens = MAI::mint(amount);
        let is_accept_token = Account::is_accepts_token<MAI::MAI>(Signer::address_of(account));
        if (!is_accept_token) {
            Account::do_accept_token<MAI::MAI>(account);
        };
        let stability_fee = Rate::stability_fee<VaultPoolType>(vault.debt_mai_amount, vault.unpay_stability_fee, vault.last_update_at);
        let mai_amount = Token::value<MAI::MAI>(&tokens);
        Account::deposit_to_self<MAI::MAI>(account, tokens);
        let vault = borrow_global_mut<Vault<VaultPoolType, TokenType>>(Signer::address_of(account));
        vault.debt_mai_amount = vault.debt_mai_amount + mai_amount;
        vault.unpay_stability_fee = vault.unpay_stability_fee + stability_fee;
        vault.last_update_at = Timestamp::now_seconds();
        mai_amount
    }

    public fun repay_mai<VaultPoolType: store + drop + copy, TokenType: store>
    (account: &signer, amount: u128): (u128, u128) acquires Vault {
        assert(
            vault_exist<VaultPoolType, TokenType>(Signer::address_of(account)),
            Errors::invalid_argument(VAULT_NOT_EXISTS)
        );
        let vault = borrow_global_mut<Vault<VaultPoolType, TokenType>>(Signer::address_of(account));
        let stability_fee = Rate::stability_fee<VaultPoolType>(vault.debt_mai_amount, vault.unpay_stability_fee, vault.last_update_at);

        vault.unpay_stability_fee = vault.unpay_stability_fee + stability_fee;
        if (amount == U128_MAX) {
            amount = vault.unpay_stability_fee + vault.debt_mai_amount;
        };
        let mai_balance = Account::balance<MAI::MAI>(Signer::address_of(account));
        assert(mai_balance > amount, Errors::invalid_argument(INSUFFICIENT_BALANCE));
        assert(
            (vault.unpay_stability_fee + vault.debt_mai_amount) >= amount,
            Errors::invalid_argument(WRONG_AMOUNT)
        );
        let tokens = Account::withdraw<MAI::MAI>(account, amount);

        let before_debit = vault.debt_mai_amount;
        let before_fee = vault.unpay_stability_fee;
        if (amount > vault.unpay_stability_fee) {
            vault.unpay_stability_fee = 0;
            vault.debt_mai_amount = vault.debt_mai_amount - (amount - before_fee);
        }else {
            vault.unpay_stability_fee = vault.unpay_stability_fee - amount;
        };
        vault.last_update_at = Timestamp::now_seconds();
        let after_debit = vault.debt_mai_amount;
        let after_fee = vault.unpay_stability_fee;
        let pay_debit = before_debit - after_debit;
        let pay_fee = before_fee - after_fee;
        assert(pay_fee + pay_debit == amount, 501);

        let (debit, fee) = Token::split<MAI::MAI>(tokens, pay_fee);
        MAI::burn(debit);
        MAI::deposit_to_treasury(fee);
        (pay_debit, pay_fee)
    }

    public fun max_borrow<VaultPoolType: store + drop + copy, TokenType: store>(address: address): u128
    acquires Vault {
        let vault = borrow_global<Vault<VaultPoolType, TokenType>>(address);
        Liquidation::cal_max_borrow<VaultPoolType, TokenType>(vault.unpay_stability_fee, balance_for(vault))
    }
}
}