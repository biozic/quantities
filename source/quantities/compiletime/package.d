module quantities.compiletime;

public import quantities.compiletime.quantity;

///
unittest
{
    import quantities.compiletime;
    import quantities.si;
    
    // Introductory example
    {
        // Use the predefined quantity types (in module quantities.si)
        Volume volume;
        Concentration concentration;
        Mass mass;

        // Define a new quantity type
        alias MolarMass = typeof(kilogram/mole);

        // I have to make a new solution at the concentration of 5 mmol/L
        concentration = 5.0 * milli(mole)/liter;

        // The final volume is 100 ml.
        volume = 100.0 * milli(liter);

        // The molar mass of my compound is 118.9 g/mol
        MolarMass mm = 118.9 * gram/mole;

        // What mass should I weigh?
        mass = concentration * volume * mm;
        writefln("Weigh %s of substance", mass); 
        // prints: Weigh 5.945e-05 [M] of substance
        // Wait! That's not really useful!
        writefln("Weigh %s of substance", mass.siFormat!"%.1f mg");
        // prints: Weigh 59.5 mg of substance
    }

    // Working with predefined units
    {
        auto distance = 384_400 * kilo(meter);
        auto speed = 299_792_458  * meter/second;
        auto time = distance / speed;
        writefln("Travel time of light from the moon: %s", time.siFormat!"%.3f s");
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
        writefln("Travel time of light from the moon: %s", time.siFormat!"%.3f s");
    }

    // Create a new unit from the predefined ones
    {
        enum inch = 2.54 * centi(meter);
        enum mile = 1609 * meter;
        writefln("There are %s inches in a mile", mile.value(inch));
        // NB. Cannot use siFormat, because inches are not SI units
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
        writefln("Travel time of light from the moon: %s", time.siFormat!"%.3f s");

        static assert(is(typeof(distance) == Length));
        static assert(is(typeof(speed) == Speed));
    }

    // Run-time parsing
    {
        auto data = [
            "distance-to-the-moon": "384_400 km",
            "speed-of-light": "299_792_458 m/s"
        ];
        auto distance = parseSI!Length(data["distance-to-the-moon"]);
        auto speed = parseSI!Speed(data["speed-of-light"]);
        auto time = distance / speed;
        writefln("Travel time of light from the moon: %s", time.siFormat!"%.3f s");
    }
}

version (unittest)
{
    version (QuantitiesPrintTests)
        import std.stdio : writefln;
    else
        private void writefln(T...)(T args) {}
}
