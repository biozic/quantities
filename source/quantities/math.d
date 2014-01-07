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
import quantities.runtime;

version (unittest)
{
    import quantities.si;
    import std.math : approxEqual;
}
version (Have_tested) import tested;
else private struct name { string dummy; }


/// Transforms a quantity/unit.
auto square(T)(T unit)
    if (isQuantityType!T || isRTQuantity!T)
{
    return pow!2(unit);
}

/// ditto
auto cubic(T)(T unit)
    if (isQuantityType!T || isRTQuantity!T)
{
    return pow!3(unit);
}

/// ditto
auto pow(int n, T)(T unit)
    if (isQuantityType!T)
{
    return Quantity!(T.dimensions * n, T.valueType)(unit.rawValue ^^ n);
}

/// ditto
auto pow(int n, T)(T unit)
    if (isRTQuantity!T)
{
    return RTQuantity(unit.dimensions * n, unit.rawValue ^^ n); 
}

// Power function when n is not known at compile time.
auto pow(T)(T unit, int n)
    if (isRTQuantity!T)
{
    return RTQuantity(unit.dimensions * n, unit.rawValue ^^ n); 
}

@name("CT square, cubic, pow")
unittest
{
    auto surface = 1 * square(meter);
    auto volume = 1 * cubic(meter);
    volume = 1 * pow!3(meter);
}

@name("RT square, cubic, pow")
unittest
{
    RTQuantity surface = 1 * square(meter);
    RTQuantity volume = 1 * cubic(meter);
    volume = 1 * pow!3(meter);
}

/// Returns the square root, the cubic root of the nth root of a quantity.
auto sqrt(Q)(Q quantity)
{
    import std.math;
    static if (isQuantity!quantity)
        return Quantity!(Q.dimensions / 2, Q.valueType)(std.math.sqrt(quantity.rawValue));
    else static if (isRTQuantity!Q)
        return RTQuantity(quantity.dimensions / 2, std.math.sqrt(quantity.rawValue));
    else
        return std.math.sqrt(quantity);
}

/// ditto
auto cbrt(Q)(Q quantity)
{
    import std.math;
    static if (isQuantity!quantity)
        return Quantity!(Q.dimensions / 3, Q.valueType)(std.math.cbrt(quantity.rawValue));
    else static if (isRTQuantity!Q)
        return RTQuantity(quantity.dimensions / 3, std.math.cbrt(quantity.rawValue));
    else
        return std.math.cbrt(quantity);
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
{
    import std.math;
    static if (isQuantity!quantity)
        return Quantity!(Q.dimensions / n, Q.valueType)(std.math.pow(quantity.rawValue, 1.0 / n));
    else static if (isRTQuantity!Q)
        return RTQuantity(quantity.dimensions / n, std.math.pow(quantity.rawValue, 1.0 / n));
    else
        return std.math.pow(quantity, 1.0 / n);
}

///
@name("CT Powers of a quantity")
unittest
{
    auto surface = 25 * square(meter);
    auto side = sqrt(surface);
    assert(approxEqual(side.value(meter), 5));
    
    auto volume = 1 * liter;
    side = cbrt(volume);
    assert(approxEqual(nthRoot!3(volume).value(deci(meter)), 1));
    assert(approxEqual(side.value(deci(meter)), 1));
}

@name("RT Powers of a quantity")
unittest
{
    RTQuantity surface = 25 * square(meter);
    RTQuantity side = sqrt(surface);
    assert(approxEqual(side.value(RTQuantity(meter)), 5));
    
    RTQuantity volume = 1 * liter;
    side = cbrt(volume);
    assert(approxEqual(nthRoot!3(volume).value(RTQuantity(meter)), 0.1));
    assert(approxEqual(side.value(RTQuantity(meter)), 0.1));
}


/// Returns the absolute value of a quantity
Q abs(Q)(Q quantity)
{
    import std.math;
    static if (isQuantity!quantity)
        return Q(std.math.fabs(quantity.rawValue));
    else static if (isRTQuantity!Q)
        return RTQuantity(quantity.dimensions, std.math.fabs(quantity.rawValue));
    else
        return std.math.abs(quantity);
}
///
@name("abs")
unittest
{
    auto deltaT = -10 * second;
    assert(abs(deltaT) == 10 * second);
}

@name("RT abs")
unittest
{
    RTQuantity deltaT = -10 * RTQuantity(second);
    assert(abs(deltaT) == 10 * RTQuantity(second));
}
