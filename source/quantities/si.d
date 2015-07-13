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
import core.time : Duration, dur;

version (unittest) import std.math : approxEqual;

alias StdN = double; // standard numeric (precision)

/++ Predefined SI units. +/
auto meters(N    = StdN)(N n = 1) { return n * unit!(N, "L"); }
alias metres     = meters; /// ditto
auto kilograms(N = StdN)(N n = 1) { return n * unit!(N, "M"); } /// ditto
auto seconds(N   = StdN)(N n = 1) { return n * unit!(N, "T"); } /// ditto
auto amperes(N   = StdN)(N n = 1) { return n * unit!(N, "I"); } /// ditto
auto kelvins(N   = StdN)(N n = 1) { return n * unit!(N, "Θ"); } /// ditto
auto moles(N     = StdN)(N n = 1) { return n * unit!(N, "N"); } /// ditto
auto candelas(N  = StdN)(N n = 1) { return n * unit!(N, "J"); } /// ditto

enum radians(N    = StdN) = meters!N() / meters!N(); // ditto
enum steradians(N = StdN) = square(meters!N()) / square(meters!N()); /// ditto
enum hertzes(N    = StdN) = 1 / seconds!N(); /// ditto
enum newtons(N    = StdN) = kilograms!N() * meters!N() / square(seconds!N()); /// ditto
enum pascals(N    = StdN) = newtons!N / square(meters!N()); /// ditto
enum joules(N     = StdN) = newtons!N * meters!N(); /// ditto
enum watts(N      = StdN) = joules!N / seconds!N(); /// ditto
enum coulombs(N   = StdN) = seconds!N() * amperes!N(); /// ditto
enum volts(N      = StdN) = watts!N / amperes!N(); /// ditto
enum farads(N     = StdN) = coulombs!N / volts!N; /// ditto
enum ohms(N       = StdN) = volts!N / amperes!N(); /// ditto
enum siemenses(N  = StdN) = amperes!N() / volts!N; /// ditto
enum webers(N     = StdN) = volts!N * seconds!N(); /// ditto
enum teslas(N     = StdN) = webers!N / square(meters!N()); /// ditto
enum henrys(N     = StdN) = webers!N / amperes!N(); /// ditto
enum celsiuses(N  = StdN) = kelvins!N(); /// ditto
enum lumens(N     = StdN) = candelas!N() / steradians!N; /// ditto
enum luxes(N      = StdN) = lumens!N / square(meters!N()); /// ditto
enum becquerels(N = StdN) = 1 / seconds!N(); /// ditto
enum grays(N      = StdN) = joules!N / kilograms!N(); /// ditto
enum sieverts(N   = StdN) = joules!N / kilograms!N(); /// ditto
enum katals(N     = StdN) = moles!N() / seconds!N(); /// ditto

enum grams(N          = StdN) = 1e-3 * kilograms!N(); /// ditto
enum minutes(N        = StdN) = 60 * seconds!N(); /// ditto
enum hours(N          = StdN) = 60 * minutes!N; /// ditto
enum days(N           = StdN) = 24 * hours!N; /// ditto
enum degreesOfAngle(N = StdN) = PI / 180 * radians!N; /// ditto
enum minutesOfAngle(N = StdN) = degreesOfAngle!N / 60; /// ditto
enum secondsOfAngle(N = StdN) = minutesOfAngle!N / 60; /// ditto
enum hectares(N       = StdN) = 1e4 * square(meters!N()); /// ditto
enum liters(N         = StdN) = 1e-3 * cubic(meters!N()); /// ditto
alias litres          = liters; /// ditto
enum tons(N           = StdN) = 1e3 * kilograms!N(); /// ditto
enum electronVolts(N  = StdN) = 1.60217653e-19 * joules!N; /// ditto
enum daltons(N        = StdN) = 1.66053886e-27 * kilograms!N(); /// ditto

//enum one = Quantity!(N, Dimensions.init)(1); /// The dimensionless unit 'one'

