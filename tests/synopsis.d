// Written in the D programming language
/++
Test code and synospis code for the README.md file.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
import std.math : approxEqual;
import quantities.base;
import quantities.si;
import quantities.parsing;

unittest
{
    import quantities;

    import std.math : approxEqual;
    import std.stdio : writeln, writefln;

    // ------------------
    // Working with units
    // ------------------
    // Hint: work with units at compile-time

    // Define new units from the predefined ones (in module quantity.si)
    enum inch = 2.54 * centi(meter);
    enum mile = 1609 * meter;

    // Define new units with non-SI dimensions
    enum euro = unit!("€");
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

    // Use the predefined quantity types (in module quantity.si)
    MassicConcentration!double conc;
    Volume!double volume;
    Mass!double mass;

    // I have to make a new solution at the concentration of 2.5 g/l.
    conc = 2.5 * gram/liter;
    // The final volume is 10 ml.
    volume = 10 * milli(liter);
    // What mass should I weigh?
    mass = conc * volume;
    writefln("Weigh %f kg of substance", mass.value(kilogram)); 
    // prints: Weigh 0.000025 kg of substance
    // Wait! My scales graduations are 0.1 milligrams!
    writefln("Weigh %.1f mg of substance", mass.value(milli(gram)));
    // prints: Weigh 25.0 mg of substance
    // I knew the result would be 25 mg.
    assert(approxEqual(mass.value(milli(gram)), 25));

    auto wage = 65 * euro / hour;
    auto workTime = 1.6 * day;
    writefln("I've just earned %s!", wage * workTime);
    // prints: I've just earned 2496[€]!
    writefln("I've just earned $%.2f!", (wage * workTime).value(dollar));
    // prints: I've just earned $3369.60!

    // Type checking prevents incorrect assignments and operations
    static assert(!__traits(compiles, mass = 10 * milli(liter)));
    static assert(!__traits(compiles, conc = 1 * euro/volume));

    // -----------------------------
    // Parsing quantities at runtime
    // -----------------------------

    Mass!double m;
    Volume!double V;
    MassicConcentration!double c;

    m = parseQuantity("25 mg");
    V = parseQuantity("10 ml");
    c = parseQuantity("2.5 g⋅L⁻¹");
    assert(c.rawValue.approxEqual((m / V).rawValue));
    auto targetUnit = parseQuantity("kg/l");
    assert(c.value(targetUnit).approxEqual(0.0025));

    import std.exception;
    assertThrown!ParsingException(c = parseQuantity("10 qGz"));
    assertThrown!DimensionException(c = parseQuantity("2.5 mol⋅L⁻¹"));

    // User-defined symbols
    auto byte_ = unit!("B");
    SymbolList binSymbols;
    binSymbols.unitSymbols["B"] = byte_;
    binSymbols.prefixSymbols["Ki"] = 2^^10;
    binSymbols.prefixSymbols["Mi"] = 2^^20;
    // ...
    auto fileLength = parseQuantity("1.0 MiB", binSymbols);
    writefln("Length: %.0f bytes", fileLength.value(byte_));
    // prints: Length: 1048576 bytes
}
