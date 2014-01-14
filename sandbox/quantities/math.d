module quantities.math;

import quantities.typtup;
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
    return Quantity!(U.valueType, Pow!(n, U.dimensions))(unit.rawValue ^^ n);
}

unittest // CT square, cubic, pow
{
    auto surface = 1 * square(meter);
    auto volume = 1 * cubic(meter);
    volume = 1 * pow!3(meter);
}

/// Returns the square root, the cubic root of the nth root of a quantity.
auto sqrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
    return Quantity!(Q.valueType, PowInverse!(2, Q.dimensions))(std.math.sqrt(quantity.rawValue));
}

/// ditto
auto cbrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
    return Quantity!(Q.valueType, PowInverse!(3, Q.dimensions))(std.math.cbrt(quantity.rawValue));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
    return Quantity!(Q.valueType, PowInverse!(n, Q.dimensions))(std.math.pow(quantity.rawValue, 1.0 / n));
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

/// Returns the absolute value of a quantity
Q abs(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
    return Q(std.math.fabs(quantity.rawValue));
}
///
unittest // abs
{
    auto deltaT = -10 * second;
    assert(abs(deltaT) == 10 * second);
}
