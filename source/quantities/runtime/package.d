module quantities.runtime;

public import quantities.runtime.qvariant;
public import quantities.runtime.parsing;

///
unittest
{
    import quantities.runtime;
    import quantities.si;

    // Note: the types of the predefined SI units (gram, mole, liter...)
    // are Quantity instances, not QVariant instance.

    // Introductory example
    {
        // I have to make a new solution at the concentration of 5 mmol/L
        QVariant!double concentration = 5.0 * milli(mole)/liter;

        // The final volume is 100 ml.
        QVariant!double volume = 100.0 * milli(liter);

        // The molar mass of my compound is 118.9 g/mol
        QVariant!double molarMass = 118.9 * gram/mole;

        // What mass should I weigh?
        QVariant!double mass = concentration * volume * molarMass;
        writefln("Weigh %s of substance", mass); 
        // prints: Weigh 5.945e-05 [M] of substance
        // Wait! That's not really useful!
        writefln("Weigh %s of substance", siFormat("%.1f mg", mass));
        // prints: Weigh 59.5 mg of substance
    }

    // Working with predefined units
    {
        QVariant!double distance = 384_400 * kilo(meter);
        QVariant!double speed = 299_792_458  * meter/second;
        QVariant!double time = distance / speed;
        writefln("Travel time of light from the moon: %s", siFormat("%.3f s", time));
    }

    // Dimensional correctness
    {
        import std.exception : assertThrown;
        QVariant!double mass = 4 * kilogram;
        assertThrown!DimensionException(mass + meter);
        assertThrown!DimensionException(mass == 1.2);
    }

    // Create a new unit from the predefined ones
    {
        QVariant!double inch = 2.54 * centi(meter);
        QVariant!double mile = 1609 * meter;
        writefln("There are %s inches in a mile", mile.value(inch));
        // NB. Cannot use siFormat, because inches are not SI units
    }

    // Create a new unit with new dimensions
    {
        // Create a new base unit of currency
        QVariant!double euro = unit!double("C"); // C is the chosen dimension symol (for currency...)

        QVariant!double dollar = euro / 1.35;
        QVariant!double price = 2000 * dollar;
        writefln("This computer costs €%.2f", price.value(euro));
    }

    // Run-time parsing
    {
        auto data = [
            "distance-to-the-moon": "384_400 km",
            "speed-of-light": "299_792_458 m/s"
        ];
        QVariant!double distance = parseSI(data["distance-to-the-moon"]);
        QVariant!double speed = parseSI(data["speed-of-light"]);
        QVariant!double time = distance / speed;
        writefln("Travel time of light from the moon: %s", siFormat("%.3f s", time));
    }
}

version (unittest)
{
    version (QuantitiesPrintTests)
        import std.stdio : writefln;
    else
        private void writefln(T...)(T args) {}
}
