// Written in the D programming language
/++
This module defines the SI units and prefixes.

Copyright: Copyright 2013-2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.si;

import quantities.base;
import quantities.parsing;
import std.conv;
import std.math : PI;
import core.time : Duration, dur;

version (unittest)
{
    import std.math : approxEqual;
}

/++
Predefined SI units.
+/
enum meter = unit!"L";
alias metre = meter; /// ditto
enum kilogram = unit!"M"; /// ditto
enum second = unit!"T"; /// ditto
enum ampere = unit!"I"; /// ditto
enum kelvin = unit!"Θ"; /// ditto
enum mole = unit!"N"; /// ditto
enum candela = unit!"J"; /// ditto

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

enum one = Quantity!real(1); /// The dimensionless unit 'one'

alias Length = QuantityType!(meter); /// Predefined quantity type templates for SI quantities
alias Mass = QuantityType!(kilogram); /// ditto
alias Time = QuantityType!(second); /// ditto
alias ElectricCurrent = QuantityType!(ampere); /// ditto
alias Temperature = QuantityType!(kelvin); /// ditto
alias AmountOfSubstance = QuantityType!(mole); /// ditto
alias LuminousIntensity = QuantityType!(candela); /// ditto

alias Area = QuantityType!(square(meter)); /// ditto
alias Surface = Area;
alias Volume = QuantityType!(cubic(meter)); /// ditto
alias Speed = QuantityType!(meter/second); /// ditto
alias Acceleration = QuantityType!(meter/square(second)); /// ditto
alias MassDensity = QuantityType!(kilogram/cubic(meter)); /// ditto
alias CurrentDensity = QuantityType!(ampere/square(meter)); /// ditto
alias MagneticFieldStrength = QuantityType!(ampere/meter); /// ditto
alias Concentration = QuantityType!(mole/cubic(meter)); /// ditto
alias MolarConcentration = Concentration; /// ditto
alias MassicConcentration = QuantityType!(kilogram/cubic(meter)); /// ditto
alias Luminance = QuantityType!(candela/square(meter)); /// ditto
alias RefractiveIndex = QuantityType!(kilogram); /// ditto

alias Angle = QuantityType!(radian); /// ditto
alias SolidAngle = QuantityType!(steradian); /// ditto
alias Frequency = QuantityType!(hertz); /// ditto
alias Force = QuantityType!(newton); /// ditto
alias Pressure = QuantityType!(pascal); /// ditto
alias Energy = QuantityType!(joule); /// ditto
alias Work = Energy; /// ditto
alias Heat = Energy; /// ditto
alias Power = QuantityType!(watt); /// ditto
alias ElectricCharge = QuantityType!(coulomb); /// ditto
alias ElectricPotential = QuantityType!(volt); /// ditto
alias Capacitance = QuantityType!(farad); /// ditto
alias ElectricResistance = QuantityType!(ohm); /// ditto
alias ElectricConductance = QuantityType!(siemens); /// ditto
alias MagneticFlux = QuantityType!(weber); /// ditto
alias MagneticFluxDensity = QuantityType!(tesla); /// ditto
alias Inductance = QuantityType!(henry); /// ditto
alias LuminousFlux = QuantityType!(lumen); /// ditto
alias Illuminance = QuantityType!(lux); /// ditto
alias CelsiusTemperature = QuantityType!(celsius); /// ditto
alias Radioactivity = QuantityType!(becquerel); /// ditto
alias AbsorbedDose = QuantityType!(gray); /// ditto
alias DoseEquivalent = QuantityType!(sievert); /// ditto
alias CatalyticActivity = QuantityType!(katal); /// ditto

alias Dimensionless = QuantityType!(meter/meter); /// The type of dimensionless quantities


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


/// Parses text for a SI unit or quantity at runtime or compile-time.
auto parseSI(Q, S)(S text)
    if (isQuantity!Q)
{
    return parseQuantity!(Q, std.conv.parse!(real, string))(text, siSymbolList);
}
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

static __gshared SymbolList!real _siSymbolList;
static this()
{
    _siSymbolList = SymbolList!real(siRTUnits, siRTPrefixes, 2);
}

