// Written in the D programming language
/++
This module defines the SI units and prefixes.

All the quantities and units defined in this module store a value
of a numeric type that defaults to `double`. To change this default,
compile the module with one of these version flags:
`-version=SIReal`,
`-version=SIDouble`, or
`-version=SIFloat`.

Copyright: Copyright 2013-2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.si;

import quantities.internal.dimensions;
import quantities.base;
import quantities.math;
import quantities.parsing;
import quantities.qvariant;

import std.array : appender;
import std.conv;
import std.math : PI;
import std.format;
import std.string;
import std.typetuple;
import std.traits : isNumeric;
import core.time : Duration, dur;

version (unittest) import std.math : approxEqual;

alias StdN = double; // standard numeric (precision)

/// Base Units
enum meter   (N = StdN) = unit!(N, "L");
enum kilogram(N = StdN) = unit!(N, "M"); /// ditto
enum second  (N = StdN) = unit!(N, "T"); /// ditto
enum ampere  (N = StdN) = unit!(N, "I"); /// ditto
enum kelvin  (N = StdN) = unit!(N, "Θ"); /// ditto
enum mole    (N = StdN) = unit!(N, "N"); /// ditto
enum candela (N = StdN) = unit!(N, "J"); /// ditto

/// Base Unit Aliases
alias metre = meter; /// ditto

/// Base Units Shorthands
auto m (N = StdN)(N n) { return n * meter!N; }
auto kg(N = StdN)(N n) { return n * kilogram!N; } /// ditto
auto g (N = StdN)(N n) { return n * gram!N; } /// ditto
auto s (N = StdN)(N n) { return n * second!N; } /// ditto
auto A (N = StdN)(N n) { return n * ampere!N; } /// ditto
auto K (N = StdN)(N n) { return n * kelvin!N; } /// ditto
auto cd(N = StdN)(N n) { return n * candela!N; } /// ditto

@safe @nogc pure nothrow unittest
{
    auto m = 1.0L; // m can be overloaded as variable
    auto y = m.m; // inferred as real
}

/// Derived Units
enum radian(N    = StdN) = meter!N / meter!N; // ditto
enum steradian(N = StdN) = square(meter!N) / square(meter!N); /// ditto
enum hertz(N    = StdN) = 1 / second!N; /// ditto
enum newton(N    = StdN) = kilogram!N * meter!N / square(second!N); /// ditto
enum pascal(N    = StdN) = newton!N / square(meter!N); /// ditto
enum joule(N     = StdN) = newton!N * meter!N; /// ditto
enum watts(N      = StdN) = joule!N / second!N; /// ditto
enum coulomb(N   = StdN) = second!N * ampere!N; /// ditto
enum volt(N      = StdN) = watts!N / ampere!N; /// ditto
enum farad(N     = StdN) = coulomb!N / volt!N; /// ditto
enum ohm(N       = StdN) = volt!N / ampere!N; /// ditto
enum siemens(N  = StdN) = ampere!N / volt!N; /// ditto
enum weber(N     = StdN) = volt!N * second!N; /// ditto
enum tesla(N     = StdN) = weber!N / square(meter!N); /// ditto
enum henry(N     = StdN) = weber!N / ampere!N; /// ditto
enum celsius(N  = StdN) = kelvin!N; /// ditto
enum lumen(N     = StdN) = candela!N / steradian!N; /// ditto
enum lux(N      = StdN) = lumen!N / square(meter!N); /// ditto
enum becquerel(N = StdN) = 1 / second!N; /// ditto
enum gray(N      = StdN) = joule!N / kilogram!N; /// ditto
enum sievert(N   = StdN) = joule!N / kilogram!N; /// ditto
enum katal(N     = StdN) = mole!N / second!N; /// ditto

enum gram(N          = StdN) = 1e-3 * kilogram!N; /// ditto
enum minute(N        = StdN) = 60 * second!N; /// ditto
enum hour(N          = StdN) = 60 * minute!N; /// ditto
enum day(N           = StdN) = 24 * hour!N; /// ditto
enum degreeOfAngle(N = StdN) = PI / 180 * radian!N; /// ditto
enum minuteOfAngle(N = StdN) = degreeOfAngle!N / 60; /// ditto
enum secondOfAngle(N = StdN) = minuteOfAngle!N / 60; /// ditto
enum hectare(N       = StdN) = 1e4 * square(meter!N); /// ditto
enum liter(N         = StdN) = 1e-3 * cubic(meter!N); /// ditto
alias litre          = liter; /// ditto
enum ton(N           = StdN) = 1e3 * kilogram!N; /// ditto
enum electronVolt(N  = StdN) = 1.60217653e-19 * joule!N; /// ditto
enum dalton(N        = StdN) = 1.66053886e-27 * kilogram!N; /// ditto

