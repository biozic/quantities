module binarysize;

import quantities;
import std.bigint;
import std.conv;
import std.stdio;

enum bit = unit!("bit", BigInt);
enum byte_ = 8 * bit;

alias tera = prefix!(BigInt(1000)^^4);
alias tebi = prefix!(BigInt(1024)^^4);
alias giga = prefix!(BigInt(1000)^^3);
alias gibi = prefix!(BigInt(1024)^^3);
alias mega = prefix!(BigInt(1000)^^2);
alias mebi = prefix!(BigInt(1024)^^2);
alias kilo = prefix!(BigInt(1000));
alias kibi = prefix!(BigInt(1024));

enum symbolList = makeSymbolList!BigInt(
    addUnit("bit", bit),
    addUnit("B", byte_),
    addPrefix("T", BigInt(1000)^^4),
    addPrefix("Ti", BigInt(1024)^^4),
    addPrefix("G", BigInt(1000)^^3),
    addPrefix("Gi", BigInt(1024)^^3),
    addPrefix("M", BigInt(1000)^^2),
    addPrefix("Mi", BigInt(1024)^^2),
    addPrefix("k", BigInt(1000)),
    addPrefix("Ki", BigInt(1024))
);

alias bin = ctQuantityParser!(BigInt, (ref string s) => parse!long(s), SymbolList);

unittest
{
    auto size = 1 * tera(byte_);
    auto sizebi = 1 * tebi(byte_);
    writefln("1 TB = %s B", size.value(byte_));
    writefln("1 TiB = %s B", sizebi.value(byte_));
}
