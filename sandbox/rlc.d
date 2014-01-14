import quantities;
import std.stdio;

alias Frequency = Store!hertz;
alias Inductance = Store!henry;
alias Capacity = Store!farad;
alias Resistance = Store!ohm;

auto freq(Inductance L, Capacity C)
{
    return sqrt(1 / (L * C)) / (2 * PI * radian);
}

auto quality(Inductance L, Resistance R, Frequency F)
{
    return R / (L * F * 2 * PI * radian);
}

void main()
{
    Inductance L = 10 * milli(henry);//parseQuantity("10 mH");
    Capacity C = 62.5 * nano(farad);//parseQuantity("62.5 nF");
    Resistance R = 100 * kilo(ohm);//parseQuantity("100 kΩ");
    auto w0 = freq(L, C);
    auto q = cast(double) quality(L, R, w0);
    
    import std.math : approxEqual;
    assert(approxEqual(w0.value(hertz), 6366.2));
    assert(approxEqual(q, 250));
    
    writefln("Frequency: %s Hz", w0.value(hertz));
    writefln("Quality: %s", q);
}