//enum one = Quantity!(N, Dimensions.init)(1); /// The dimensionless unit 'one'

alias Length(N = StdN) = typeof(meter!N); /// Predefined quantity type templates for SI quantities
alias Mass(N = StdN) = typeof(kilogram!N); /// ditto
alias Time(N = StdN) = typeof(second!N); /// ditto
alias ElectricCurrent(N = StdN) = typeof(ampere!N); /// ditto
alias Temperature(N = StdN) = typeof(kelvin!N); /// ditto
alias AmountOfSubstance(N = StdN) = typeof(mole!N); /// ditto
alias LuminousIntensity(N = StdN) = typeof(candela!N); /// ditto

alias Area(N = StdN) = typeof(square(meter!N)); /// ditto
alias Surface(N = StdN) = Area!N;
alias Volume(N = StdN) = typeof(cubic(meter!N)); /// ditto
alias Speed(N = StdN) = typeof(meter!N/second!N); /// ditto
alias Acceleration(N = StdN) = typeof(meter!N/square(second!N)); /// ditto
alias MassDensity(N = StdN) = typeof(kilogram!N/cubic(meter!N)); /// ditto
alias CurrentDensity(N = StdN) = typeof(ampere!N/square(meter!N)); /// ditto
alias MagneticFieldStrength(N = StdN) = typeof(ampere!N/meter!N); /// ditto
alias Concentration(N = StdN) = typeof(mole!N/cubic(meter!N)); /// ditto
alias MolarConcentration(N = StdN) = Concentration!N; /// ditto
alias MassicConcentration(N = StdN) = typeof(kilogram!N/cubic(meter!N)); /// ditto
alias Luminance(N = StdN) = typeof(candela!N/square(meter!N)); /// ditto
alias RefractiveIndex(N = StdN) = typeof(kilogram!N); /// ditto

alias Angle(N = StdN) = typeof(radian!N); /// ditto
alias SolidAngle(N = StdN) = typeof(steradian!N); /// ditto
alias Frequency(N = StdN) = typeof(hertz!N); /// ditto
alias Force(N = StdN) = typeof(newton!N); /// ditto
alias Pressure(N = StdN) = typeof(pascal!N); /// ditto
alias Energy(N = StdN) = typeof(joule!N); /// ditto
alias Work(N) = Energy!N; /// ditto
alias Heat(N) = Energy!N; /// ditto
alias Power(N = StdN) = typeof(watts!N); /// ditto
alias ElectricCharge(N = StdN) = typeof(coulomb!N); /// ditto
alias ElectricPotential(N = StdN) = typeof(volt!N); /// ditto
alias Capacitance(N = StdN) = typeof(farad!N); /// ditto
alias ElectricResistance(N = StdN) = typeof(ohm!N); /// ditto
alias ElectricConductance(N = StdN) = typeof(siemens!N); /// ditto
alias MagneticFlux(N = StdN) = typeof(weber!N); /// ditto
alias MagneticFluxDensity(N = StdN) = typeof(tesla!N); /// ditto
alias Inductance(N = StdN) = typeof(henry!N); /// ditto
alias LuminousFlux(N = StdN) = typeof(lumen!N); /// ditto
alias Illuminance(N = StdN) = typeof(lux!N); /// ditto
alias CelsiusTemperature(N = StdN) = typeof(celsius!N); /// ditto
alias Radioactivity(N = StdN) = typeof(becquerel!N); /// ditto
alias AbsorbedDose(N = StdN) = typeof(gray!N); /// ditto
alias DoseEquivalent(N = StdN) = typeof(sievert!N); /// ditto
alias CatalyticActivity(N = StdN) = typeof(katal!N); /// ditto

alias Dimensionless(N = StdN) = typeof(meter!N/meter!N); /// The type of dimensionless quantities

/// SI prefixes.
alias yotta = prefix!1e24;
alias zetta = prefix!1e21; /// ditto
alias exa = prefix!1e18; /// ditto
alias peta = prefix!1e15; /// ditto
alias tera = prefix!1e12; /// ditto
alias giga = prefix!1e9; /// ditto
alias mega = prefix!1e6; /// ditto
alias kilo = prefix!1e3; /// ditto
alias hecto = prefix!1e2; /// ditto
alias deca = prefix!1e1; /// ditto
alias deci = prefix!1e-1; /// ditto
alias centi = prefix!1e-2; /// ditto
alias milli = prefix!1e-3; /// ditto
alias micro = prefix!1e-6; /// ditto
alias nano = prefix!1e-9; /// ditto
alias pico = prefix!1e-12; /// ditto
alias femto = prefix!1e-15; /// ditto
alias atto = prefix!1e-18; /// ditto
alias zepto = prefix!1e-21; /// ditto
alias yocto = prefix!1e-24; /// ditto

