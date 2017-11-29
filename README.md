## About _quantities_

[![Build Status](https://travis-ci.org/biozic/quantities.svg?branch=master)](https://travis-ci.org/biozic/quantities)

The purpose of this small library is to perform automatic compile-time or
runtime dimensional checking when dealing with quantities and units.

There is no actual distinction between units and quantities, so there are no
distinct quantity and unit types. All operations are actually done on
quantities. For example, `meter` is both the unit _meter_ and the quantity _1m_.
New quantities can be derived from other ones using operators or dedicated
functions.

Quantities can be parsed from strings at runtime and compile-time.

The main SI units and prefixes are predefined. Units with other dimensions can
be defined by the user.

Copyright 2013-2015, Nicolas Sicard.

License: Boost License 1.0.


### Design rationale (work in progress)

#### Principles

1. The library defines a `Quantity` type (a template) that represents a physical
quantity, or any user-defined type of quantity. A quantity can be seen as the
product of a scalar value and a vector of dimensions.

2. A `Quantity` is a wrapper struct around a numeric value, where the only
payload is this numeric value; no other data is stored. So the memory size of a
quantity is the same as its underlying numeric type. With optimizations on, the
compiler generates the same code as if normal numeric values were used.

  For the moment, only built-in numeric types are handled. But it should be
possible to make it work with any "number-like" type.

3. Two quantities with the same dimensions share the same type (assuming the
underlying numeric types are the same). Thus functions and types using
quantities generally won't have to be templated if the dimensions of the
quantities are known at compile time.


#### Impact on the design 

The main consequence of principle #3 is that all quantities sharing the same
dimensions are internally expressed in the same unit, which is the base unit for
this quantity. For instance, all lengths are stored as meters, which is the base
unit of length. The quantity _3km_ is stored as _3000m_, _2min_ is stored as
_120s_, etc. The drawback (possibly an important one) is that, when assigning a
new value to a quantity, the binary representation is preserved only if the
quantity is expressed in the base unit.

An indirect consequence is that there is no unit symbol associated with a
quantity. The only relevant symbol would have been the one of the base unit, but
it's rarely the best choice. But in practice, when formatting a quantity, the
unit is usually chosen in advance. If not, no simple algorithm is capable of
guessing the relevant unit. So I have decided that a quantity wouldn't format
itself correctly. Instead, for now, the `toString` function prints the value and
the dimensions vector. To print the units properly, the user can use the
provided format helpers, or use the result of the `value` method.


### Synopsis

#### Introductory example

```d
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
writefln("Weigh %s of substance", siFormat!"%.1f mg"(mass));
// prints: Weigh 59.5 mg of substance
```

#### Working with predefined units

The package defines all the main SI units and prefixes, as well as aliases for
their types.

```d
auto distance = 384_400 * kilo(meter);
auto speed = 299_792_458  * meter/second;
auto time = distance / speed;
writefln("Travel time of light from the moon: %s s", time.value(second));
}
```

#### Dimensional correctness is checked at compile-time

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
writefln("Travel time of light from the moon: %s", siFormat!"%.3f s"(time));
```

#### Create a new unit from the predefined ones
```d
    enum inch = 2.54 * centi(meter);
    enum mile = 1609 * meter;
    writefln("There are %s inches in a mile", mile.value(inch));
    // NB. Cannot use siFormat, because inches are not SI units
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
writefln("Travel time of light from the moon: %s", siFormat!"%.3f s"(time));

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
writefln("Travel time of light from the moon: %s", siFormat!"%.3f s"(time));
```
