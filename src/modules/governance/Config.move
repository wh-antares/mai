address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module Config {
    use 0x1::Config;
    use 0x1::Signer;
    use 0x1::Errors;
    //    use 0x1::Debug;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Admin;

    struct CapHolder<VaultPoolType: copy + store + drop> has key, store {
        cap: Config::ModifyConfigCapability<VaultPoolConfig<VaultPoolType>>,
    }

    struct VaultPoolConfig<VaultPoolType: copy + store + drop>  has copy, drop, store {
        max_mai_supply: u128,
        min_mint_amount: u128,
        stability_fee_ratio: u128,
        ccr: u128,
        liquidation_penalty: u128,
        liquidation_threshold: u128,
    }

    public fun new_config<VaultPoolType: copy + store + drop>
    (max_mai_supply: u128,
     min_mint_amount: u128,
     stability_fee_ratio: u128,
     ccr: u128,
     liquidation_penalty: u128,
     liquidation_threshold: u128): VaultPoolConfig<VaultPoolType> {
        VaultPoolConfig<VaultPoolType> {
            max_mai_supply: max_mai_supply,
            min_mint_amount: min_mint_amount,
            stability_fee_ratio: stability_fee_ratio,
            ccr: ccr,
            liquidation_penalty: liquidation_penalty,
            liquidation_threshold: liquidation_threshold,
        }
    }


    public fun unpack<VaultPoolType: copy + store + drop>(config: VaultPoolConfig<VaultPoolType>): (u128, u128, u128, u128,u128, u128) {
        (   config.max_mai_supply,
            config.min_mint_amount,
            config.stability_fee_ratio,
            config.ccr,
            config.liquidation_penalty,
            config. liquidation_threshold,
        )
    }

    public fun publish_new_config_with_capability<VaultPoolType: copy + store + drop>
    (account: &signer, cofing: VaultPoolConfig<VaultPoolType>) {
        let account_address = Signer::address_of(account);
        Admin::is_admin_address(account_address);
        let cap = Config::publish_new_config_with_capability<VaultPoolConfig<VaultPoolType>>(account, cofing);
        move_to(account, CapHolder { cap: cap });
    }

    public fun update_config<VaultPoolType: copy + store + drop>(cofing: VaultPoolConfig<VaultPoolType>)
    acquires CapHolder {
        let holder = borrow_global_mut<CapHolder<VaultPoolType>>(Admin::admin_address());
        Config::set_with_capability(&mut holder.cap, cofing);
    }

    public fun get<VaultPoolType: copy + store + drop>(): VaultPoolConfig<VaultPoolType> {
        Config::get_by_address<VaultPoolConfig<VaultPoolType>>(Admin::admin_address())
    }

    const MIN_MINT_AMOUNT: u64 = 205;
    const MAX_MINT_AMOUNT: u64 = 206;

    public fun check_max_mai_supply<VaultPoolType: copy + store + drop>
    (config: &VaultPoolConfig<VaultPoolType>, current_supply: u128, borrow_amount: u128) {
        assert(config.max_mai_supply >=current_supply + borrow_amount, Errors::invalid_argument(MAX_MINT_AMOUNT));
    }

    public fun check_min_mint_amount<VaultPoolType: copy + store + drop>
    (config: &VaultPoolConfig<VaultPoolType>, borrow_amount: u128) {
        assert(config.min_mint_amount <= borrow_amount, Errors::invalid_argument(MIN_MINT_AMOUNT));
    }
}
}