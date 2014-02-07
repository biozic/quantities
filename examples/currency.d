module currency;

import quantities;
import std.conv;
import std.stdio;
import std.traits;
import std.typecons;

enum euro = unit!("C", double);
alias Currency = QuantityType!euro;

static __gshared SymbolList!(double) currencySymbols;
shared static this()
{
    currencySymbols = SymbolList!double(
        addUnit("€", euro),
        addUnit("$", 0.73 * euro)
    );
}

Currency parseCurrency(S)(S text)
{
    return parseQuantity!Currency(text, currencySymbols);
}

unittest
{
    writefln("The price is %.2f €", parseCurrency("2000 $").value(euro));
}

unittest
{
    currencySymbols.addUnit("$", 0.74 * euro);
}

unittest
{
    writefln("The price is %.2f €", parseCurrency("2000 $").value(euro));
}
