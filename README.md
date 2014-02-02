## About `quantities`

The purpose of this small D package is to perform automatic compile-time or
runtime dimensional checking when dealing with quantities and units.

In order to remain simple, there is no actual distinction between units and
quantities, so there are no distinct quantity and unit types. All operations
are actually done on quantities. For example, `meter` is both the unit _meter_
and the quantity _1 m_. New quantities can be derived from other ones using
operators or dedicated functions.

Quantities can be parsed from strings at runtime and compile-time (with
limitations).

The main SI units and prefixes are predefined. Units with other dimensions can
be defined by the user.

Tested with DMD 2.065+

Copyright 2013-2014, Nicolas Sicard.

License: Boost License 1.0.

### Synopsis

```d
import quantities;

import std.math : approxEqual;
import std.stdio : writeln, writefln;

// ------------------
// Working with units
// ------------------

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
writeln(volt);   // prints: 1 m^2 kg s^-3 A^-1

// -----------------------
// Working with quantities
// -----------------------

// Use the predefined quantity types (in module quantity.si)
Volume volume;
Concentration concentration;
Mass mass;

// Define a new quantity type
alias MolarMass = QuantityType!(kilogram/mole);

// I have to make a new solution at the concentration of 25 mmol/L
concentration = 25 * milli(mole)/liter;

// The final volume is 100 ml.
volume = 100 * milli(liter);

// The molar mass of my compound is 118.9 g/mol
MolarMass mm = 118.9 * gram/mole;

// What mass should I weigh?
mass = concentration * volume * mm;
writefln("Weigh %s of substance", mass.toString); 
// prints: Weigh 0.00029725 kg of substance

// Wait! My scales graduations are in 1/10 milligrams!
writefln("Weigh %s of substance", mass.toString!"%.1f mg");
// prints: Weigh 297.3 mg of substance

// Extract the value of the quantity expressed in mg
auto val = mass.value(milli(gram)); 
assert(val.approxEqual(297.25));

// Type checking prevents incorrect assignments and operations
static assert(!__traits(compiles, mass = 10 * milli(liter)));
static assert(!__traits(compiles, concentration = 1 * euro/volume));

// ----------------------------------------
// Parsing quantities/units at compile-time
// ----------------------------------------

enum ctConcentration = si!"25 mmol⋅L⁻¹";
enum ctVolume = si!"100 mL";
enum ctMass = ctConcentration * ctVolume * si!"118.9 g/mol";
writefln("Weigh %s of substance", mass.toString!"%.1f mg");
// prints: Weigh 297.3 mg of substance

// -----------------------------------
// Parsing quantities/units at runtime
// -----------------------------------

mass = parseQuantity!Mass("297.3 mg");
volume = parseQuantity!Volume("100 ml");
mm = parseQuantity!MolarMass("118.9 g/mol");
concentration = parseQuantity!Concentration("2.5 mmol⋅l⁻¹");

import std.exception;
assertThrown!ParsingException(concentration = parseQuantity!Concentration("10 qGz"));
assertThrown!DimensionException(concentration = parseQuantity!Concentration("2.5 g⋅L⁻¹"));
```
