address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module Liquidation {
    use 0x1::STC;
    use 0x1::Token;
    use 0x1::Math as SMath;
    use 0x1::Errors;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Config;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::PriceOracle;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Price;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::MAI;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Math;

    const HF_IS_TOO_LOW: u64 = 666;

    const PERCENT_PRECISION: u8 = 4;
    const E18: u128 = 1000000000000000000;


    public fun check_health_factor<VaultPoolType: copy + store + drop, TokenType: store>
    (amount: u128, unpay_stability_fee: u128, debt_mai_amount: u128, collateral: u128) {
        let base_line = cal_max_borrow<VaultPoolType, TokenType>(unpay_stability_fee, collateral);
        assert(amount + debt_mai_amount <= base_line, Errors::invalid_argument(HF_IS_TOO_LOW));
    }

    fun max_borrow<TokenType: store>(collateral: u128, lt: u128): u128 {
        let price_number = PriceOracle::usdt_price<TokenType>();
        let (price, price_dec) = Price::unpack(price_number);
        let scaling_factor = Token::scaling_factor<STC::STC>();
        let a = SMath::mul_div((price as u128), collateral, scaling_factor);
        let mai_amount = SMath::mul_div(a, lt, Math::pow_10(PERCENT_PRECISION) * (price_dec as u128));
        let mai_scaling_factor = Token::scaling_factor<MAI::MAI>();
        let mai_price_number = PriceOracle::usdt_price<MAI::MAI>();
        let (mai_price, mai_price_dec) = Price::unpack(mai_price_number);
        SMath::mul_div(mai_amount * mai_scaling_factor, (mai_price_dec as u128), (mai_price as u128))
    }

    public fun cal_max_borrow<VaultPoolType: copy + store + drop, TokenType: store>
    (unpay_stability_fee: u128, collateral: u128): u128 {
        let config = Config::get<VaultPoolType>();
        let (_, _, _, ccr, _, liquidation_threshold) = Config::unpack<VaultPoolType>(config);
        let max_borrow = max_borrow<TokenType>(collateral, liquidation_threshold);
        let base_line = SMath::mul_div(max_borrow, ccr, Math::pow_10(PERCENT_PRECISION)) ;
        base_line - unpay_stability_fee
    }
}
}