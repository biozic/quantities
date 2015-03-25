## About `quantities`

The purpose of this small library is to perform automatic compile-time or
runtime dimensional checking when dealing with quantities and units.

In order to remain simple, there is no actual distinction between units and
quantities, so there are no distinct quantity and unit types. All operations
are actually done on quantities. For example, `meter` is both the unit _meter_
and the quantity _1 m_. New quantities can be derived from other ones using
operators or dedicated functions.

Quantities can be parsed from strings at runtime and compile-time.

The main SI units and prefixes are predefined. Units with other dimensions can
be defined by the user.

Tested with DMD 2.065, 2.066.1   
Fails with DMD 2.066

Copyright 2013-2014, Nicolas Sicard.

License: Boost License 1.0.

### Synopsis

#### Working with predefined units

The package defines all the main SI units and prefixes, as well as aliases for their types.

```d
import quantities;
import std.math : approxEqual;
import std.stdio : writeln, writefln;

void main()
{
    auto distance = 384_400 * kilo(meter);
    auto speed = 299_792_458  * meter/second;
    
    Time time;
    time = distance / speed;
    writefln("Travel time of light from the moon: %s s", time.value(second));

    static assert(is(typeof(distance) == Length));
    static assert(is(Speed == Quantity!(double, ["L": 1, "T": -1])));
}
```

#### Dimensional correctness is check at compile-time

```d
Mass mass;
static assert(!__traits(compiles, mass = 15 * meter));
static assert(!__traits(compiles, mass = 1.2));
```

#### Calculations can be done at compile-time

```d
enum distance = 384_400 * kilo(meter);
enum speed = 299_792_458  * meter/second;
enum time = distance / speed;
writefln("Travel time of light from the moon: %s s", time.value(second));
```

#### Create a new unit from the predefined ones
```d
enum inch = 2.54 * centi(meter);
enum mile = 1609 * meter;
writefln("There are %s inches in a mile", mile.value(inch));
```

#### Create a new unit with new dimensions

```d
// Create a new base unit of currency
enum euro = unit!(double, "C"); // C is the chosen dimension symol (for currency...)

auto dollar = euro / 1.35;
auto price = 2000 * dollar;
writefln("This computer costs €%.2f", price.value(euro));
```

#### Parsing

At compile time:

```d
enum distance = si!"384_400 km";
enum speed = si!"299_792_458 m/s";
enum time = distance / speed;
writefln("Travel time of light from the moon: %s s", time.value(second));

static assert(is(typeof(distance) == Length));
static assert(is(typeof(speed) == Speed));
```

At runtime:

```d
auto data = [
    "distance-to-the-moon": "384_400 km",
    "speed-of-light": "299_792_458 m/s"
    ];
auto distance = parseSI!Length(data["distance-to-the-moon"]);
auto speed = parseSI!Speed(data["speed-of-light"]);
auto time = distance / speed;
writefln("Travel time of light from the moon: %s s", time.value(second));
```

#### Example: chemistry session

```d
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
```
