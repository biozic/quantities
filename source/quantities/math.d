/++
This module defines common math operations on quantities.

Copyright: Copyright 2013-2016, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.math;

import quantities.internal.dimensions;
import quantities.base;
import quantities.qvariant;

static import std.math;
version (unittest)
    import std.math : approxEqual;


/// Basic math functions that work with Quantity and QVariant.
auto square(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.pow(2))(quantity.rawValue ^^ 2);
}

/// ditto
auto square(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q(quantity.rawValue ^^ 2, quantity.dimensions.pow(2));
}

/// ditto
auto sqrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.powinverse(2))(std.math.sqrt(quantity.rawValue));
}

/// ditto
auto sqrt(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q(std.math.sqrt(quantity.rawValue), quantity.dimensions.powinverse(2));
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
    return Quantity!(Q.valueType, Q.dimensions.pow(3))(quantity.rawValue ^^ 3);
}

/// ditto
auto cubic(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q(quantity.rawValue ^^ 3, quantity.dimensions.pow(3));
}

/// ditto
auto cbrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.powinverse(3))(std.math.cbrt(quantity.rawValue));
}

/// ditto
auto cbrt(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q(std.math.cbrt(quantity.rawValue), quantity.dimensions.powinverse(3));
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
    return Quantity!(Q.valueType, Q.dimensions.pow(n))(std.math.pow(quantity.rawValue, n));
}

/// ditto
auto pow(int n, Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q(std.math.pow(quantity.rawValue, n), quantity.dimensions.pow(n));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
    if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.powinverse(n))(std.math.pow(quantity.rawValue, 1.0 / n));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q(std.math.pow(quantity.rawValue, 1.0 / n), quantity.dimensions.powinverse(n));
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
    return Q(std.math.fabs(quantity.rawValue));
}

/// ditto
Q abs(Q)(Q quantity)
    if (isQVariant!Q)
{
    return Q(std.math.fabs(quantity.rawValue), quantity.dimensions);
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
