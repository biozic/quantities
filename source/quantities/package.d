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
public import quantities.common;
public import quantities.parsing;
public import quantities.si;

/// Synopsis at compile-time
@("Synopsis at compile-time")
unittest
{
    import quantities.compiletime;
    import quantities.si;

    // Define a quantity from SI units
    auto distance = 384_400 * kilo(meter);

    // Define a quantity from a string
    auto speed = si!"299_792_458 m/s";
    // Define a type for a quantity
    alias Speed = typeof(speed);

    // Calculations on quantities
    auto calculateTime(Length d, Speed s)
    {
        return d / s;
    }
    Time time = calculateTime(distance, speed);

    // Dimensions are checked at compile time for consistency
    assert(!__traits(compiles, distance + speed));

    // Format a quantity with a format specification known at compile-time
    assert(siFormat!"%.3f s"(time) == "1.282 s");
}

/// Synopsis at run-time
@("Synopsis at run-time")
unittest
{
    import quantities.runtime;
    import quantities.si;
    import std.exception : assertThrown;

    // Define a quantity from SI units (using the helper function `qVariant`)
    auto distance = qVariant(384_400 * kilo(meter));

    // Define a quantity from a string
    auto speed = parseSI("299_792_458 m/s");

    // Calculations on quantities (checked at compile time for consistency)
    QVariant!double calculateTime(QVariant!double d, QVariant!double s)
    {
        return d / s;
    }
    auto time = calculateTime(distance, speed);

    // Dimensions are checked at run time for consistency
    assertThrown!DimensionException(distance + speed);

    // Format a quantity with a format specification known at run-time
    assert(siFormat("%.3f s", time) == "1.282 s");
}
