/++
This module defines dimensionally variant quantities, for use mainly at run time.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.runtime.qvariant;

import quantities.compiletime.quantity : isQuantity;
import quantities.internal.dimensions;

import std.conv;
import std.exception;
import std.format;
import std.math;
import std.string;
import std.traits;

/++
Exception thrown when operating on two units that are not interconvertible.
+/
class DimensionException : Exception
{
    /// Holds the dimensions of the quantity currently operated on
    Dimensions thisDim;
    /// Holds the dimensions of the eventual other operand
    Dimensions otherDim;

    mixin basicExceptionCtors;

    this(string msg, Dimensions thisDim, Dimensions otherDim,
            string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        super(msg, file, line, next);
        this.thisDim = thisDim;
        this.otherDim = otherDim;
    }
}
///
unittest
{
    import std.exception : assertThrown;

    enum meter = unit!double("L");
    enum second = unit!double("T");

}

/++
A dimensionnaly variant quantity.

Params:
    N = the numeric type of the quantity.

See_Also:
    QVariant has the same public members and overloaded operators as Quantity.
+/
struct QVariant(N)
{
    static assert(isNumeric!N, "Incompatible type: " ~ N.stringof);

private:
    N _value;
    Dimensions _dimensions;

    void checkDim(Dimensions dim) @safe pure const
    {
        enforce(_dimensions == dim,
                new DimensionException("Incompatible dimensions", _dimensions, dim));
    }

    void checkDimensionless() @safe pure const
    {
        enforce(_dimensions.empty, new DimensionException("Not dimensionless",
                _dimensions, Dimensions.init));
    }

package(quantities):
    alias valueType = N;

    N rawValue() const
    {
        return _value;
    }

public:
    // Creates a new quantity with non-empty dimensions
    this(T)(T scalar, const Dimensions dim)
            if (isNumeric!T)
    {
        _value = scalar;
        _dimensions = dim;
    }

    /// Creates a new quantity from another one with the same dimensions
    this(Q)(auto ref const Q qty)
            if (isQVariant!Q)
    {
        _value = qty._value;
        _dimensions = qty._dimensions;
    }

    /// Ditto
    this(Q)(auto ref const Q qty)
            if (isQuantity!Q)
    {
        import quantities.compiletime.quantity : qVariant;

        this = qty.qVariant;
    }

    /// Creates a new dimensionless quantity from a number
    this(T)(T scalar)
            if (isNumeric!T)
    {
        _dimensions = Dimensions.init;
        _value = scalar;
    }

    /// Returns the dimensions of the quantity
    Dimensions dimensions() @property const
    {
        return _dimensions;
    }

    /++
    Implicitly convert a dimensionless value to the value type.

    Calling get will throw DimensionException if the quantity is not
    dimensionless.
    +/
    N get() const
    {
        checkDimensionless;
        return _value;
    }

    alias get this;

    /++
    Gets the _value of this quantity when expressed in the given target unit.
    +/
    N value(Q)(auto ref const Q target) const 
            if (isQVariantOrQuantity!Q)
    {
        checkDim(target.dimensions);
        return _value / target.rawValue;
    }
    ///
    @safe pure unittest
    {
        auto minute = unit!int("T");
        auto hour = 60 * minute;

        QVariant!int time = 120 * minute;
        assert(time.value(hour) == 2);
        assert(time.value(minute) == 120);
    }

    /++
    Test whether this quantity is dimensionless
    +/
    bool isDimensionless() @property const
    {
        return _dimensions.empty;
    }

    /++
    Tests wheter this quantity has the same dimensions as another one.
    +/
    bool isConsistentWith(Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q)
    {
        return _dimensions == qty.dimensions;
    }
    ///
    @safe pure unittest
    {
        auto second = unit!double("T");
        auto minute = 60 * second;
        auto meter = unit!double("L");

        assert(minute.isConsistentWith(second));
        assert(!meter.isConsistentWith(second));
    }

    /++
    Cast a dimensionless quantity to a numeric type.

    The cast operation will throw DimensionException if the quantity is not
    dimensionless.
    +/
    T opCast(T)() const 
            if (isNumeric!T)
    {
        checkDimensionless;
        return _value;
    }