alias Length(N = StdN) = typeof(meters!N()); /// Predefined quantity type templates for SI quantities
alias Mass(N = StdN) = typeof(kilograms!N()); /// ditto
alias Time(N = StdN) = typeof(seconds!N()); /// ditto
alias ElectricCurrent(N = StdN) = typeof(amperes!N()); /// ditto
alias Temperature(N = StdN) = typeof(kelvins!N()); /// ditto
alias AmountOfSubstance(N = StdN) = typeof(moles!N()); /// ditto
alias LuminousIntensity(N = StdN) = typeof(candelas!N()); /// ditto

alias Area(N = StdN) = typeof(square(meters!N())); /// ditto
alias Surface(N = StdN) = Area!N;
alias Volume(N = StdN) = typeof(cubic(meters!N())); /// ditto
alias Speed(N = StdN) = typeof(meters!N()/seconds!N()); /// ditto
alias Acceleration(N = StdN) = typeof(meters!N()/square(seconds!N())); /// ditto
alias MassDensity(N = StdN) = typeof(kilograms!N()/cubic(meters!N())); /// ditto
alias CurrentDensity(N = StdN) = typeof(amperes!N()/square(meters!N())); /// ditto
alias MagneticFieldStrength(N = StdN) = typeof(amperes!N()/meters!N()); /// ditto
alias Concentration(N = StdN) = typeof(moles!N()/cubic(meters!N())); /// ditto
alias MolarConcentration(N = StdN) = Concentration!N; /// ditto
alias MassicConcentration(N = StdN) = typeof(kilograms!N()/cubic(meters!N())); /// ditto
alias Luminance(N = StdN) = typeof(candelas!N()/square(meters!N())); /// ditto
alias RefractiveIndex(N = StdN) = typeof(kilograms!N()); /// ditto

alias Angle(N = StdN) = typeof(radians!N); /// ditto
alias SolidAngle(N = StdN) = typeof(steradians!N); /// ditto
alias Frequency(N = StdN) = typeof(hertzes!N); /// ditto
alias Force(N = StdN) = typeof(newtons!N); /// ditto
alias Pressure(N = StdN) = typeof(pascals!N); /// ditto
alias Energy(N = StdN) = typeof(joules!N); /// ditto
alias Work(N) = Energy!N; /// ditto
alias Heat(N) = Energy!N; /// ditto
alias Power(N = StdN) = typeof(watts!N); /// ditto
alias ElectricCharge(N = StdN) = typeof(coulombs!N); /// ditto
alias ElectricPotential(N = StdN) = typeof(volts!N); /// ditto
alias Capacitance(N = StdN) = typeof(farads!N); /// ditto
alias ElectricResistance(N = StdN) = typeof(ohms!N); /// ditto
alias ElectricConductance(N = StdN) = typeof(siemenses!N); /// ditto
alias MagneticFlux(N = StdN) = typeof(webers!N); /// ditto
alias MagneticFluxDensity(N = StdN) = typeof(teslas!N); /// ditto
alias Inductance(N = StdN) = typeof(henrys!N); /// ditto
alias LuminousFlux(N = StdN) = typeof(lumens!N); /// ditto
alias Illuminance(N = StdN) = typeof(luxes!N); /// ditto
alias CelsiusTemperature(N = StdN) = typeof(celsiuses!N); /// ditto
alias Radioactivity(N = StdN) = typeof(becquerels!N); /// ditto
alias AbsorbedDose(N = StdN) = typeof(grays!N); /// ditto
alias DoseEquivalent(N = StdN) = typeof(sieverts!N); /// ditto
alias CatalyticActivity(N = StdN) = typeof(katals!N); /// ditto

