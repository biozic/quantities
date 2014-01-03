// Written in the D programming language
/++
This module defines functions to parse units and quantities.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.parsing;

import quantities.base, quantities.si;
import std.conv : parse;
import std.string : squeeze;
import std.traits : isSomeString;
import std.variant : VariantN;

version (Have_tested) import tested;
else struct name { string dummy; }

alias VariantQ = VariantN!(real.sizeof);

/++
Parses a string for a unit.
+/
VariantQ parseUnit(S)(S str)
    if (isSomeString!S)
{
    VariantQ unit;
    unit = meter;
    return unit;
}

@name("Parse at compile time")
unittest
{
    // FIXME: VariantN cannot be used at compile-time because it uses memcpy
    // static assert(parseUnit("m") == meter);
}

@name("SI base units")
unittest
{
    assert(parseUnit("m") == meter);
    assert(parseUnit("s") == second);
}