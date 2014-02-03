module absorbance;

import quantities.base;
import quantities.parsing;
import quantities.si;
import std.math;
import std.stdio;

alias Absorbance = QuantityType!one;
alias Flux = QuantityType!lumen;

Absorbance absorbance(Flux incident, Flux transmitted)
{
    return Absorbance(-log10(transmitted / incident));
}

unittest
{
    Absorbance a;
    a = absorbance(si!"4.23 lm", si!"2.87 lm");
    writefln("Absorbance: %.3f", cast(real) a);
}
