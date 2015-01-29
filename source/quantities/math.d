// Written in the D programming language
/++
This module defines common math operations on quantities.

Copyright: Copyright 2013-2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.math;

import quantities.base;
import std.math;
import std.traits;

/// Basic math functions that work with Quantities where N is a builtin floating point type.
auto square(Q)(Q quantity)
    if (isQuantity!Q)
{
    return quantity * quantity;
}

/// ditto
auto cubic(Q)(Q quantity)
    if (isQuantity!Q)
{
    return quantity * quantity * quantity;
}

/// ditto
auto sqrt(Q)(Q quantity)
    if (isQuantity!Q && isFloatingPoint!(Q.valueType))
{
    return Quantity!(Q.valueType, powinverse(Q.dimensions, 2)).make(std.math.sqrt(quantity.rawValue));
}

/// ditto
auto cbrt(Q)(Q quantity)
    if (isQuantity!Q && isFloatingPoint!(Q.valueType))
{
    return Quantity!(Q.valueType, powinverse(Q.dimensions, 3)).make(std.math.cbrt(quantity.rawValue));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
    if (isQuantity!Q && isFloatingPoint!(Q.valueType))
{
    return Quantity!(Q.valueType, powinverse(Q.dimensions, n)).make(std.math.pow(quantity.rawValue, 1.0 / n));
}

/// ditto
Q abs(Q)(Q quantity)
    if (isQuantity!Q && isFloatingPoint!(Q.valueType))
{
    return Q.make(std.math.fabs(quantity.rawValue));
}

///
auto pow(int n, Q)(Q quantity)
    if (isQuantity!Q && isFloatingPoint!(Q.valueType))
{
    return Quantity!(Q.valueType, pow(Q.dimensions, n)).make(std.math.pow(quantity.rawValue, n));
}

///
unittest
{
    enum meter = unit!(double, "L");
    enum liter = 0.001 * meter * meter * meter;

    auto surface = 25 * square(meter);
    auto side = sqrt(surface);
    assert(side.value(meter).approxEqual(5));

    auto volume = 27 * liter;
    side = cbrt(volume);
    assert(side.value(meter).approxEqual(0.3));

    auto delta = -10 * meter;
    assert(abs(delta) == 10 * meter);
}


/// Utility templates to manipulate quantity types.
template Inverse(Q)
    if (isQuantity!Q)
{
    alias Inverse = typeof(1 / Q.init);
}

/// ditto
template Product(Q1, Q2)
    if (isQuantity!Q1 && isQuantity!Q2)
{
    alias Product = typeof(Q1.init * Q2.init);
}

/// ditto
template Quotient(Q1, Q2)
    if (isQuantity!Q1 && isQuantity!Q2)
{
    alias Quotient = typeof(Q1.init / Q2.init);
}

/// ditto
template Square(Q)
    if (isQuantity!Q)
{
    alias Square = typeof(Q.init * Q.init);
}

/// ditto
template Cubic(Q)
    if (isQuantity!Q)
{
    alias Cubic = typeof(Q.init * Q.init * Q.init);
}

///
unittest
{
    import quantities.si;

    static assert(is(Inverse!Time == Frequency));
    static assert(is(Product!(Power, Time) == Energy));
    static assert(is(Quotient!(Length, Time) == Speed));
    static assert(is(Square!Length == Area));
    static assert(is(Cubic!Length == Volume));
    static assert(AreConsistent!(Product!(Inverse!Time, Length), Speed));
}
