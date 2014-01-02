import quantities.base, quantities.si;
import std.stdio;

auto freq(Inductance, Capacity)(Inductance L, Capacity C)
{
    return sqrt(1 / (L * C)) / (2 * PI * radian);
}

auto quality(Inductance, Resistance, Frequency)(Inductance L, Resistance R, Frequency F)
{
    return R / (L * F * 2 * PI * radian);
}

void main()
{
    alias Frequency = Store!hertz;
    alias Inductance = Store!henry;
    alias Capacity = Store!farad;
    alias Resistance = Store!ohm;
    
    auto L = 10 * milli!henry;
    auto C = 62.5 * nano!farad;
    auto R = 100 * kilo!ohm;
    auto w0 = freq(L, C);
    auto q = quality(L, R, w0);
    
    import std.math : approxEqual;
    assert(approxEqual(w0.value!hertz, 6366.2));
    assert(approxEqual(q, 250));
    
    writefln("Frequency: %s Hz", w0.value!hertz);
    writefln("Quality: %s", q);
}