module absorbance;

import quantities.base;
import quantities.parsing;
import quantities.si;
import std.math;
import std.stdio;

alias Absorbance = Dimensionless;

Absorbance absorbance(LuminousFlux incident, LuminousFlux transmitted)
{
    return Absorbance(-log10(transmitted / incident));
}

void main()
{
    Absorbance a;
    a = absorbance(si!"4.23 lm", si!"2.87 lm");
    writefln("Absorbance: %.3f", cast(double) a);
}
