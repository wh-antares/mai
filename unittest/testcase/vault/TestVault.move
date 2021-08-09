//#[test_only]
address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module TestVault {
    use 0x1::Signer;
    use 0x1::STC;
    use 0x1::Timestamp;
    //    use 0x1::Account;
    use 0x1::Debug;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Vault;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::STCVaultPoolA;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::VaultCounter;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::TestHelper;

    #[test(account = @0x1)]
    #[expected_failure(abort_code = 26119)]
    fun test_deposit_not_exist(account: &signer) {
        Vault::deposit<STCVaultPoolA::VaultPool, STC::STC>(account, 0);
    }


    #[test(admin = @0xb987F1aB0D7879b2aB421b98f96eFb44,
    account = @0x0000000000000000000000000a550c18 ) ]
    fun test_deposit(admin: signer, account: signer) {
        let std_signer = TestHelper::init_stdlib();
        TestHelper::init_account_with_stc(&admin, 0u128, &std_signer);
        TestHelper::init_account_with_stc(&account, 0u128, &std_signer);
        create_value(&admin, &account, TestConfig {
            max_mai_supply: 10000,
            min_mint_amount: 1,
            stability_fee_ratio: 10000,
            liquidation_ratio: 10000,
            liquidation_penalty: 10000,
            liquidation_threshold:10000
        });

        let balance = Vault::balance<STCVaultPoolA::VaultPool, STC::STC>( Signer::address_of(&account));
        assert(balance == 0, 305);
        let amount: u128 = TestHelper::wrap_to_stc_amount(1000u128);
        let balance = deposit(&account, amount, &std_signer);
        assert(balance == amount, 305);
    }


    #[test(admin = @0xb987F1aB0D7879b2aB421b98f96eFb44,
    account = @0x0000000000000000000000000a550c18 ) ]
    fun test_borrow_mai(admin: signer, account: signer) {
        let std_signer = TestHelper::init_stdlib();
        TestHelper::init_account_with_stc(&admin, 0u128, &std_signer);
        TestHelper::init_account_with_stc(&account, 0u128, &std_signer);
        create_value(&admin, &account, TestConfig {
            max_mai_supply: 10000,
            min_mint_amount: 1,
            stability_fee_ratio: 10000,
            liquidation_ratio: 10000,
            liquidation_penalty: 10000,
            liquidation_threshold:10000
        });
        let deposit_amount: u128 = TestHelper::wrap_to_stc_amount(1000u128);
        deposit(&account, deposit_amount, &std_signer);

        let ts = Timestamp::now_seconds();
        let borrow_mai = 20u128;
        let balance = Vault::borrow_mai<STCVaultPoolA::VaultPool, STC::STC>(&account, borrow_mai);
        assert(balance == borrow_mai, 11);

        let up_ts =Vault::last_update_at<STCVaultPoolA::VaultPool, STC::STC>(&Signer::address_of(&account));
        assert(ts==up_ts,12);

        Debug::print(&ts);
        Debug::print(&up_ts);
    }


    struct TestConfig  has drop {
        max_mai_supply: u128,
        min_mint_amount: u128,
        stability_fee_ratio: u128,
        liquidation_ratio: u128,
        liquidation_penalty: u128,
        liquidation_threshold: u128,
    }

    fun create_value(admin: &signer, account: &signer, config: TestConfig) {
        STCVaultPoolA::initialize(admin, config.max_mai_supply,
            config.min_mint_amount, config.stability_fee_ratio,
            config.liquidation_ratio, config.liquidation_penalty,config.liquidation_threshold);
        let id = STCVaultPoolA::create_vault(account);
        let start_at = VaultCounter::get_guid_start_at();
        assert(id == start_at + 1, 303);
        let vault_count = STCVaultPoolA::vault_count();
        assert(vault_count == 1, 304);

        let balance = Vault::balance<STCVaultPoolA::VaultPool, STC::STC>(Signer::address_of(account));
        assert(balance == 0, 305);
    }

    fun deposit(account: &signer, amount: u128, std_signer: &signer, ): u128 {
        TestHelper::deposit_stc_to(account,amount, std_signer);

        Vault::deposit<STCVaultPoolA::VaultPool, STC::STC>(account, amount)

    }
}
}
