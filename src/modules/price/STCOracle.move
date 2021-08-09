address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module STCOracle {

    use 0xb987F1aB0D7879b2aB421b98f96eFb44::Price ;
    //0.2
    public fun usdt_price(): Price::PriceNumber {
        Price::of(2000,10000)
    }

}
}
    