alias Dimensionless(N = StdN) = typeof(meters!N()/meters!N()); /// The type of dimensionless quantities

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
    .addUnit("m", meters!N())
    .addUnit("kg", kilograms!N())
    .addUnit("s", seconds!N())
    .addUnit("A", amperes!N())
    .addUnit("K", kelvins!N())
    .addUnit("mol", moles!N())
    .addUnit("cd", candelas!N())
    .addUnit("rad", radians!N)
    .addUnit("sr", steradians!N)
    .addUnit("Hz", hertzes!N)
    .addUnit("N", newtons!N)
    .addUnit("Pa", pascals!N)
    .addUnit("J", joules!N)
    .addUnit("W", watts!N)
    .addUnit("C", coulombs!N)
    .addUnit("V", volts!N)
    .addUnit("F", farads!N)
    .addUnit("Ω", ohms!N)
    .addUnit("S", siemenses!N)
    .addUnit("Wb", webers!N)
    .addUnit("T", teslas!N)
    .addUnit("H", henrys!N)
    .addUnit("lm", lumens!N)
    .addUnit("lx", luxes!N)
    .addUnit("Bq", becquerels!N)
    .addUnit("Gy", grays!N)
    .addUnit("Sv", sieverts!N)
    .addUnit("kat", katals!N)
    .addUnit("g", grams!N)
    .addUnit("min", minutes!N)
    .addUnit("h", hours!N)
    .addUnit("d", days!N)
    .addUnit("l", liters!N)
    .addUnit("L", liters!N)
    .addUnit("t", tons!N)
    .addUnit("eV", electronVolts!N)
    .addUnit("Da", daltons!N)
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
    assert(t == 90 * minutes!N);
    t = "h".parseSI!(Time!N);
    assert(t == 1 * hours!N);

    auto v = "2".parseSI!(Dimensionless!N);
    assert(v == (2 * meters!N()) / meters!N());
}

/// A compile-time parser with automatic type deduction for SI quantities.
alias si(N = StdN) = compileTimeParser!(N, siSymbols!N, std.conv.parse!(N, string));
///
pure @safe unittest
{
    alias N = double;
    alias siN = si!N;

    enum min = siN!"min";
    enum inch = siN!"2.54 cm";
    auto conc = siN!"1 µmol/L";
    auto speed = siN!"m s^-1";
    auto value = siN!"0.5";

    static assert(is(typeof(inch) == Length!N));
    static assert(is(typeof(conc) == Concentration!N));
    static assert(is(typeof(speed) == Speed!N));
    static assert(is(typeof(value) == Dimensionless!N));
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
    auto speed = 343.4 * meters!N()/seconds!N();
    assert("Speed: %s".format(sf(speed)) == "Speed: 1236.2 km/h");
}

unittest
{
    alias N = double;
    auto sf = SIFormatWrapper!(Speed!N)("%.1f km/h");
    alias siN = si!N;
    assert(text(sf(siN!"343.4 m/s")) == "1236.2 km/h");
    assert(text(sf("343.4 m/s".parseSI!(Speed!N))) == "1236.2 km/h");
}

/++
Convenience function that returns a SIFormatter when the format string is
known at compile-time.
+/
auto siFormatWrapper(N, string fmt)()
{
    alias siN = si!N;
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
    auto speed = 343.4 * meters!N() / seconds!N();
    assert("Speed: %s".format(sf(speed)) == "Speed: 1236.2 km/h");
}

/// Converts a quantity of time to or from a core.time.Duration
Time!N fromDuration(N)(Duration d) pure @safe
{
    return d.total!"hnsecs" * hecto(nano(seconds!N()));
}

/// ditto
Duration toDuration(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.conv;
    alias N = Q.valueType;
    auto hns = quantity.value(hecto(nano(seconds!N())));
    return dur!"hnsecs"(hns.roundTo!long);
}

///
@safe unittest // Durations
{
    alias N = double;
    auto d = 4.dur!"msecs";
    auto t = d.fromDuration!N;
    assert(t.value(milli(seconds!N())).approxEqual(4));

    auto t2 = 3.5 * minutes!N;
    auto d2 = t2.toDuration;
    auto s = d2.split!("minutes", "seconds")();
    assert(s.minutes == 3 && s.seconds == 30);
}
