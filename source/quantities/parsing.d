// Written in the D programming language
/++
This module defines functions to parse units and quantities.

Cannot be used at compile-time because of a limitation in VariantN.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.parsing;

import quantities.base, quantities.runtime.base, quantities.runtime.si;
import std.algorithm : any;
import std.array;
import std.conv;
import std.exception;
import std.range;
import std.string;
import std.traits;

version (Have_tested) import tested;
else private struct name { string dummy; }

class ParseException : Exception
{
    @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
    
    @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}

static RTQuantity!()[string] SIUnitSymbols;
static real[string] SIPrefixSymbols;

shared static this()
{
    SIUnitSymbols = [
        "m" : meter,
        "g" : gram,
        "s" : second,
        "A" : ampere,
        "K" : kelvin,
        "mol" : mole,
        "cd" : candela,
        "rad" : radian,
        "sr" : steradian,
        "Hz" : hertz,
        "N" : newton,
        "Pa" : pascal,
        "J" : joule,
        "W" : watt,
        "C" : coulomb,
        "V" : volt,
        "F" : farad,
        "Ω" : ohm,
        "S" : siemens,
        "Wb" : weber,
        "T" : tesla,
        "H" : henry,
        "lm" : lumen,
        "lx" : lux,
        "Bq" : becquerel,
        "Gy" : gray,
        "Sv" : sievert,
        "kat" : katal,
        "min" : minute,
        "h" : hour,
        "d" : day,
        "l" : liter,
        "L" : liter,
        "t" : ton,
        "eV" : electronVolt,
        "Da" : dalton,
    ];

    SIPrefixSymbols = [
        "Y" : 1e24,
        "Z" : 1e21,
        "E" : 1e18,
        "P" : 1e15,
        "T" : 1e12,
        "G" : 1e9,
        "M" : 1e6,
        "k" : 1e3,
        "h" : 1e2,
        "da": 1e1,
        "d" : 1e-1,
        "c" : 1e-2,
        "m" : 1e-3,
        "µ" : 1e-6,
        "n" : 1e-9,
        "p" : 1e-12,
        "f" : 1e-15,
        "a" : 1e-18,
        "z" : 1e-21,
        "y" : 1e-24
    ];
}

// Parses a string for a single unit (without prefix nor exponent).
RTQuantity!() rtParseUnit(string str, RTQuantity!()[string] possibleUnits = SIUnitSymbols)
{
    assert(str.length);
    return *enforceEx!ParseException(str in possibleUnits, "Unknown unit symbol: " ~ str);
}

@name("RT Parse SI base units")
unittest
{
    assert(rtParseUnit("m") == meter);
    assert(rtParseUnit("s") == second);
}

RTQuantity!() rtParsePrefixedUnit(string str, real[string] possiblePrefixes = SIPrefixSymbols)
{
    assert(str.length);

    // Special cases where a prefix starts like a unit
    if (str == "m")
        return meter;
    if (str == "cd")
        return candela;
    if (str == "mol")
        return mole;
    if (str == "Pa")
        return pascal;
    if (str == "T")
        return tesla;
    if (str == "Gy")
        return gray;
    if (str == "kat")
        return katal;
    if (str == "h")
        return hour;
    if (str == "d")
        return day;
    if (str == "min")
        return minute;

    string prefix = str.takeExactly(1).to!string;
    string unit = str.dropOne.to!string;

    auto factor = *enforceEx!ParseException(prefix in possiblePrefixes, "Unknown unit prefix: " ~ prefix);
    auto quantity = rtParseUnit(unit);
    return quantity * factor;
}

@name("RT Parse prefixed SI base units")
unittest
{
    assert(rtParsePrefixedUnit("cm") == centi(meter));
    assert(rtParsePrefixedUnit("µs") == micro(second));
    assert(rtParsePrefixedUnit("mm") == milli(meter));
}

