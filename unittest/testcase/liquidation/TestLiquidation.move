address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module TestLiquidation {

    use 0x1::STC;
    use 0x1::Debug;
    use 0x1::Token;
    use 0x1::Math as SMath;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Liquidation;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::TestHelper;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::MAI;
    #[test(admin = @0xb987F1aB0D7879b2aB421b98f96eFb44 ) ]
    fun test_get_health_factor(admin: signer) {
        let std_signer = TestHelper::init_stdlib();
        TestHelper::init_account_with_stc(&admin, 0u128, &std_signer);
        let stc_scaling_factor = Token::scaling_factor<STC::STC>();
        let stc_amount = 10000 * stc_scaling_factor;
        let rst = Liquidation::max_borrow<STC::STC>(stc_amount, 8000);
        let mai_scaling_factor = Token::scaling_factor<MAI::MAI>();
        Debug::print(&rst);
        assert(rst == 1600 * mai_scaling_factor, 2);
    }

    const E27: u128 = 1000000000000000000000000000;
    const E20: u128 = 100000000000000000000;
    const E18: u128 = 1000000000000000000;

    const E9: u128 = 1000000000;
    #[test]
    fun dsrPerBlock(): u128 {
        let pot = 1000000000003170820659990704;
        let a = pot - E27;
        let r = SMath::mul_div(a, 15, E9);
        assert(47562300 == r, 1);
        r
    }
    #[test]
    fun baseRatePerBlock() {
        let dsr = dsrPerBlock();
        //0.95e18
        let baseRatePerBlock = SMath::mul_div(dsr, E18, E20);
        Debug::print(&baseRatePerBlock);
    }
    #[test]
    fun stabilityFeePerBlock() {
        let base_rate = 35u128;
        let rst = SMath::mul_div(base_rate * E27 - E27, E18, E27);
        Debug::print(&rst);
    }
}
}
