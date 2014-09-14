// Written in the D programming language
/++
This module defines the SI units and prefixes.

All the quantities and units defined in this module store a value
of type double intenally. So the predefined parsers can only parse
double values.

Copyright: Copyright 2013-2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.si;

import quantities.base;
import quantities.math;
import quantities.parsing;
import std.conv;
import std.math : PI;
import std.typetuple;
import core.time : Duration, dur;

version (unittest) import std.math : approxEqual;

/++
Predefined SI units.
+/
enum meter = unit!(double, "L");
alias metre = meter; /// ditto
enum kilogram = unit!(double, "M"); /// ditto
enum second = unit!(double, "T"); /// ditto
enum ampere = unit!(double, "I"); /// ditto
enum kelvin = unit!(double, "Θ"); /// ditto
enum mole = unit!(double, "N"); /// ditto
enum candela = unit!(double, "J"); /// ditto

enum radian = meter / meter; // ditto
enum steradian = square(meter) / square(meter); /// ditto
enum hertz = 1 / second; /// ditto
enum newton = kilogram * meter / square(second); /// ditto
enum pascal = newton / square(meter); /// ditto
enum joule = newton * meter; /// ditto
enum watt = joule / second; /// ditto
enum coulomb = second * ampere; /// ditto
enum volt = watt / ampere; /// ditto
enum farad = coulomb / volt; /// ditto
enum ohm = volt / ampere; /// ditto
enum siemens = ampere / volt; /// ditto
enum weber = volt * second; /// ditto
enum tesla = weber / square(meter); /// ditto
enum henry = weber / ampere; /// ditto
enum celsius = kelvin; /// ditto
enum lumen = candela / steradian; /// ditto
enum lux = lumen / square(meter); /// ditto
enum becquerel = 1 / second; /// ditto
enum gray = joule / kilogram; /// ditto
enum sievert = joule / kilogram; /// ditto
enum katal = mole / second; /// ditto

enum gram = 1e-3 * kilogram; /// ditto
enum minute = 60 * second; /// ditto
enum hour = 60 * minute; /// ditto
enum day = 24 * hour; /// ditto
enum degreeOfAngle = PI / 180 * radian; /// ditto
enum minuteOfAngle = degreeOfAngle / 60; /// ditto
enum secondOfAngle = minuteOfAngle / 60; /// ditto
enum hectare = 1e4 * square(meter); /// ditto
enum liter = 1e-3 * cubic(meter); /// ditto
alias litre = liter; /// ditto
enum ton = 1e3 * kilogram; /// ditto
enum electronVolt = 1.60217653e-19 * joule; /// ditto
enum dalton = 1.66053886e-27 * kilogram; /// ditto

enum one = Quantity!double(1); /// The dimensionless unit 'one'

alias Length = typeof(meter); /// Predefined quantity type templates for SI quantities
alias Mass = typeof(kilogram); /// ditto
alias Time = typeof(second); /// ditto
alias ElectricCurrent = typeof(ampere); /// ditto
alias Temperature = typeof(kelvin); /// ditto
alias AmountOfSubstance = typeof(mole); /// ditto
alias LuminousIntensity = typeof(candela); /// ditto

alias Area = typeof(square(meter)); /// ditto
alias Surface = Area;
alias Volume = typeof(cubic(meter)); /// ditto
alias Speed = typeof(meter/second); /// ditto
alias Acceleration = typeof(meter/square(second)); /// ditto
alias MassDensity = typeof(kilogram/cubic(meter)); /// ditto
alias CurrentDensity = typeof(ampere/square(meter)); /// ditto
alias MagneticFieldStrength = typeof(ampere/meter); /// ditto
alias Concentration = typeof(mole/cubic(meter)); /// ditto
alias MolarConcentration = Concentration; /// ditto
alias MassicConcentration = typeof(kilogram/cubic(meter)); /// ditto
alias Luminance = typeof(candela/square(meter)); /// ditto
alias RefractiveIndex = typeof(kilogram); /// ditto

alias Angle = typeof(radian); /// ditto
alias SolidAngle = typeof(steradian); /// ditto
alias Frequency = typeof(hertz); /// ditto
alias Force = typeof(newton); /// ditto
alias Pressure = typeof(pascal); /// ditto
alias Energy = typeof(joule); /// ditto
alias Work = Energy; /// ditto
alias Heat = Energy; /// ditto
alias Power = typeof(watt); /// ditto
alias ElectricCharge = typeof(coulomb); /// ditto
alias ElectricPotential = typeof(volt); /// ditto
alias Capacitance = typeof(farad); /// ditto
alias ElectricResistance = typeof(ohm); /// ditto
alias ElectricConductance = typeof(siemens); /// ditto
alias MagneticFlux = typeof(weber); /// ditto
alias MagneticFluxDensity = typeof(tesla); /// ditto
alias Inductance = typeof(henry); /// ditto
alias LuminousFlux = typeof(lumen); /// ditto
alias Illuminance = typeof(lux); /// ditto
alias CelsiusTemperature = typeof(celsius); /// ditto
alias Radioactivity = typeof(becquerel); /// ditto
alias AbsorbedDose = typeof(gray); /// ditto
alias DoseEquivalent = typeof(sievert); /// ditto
alias CatalyticActivity = typeof(katal); /// ditto

