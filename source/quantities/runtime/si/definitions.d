/++
This module only contains a template mixin used to generate
SI units, prefixes and utility functions usable at run time.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.runtime.si.definitions;

/++
Generates SI units, prefixes and several utility functions
(parsing and formatting) usable at run time.
+/
mixin template RuntimeSI(N)
{
    import std.traits : isSomeString;

    /// A list of common SI symbols and prefixes
    static __gshared SymbolList!N siSymbols;
    shared static this()
    {
        siSymbols = siSymbolList;
    }

    import quantities.runtime.qvariant;
    import std.traits : isSomeString;

    /++
    Parses a string for a quantity of type Q at run time.

    Throws a DimensionException.

    Params:
        str = the string to parse.
    +/
    QVariant!N parseSI(S)(S str)
            if (isSomeString!S)
    {
        import quantities.runtime.parsing : Parser;
        import std.conv : parse;

        static Parser!(N, (ref S s) => parse!N(s)) siParser;
        static bool initialized = false;
        if (!initialized)
            siParser.symbolList = siSymbols;
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
    Format a SI quantity according to a format string known at run time.

    Params:
        format = The format string. Must start with a format specification
              for the value of the quantity (a numeric type), that must be 
              followed by the symbol of a SI unit.
        quantity = The quantity that must be formatted.
    +/
    SIFormatter siFormat(string format, QVariant!N quantity)
    {
        return SIFormatter(format, quantity);
    }
    ///
    unittest
    {
        import std.conv : text;

        QVariant!double speed = 12.5 * kilo(meter) / hour;
        assert(siFormat("%.2f m/s", speed).text == "3.47 m/s");
    }

    /// ditto
    struct SIFormatter
    {
        private
        {
            string fmt;
            QVariant!N unit;
            QVariant!N quantity;
        }

        /++
        Create a formatter struct.

        Params:
            format = The format string. Must start with a format specification
                for the value of the quantity (a numeric type), that must be 
                followed by the symbol of a SI unit.
            quantity = The quantity that must be formatted.
        +/
        this(string format, QVariant!N quantity)
        {
            import std.format : FormatSpec;
            import std.array : Appender;

            fmt = format;
            auto spec = FormatSpec!char(format);
            auto app = Appender!string();
            spec.writeUpToNextSpec(app);
            unit = parseSI(spec.trailing);
            this.quantity = quantity;
        }

        ///
        void toString(scope void delegate(const(char)[]) sink) const
        {
            import std.format : formattedWrite;

            sink.formattedWrite(fmt, quantity.value(unit));
        }
    }
}