/// A list of common SI symbols and prefixes
enum siSymbols(N) = SymbolList!N()
    .addUnit("m", meter!N)
    .addUnit("kg", kilogram!N)
    .addUnit("s", second!N)
    .addUnit("A", ampere!N)
    .addUnit("K", kelvin!N)
    .addUnit("mol", mole!N)
    .addUnit("cd", candela!N)
    .addUnit("rad", radian!N)
    .addUnit("sr", steradian!N)
    .addUnit("Hz", hertz!N)
    .addUnit("N", newton!N)
    .addUnit("Pa", pascal!N)
    .addUnit("J", joule!N)
    .addUnit("W", watts!N)
    .addUnit("C", coulomb!N)
    .addUnit("V", volt!N)
    .addUnit("F", farad!N)
    .addUnit("Ω", ohm!N)
    .addUnit("S", siemens!N)
    .addUnit("Wb", weber!N)
    .addUnit("T", tesla!N)
    .addUnit("H", henry!N)
    .addUnit("lm", lumen!N)
    .addUnit("lx", lux!N)
    .addUnit("Bq", becquerel!N)
    .addUnit("Gy", gray!N)
    .addUnit("Sv", sievert!N)
    .addUnit("kat", katal!N)
    .addUnit("g", gram!N)
    .addUnit("min", minute!N)
    .addUnit("h", hour!N)
    .addUnit("d", day!N)
    .addUnit("l", liter!N)
    .addUnit("L", liter!N)
    .addUnit("t", ton!N)
    .addUnit("eV", electronVolt!N)
    .addUnit("Da", dalton!N)
    .addPrefix("Y", 1e24)
    .addPrefix("Z", 1e21)
    .addPrefix("E", 1e18)
    .addPrefix("P", 1e15)
    .addPrefix("T", 1e12)
    .addPrefix("G", 1e9)
    .addPrefix("M", 1e6)
    .addPrefix("k", 1e3)
    .addPrefix("h", 1e2)
    .addPrefix("da", 1e1)
    .addPrefix("d", 1e-1)
    .addPrefix("c", 1e-2)
    .addPrefix("m", 1e-3)
    .addPrefix("µ", 1e-6)
    .addPrefix("n", 1e-9)
    .addPrefix("p", 1e-12)
    .addPrefix("f", 1e-15)
    .addPrefix("a", 1e-18)
    .addPrefix("z", 1e-21)
    .addPrefix("y", 1e-24)
    .addPrefix("Yi", 1024.0^^8)
    .addPrefix("Zi", 1024.0^^7)
    .addPrefix("Ei", 1024.0^^6)
    .addPrefix("Pi", 1024.0^^5)
    .addPrefix("Ti", 1024.0^^4)
    .addPrefix("Gi", 1024.0^^3)
    .addPrefix("Mi", 1024.0^^2)
    .addPrefix("Ki", 1024.0);

private static SymbolList!float _siSymbolsFloat;
private static SymbolList!double _siSymbolsDouble;
private static SymbolList!real _siSymbolsReal;

private static Parser!float _siParserFloat;
private static Parser!double _siParserDouble;
private static Parser!real _siParserReal;

static this()
{
    _siSymbolsFloat = siSymbols!float;
    _siSymbolsDouble = siSymbols!double;
    _siSymbolsReal = siSymbols!real;
    _siParserFloat = Parser!float(_siSymbolsFloat, &std.conv.parse!(float, string));
    _siParserDouble = Parser!double(_siSymbolsDouble, &std.conv.parse!(double, string));
    _siParserReal = Parser!real(_siSymbolsReal, &std.conv.parse!(real, string));
}

/// Parses a string for a quantity of type Q at runtime
Q parseSI(Q)(string str)
    if (isQuantity!Q)
{
    alias N = Q.valueType;
    static if (is(N == float))
    {
        return _siParserFloat.parse!Q(str);
    }
    else static if (is(N == double))
    {
        return _siParserDouble.parse!Q(str);
    }
    else static if (is(N == real))
    {
        return _siParserReal.parse!Q(str);
    }
    else
    {
        static assert("Unsupported type Quantity Value Type " ~ N.stringof);
    }
}
///
@safe unittest
{
    alias N = double;
    auto t = "90 min".parseSI!(Time!N);
    assert(t == 90 * minute!N);
    t = "h".parseSI!(Time!N);
    assert(t == 1 * hour!N);

    auto v = "2".parseSI!(Dimensionless!N);
    assert(v == (2 * meter!N) / meter!N);
}

