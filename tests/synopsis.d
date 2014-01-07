// Written in the D programming language
/++
Synospis code for the README.md file.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
import std.math : approxEqual;
import quantities.base;
import quantities.si;
import quantities.parsing;

version (Have_tested) import tested;
else private struct name { string dummy; }

@name("Synopsis")
unittest
{
    import std.stdio;

    // ------------------
    // Working with units
    // ------------------

    // Hint: work with units at compile-time

    // Define new units
    enum inch = 2.54 * centi(meter);
    enum mile = 1609 * meter;

    // Define new units with non-SI dimensions
    enum euro = unit!("currency", "€");
    enum dollar = euro / 1.35;

    // Default string representations
    writeln(meter);  // prints: 1 m
    writeln(inch);   // prints: 0.0254 m
    writeln(dollar); // prints: 0.740741 €
    writeln(volt);   // prints: 1 kg^-1 s^-3 m^2 A^-1 

    // -----------------------
    // Working with quantities
    // -----------------------

    // Hint: work with quantities at runtime

    // I have to make a new solution at the concentration of 2.5 g/l.
    auto conc = 2.5 * gram/liter;
    // The final volume is 10 ml.
    auto volume = 10 * milli(liter);
    // What mass should I weigh?
    auto mass = conc * volume;
    writefln("Weigh %f kg of substance", mass.value(kilogram)); 
    // prints: Weigh 0.000025 kg of substance
    // Wait! My scales graduations are 0.1 milligrams!
    writefln("Weigh %.1f mg of substance", mass.value(milli(gram)));
    // prints: Weigh 25.0 mg of substance
    // I knew the result would be 25 mg.
    assert(approxEqual(mass.value(milli(gram)), 25));

    // Optional: we could have defined new types to hold our quantities
    alias Mass = Store!kilogram; // Using a SI base unit.
    alias Volume = Store!liter; // Using a SI compatible unit.
    alias Concentration = Store!(kilogram/liter); // Using a derived unit.

    auto speedMPH = 30 * mile/hour;
    writefln("The speed limit is %s", speedMPH);
    // prints: The speed limit is 13.4083[s^-1 m]
    writefln("The speed limit is %.0f km/h", speedMPH.value(kilo(meter)/hour));
    // prints: The speed limit is 48 km/h
    writefln("The speed limit is %.0f in/s", speedMPH.value(inch/second));
    // prints: The speed limit is 528 in/s

    auto wage = 65 * euro / hour;
    auto workTime = 1.6 * day;
    writefln("I've just earned %s!", wage * workTime);
    // prints: I've just earned 2496[€]!
    writefln("I've just earned $ %.2f!", (wage * workTime).value(dollar));
    // prints: I've just earned $ 3369.60!

    // Type checking prevents incorrect assignments and operations
    static assert(!__traits(compiles, mass = 10 * milli(liter)));
    static assert(!__traits(compiles, conc = 1 * euro/volume));

    // -----------------------------
    // Parsing quantities at runtime
    // -----------------------------

    Mass m = parseQuantity("25 mg");
    Volume V = parseQuantity("10 ml");
    Concentration c = parseQuantity("2.5 g⋅L⁻¹");
    assert(c == m / V);
    Concentration target = parseQuantity("kg/l");
    assert(c.value(target) == 0.0025);

    import std.exception;
    assertThrown!DimensionException(m = parseQuantity("10 ml"));
    assertThrown!ParsingException(m = parseQuantity("10 qGz"));
}
