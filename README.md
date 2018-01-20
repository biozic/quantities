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
be defined by the user. With a bit of work, a whole system of new units could be
defined to use for calculations and parsing.

Copyright 2013-2018, Nicolas Sicard.

License: Boost License 1.0.

### Online documentation

Check online documentation [here](https://biozic.github.io/quantities/quantities.html).

### Design rationale

#### Quantities at compile time

1. The library defines a `Quantity` type (a template) that represents a physical
   quantity, or any user-defined type of quantity. A quantity can be seen as the
   product of a scalar value and a vector of dimensions. The vector of
   dimensions is known at compile time and is part of the type.

2. A `Quantity` is a wrapper struct around a numeric value, where the only
   payload is this numeric value; no other data is stored. So the memory size of
   a quantity is the same as its underlying numeric type. With optimizations on,
   the compiler generates the same code as if normal numeric values were used.

    For the moment, only built-in numeric types are handled. But it should be
possible to make it work with any "number-like" type.

3. Two quantities with the same dimensions share the same type (assuming the
   underlying numeric types are the same). Thus functions and types using
   quantities generally won't have to be templated if the dimensions of the
   quantities are known at compile time.

4. All operations on `Quantity` values are statically checked for dimensional
   consistency. If a constuction, an assignment, a calculation (using overloaded
   operators or special functions) or parsing from string at compile-time is not
   dimensionnaly consistent, there's a compilation error. Most notably,
   calculations involving plain built-in numeric types (`double`, `int`, etc.)
   only work with quantities with no dimensions.

    Some operations (construction, assignment, `value` function, parsing from a
   run-time string) can use a `QVariant` argument. In this case, the checks are
   done at run-time.

#### Quantities at run time

1. Since it is not always possible, nor sometimes desirable, to know the
   dimensions of quantities at compile time, the library defines a `QVariant`
   type, for which the vector of dimensions is not part of the type, but stored
   as a member along the numeric value.

2. Calculations *and* dimensionnal checks are done at run time. Both `QVariant`
   and `Quantity` can be used in the same expressions to a certain extent.

3. All quantities stored as `QVariant` share the same type, event if the
   dimensions of the quantities are different.

4. Only calculations that break dimensional consitencies are checked an throw a
   `DimensionException`. A `QVariant` can be reassigned a new quantity with
   other dimensions.


#### Consequences of the design 

1. The main consequence of principles #3 is that all quantities sharing the same
   dimensions are internally expressed in the same unit, which is the base unit
   for this quantity. For instance, all lengths are stored as meters, which is
   the base unit of length. The quantity _3&nbsp;km_ is stored as _3000&nbsp;m_,
   _2&nbsp;min_ is stored as _120&nbsp;s_, etc.

    The drawback (possibly an important one) is that, when assigning a
new value to a quantity, the binary representation is preserved only if the
quantity is expressed in the base unit.

2. An indirect consequence is that there is no unit symbol stored with a
   quantity. The only relevant symbol would have been the one of the base unit,
   but it's rarely the best choice.

    But in practice, when formatting a quantity, the unit is usually chosen in
advance. If not, no simple algorithm is capable of guessing the relevant unit.
So I have decided that a quantity wouldn't format itself correctly. Instead, for
now, the `toString` function prints the value and the dimensions vector.

    To print the units properly, the user can use the `siFormat` functions
(obviously, they work only for SI units at the moment), or use the result of the
`value` method.

### Examples

#### Synopsis at compile-time

```d
import quantities.compiletime;
import quantities.si;

// Define a quantity from SI units
auto distance = 384_400 * kilo(meter);

// Define a quantity from a string
auto speed = si!"299_792_458 m/s";
// Define a type for a quantity
alias Speed = typeof(speed);

// Calculations on quantities
auto calculateTime(Length d, Speed s)
{
    return d / s;
}
Time time = calculateTime(distance, speed);

// Dimensions are checked at compile time for consistency
static assert(!__traits(compiles, distance + speed));

// Format a quantity with a format specification known at compile-time
assert(siFormat!"%.3f s"(time) == "1.282 s");
``` 

#### Synopsis at run-time

```d
import quantities.runtime;
import quantities.si;
import std.exception : assertThrown;

// Define a quantity from SI units (using the helper function `qVariant`)
auto distance = qVariant(384_400 * kilo(meter));

// Define a quantity from a string
auto speed = parseSI("299_792_458 m/s");

// Calculations on quantities (checked at compile time for consistency)
QVariant!double calculateTime(QVariant!double d, QVariant!double s)
{
    return d / s;
}
auto time = calculateTime(distance, speed);

// Dimensions are checked at run time for consistency
assertThrown!DimensionException(distance + speed);

// Format a quantity with a format specification known at run-time
assert(siFormat("%.3f s", time) == "1.282 s");
```

See more complete examples [at run
time](https://biozic.github.io/quantities/quantities/runtime.html)
and [at compile
time](https://biozic.github.io/quantities/quantities/compiletime.html).
