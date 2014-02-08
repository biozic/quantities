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
	currencySymbols.addUnit("€", euro);
	currencySymbols.addUnit("$", 0.73 * euro);
}

alias parse =  rtQuantityParser!(double, currencySymbols);

unittest
{
    writefln("The price is %.2f €", parse!Currency("2000 $").value(euro));
}

unittest
{
    currencySymbols.addUnit("$", 0.74 * euro);
}

unittest
{
    writefln("The price is %.2f €", parse!Currency("2000 $").value(euro));
}
