/++
This module only contains the template mixins that define
SI units, prefixes and symbols for use at compile-time and/or
at run-time.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.internal.si;

/++
Generates SI units, prefixes and several utility functions
(parsing and formatting) usable at compile-time and/or at run-time.
+/
mixin template SIDefinitions(N)
{
    import quantities.common : prefix;
    import quantities.compiletime : Quantity, isQuantity, unit, square, cubic;
    import quantities.runtime : QVariant, isQVariantOrQuantity;
    import quantities.parsing : SymbolList, Parser;
    import std.conv : parse;
    import std.math : PI;
    import std.traits : isNumeric, isSomeString;

    static assert(isNumeric!N);

    /// The dimensionless unit 1.
    enum one = unit!(N, "", 0);

    /// Base SI units.
    enum meter = unit!(N, "L", 1);
    alias metre = meter; /// ditto
    enum kilogram = unit!(N, "M", 2); /// ditto
    enum second = unit!(N, "T", 3); /// ditto
    enum ampere = unit!(N, "I", 4); /// ditto
    enum kelvin = unit!(N, "Θ", 5); /// ditto
    enum mole = unit!(N, "N", 6); /// ditto
    enum candela = unit!(N, "J", 7); /// ditto

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

    /// Predefined quantity type templates for SI quantities
    alias Dimensionless = typeof(one);
    alias Length = typeof(meter);
    alias Mass = typeof(kilogram); /// ditto
    alias Time = typeof(second); /// ditto
    alias ElectricCurrent = typeof(ampere); /// ditto
    alias Temperature = typeof(kelvin); /// ditto
    alias AmountOfSubstance = typeof(mole); /// ditto
    alias LuminousIntensity = typeof(candela); /// ditto

    alias Area = typeof(square(meter)); /// ditto
    alias Surface = Area;
    alias Volume = typeof(cubic(meter)); /// ditto
    alias Speed = typeof(meter / second); /// ditto
    alias Acceleration = typeof(meter / square(second)); /// ditto
    alias MassDensity = typeof(kilogram / cubic(meter)); /// ditto
    alias CurrentDensity = typeof(ampere / square(meter)); /// ditto
    alias MagneticFieldStrength = typeof(ampere / meter); /// ditto
    alias Concentration = typeof(mole / cubic(meter)); /// ditto
    alias MolarConcentration = Concentration; /// ditto
    alias MassicConcentration = typeof(kilogram / cubic(meter)); /// ditto
    alias Luminance = typeof(candela / square(meter)); /// ditto
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

    /// A list of common SI symbols and prefixes
    static
    {
        SymbolList!N siSymbols;
        Parser!(N, (ref s) => parse!N(s)) siParser;
    }
    static this()
    {
        siSymbols = siSymbolList;
        siParser = typeof(siParser)(siSymbols);
    }

    /++
    Parses a statically-typed Quantity from a string at run time.

    Throws a DimensionException if the parsed quantity doesn't have the same
    dimensions as Q.

    Params:
        Q = the type of the returned quantity.
        str = the string to parse.
    +/
    Q parseSI(Q, S)(S str)
            if (isQuantity!Q && isSomeString!S)
    {
        return Q(siParser.parse(str));
    }
    ///
    unittest
    {
        alias Time = typeof(second);
        Time t = parseSI!Time("90 min");
        assert(t == 90 * minute);
        t = parseSI!Time("h");
        assert(t == 1 * hour);
    }

    /++
    Creates a Quantity from a string at compile-time.
    +/
    template si(string str)
    {
        enum ctSIParser = Parser!(N, (ref s) => parse!N(s))(siSymbolList);
        enum qty = ctSIParser.parse(str);
        enum si = Quantity!(N, qty.dimensions())(qty);
    }
    ///
    unittest
    {
        alias Time = typeof(second);
        enum t = si!"90 min";
        assert(is(typeof(t) == Time));
        assert(si!"h" == 60 * 60 * second);
    }

    /++
    Parses a string for a quantity at run time.

    Params:
        str = the string to parse.
    +/
    QVariant!N parseSI(S)(S str)
            if (isSomeString!S)
    {
        if (__ctfe)
        {
            import quantities.parsing : Parser;
            import std.conv : parse;

            auto ctSIParser = Parser!(N, (ref s) => parse!N(s))(siSymbolList);
            return ctSIParser.parse(str);
        }
        return siParser.parse(str);
    }
    ///
    unittest
    {
        auto t = parseSI("90 min");
        assert(t == 90 * minute);
        t = parseSI("h");
        assert(t == 1 * hour);

        auto v = parseSI("2");
        assert(v == (2 * meter) / meter);
    }

    /++
    A struct able to format a SI quantity.
    +/
    struct SIFormatter(S)
            if (isSomeString!S)
    {
        import std.range : ElementEncodingType;

        alias Char = ElementEncodingType!S;

        private
        {
            S fmt;
            QVariant!double unit;
        }

        /++
        Creates the formatter.

        Params:
        format = The format string. Must start with a format specification
              for the value of the quantity (a numeric type), that must be 
              followed by the symbol of a SI unit.
        +/
        this(S format)
        {
            import std.format : FormatSpec;
            import std.array : appender;

            fmt = format;
            auto spec = FormatSpec!Char(format);
            auto app = appender!S;
            spec.writeUpToNextSpec(app);
            unit = parseSI(spec.trailing);
        }

        void write(Writer, Q)(auto ref Writer writer, auto ref Q quantity) const 
                if (isQVariantOrQuantity!Q)
        {
            import std.format : formattedWrite;

            formattedWrite(writer, fmt, quantity.value(unit));
        }
    }

    /++
    Formats a SI quantity according to a format string known at run-time.

    Params:
        format = The format string. Must start with a format specification
              for the value of the quantity (a numeric type), that must be 
              followed by the symbol of a SI unit.
        quantity = The quantity that must be formatted.
    +/
    S siFormat(S, Q)(S format, Q quantity)
            if (isSomeString!S && isQVariantOrQuantity!Q)
    {
        import std.array : appender;

        auto formatter = SIFormatter!S(format);
        auto app = appender!S;
        formatter.write(app, quantity);
        return app.data;
    }
    ///
    unittest
    {
        QVariant!double speed = 12.5 * kilo(meter) / hour;
        assert("%.2f m/s".siFormat(speed) == "3.47 m/s");
    }

    /++
    Formats a SI quantity according to a format string known at compile-time.

    Params:
        format = The format string. Must start with a format specification
              for the value of the quantity (a numeric type), that must be 
              followed by the symbol of a SI unit.
        quantity = The quantity that must be formatted.
    +/
    auto siFormat(alias format, Q)(Q quantity)
            if (isSomeString!(typeof(format)) && isQVariantOrQuantity!Q)
    {
        return siFormat(format, quantity);
    }
    ///
    unittest
    {
        enum speed = 12.5 * kilo(meter) / hour;
        assert(siFormat!"%.2f m/s"(speed) == "3.47 m/s");
    }
}
