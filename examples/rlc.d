import quantities;
import std.stdio;

alias Frequency = QuantityType!hertz;
alias Inductance = QuantityType!henry;
alias Capacity = QuantityType!farad;
alias Resistance = QuantityType!ohm;

auto freq(Inductance L, Capacity C)
{
    return sqrt(1 / (L * C)) / (2 * PI * radian);
}

auto quality(Inductance L, Resistance R, Frequency F)
{
    return R / (L * F * 2 * PI * radian);
}

unittest
{
    Inductance L = parseQuantity("10 mH");
    Capacity C = parseQuantity("62.5 nF");
    Resistance R = parseQuantity("100 kΩ");
    auto w0 = freq(L, C);
    auto q = cast(real) quality(L, R, w0);
    
    import std.math : approxEqual;
    assert(approxEqual(w0.value(hertz), 6366.2));
    assert(approxEqual(q, 250));
    
    writefln("Frequency: %s Hz", w0.value(hertz));
    writefln("Quality: %s", q);
}