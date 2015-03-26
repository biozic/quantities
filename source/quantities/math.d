/++
This module defines common math operations on quantities.

Copyright: Copyright 2013-2015, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.math;

import quantities.base;
import quantities.qvariant;

import std.math;
import std.traits;

alias dimpow = quantities.base.pow;

/// Basic math functions that work with Quantity and QVariant.
auto square(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, dimpow(Q.dimensions, 2)).make(quantity.rawValue ^^ 2);
}

/// ditto
auto square(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(quantity.rawValue ^^ 2, dimpow(quantity.dimensions, 2));
}

/// ditto
auto sqrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, powinverse(Q.dimensions, 2)).make(std.math.sqrt(quantity.rawValue));
}

/// ditto
auto sqrt(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(std.math.sqrt(quantity.rawValue), powinverse(quantity.dimensions, 2));
}

unittest
{
    enum meter = unit!(double, "L");
    enum surface = 25 * square(meter);
    enum side = sqrt(surface);
    static assert(side.value(meter).approxEqual(5));
}

unittest
{
    enum meter = unit!(double, "L").qVariant;
    enum surface = 25 * square(meter);
    enum side = sqrt(surface);
    static assert(side.value(meter).approxEqual(5));
}

/// ditto
auto cubic(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, dimpow(Q.dimensions, 3)).make(quantity.rawValue ^^ 3);
}

/// ditto
auto cubic(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(quantity.rawValue ^^ 3, dimpow(quantity.dimensions, 3));
}

/// ditto
auto cbrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, powinverse(Q.dimensions, 3)).make(std.math.cbrt(quantity.rawValue));
}

/// ditto
auto cbrt(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(std.math.cbrt(quantity.rawValue), powinverse(quantity.dimensions, 3));
}

unittest
{
    enum meter = unit!(double, "L");
    enum vol = 27 * cubic(meter);
    auto side = cbrt(vol); // Doesn't work with CTFE
    assert(side.value(meter).approxEqual(3));
}

unittest
{
    enum meter = unit!(double, "L").qVariant;
    enum vol = 27 * cubic(meter);
    auto side = cbrt(vol); // Doesn't work with CTFE
    assert(side.value(meter).approxEqual(3));
}

/// ditto
auto pow(int n, Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, dimpow(Q.dimensions, n)).make(std.math.pow(quantity.rawValue, n));
}

// ditto
auto pow(int n, Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(std.math.pow(quantity.rawValue, n), dimpow(quantity.dimensions, n));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, powinverse(Q.dimensions, n)).make(std.math.pow(quantity.rawValue, 1.0 / n));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(std.math.pow(quantity.rawValue, 1.0 / n), powinverse(quantity.dimensions, n));
}

unittest
{
    enum meter = unit!(double, "L");
    enum x = 16 * pow!4(meter);
    auto side = nthRoot!4(x);  // Doesn't work with CTFE
    assert(side.value(meter).approxEqual(2));
}

unittest
{
    enum meter = unit!(double, "L").qVariant;
    enum x = 16 * pow!4(meter);
    auto side = nthRoot!4(x); // Doesn't work with CTFE
    assert(side.value(meter).approxEqual(2));
}

/// ditto
Q abs(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Q.make(std.math.fabs(quantity.rawValue));
}

// ditto
Q abs(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(std.math.fabs(quantity.rawValue), quantity.dimensions);
}

unittest
{
    enum meter = unit!(double, "L");
    enum mlength = -12 * meter;
    enum length = abs(mlength);
    static assert(length.value(meter).approxEqual(12));
}

unittest
{
    enum meter = unit!(double, "L").qVariant;
    enum mlength = -12 * meter;
    enum length = abs(mlength);
    static assert(length.value(meter).approxEqual(12));
}

/// Utility templates to manipulate Quantity types.
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
