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

/++
Mixin template that introduces math functions operating on a quantity of value type N in the
current scope. Each function imports module_ internally. This module should
contain the math primitives that can operate on the variables of type N, such
as sqrt, cbrt, pow and fabs.
+/
mixin template MathFunctions(N, string module_ = "std.math")
{
    auto square(U)(U unit)
        if (isQuantity!U && is(U.valueType == N))
    {
        return pow!2(unit);
    }

    /// ditto
    auto cubic(U)(U unit)
        if (isQuantity!U && is(U.valueType == N))
    {
        return pow!3(unit);
    }

    /// ditto
    auto pow(int n, U)(U unit)
        if (isQuantity!U && is(U.valueType == N))
    {
        mixin("import " ~ module_ ~ ";");
        static assert(__traits(compiles, unit.rawValue ^^ n),
                      U.valueType.stringof ~ " doesn't overload operator ^^");
        return Quantity!(U.valueType, Pow!(n, U.dimensions)).make(unit.rawValue ^^ n);
    }

    /// ditto
    auto sqrt(Q)(Q quantity)
        if (isQuantity!Q && is(Q.valueType == N))
    {
        mixin("import " ~ module_ ~ ";");
        static assert(__traits(compiles, sqrt(quantity.rawValue)),
                      "No overload of sqrt for an argument of type " ~ Q.valueType.stringof);
        return Quantity!(Q.valueType, PowInverse!(2, Q.dimensions)).make(sqrt(quantity.rawValue));
    }

    /// ditto
    auto cbrt(Q)(Q quantity)
        if (isQuantity!Q && is(Q.valueType == N))
    {
        mixin("import " ~ module_ ~ ";");
        static assert(__traits(compiles, cbrt(quantity.rawValue)),
                      "No overload of cbrt for an argument of type " ~ Q.valueType.stringof);
        return Quantity!(Q.valueType, PowInverse!(3, Q.dimensions)).make(cbrt(quantity.rawValue));
    }

    /// ditto
    auto nthRoot(int n, Q)(Q quantity)
        if (isQuantity!Q && is(Q.valueType == N))
    {
        mixin("import " ~ module_ ~ ";");
        static assert(__traits(compiles, pow(quantity.rawValue, 1.0 / n)),
                      "No overload of pow for an argument of type " ~ Q.valueType.stringof);
        return Quantity!(Q.valueType, PowInverse!(n, Q.dimensions)).make(pow(quantity.rawValue, 1.0 / n));
    }

    /// ditto
    Q abs(Q)(Q quantity)
        if (isQuantity!Q && is(Q.valueType == N))
    {
        mixin("import " ~ module_ ~ ";");
        static assert(__traits(compiles, fabs(quantity.rawValue)),
                      "No overload of fabs for an argument of type " ~ Q.valueType.stringof);
        return Q.make(fabs(quantity.rawValue));
    }
}

///
unittest
{
    enum meter = unit!("L");
    enum liter = 0.001 * meter * meter * meter;

    mixin MathFunctions!(double, "std.math");

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
