/++
This module defines common math operations on quantities.

Copyright: Copyright 2013-2015, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.math;

import quantities.internal.dimensions;
import quantities.base;
import quantities.qvariant;

import std.math;
import std.traits;

/// Basic math functions that work with Quantity and QVariant.
auto square(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.pow(2)).make(quantity.rawValue ^^ 2);
}

/// ditto
auto square(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(quantity.rawValue ^^ 2, quantity.dimensions.pow(2));
}

/// ditto
auto sqrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.powinverse(2)).make(std.math.sqrt(quantity.rawValue));
}

/// ditto
auto sqrt(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(std.math.sqrt(quantity.rawValue), quantity.dimensions.powinverse(2));
}

unittest
{
    auto meter = unit!(double, "L");
    auto surface = 25 * square(meter);
    auto side = sqrt(surface);
    assert(side.value(meter).approxEqual(5));
}

unittest
{
    import std.stdio;
    auto meter = unit!(double, "L");
    auto sqrtm = sqrt(meter);
    assert(square(5 * sqrtm) == 25 * meter);
}

unittest
{
    auto meter = unit!(double, "L").qVariant;
    auto surface = 25 * square(meter);
    auto side = sqrt(surface);
    assert(side.value(meter).approxEqual(5));
}

/// ditto
auto cubic(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.pow(3)).make(quantity.rawValue ^^ 3);
}

/// ditto
auto cubic(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(quantity.rawValue ^^ 3, quantity.dimensions.pow(3));
}

/// ditto
auto cbrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.powinverse(3)).make(std.math.cbrt(quantity.rawValue));
}

/// ditto
auto cbrt(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(std.math.cbrt(quantity.rawValue), quantity.dimensions.powinverse(3));
}

unittest
{
    auto meter = unit!(double, "L");
    auto vol = 27 * cubic(meter);
    auto side = cbrt(vol);
    assert(side.value(meter).approxEqual(3));
}

unittest
{
    auto meter = unit!(double, "L").qVariant;
    auto vol = 27 * cubic(meter);
    auto side = cbrt(vol);
    assert(side.value(meter).approxEqual(3));
}

/// ditto
auto pow(int n, Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.pow(n)).make(std.math.pow(quantity.rawValue, n));
}

/// ditto
auto pow(int n, Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(std.math.pow(quantity.rawValue, n), quantity.dimensions.pow(n));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.powinverse(n)).make(std.math.pow(quantity.rawValue, 1.0 / n));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(std.math.pow(quantity.rawValue, 1.0 / n), quantity.dimensions.powinverse(n));
}

unittest
{
    auto meter = unit!(double, "L");
    auto x = 16 * pow!4(meter);
    auto side = nthRoot!4(x);
    assert(side.value(meter).approxEqual(2));
}

unittest
{
    auto meter = unit!(double, "L").qVariant;
    auto x = 16 * pow!4(meter);
    auto side = nthRoot!4(x);
    assert(side.value(meter).approxEqual(2));
}

/// ditto
Q abs(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Q.make(std.math.fabs(quantity.rawValue));
}

/// ditto
Q abs(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q.make(std.math.fabs(quantity.rawValue), quantity.dimensions);
}

unittest
{
    auto meter = unit!(double, "L");
    auto mlength = -12 * meter;
    auto length = abs(mlength);
    assert(length.value(meter).approxEqual(12));
}

unittest
{
    auto meter = unit!(double, "L").qVariant;
    auto mlength = -12 * meter;
    auto length = abs(mlength);
    assert(length.value(meter).approxEqual(12));
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

/// ditto
template Pow(Q, int n)
    if (isQuantity!Q)
{
    alias Pow = typeof(pow!n(Q.init));
}

///
unittest
{
    enum meter = unit!(double, "L");
    enum second = unit!(double, "T");
    enum hertz = 1 / second;

    alias Length = typeof(meter);
    alias Area = typeof(meter * meter);
    alias Volume = typeof(meter * meter * meter);
    alias Time = typeof(second);
    alias Frequency = typeof(hertz);
    alias Speed = typeof(meter / second);

    static assert(is(Inverse!Time == Frequency));
    static assert(is(Quotient!(Length, Time) == Speed));
    static assert(is(Square!Length == Area));
    static assert(is(Cubic!Length == Volume));
    static assert(AreConsistent!(Product!(Inverse!Time, Length), Speed));
}
