import quantities;
import std.stdio;

auto freq(Inductance L, Capacitance C)
{
    return sqrt(1 / (L * C)) / (2 * PI * radian);
}

auto quality(Inductance L, ElectricResistance R, Frequency F)
{
    return R / (L * F * 2 * PI * radian);
}

unittest
{
    Inductance L = si!"10 mH";
    Capacitance C = si!"62.5 nF";
    ElectricResistance R = si!"100 kΩ";
    auto w0 = freq(L, C);
    auto q = cast(real) quality(L, R, w0);
    
    import std.math : approxEqual;
    assert(approxEqual(w0.value(hertz), 6366.2));
    assert(approxEqual(q, 250));
    
    writefln("Frequency: %s Hz", w0.value(hertz));
    writefln("Quality: %s", q);
}