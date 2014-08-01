import quantities;
import std.math : approxEqual;
import std.stdio : writeln, writefln;

// Working with predefined units
unittest
{
    auto distance = 384_400 * kilo(meter);
    auto speed = 299_792_458  * meter/second;
    auto time = distance / speed;
    writefln("Travel time of light from the moon: %s s", time.value(second));
}

// Dimensional correctness is check at compile-time
unittest
{
    Mass mass;
    static assert(!__traits(compiles, mass = 15 * meter));
    static assert(!__traits(compiles, mass = 1.2));
}

// Calculations can be done at compile-time
unittest
{
    enum distance = 384_400 * kilo(meter);
    enum speed = 299_792_458  * meter/second;
    enum time = distance / speed;
    writefln("Travel time of light from the moon: %s s", time.value(second));
}

// Type of quantity variables
unittest
{
    // Length is defined as a quantity of dimension L storing a real value
    static assert(is(Length == Quantity!(double, "L", 1)));

    // Time is defined as a quantity of dimension T
    static assert(is(Time == Quantity!(double, "T", 1)));

    // Speed is defined as a quantity of dimension L T⁻¹
    static assert(is(Speed == Quantity!(double, "L", 1, "T", -1)));

    // Quantities that share the same dimensions are of the same type
    static assert(is(typeof(meter) == Length));
    static assert(is(typeof(second) == Time));
    static assert(is(typeof(hour) == Time));
    static assert(is(typeof(kilo(meter)/hour) == Speed));
}

// Create a new unit from the predefined ones
unittest
{
    enum inch = 2.54 * centi(meter);
    enum mile = 1609 * meter;
    writefln("There are %s inches in a mile", mile.value(inch));
}

// Create a new unit with new dimensions
unittest
{
    // Create a new base unit of currency
    enum euro = unit!("C"); // C is the chosen dimension symol (for currency...)

    auto dollar = euro / 1.35;
    auto price = 2000 * dollar;
    writefln("This computer costs €%.2f", price.value(euro));
}

// Compile-time parsing
unittest
{
    enum distance = si!"384_400 km";
    enum speed = si!"299_792_458 m/s";
    enum time = distance / speed;
    writefln("Travel time of light from the moon: %s s", time.value(second));

    static assert(is(typeof(distance) == Length));
    static assert(is(typeof(speed) == Speed));
}

// Runtime parsing
unittest
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
unittest
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
    writefln("Weigh %s of substance", mass.toString); 
    // prints: Weigh 0.00029725 [M] of substance
    // Wait! That's not really useful!
    // My scales graduations are in 1/10 milligrams!
    writefln("Weigh %.1f mg of substance", mass.value(milli(gram)));
    // prints: Weigh 297.3 mg of substance
}
