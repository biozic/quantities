module binarysize;

import quantities;
import std.bigint;
import std.conv;
import std.stdio;

enum bit = unit!("bit", BigInt);
enum byte_ = 8 * bit;

alias tera = prefix!(BigInt(1000)^^4); 
alias tebi = prefix!(BigInt(1024)^^4);

alias bin = ctQuantityParser!(
    BigInt,
    (ref string s) => parse!long(s),
    addUnit("bit", bit),
    addUnit("B", byte_),
    addPrefix("T", BigInt(1000)^^4),
    addPrefix("Ti", BigInt(1024)^^4)
);

unittest
{
    auto size = 1 * tera(byte_);
    auto sizebi = 1 * tebi(byte_);
    writefln("1 TB = %s B", size.value(byte_));
    writefln("1 TiB = %s B", sizebi.value(byte_));
}

unittest
{
    
}
