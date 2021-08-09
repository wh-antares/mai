address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module Rate {

    use 0x1:: Timestamp;
    use 0x1:: Math;
    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Config;

    const PERCENT_PRECISION: u128 = 10000;

    const SECONDS_PER_YEAR: u128 = 31536000;


    public fun stability_fee<VaultPoolType: copy + store + drop>(current_amount: u128, unpay_fee: u128, from_seconds: u64): u128 {
        let now = Timestamp::now_seconds();
        let ts_gap = now - from_seconds;
        let config = Config::get<VaultPoolType>();

        let (_, _, stability_fee_ratio, _, _, _) = Config::unpack<VaultPoolType>(config);
        //         amount * fee *ts_gap/sencod
        let x =(ts_gap as u128) *( current_amount + unpay_fee);
        let fee = Math::mul_div( x,
            stability_fee_ratio,
            SECONDS_PER_YEAR * PERCENT_PRECISION);
        fee
    }
}
}