/++
The purpose of this small library is to perform automatic compile-time or
run-time dimensional checking when dealing with quantities and units.

There is no actual distinction between units and quantities, so there are no
distinct quantity and unit types. All operations are actually done on
quantities. For example, `meter` is both the unit _meter_ and the quantity _1m_.
New quantities can be derived from other ones using operators or dedicated
functions.

Quantities can be parsed from strings at run time and compile time.

The main SI units and prefixes are predefined. Units with other dimensions can
be defined by the user.

Copyright: Copyright 2013-2018, Nicolas Sicard.
License: Boost License 1.0.
+/
module quantities;

public import quantities.compiletime;
public import quantities.runtime;
public import quantities.si;

///
@("Synopsis at compile time")
unittest
{
    import quantities.compiletime;
    import quantities.si;
    import std.conv : text;

    // Define a quantity from SI units
    auto distance = 384_400 * kilo(meter);

    // Define a quantity from a string
    auto speed = si!"299_792_458 m/s";

    // Calculations on quantitites (checked at compile time for consistency)
    auto time = distance / speed;
    static assert(!__traits(compiles, distance + speed));

    // Format a quantity with a format specification containing a unit
    assert(time.siFormat!"%.3f s".text == "1.282 s");
}

///
@("Synopsis at run time")
unittest
{
    import quantities.runtime;
    import quantities.si;
    import std.exception : assertThrown;
    import std.conv : text;

    // Define a quantity from SI units
    auto distance = 384_400 * kilo(meter);

    // Define a quantity from a string
    auto speed = parseSI("299_792_458 m/s");

    // Calculations on quantitites (checked at compile time for consistency)
    auto time = distance / speed;
    assertThrown!DimensionException(distance + speed);

    // Format a quantity with a format specification containing a unit
    assert(siFormat("%.3f s", time).text == "1.282 s");
}