/++
Parses a string for a a SI-compatible quantity.
+/
alias si = ctQuantityParser!(
    real,
    std.conv.parse!(real, string),
    addUnit("m", meter),
    addUnit("kg", kilogram),
    addUnit("s", second),
    addUnit("A", ampere),
    addUnit("K", kelvin),
    addUnit("mol", mole),
    addUnit("cd", candela),
    addUnit("rad", radian),
    addUnit("sr", steradian),
    addUnit("Hz", hertz),
    addUnit("N", newton),
    addUnit("Pa", pascal),
    addUnit("J", joule),
    addUnit("W", watt),
    addUnit("C", coulomb),
    addUnit("V", volt),
    addUnit("F", farad),
    addUnit("Ω", ohm),
    addUnit("S", siemens),
    addUnit("Wb", weber),
    addUnit("T", tesla),
    addUnit("H", henry),
    addUnit("lm", lumen),
    addUnit("lx", lux),
    addUnit("Bq", becquerel),
    addUnit("Gy", gray),
    addUnit("Sv", sievert),
    addUnit("kat", katal),
    addUnit("g", gram),
    addUnit("min", minute),
    addUnit("h", hour),
    addUnit("d", day),
    addUnit("l", liter),
    addUnit("L", liter),
    addUnit("t", ton),
    addUnit("eV", electronVolt),
    addUnit("Da", dalton),
    addPrefix("Y", 1e24L),
    addPrefix("Z", 1e21L),
    addPrefix("E", 1e18L),
    addPrefix("P", 1e15L),
    addPrefix("T", 1e12L),
    addPrefix("G", 1e9L),
    addPrefix("M", 1e6L),
    addPrefix("k", 1e3L),
    addPrefix("h", 1e2L),
    addPrefix("da", 1e1L),
    addPrefix("d", 1e-1L),
    addPrefix("c", 1e-2L),
    addPrefix("m", 1e-3L),
    addPrefix("µ", 1e-6L),
    addPrefix("n", 1e-9L),
    addPrefix("p", 1e-12L),
    addPrefix("f", 1e-15L),
    addPrefix("a", 1e-18L),
    addPrefix("z", 1e-21L),
    addPrefix("y", 1e-24L),
    addPrefix("Yi", (2.0^^10)^^8),
    addPrefix("Zi", (2.0^^10)^^7),
    addPrefix("Ei", (2.0^^10)^^6),
    addPrefix("Pi", (2.0^^10)^^5),
    addPrefix("Ti", (2.0^^10)^^4),
    addPrefix("Gi", (2.0^^10)^^3),
    addPrefix("Mi", (2.0^^10)^^2),
    addPrefix("Ki", (2.0^^10))
);
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

/// Returns a SymbolList consisting of the main SI units and prefixes.
SymbolList!real siSymbolList()
{
    return _siSymbolList;
}

package
{
    enum siRTUnits = [
        "m" : meter.toRuntime,
        "kg" : kilogram.toRuntime,
        "s" : second.toRuntime,
        "A" : ampere.toRuntime,
        "K" : kelvin.toRuntime,
        "mol" : mole.toRuntime,
        "cd" : candela.toRuntime,
        "rad" : radian.toRuntime,
        "sr" : steradian.toRuntime,
        "Hz" : hertz.toRuntime,
        "N" : newton.toRuntime,
        "Pa" : pascal.toRuntime,
        "J" : joule.toRuntime,
        "W" : watt.toRuntime,
        "C" : coulomb.toRuntime,
        "V" : volt.toRuntime,
        "F" : farad.toRuntime,
        "Ω" : ohm.toRuntime,
        "S" : siemens.toRuntime,
        "Wb" : weber.toRuntime,
        "T" : tesla.toRuntime,
        "H" : henry.toRuntime,
        "lm" : lumen.toRuntime,
        "lx" : lux.toRuntime,
        "Bq" : becquerel.toRuntime,
        "Gy" : gray.toRuntime,
        "Sv" : sievert.toRuntime,
        "kat" : katal.toRuntime,
        "g" : gram.toRuntime,
        "min" : minute.toRuntime,
        "h" : hour.toRuntime,
        "d" : day.toRuntime,
        "l" : liter.toRuntime,
        "L" : liter.toRuntime,
        "t" : ton.toRuntime,
        "eV" : electronVolt.toRuntime,
        "Da" : dalton.toRuntime,
    ];
    
    enum siRTPrefixes = [
        "Y" : 1e24L,
        "Z" : 1e21L,
        "E" : 1e18L,
        "P" : 1e15L,
        "T" : 1e12L,
        "G" : 1e9L,
        "M" : 1e6L,
        "k" : 1e3L,
        "h" : 1e2L,
        "da": 1e1L,
        "d" : 1e-1L,
        "c" : 1e-2L,
        "m" : 1e-3L,
        "µ" : 1e-6L,
        "n" : 1e-9L,
        "p" : 1e-12L,
        "f" : 1e-15L,
        "a" : 1e-18L,
        "z" : 1e-21L,
        "y" : 1e-24L,
        "Yi": (2.0^^10)^^8,
        "Zi": (2.0^^10)^^7,
        "Ei": (2.0^^10)^^6,
        "Pi": (2.0^^10)^^5,
        "Ti": (2.0^^10)^^4,
        "Gi": (2.0^^10)^^3,
        "Mi": (2.0^^10)^^2,
        "Ki": (2.0^^10),
    ];
}


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

