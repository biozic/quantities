/++
This module only contains a template mixin that defines
SI units, prefixes and symbols.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.si.definitions;

/++
Generates the definitions of the SI units, prefixes and symbols.
+/
mixin template SIDefinitions(N)
{
    import quantities.compiletime.quantity : Quantity, unit, square, cubic;
    import quantities.runtime.qvariant : prefix;
    import quantities.runtime.parsing : SymbolList;
    import std.math : PI;
    import std.traits : isNumeric;

    static assert(isNumeric!N);

    /// The dimensionless unit 1.
    enum one = unit!(N, "");
    
    /// Base SI units.
    enum meter = unit!(N, "L");
    alias metre = meter; /// ditto
    enum kilogram = unit!(N, "M"); /// ditto
    enum second = unit!(N, "T"); /// ditto
    enum ampere = unit!(N, "I"); /// ditto
    enum kelvin = unit!(N, "Θ"); /// ditto
    enum mole = unit!(N, "N"); /// ditto
    enum candela = unit!(N, "J"); /// ditto

    /// Derived SI units
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

    /// Units compatible with the SI
    enum gram = 1e-3 * kilogram;
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
    // dfmt off
    enum siSymbolList = SymbolList!N()
        .addUnit("m", meter)
        .addUnit("kg", kilogram)
        .addUnit("s", second)
        .addUnit("A", ampere)
        .addUnit("K", kelvin)
        .addUnit("mol", mole)
        .addUnit("cd", candela)
        .addUnit("rad", radian)
        .addUnit("sr", steradian)
        .addUnit("Hz", hertz)
        .addUnit("N", newton)
        .addUnit("Pa", pascal)
        .addUnit("J", joule)
        .addUnit("W", watt)
        .addUnit("C", coulomb)
        .addUnit("V", volt)
        .addUnit("F", farad)
        .addUnit("Ω", ohm)
        .addUnit("S", siemens)
        .addUnit("Wb", weber)
        .addUnit("T", tesla)
        .addUnit("H", henry)
        .addUnit("lm", lumen)
        .addUnit("lx", lux)
        .addUnit("Bq", becquerel)
        .addUnit("Gy", gray)
        .addUnit("Sv", sievert)
        .addUnit("kat", katal)
        .addUnit("g", gram)
        .addUnit("min", minute)
        .addUnit("h", hour)
        .addUnit("d", day)
        .addUnit("l", liter)
        .addUnit("L", liter)
        .addUnit("t", ton)
        .addUnit("eV", electronVolt)
        .addUnit("Da", dalton)
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
        .addPrefix("y", 1e-24);
    // dfmt on
}