/// A compile-time parser with automatic type deduction for SI quantities.
alias SI(N = StdN) = compileTimeParser!(N, siSymbols!N, std.conv.parse!(N, string));

/// Instantiator for $(D SI) of unit expression $(D unitExpression).
auto si(string unitExpression, T)(T n = 1.0)
    if (isNumeric!T)
{
    alias siN = SI!T;
    return n * siN!unitExpression;
}
///
pure nothrow @safe @nogc unittest
{
    auto min__ = si!"min";
    assert(is(typeof(min__) == Time!double));

    enum min_ = si!"min";
    static assert(is(typeof(min_) == Time!double));

    enum min = 1.0.si!"min";
    static assert(is(typeof(min) == Time!double));

    enum inch = 1.0f.si!"2.54 cm";
    static assert(is(typeof(inch) == Length!float));

    auto conc = 1.0L.si!"1 µmol/L";
    static assert(is(typeof(conc) == Concentration!real));

    auto speed = 1.0.si!"m s^-1";
    static assert(is(typeof(speed) == Speed!double));

    auto value = 1.0f.si!"0.5";
    static assert(is(typeof(value) == Dimensionless!float));
}

/++
Helper struct that formats a SI quantity.
+/
struct SIFormatWrapper(Q)
    if (isQuantity!Q || isQVariant!Q)
{
    private string fmt;

    /++
    Creates a new formatter from a format string.
    +/
    this(string fmt)
    {
        this.fmt = fmt;
    }

    /++
    Returns a wrapper struct that can be formatted by `std.string.format` or
    `std.format` functions.
    +/
    auto opCall(Q quantity) const
    {
        auto _fmt = fmt;

        ///
        struct Wrapper
        {
            private Q quantity;

            void toString(scope void delegate(const(char)[]) sink) const
            {
                auto spec = FormatSpec!char(_fmt);
                spec.writeUpToNextSpec(sink);
                auto target = spec.trailing.idup;
                auto unit = target.parseSI!Q;
                sink.formatValue(quantity.value(unit), spec);
                sink(target);
            }

            string toString() const
            {
                return format("%s", this);
            }
        }

        return Wrapper(quantity);
    }
}
///
unittest
{
    import std.string;

    alias N = double;
    auto sf = SIFormatWrapper!(Speed!N)("%.1f km/h");
    auto speed = 343.4 * meter!N / second!N;
    assert("Speed: %s".format(sf(speed)) == "Speed: 1236.2 km/h");
}

unittest
{
    alias N = double;
    auto sf = SIFormatWrapper!(Speed!N)("%.1f km/h");
    alias siN = SI!N;
    assert(text(sf(siN!"343.4 m/s")) == "1236.2 km/h");
    assert(text(sf("343.4 m/s".parseSI!(Speed!N))) == "1236.2 km/h");
}

/++
Convenience function that returns a SIFormatter when the format string is
known at compile-time.
+/
auto siFormatWrapper(N, string fmt)()
{
    alias siN = SI!N;
    enum unit = siN!({
            auto spec = FormatSpec!char(fmt);
            auto dummy = appender!string;
            spec.writeUpToNextSpec(dummy);
            return spec.trailing.idup;
        }());
    return SIFormatWrapper!(typeof(unit))(fmt);
}
///
unittest
{
    import std.string;

    alias N = double;
    auto sf = siFormatWrapper!(N, "%.1f km/h");
    auto speed = 343.4 * meter!N / second!N;
    assert("Speed: %s".format(sf(speed)) == "Speed: 1236.2 km/h");
}

/// Converts a quantity of time to or from a core.time.Duration
Time!N fromDuration(N)(Duration d) pure @safe
{
    return d.total!"hnsecs" * hecto(nano(second!N));
}

/// ditto
Duration toDuration(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.conv;
    alias N = Q.valueType;
    auto hns = quantity.value(hecto(nano(second!N)));
    return dur!"hnsecs"(hns.roundTo!long);
}

///
@safe unittest // Durations
{
    alias N = double;
    auto d = 4.dur!"msecs";
    auto t = d.fromDuration!N;
    assert(t.value(milli(second!N)).approxEqual(4));

    auto t2 = 3.5 * minute!N;
    auto d2 = t2.toDuration;
    // auto s = d2.split!("minute", "second");
    // assert(s.minute == 3 && s.second == 30);
}