    // Assign from another quantity
    /// Operator overloading
    ref QVariant opAssign(Q)(auto ref const Q qty)
            if (isQVariantOrQuantity!Q)
    {
        _dimensions = qty.dimensions;
        _value = qty.rawValue;
        return this;
    }

    // Assign from a numeric value if this quantity is dimensionless
    /// ditto
    ref QVariant opAssign(T)(T scalar)
            if (isNumeric!T)
    {
        _dimensions = Dimensions.init;
        _value = scalar;
        return this;
    }

    // Unary + and -
    /// ditto
    QVariant!N opUnary(string op)() const 
            if (op == "+" || op == "-")
    {
        return QVariant(mixin(op ~ "_value"), _dimensions);
    }

    // Unary ++ and --
    /// ditto
    QVariant!N opUnary(string op)()
            if (op == "++" || op == "--")
    {
        mixin(op ~ "_value;");
        return this;
    }

    // Add (or substract) two quantities if they share the same dimensions
    /// ditto
    QVariant!N opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "+" || op == "-"))
    {
        checkDim(qty.dimensions);
        return QVariant(mixin("_value" ~ op ~ "qty.rawValue"), _dimensions);
    }

    /// ditto
    QVariant!N opBinaryRight(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "+" || op == "-"))
    {
        checkDim(qty.dimensions);
        return QVariant(mixin("qty.rawValue" ~ op ~ "_value"), _dimensions);
    }

    // Add (or substract) a dimensionless quantity and a number
    /// ditto
    QVariant!N opBinary(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDimensionless;
        return QVariant(mixin("_value" ~ op ~ "scalar"), _dimensions);
    }

    /// ditto
    QVariant!N opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDimensionless;
        return QVariant(mixin("scalar" ~ op ~ "_value"), _dimensions);
    }

    // Multiply or divide a quantity by a number
    /// ditto
    QVariant!N opBinary(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "*" || op == "/" || op == "%"))
    {
        return QVariant(mixin("_value" ~ op ~ "scalar"), _dimensions);
    }

    /// ditto
    QVariant!N opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && op == "*")
    {
        return QVariant(mixin("scalar" ~ op ~ "_value"), _dimensions);
    }

    /// ditto
    QVariant!N opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "/" || op == "%"))
    {
        return QVariant(mixin("scalar" ~ op ~ "_value"), ~_dimensions);
    }

    // Multiply or divide two quantities
    /// ditto
    QVariant!N opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "*" || op == "/"))
    {
        return QVariant(mixin("(_value" ~ op ~ "qty.rawValue)"),
                mixin("_dimensions" ~ op ~ "qty.dimensions"));
    }

    /// ditto
    QVariant!N opBinaryRight(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "*" || op == "/"))
    {
        return QVariant(mixin("(qty.rawValue" ~ op ~ "_value)"),
                mixin("qty.dimensions" ~ op ~ "_dimensions"));
    }

    /// ditto
    QVariant!N opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "%"))
    {
        checkDim(qty.dimensions);
        return QVariant(_value % qty.rawValue, _dimensions);
    }

    /// ditto
    QVariant!N opBinaryRight(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "%"))
    {
        checkDim(qty.dimensions);
        return QVariant(qty.rawValue % _value, _dimensions);
    }

    /// ditto
    QVariant!N opBinary(string op, T)(T power) const 
            if (isIntegral!T && op == "^^")
    {
        return QVariant(_value ^^ power, _dimensions.pow(Rational(power)));
    }

    /// ditto
    QVariant!N opBinary(string op)(Rational power) const 
            if (op == "^^")
    {
        return QVariant(std.math.pow(_value, cast(N) power), _dimensions.pow(power));
    }

    // Add/sub assign with a quantity that shares the same dimensions
    /// ditto
    void opOpAssign(string op, Q)(auto ref const Q qty)
            if (isQVariantOrQuantity!Q && (op == "+" || op == "-"))
    {
        checkDim(qty.dimensions);
        mixin("_value " ~ op ~ "= qty.rawValue;");
    }

    // Add/sub assign a number to a dimensionless quantity
    /// ditto
    void opOpAssign(string op, T)(T scalar)
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDimensionless;
        mixin("_value " ~ op ~ "= scalar;");
    }

    // Mul/div assign another quantity to a quantity
    /// ditto
    void opOpAssign(string op, Q)(auto ref const Q qty)
            if (isQVariantOrQuantity!Q && (op == "*" || op == "/" || op == "%"))
    {
        mixin("_value" ~ op ~ "= qty.rawValue;");
        static if (op == "*")
            _dimensions = _dimensions * qty.dimensions;
        else
            _dimensions = _dimensions / qty.dimensions;
    }

    // Mul/div assign a number to a quantity
    /// ditto
    void opOpAssign(string op, T)(T scalar)
            if (isNumeric!T && (op == "*" || op == "/"))
    {
        mixin("_value" ~ op ~ "= scalar;");
    }

    /// ditto
    void opOpAssign(string op, T)(T scalar)
            if (isNumeric!T && op == "%")
    {
        checkDimensionless;
        mixin("_value" ~ op ~ "= scalar;");
    }

    // Exact equality between quantities
    /// ditto
    bool opEquals(Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q)
    {
        checkDim(qty.dimensions);
        return _value == qty.rawValue;
    }

    // Exact equality between a dimensionless quantity and a number
    /// ditto
    bool opEquals(T)(T scalar) const 
            if (isNumeric!T)
    {
        checkDimensionless;
        return _value == scalar;
    }

    // Comparison between two quantities
    /// ditto
    int opCmp(Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q)
    {
        checkDim(qty.dimensions);
        if (_value == qty.rawValue)
            return 0;
        if (_value < qty.rawValue)
            return -1;
        return 1;
    }

    // Comparison between a dimensionless quantity and a number
    /// ditto
    int opCmp(T)(T scalar) const 
            if (isNumeric!T)
    {
        checkDimensionless;
        if (_value < scalar)
            return -1;
        if (_value > scalar)
            return 1;
        return 0;
    }

    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        sink.formatValue(_value, fmt);
        sink(" ");
        sink.formattedWrite!"%s"(_dimensions);
    }
}

