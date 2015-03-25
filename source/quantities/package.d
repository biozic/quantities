// Written in the D programming language
/++
The purpose  of this  package is  to perform  automatic compile-time or runtime
dimensional checking when dealing with quantities and units.

Synopsis:
---
import quantities;
import std.math : approxEqual;
import std.stdio : writeln, writefln;

// Working with predefined units
{
    auto distance = 384_400 * kilo(meter);
    auto speed = 299_792_458  * meter/second;
    
    Time time;
    time = distance / speed;
    writefln("Travel time of light from the moon: %s s", time.value(second));

    static assert(is(typeof(distance) == Length));
    static assert(is(Speed == Quantity!(double, ["L": 1, "T": -1])));
}

// Dimensional correctness is check at compile-time
{
    Mass mass;
    static assert(!__traits(compiles, mass = 15 * meter));
    static assert(!__traits(compiles, mass = 1.2));
}

// Calculations can be done at compile-time
{
    enum distance = 384_400 * kilo(meter);
    enum speed = 299_792_458  * meter/second;
    enum time = distance / speed;
    writefln("Travel time of light from the moon: %s s", time.value(second));
}

// Create a new unit from the predefined ones
{
    enum inch = 2.54 * centi(meter);
    enum mile = 1609 * meter;
    writefln("There are %s inches in a mile", mile.value(inch));
}

// Create a new unit with new dimensions
{
    // Create a new base unit of currency
    enum euro = unit!(double, "C"); // C is the chosen dimension symol (for currency...)

    auto dollar = euro / 1.35;
    auto price = 2000 * dollar;
    writefln("This computer costs €%.2f", price.value(euro));
}

// Compile-time parsing
{
    enum distance = si!"384_400 km";
    enum speed = si!"299_792_458 m/s";
    enum time = distance / speed;
    writefln("Travel time of light from the moon: %s s", time.value(second));

    static assert(is(typeof(distance) == Length));
    static assert(is(typeof(speed) == Speed));
}

// Runtime parsing
{
    auto data = [
        "distance-to-the-moon": "384_400 km",
        "speed-of-light": "299_792_458 m/s"
    ];
    auto distance = parseSI!Length(data["distance-to-the-moon"]);
    auto speed = parseSI!Speed(data["speed-of-light"]);
    auto time = distance / speed;
    writefln("Travel time of light from the moon: %s s", time.value(second));
}

// Chemistry session
{
    // Use the predefined quantity types (in module quantities.si)
    Volume volume;
    Concentration concentration;
    Mass mass;

    // Define a new quantity type
    alias MolarMass = typeof(kilogram/mole);

    // I have to make a new solution at the concentration of 25 mmol/L
    concentration = 25 * milli(mole)/liter;

    // The final volume is 100 ml.
    volume = 100 * milli(liter);

    // The molar mass of my compound is 118.9 g/mol
    MolarMass mm = 118.9 * gram/mole;

    // What mass should I weigh?
    mass = concentration * volume * mm;
    writefln("Weigh %s of substance", mass); 
    // prints: Weigh 0.00029725 [M] of substance
    // Wait! That's not really useful!
    // My scales graduations are in 1/10 milligrams!
    writefln("Weigh %.1f mg of substance", mass.value(milli(gram)));
    // prints: Weigh 297.3 mg of substance
}
---

Copyright: Copyright 2013-2015, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities;

public import quantities.base;
public import quantities.math;
public import quantities.si;
public import quantities.parsing;
