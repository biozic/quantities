// Written in the D programming language
/++
This module defines the SI units and prefixes.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.si;

import quantities.base;
import std.math : PI;
import core.time : Duration, dur;

version (unittest)
{
    import std.math : approxEqual;
}

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
unittest // Durations
{
    auto d = 4.dur!"msecs";
    auto t = fromDuration(d);
    assert(t.value(milli(second)).approxEqual(4));
    
    auto t2 = 3.5 * minute;
    auto d2 = t2.toDuration;
    assert(d2.get!"minutes" == 3 && d2.get!"seconds" == 30);
}

/++
Predefined SI units.
+/
enum meter = unit!("m");
alias metre = meter; /// ditto
enum kilogram = unit!("kg"); /// ditto
enum second = unit!("s"); /// ditto
enum ampere = unit!("A"); /// ditto
enum kelvin = unit!("K"); /// ditto
enum mole = unit!("mol"); /// ditto
enum candela = unit!("cd"); /// ditto

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


/// Functions that apply a SI prefix to a unit.
auto yotta(Q)(Q base) { return base * 1e24; }
/// ditto
auto zetta(Q)(Q base) { return base * 1e21; }
/// ditto
auto exa(Q)(Q base) { return base * 1e18; }
/// ditto
auto peta(Q)(Q base) { return base * 1e15; }
/// ditto
auto tera(Q)(Q base) { return base * 1e12; }
/// ditto
auto giga(Q)(Q base) { return base * 1e9; }
/// ditto
auto mega(Q)(Q base) { return base * 1e6; }
/// ditto
auto kilo(Q)(Q base) { return base * 1e3; }
/// ditto
auto hecto(Q)(Q base) { return base * 1e2; }
/// ditto
auto deca(Q)(Q base) { return base * 1e1; }
/// ditto
auto deci(Q)(Q base) { return base * 1e-1; }
/// ditto
auto centi(Q)(Q base) { return base * 1e-2; }
/// ditto
auto milli(Q)(Q base) { return base * 1e-3; }
/// ditto
auto micro(Q)(Q base) { return base * 1e-6; }
/// ditto
auto nano(Q)(Q base) { return base * 1e-9; }
/// ditto
auto pico(Q)(Q base) { return base * 1e-12; }
/// ditto
auto femto(Q)(Q base) { return base * 1e-15; }
/// ditto
auto atto(Q)(Q base) { return base * 1e-18; }
/// ditto
auto zepto(Q)(Q base) { return base * 1e-21; }
/// ditto
auto yocto(Q)(Q base) { return base * 1e-24; }

/// Functions that apply a SI binary prefix to a unit.
auto yobi(Q)(Q base) { return base * (2.0^^10)^^8; }
/// ditto
auto zebi(Q)(Q base) { return base * (2.0^^10)^^7; }
/// ditto
auto exbi(Q)(Q base) { return base * (2.0^^10)^^6; }
/// ditto
auto pebi(Q)(Q base) { return base * (2.0^^10)^^5; }
/// ditto
auto tebi(Q)(Q base) { return base * (2.0^^10)^^4; }
/// ditto
auto gibi(Q)(Q base) { return base * (2.0^^10)^^3; }
/// ditto
auto mebi(Q)(Q base) { return base * (2.0^^10)^^2; }
/// ditto
auto kibi(Q)(Q base) { return base * (2.0^^10); }
