// Written in the D programming language
/++
This module defines the main basic math operations on quantities.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.math;

import quantities.base;

version (unittest)
{
    import quantities.si;
    import std.math : approxEqual;
}

/// Transforms a quantity/unit.
auto square(U)(U unit)
    if (isQuantity!U)
{
    return pow!2(unit);
}

/// ditto
auto cubic(U)(U unit)
    if (isQuantity!U)
{
    return pow!3(unit);
}

/// ditto
auto pow(int n, U)(U unit)
    if (isQuantity!U)
{
    static if (U.runtime)
        return RTQuantity(unit.rawValue ^^ n, unit.dimensions.exp(n)); 
    else
        return Quantity!(U.dimensions.exp(n), U.valueType)(unit.rawValue ^^ n);
}

// Power function when n is not known at compile time.
auto pow(U)(U unit, int n)
    if (isQuantity!U && U.runtime)
{
    return RTQuantity(unit.rawValue ^^ n, unit.dimensions.exp(n)); 
}

unittest // CT square, cubic, pow
{
    auto surface = 1 * square(meter);
    auto volume = 1 * cubic(meter);
    volume = 1 * pow!3(meter);
}

unittest // RT square, cubic, pow
{
    RTQuantity surface = 1 * square(meter);
    RTQuantity volume = 1 * cubic(meter);
    volume = 1 * pow!3(meter);
}

/// Returns the square root, the cubic root of the nth root of a quantity.
auto sqrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
    static if (Q.runtime)
        return RTQuantity(std.math.sqrt(quantity.rawValue), quantity.dimensions.expInv(2));
    else
        return Quantity!(Q.dimensions.expInv(2), Q.valueType)(std.math.sqrt(quantity.rawValue));
}

/// ditto
auto cbrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
    static if (Q.runtime)
        return RTQuantity(std.math.cbrt(quantity.rawValue), quantity.dimensions.expInv(3));
    else
        return Quantity!(Q.dimensions.expInv(3), Q.valueType)(std.math.cbrt(quantity.rawValue));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
    static if (Q.runtime)
        return RTQuantity(std.math.pow(quantity.rawValue, 1.0 / n), quantity.dimensions.expInv(n));
    else
        return Quantity!(Q.dimensions.expInv(n), Q.valueType)(std.math.pow(quantity.rawValue, 1.0 / n));
}

///
unittest // CT Powers of a quantity
{
    auto surface = 25 * square(meter);
    auto side = sqrt(surface);
    assert(side.value(meter).approxEqual(5));
    
    auto volume = 1 * liter;
    side = cbrt(volume);
    assert(nthRoot!3(volume).value(deci(meter)).approxEqual(1));
    assert(side.value(deci(meter)).approxEqual(1));
}

unittest // RT Powers of a quantity
{
    RTQuantity surface = 25 * square(meter);
    RTQuantity side = sqrt(surface);
    assert(side.value(RTQuantity(meter)).approxEqual(5));
    
    RTQuantity volume = 1 * liter;
    side = cbrt(volume);
    assert(nthRoot!3(volume).value(RTQuantity(meter)).approxEqual(0.1));
    assert(side.value(RTQuantity(meter)).approxEqual(0.1));
}


/// Returns the absolute value of a quantity
Q abs(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
    static if (Q.runtime)
        return RTQuantity(std.math.fabs(quantity.rawValue), quantity.dimensions);
    else
        return Q(std.math.fabs(quantity.rawValue));
}
///
unittest // abs
{
    auto deltaT = -10 * second;
    assert(abs(deltaT) == 10 * second);
}

unittest // RT abs
{
    RTQuantity deltaT = -10 * RTQuantity(second);
    assert(abs(deltaT) == 10 * RTQuantity(second));
}