/// Creates a new monodimensional unit as a QVariant
QVariant!N unit(N)(string symbol)
{
    return QVariant!N(N(1), Dimensions.mono(symbol));
}

// Tests whether T is a quantity type
template isQVariant(T)
{
    alias U = Unqual!T;
    static if (is(U == QVariant!X, X...))
        enum isQVariant = true;
    else
        enum isQVariant = false;
}

enum isQVariantOrQuantity(T) = isQVariant!T || isQuantity!T;

/// Turns a Quantity into a QVariant
auto qVariant(Q)(auto ref const Q qty)
        if (isQuantity!Q)
{
    return QVariant!(Q.valueType)(qty.rawValue, qty.dimensions);
}

/// Turns a scalar into a dimensionless QVariant
auto qVariant(N)(N scalar)
        if (isNumeric!N)
{
    return QVariant!N(scalar, Dimensions.init);
}

/++
Creates a new prefix function that multiplies a QVariant by a _factor.
+/
template prefix(alias factor)
{
    alias N = typeof(factor);
    static assert(isNumeric!N, "Incompatible type: " ~ N.stringof);

    auto prefix(Q)(auto ref const Q base)
            if (isQVariantOrQuantity!Q)
    {
        return base * factor;
    }
}
///
@safe pure unittest
{
    import std.math : approxEqual;

    auto meter = unit!double("L");
    alias milli = prefix!1e-3;
    assert(milli(meter).value(meter).approxEqual(1e-3));
}

/// Basic math functions that work with QVariant.
auto square(Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(quantity._value ^^ 2, quantity._dimensions.pow(Rational(2)));
}

/// ditto
auto sqrt(Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(std.math.sqrt(quantity._value), quantity._dimensions.powinverse(Rational(2)));
}

/// ditto
auto cubic(Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(quantity._value ^^ 3, quantity._dimensions.pow(Rational(3)));
}

/// ditto
auto cbrt(Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(std.math.cbrt(quantity._value), quantity._dimensions.powinverse(Rational(3)));
}

/// ditto
auto pow(int n, Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(std.math.pow(quantity._value, n), quantity._dimensions.pow(Rational(n)));
}

/// ditto
auto nthRoot(int n, Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(std.math.pow(quantity._value, 1.0 / n), quantity._dimensions.powinverse(Rational(n)));
}

/// ditto
Q abs(Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(std.math.fabs(quantity._value), quantity._dimensions);
}
