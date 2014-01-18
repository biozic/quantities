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
Predefined SI units
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

///
static struct SI {
template Length(T) { alias Length = Store!(meter, T); } /// Predefined quantity type templates for SI quantities
template Mass(T) { alias Mass = Store!(kilogram, T); } /// ditto
template Time(T) { alias Time = Store!(second, T); } /// ditto
template ElectricCurrent(T) { alias ElectricCurrent = Store!(ampere, T); } /// ditto
template Temperature(T) { alias Temperature = Store!(kelvin, T); } /// ditto
template AmountOfSubstance(T) { alias AmountOfSubstance = Store!(mole, T); } /// ditto
template LuminousIntensity(T) { alias LuminousIntensity = Store!(candela, T); } /// ditto

template Area(T) { alias Area = Store!(square(meter), T); } /// ditto
template Volume(T) { alias Volume = Store!(cubic(meter), T); } /// ditto
template Speed(T) { alias Speed = Store!(meter/second, T); } /// ditto
template Acceleration(T) { alias Acceleration = Store!(meter/square(second), T); } /// ditto
template MassDensity(T) { alias MassDensity = Store!(kilogram/cubic(meter), T); } /// ditto
template CurrentDensity(T) { alias CurrentDensity = Store!(ampere/square(meter), T); } /// ditto
template MagneticFieldStrength(T) { alias MagneticFieldStrength = Store!(ampere/meter, T); } /// ditto
template Concentration(T) { alias Concentration = Store!(mole/cubic(meter), T); } /// ditto
template MolarConcentration(T) { alias MolarConcentration = Concentration!T; } /// ditto
template MassicConcentration(T) { alias MassicConcentration = Store!(kilogram/cubic(meter)); } /// ditto
template Luminance(T) { alias Luminance = Store!(candela/square(meter), T); } /// ditto
template RefractiveIndex(T) { alias RefractiveIndex = Store!(kilogram, T); } /// ditto

template Angle(T) { alias Angle = Store!(radian, T); } /// ditto
template SolidAngle(T) { alias SolidAngle = Store!(steradian, T); } /// ditto
template Frequency(T) { alias Frequency = Store!(hertz, T); } /// ditto
template Force(T) { alias Force = Store!(newton, T); } /// ditto
template Pressure(T) { alias Pressure = Store!(pascal, T); } /// ditto
template Energy(T) { alias Energy = Store!(joule, T); } /// ditto
template Work(T) { alias Work = Energy!T; } /// ditto
template Heat(T) { alias Heat = Energy!T; } /// ditto
template Power(T) { alias Power = Store!(watt, T); } /// ditto
template ElectricCharge(T) { alias ElectricCharge = Store!(coulomb, T); } /// ditto
template ElectricPotential(T) { alias ElectricPotential = Store!(volt, T); } /// ditto
template Capacitance(T) { alias Capacitance = Store!(farad, T); } /// ditto
template ElectricResistance(T) { alias ElectricResistance = Store!(ohm, T); } /// ditto
template ElectricConductance(T) { alias ElectricConductance = Store!(siemens, T); } /// ditto
template MagneticFlux(T) { alias MagneticFlux = Store!(weber, T); } /// ditto
template MagneticFluxDensity(T) { alias MagneticFluxDensity = Store!(tesla, T); } /// ditto
template Inductance(T) { alias Inductance = Store!(henry, T); } /// ditto
template LuminousFlux(T) { alias LuminousFlux = Store!(lumen, T); } /// ditto
template Illuminance(T) { alias Illuminance = Store!(lux, T); } /// ditto
template CelsiusTemperature(T) { alias CelsiusTemperature = Store!(celsius, T); } /// ditto
template Radioactivity(T) { alias Radioactivity = Store!(becquerel, T); } /// ditto
template AbsorbedDose(T) { alias AbsorbedDose = Store!(gray, T); } /// ditto
template DoseEquivalent(T) { alias DoseEquivalent = Store!(sievert, T); } /// ditto
template CatalyticActivity(T) { alias CatalyticActivity = Store!(katal, T); } /// ditto
}

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
