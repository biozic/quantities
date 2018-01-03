## About _quantities_

[![Build Status](https://travis-ci.org/biozic/quantities.svg?branch=master)](https://travis-ci.org/biozic/quantities)

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

Copyright 2013-2018, Nicolas Sicard.

License: Boost License 1.0.


### Design rationale

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

### Examples

#### Synopsis at compile time

```d
import quantities.compiletime;
import quantities.si;
import std.conv : text;

// Define a quantity from SI units
auto distance = 384_400 * kilo(meter);

// Define a quantity from a string
auto speed = si!"299_792_458 m/s";

// Calculations on quantitites (checked at compile time for consistency)
auto time = distance / speed;
static assert(!__traits(compiles, distance + speed));

// Format a quantity with a format specification containing a unit
assert(time.siFormat!"%.3f s".text == "1.282 s");
``` 

#### Synopsis at run time

```d
import quantities.runtime;
import quantities.si;
import std.exception : assertThrown;
import std.conv : text;

// Define a quantity from SI units
auto distance = 384_400 * kilo(meter);

// Define a quantity from a string
auto speed = parseSI("299_792_458 m/s");

// Calculations on quantitites (checked at compile time for consistency)
auto time = distance / speed;
assertThrown!DimensionException(distance + speed);

// Format a quantity with a format specification containing a unit
assert(siFormat("%.3f s", time).text == "1.282 s");
```

See more complete examples [at run
time](https://github.com/biozic/quantities/blob/master/source/quantities/compiletime/package.d#L13)
and [at compile
time](https://github.com/biozic/quantities/blob/master/source/quantities/runtime/package.d#L12).