alias Dimensionless = typeof(meter/meter); /// The type of dimensionless quantities

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

private alias siSymbolTuple = TypeTuple!(
    withUnit("m", meter),
    withUnit("kg", kilogram),
    withUnit("s", second),
    withUnit("A", ampere),
    withUnit("K", kelvin),
    withUnit("mol", mole),
    withUnit("cd", candela),
    withUnit("rad", radian),
    withUnit("sr", steradian),
    withUnit("Hz", hertz),
    withUnit("N", newton),
    withUnit("Pa", pascal),
    withUnit("J", joule),
    withUnit("W", watt),
    withUnit("C", coulomb),
    withUnit("V", volt),
    withUnit("F", farad),
    withUnit("Ω", ohm),
    withUnit("S", siemens),
    withUnit("Wb", weber),
    withUnit("T", tesla),
    withUnit("H", henry),
    withUnit("lm", lumen),
    withUnit("lx", lux),
    withUnit("Bq", becquerel),
    withUnit("Gy", gray),
    withUnit("Sv", sievert),
    withUnit("kat", katal),
    withUnit("g", gram),
    withUnit("min", minute),
    withUnit("h", hour),
    withUnit("d", day),
    withUnit("l", liter),
    withUnit("L", liter),
    withUnit("t", ton),
    withUnit("eV", electronVolt),
    withUnit("Da", dalton),
    withPrefix("Y", 1e24),
    withPrefix("Z", 1e21),
    withPrefix("E", 1e18),
    withPrefix("P", 1e15),
    withPrefix("T", 1e12),
    withPrefix("G", 1e9),
    withPrefix("M", 1e6),
    withPrefix("k", 1e3),
    withPrefix("h", 1e2),
    withPrefix("da", 1e1),
    withPrefix("d", 1e-1),
    withPrefix("c", 1e-2),
    withPrefix("m", 1e-3),
    withPrefix("µ", 1e-6),
    withPrefix("n", 1e-9),
    withPrefix("p", 1e-12),
    withPrefix("f", 1e-15),
    withPrefix("a", 1e-18),
    withPrefix("z", 1e-21),
    withPrefix("y", 1e-24),
    withPrefix("Yi", 1024.0^^8),
    withPrefix("Zi", 1024.0^^7),
    withPrefix("Ei", 1024.0^^6),
    withPrefix("Pi", 1024.0^^5),
    withPrefix("Ti", 1024.0^^4),
    withPrefix("Gi", 1024.0^^3),
    withPrefix("Mi", 1024.0^^2),
    withPrefix("Ki", 1024.0)
);

enum _siSymbolList = makeSymbolList!double(siSymbolTuple);
static __gshared SymbolList!double siSymbolList;
shared static this()
{
    siSymbolList = _siSymbolList;
}

/// Creates a function that parses a string for a SI unit or quantity at runtime.
alias parseSI = rtQuantityParser!(double, siSymbolList);
///
unittest
{
    auto t = parseSI!Time("90 min");
    assert(t == 90 * minute);
    t = parseSI!Time("h");
    assert(t == 1 * hour);
}

unittest
{
    auto v = parseSI!Dimensionless("2");
    assert(v == (2 * meter) / meter);
}

/// Creates a function that parses a string for a SI unit or quantity at compile-time.
alias si = ctQuantityParser!(double, _siSymbolList, std.conv.parse!(double, string));
///
unittest
{
    enum min = si!"min";
    enum inch = si!"2.54 cm";
    
    auto conc = si!"1 µmol/L";
    auto speed = si!"m s^-1";
    auto value = si!"0.5";
    
    static assert(is(typeof(conc) == Concentration));
    static assert(is(typeof(speed) == Speed));
    static assert(is(typeof(value) == Dimensionless));
}

/++
Helper template that can be used to add all SI units and prefixes when
building a symbol list with makeSymbolList.
+/
alias withAllSI = siSymbolTuple;

/// Converts a quantity of time to or from a core.time.Duration
Time fromDuration(Duration d)
{
    return d.total!"hnsecs" * hecto(nano(second));
}

/// ditto
Duration toDuration(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.conv;
    auto hns = quantity.value(hecto(nano(second)));
    return dur!"hnsecs"(roundTo!long(hns));
}

///
unittest // Durations
{
    auto d = 4.dur!"msecs";
    auto t = fromDuration(d);
    assert(t.value(milli(second)).approxEqual(4));

    auto t2 = 3.5 * minute;
    auto d2 = t2.toDuration;
    assert(d2.get!"minutes" == 3 && d2.get!"seconds" == 30);
}

