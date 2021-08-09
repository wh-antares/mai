address 0xb987F1aB0D7879b2aB421b98f96eFb44 {
module Price {

    struct PriceNumber has drop,copy{
        value: u64,
        scaling_factor: u64
    }

    public fun of(value: u64, dec: u64): PriceNumber {
        PriceNumber {
            value: value,
            scaling_factor: dec
        }
    }

    public fun unpack(v: PriceNumber): (u64, u64) {
        (v.value, v.scaling_factor)
    }
}
}
    