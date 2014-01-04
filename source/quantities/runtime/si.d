// Written in the D programming language
/++
This module defines the SI units and prefixes.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.runtime.si;

import quantities.runtime.base;
import std.math : PI;
import core.time : Duration, dur;

version (unittest)
{
    import std.math : approxEqual;
}
version (Have_tested) import tested;
else private struct name { string dummy; }

/// Converts a quantity of time to or from a core.time.Duration
auto fromDuration(Duration d)
{
    return d.total!"hnsecs" * hecto(nano(second));
}

/// ditto
Duration toDuration(Q)(Q quantity)
{
    import std.conv;
    auto hns = quantity.value(hecto(nano(second)));
    return dur!"hnsecs"(roundTo!long(hns));
}

///
@name("Durations")
unittest
{
    auto d = 4.dur!"msecs";
    auto t = fromDuration(d);
    assert(t.value(milli(second)) == 4);

    auto t2 = 3.5 * minute;
    auto d2 = t2.toDuration;
    assert(d2.get!"minutes" == 3 && d2.get!"seconds" == 30);
}

/// Reserved names for SI dimensions
enum SI : string
{
    length = "length", ///
    mass = "mass", ///
    time = "time", ///
    electricCurrent = "electricCurrent", ///
    temperature = "temperature", ///
    amountOfSubstance = "amountOfSubstance", ///
    luminousIntensity = "luminousIntensity" ///
}

/++
Predefined units corresponding to the seven SI base units
+/
RTQuantity!() meter;
alias metre = meter;
RTQuantity!() kilogram;
RTQuantity!() second;
RTQuantity!() ampere;
RTQuantity!() kelvin;
RTQuantity!() mole;
RTQuantity!() candela;

/++
Predefined unit corresponding to other common
units that are derived from them or compatible with them. The type of these
quantities is a built-in numeric type when they have no dimensions.
+/
RTQuantity!() radian;
RTQuantity!() steradian;
RTQuantity!() hertz;
RTQuantity!() newton;
RTQuantity!() pascal;
RTQuantity!() joule;
RTQuantity!() watt;
RTQuantity!() coulomb;
RTQuantity!() volt;
RTQuantity!() farad;
RTQuantity!() ohm;
RTQuantity!() siemens;
RTQuantity!() weber;
RTQuantity!() tesla;
RTQuantity!() henry;
RTQuantity!() lumen;
RTQuantity!() lux;
RTQuantity!() becquerel;
RTQuantity!() gray;
RTQuantity!() sievert;
RTQuantity!() katal;

RTQuantity!() gram;
RTQuantity!() minute;
RTQuantity!() hour;
RTQuantity!() day;
RTQuantity!() degreeOfAngle;
RTQuantity!() minuteOfAngle;
RTQuantity!() secondOfAngle;
RTQuantity!() hectare;
RTQuantity!() liter;
alias litre = liter;
RTQuantity!() ton;
RTQuantity!() electronVolt;
RTQuantity!() dalton;

shared static this()
{
    meter = unit(SI.length, "m");
    kilogram = unit(SI.mass, "kg");
    second = unit(SI.time, "s");
    ampere = unit(SI.electricCurrent, "A");
    kelvin = unit(SI.temperature, "K");
    mole = unit(SI.amountOfSubstance, "mol");
    candela = unit(SI.luminousIntensity, "cd");
    
    radian = meter / meter;
    steradian = square(meter) / square(meter);
    hertz = 1 / second;
    newton = meter / kilogram / square(second);
    pascal = newton / square(meter);
    joule = newton * meter;
    watt = joule / second;
    coulomb = second * ampere;
    volt = watt / ampere;
    farad = coulomb / volt;
    ohm = volt / ampere;
    siemens = ampere / volt;
    weber = volt * second;
    tesla = weber / square(meter);
    henry = weber / ampere;
    lumen = candela / steradian;
    lux = lumen / square(meter);
    becquerel = 1 / second;
    gray = joule / kilogram;
    sievert = joule / kilogram;
    katal = mole / second;
    
    gram = 1e-3 * kilogram;
    minute = 60 * second;
    hour = 60 * minute;
    day = 24 * hour;
    degreeOfAngle = PI / 180 * radian;
    minuteOfAngle = degreeOfAngle / 60;
    secondOfAngle = minuteOfAngle / 60;
    hectare = 1e4 * square(meter);
    liter = 1e-3 * cubic(meter);
    ton = 1e3 * kilogram;
    electronVolt = 1.60217653e-19 * joule;
    dalton = 1.66053886e-27 * kilogram;
}

/// Functions that apply a SI prefix to a unit.
auto yotta(T)(T unit) { return 1e24 * unit; } 
/// ditto
auto zetta(T)(T unit) { return 1e21 * unit; }
/// ditto
auto exa(T)(T unit) { return 1e18 * unit; }
/// ditto
auto peta(T)(T unit) { return 1e15 * unit; }
/// ditto
auto tera(T)(T unit) { return 1e12 * unit; }
/// ditto
auto giga(T)(T unit) { return 1e9 * unit; }
/// ditto
auto mega(T)(T unit) { return 1e6 * unit; }
/// ditto
auto kilo(T)(T unit) { return 1e3 * unit; }
/// ditto
auto hecto(T)(T unit) { return 1e2 * unit; }
/// ditto
auto deca(T)(T unit) { return 1e1 * unit; }
/// ditto
auto deci(T)(T unit) { return 1e-1 * unit; }
/// ditto
auto centi(T)(T unit) { return 1e-2 * unit; }
/// ditto
auto milli(T)(T unit) { return 1e-3 * unit; }
/// ditto
auto micro(T)(T unit) { return 1e-6 * unit; }
/// ditto
auto nano(T)(T unit) { return 1e-9 * unit; }
/// ditto
auto pico(T)(T unit) { return 1e-12 * unit; }
/// ditto
auto femto(T)(T unit) { return 1e-15 * unit; }
/// ditto
auto atto(T)(T unit) { return 1e-18 * unit; }
/// ditto
auto zepto(T)(T unit) { return 1e-21 * unit; }
/// ditto
auto yocto(T)(T unit) { return 1e-24 * unit; }
