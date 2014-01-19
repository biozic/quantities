module absorbance;

import quantities;
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
    a = absorbance(qty!"4.23 lm", qty!"2.87 lm");
    writefln("Absorbance: %.3f", cast(real) a);
}
