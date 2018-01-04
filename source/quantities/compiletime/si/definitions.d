/++
This module only contains a template mixin used to generate
SI units, prefixes and utility functions usable at compile time.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.compiletime.si.definitions;

/++
Generates SI units, prefixes and several utility functions
(parsing and formatting) usable at compile time.
+/
mixin template CompiletimeSI(N)
{
    enum siSymbols = siSymbolList;

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

    import std.traits : isSomeString;

    /++
    Parses a string for a quantity of type Q at run time.

    Params:
        Q = the type of the returned quantity.
        str = the string to parse.
    +/
    Q parseSI(Q, S)(S str)
            if (isSomeString!S)
    {
        import quantities.runtime.parsing : Parser;
        import std.conv : parse;

        enum siParser = Parser!(N, (ref S s) => parse!N(s))(siSymbols);
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
        import quantities.runtime.qvariant;
        import quantities.runtime.parsing : Parser;
        import std.conv : parse;

        enum siParser = Parser!(N, (ref string s) => parse!N(s))(siSymbols);
        enum qty = siParser.parse(str);
        enum spec = QVariant!N(1, qty.dimensions);
        enum si = Quantity!(N, spec)(qty);
    }
    ///
    unittest
    {
        alias Time = typeof(second);
        enum t = si!"90 min";
        static assert(is(typeof(t) == Time));
        static assert(si!"h" == 60 * 60 * second);
    }

    /++
    Formats a SI quantity according to a format string known at compile time.
    Params:
        fmt = The format string. Must start with a format specification
                for the value of the quantity (a numeric type), that must be 
                followed by the symbol of a SI unit.
        quantity = The quantity that must be formatted.
    +/
    auto siFormat(string fmt, Q)(Q quantity)
    {
        return SIFormatter!(fmt, Q)(quantity);
    }
    ///
    unittest
    {
        import std.conv : text;

        enum speed = 12.5 * kilo(meter) / hour;
        assert(siFormat!"%.2f m/s"(speed).text == "3.47 m/s");
    }

    /// ditto
    struct SIFormatter(string fmt, Q)
    {
        private Q quantity;

        enum unit = {
            import std.format : FormatSpec;
            import std.array : Appender;

            auto spec = FormatSpec!char(fmt);
            auto app = Appender!string();
            spec.writeUpToNextSpec(app);
            return parseSI!Q(spec.trailing);
        }();

        /++
        Create a formatter struct.

        Params:
            format = The format string. Must start with a format specification
                for the value of the quantity (a numeric type), that must be 
                followed by the symbol of a SI unit.
            quantity = The quantity that must be formatted.
        +/
        this(Q quantity)
        {
            this.quantity = quantity;
        }

        ///
        void toString(scope void delegate(const(char)[]) sink) const
        {
            import std.format : formattedWrite;

            sink.formattedWrite!fmt(quantity.value(unit));
        }
    }
}
