/++
This module quantities that are checked at compile-time for
dimensional consistency.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.compiletime.quantity;

import quantities.internal.dimensions;
import quantities.runtime.qvariant;
import std.format;
import std.math;
import std.traits : isNumeric, isIntegral;

/++
A quantity checked at compile-time for dimensional consistency.

Params:
    N = the numeric type of the quantity.

See_Also:
    QVariant has the same public members and overloaded operators as Quantity.
+/
struct Quantity(N, alias unitSpec)
{
    static assert(isNumeric!N);
    static assert(isQVariant!(typeof(unitSpec)));
    static assert(Quantity.sizeof == N.sizeof);

private:
    N _value;
    alias unit = unitSpec;

    // Creates a new quantity with non-empty dimensions
    static Quantity make(T)(T scalar)
            if (isNumeric!T)
    {
        Quantity result;
        result._value = scalar;
        return result;
    }

    mixin template checkDim(alias u)
    {
        static if (unit.dimensions != u.dimensions)
            static assert(false,
                    "Dimension error: %s is not consistent with %s".format(unit.dimensions,
                        u.dimensions));
    }

    mixin template checkDimensionless(alias u)
    {
        static assert(u.isDimensionless, "Dimension error: %s instead of no dimensions");
    }

package(quantities):
    alias valueType = N;

    N rawValue() const
    {
        return _value;
    }

public:
    /// Creates a new quantity from another one with the same dimensions
    this(Q)(auto ref const Q qty)
            if (isQuantity!Q)
    {
        mixin checkDim!(Q.unit);
        _value = qty._value;
    }

    /// ditto
    this(Q)(auto ref const Q qty)
            if (isQVariant!Q)
    {
        import std.exception;

        enforce(unit.dimensions == qty.dimensions,
                new DimensionException("Incompatible dimensions", unit.dimensions, qty.dimensions));
        _value = qty.rawValue;
    }

    /// Creates a new dimensionless quantity from a number
    this(T)(T scalar)
            if (isNumeric!T && unit.isDimensionless)
    {
        _value = scalar;
    }

    /// Returns the dimensions of the quantity
    enum dimensions = unit.dimensions;

    /++
    Implicitly convert a dimensionless value to the value type.
    +/
    static if (unit.isDimensionless)
    {
        N get() const
        {
            return _value;
        }

        alias get this;
    }

    /++
    Gets the _value of this quantity when expressed in the given target unit.
    +/
    N value(Q)(auto ref const Q target) const 
            if (isQuantity!Q)
    {
        mixin checkDim!(Q.unit);
        return _value / target._value;
    }

    /++
    Test whether this quantity is dimensionless
    +/
    enum bool isDimensionless = unit.isDimensionless;

    /++
    Tests wheter this quantity has the same dimensions as another one.
    +/
    bool isConsistentWith(Q)(auto ref const Q qty) const 
            if (isQuantity!Q)
    {
        enum yesOrNo = unit.isConsistentWith(Q.unit);
        return yesOrNo;
    }

    /++
    Cast a dimensionless quantity to a numeric type.

    The cast operation will throw DimensionException if the quantity is not
    dimensionless.
    +/
    static if (unit.isDimensionless)
    {
        T opCast(T)() const 
                if (isNumeric!T)
        {
            return _value;
        }
    }

    // Assign from another quantity
    /// Operator overloading
    ref Quantity opAssign(Q)(auto ref const Q qty)
            if (isQuantity!Q)
    {
        mixin checkDim!(Q.unit);
        _value = qty._value;
        return this;
    }

    // Assign from a numeric value if this quantity is dimensionless
    /// ditto
    ref Quantity opAssign(T)(T scalar)
            if (isNumeric!T)
    {
        mixin checkDimensionless!unit;
        _value = scalar;
        return this;
    }

    // Unary + and -
    /// ditto
    Quantity opUnary(string op)() const 
            if (op == "+" || op == "-")
    {
        return Quantity.make(mixin(op ~ "_value"));
    }

    // Unary ++ and --
    /// ditto
    Quantity opUnary(string op)()
            if (op == "++" || op == "--")
    {
        mixin(op ~ "_value;");
        return this;
    }

    // Add (or substract) two quantities if they share the same dimensions
    /// ditto
    Quantity opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQuantity!Q && (op == "+" || op == "-"))
    {
        mixin checkDim!(Q.unit);
        return Quantity.make(mixin("_value" ~ op ~ "qty._value"));
    }

    // Add (or substract) a dimensionless quantity and a number
    /// ditto
    Quantity opBinary(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        mixin checkDimensionless!unit;
        return Quantity.make(mixin("_value" ~ op ~ "scalar"));
    }

    /// ditto
    Quantity opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        mixin checkDimensionless!unit;
        return Quantity.make(mixin("scalar" ~ op ~ "_value"));
    }

    // Multiply or divide a quantity by a number
    /// ditto
    Quantity opBinary(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "*" || op == "/" || op == "%"))
    {
        return Quantity.make(mixin("_value" ~ op ~ "scalar"));
    }

    /// ditto
    Quantity opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && op == "*")
    {
        return Quantity.make(mixin("scalar" ~ op ~ "_value"));
    }

    /// ditto
    auto opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "/" || op == "%"))
    {
        alias RQ = Quantity!(N, 1 / unit);
        return RQ.make(mixin("scalar" ~ op ~ "_value"));
    }

    // Multiply or divide two quantities
    /// ditto
    auto opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQuantity!Q && (op == "*" || op == "/"))
    {
        alias RQ = Quantity!(N, mixin("unit" ~ op ~ "Q.unit"));
        return RQ.make(mixin("(_value" ~ op ~ "qty._value)"));
    }

    /// ditto
    Quantity opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQuantity!Q && (op == "%"))
    {
        mixin checkDim!(Q.unit);
        return Quantity.make(mixin("(_value" ~ op ~ "qty._value)"));
    }

    // Add/sub assign with a quantity that shares the same dimensions
    /// ditto
    void opOpAssign(string op, Q)(auto ref const Q qty)
            if (isQuantity!Q && (op == "+" || op == "-"))
    {
        mixin checkDim!(Q.unit);
        mixin("_value " ~ op ~ "= qty._value;");
    }

    // Add/sub assign a number to a dimensionless quantity
    /// ditto
    void opOpAssign(string op, T)(T scalar)
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        mixin checkDimensionless!unit;
        mixin("_value " ~ op ~ "= scalar;");
    }

    // Mul/div assign another dimensionless quantity to a dimensionsless quantity
    /// ditto
    void opOpAssign(string op, Q)(auto ref const Q qty)
            if (isQuantity!Q && (op == "*" || op == "/" || op == "%"))
    {
        mixin checkDimensionless!unit;
        mixin("_value" ~ op ~ "= qty._value;");
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
        mixin checkDimensionless!unit;
        mixin("_value" ~ op ~ "= scalar;");
    }

    // Exact equality between quantities
    /// ditto
    bool opEquals(Q)(auto ref const Q qty) const 
            if (isQuantity!Q)
    {
        mixin checkDim!(Q.unit);
        return _value == qty._value;
    }

    // Exact equality between a dimensionless quantity and a number
    /// ditto
    bool opEquals(T)(T scalar) const 
            if (isNumeric!T)
    {
        mixin checkDimensionless!unit;
        return _value == scalar;
    }

    // Comparison between two quantities
    /// ditto
    int opCmp(Q)(auto ref const Q qty) const 
            if (isQuantity!Q)
    {
        mixin checkDim!(Q.unit);
        if (_value == qty._value)
            return 0;
        if (_value < qty._value)
            return -1;
        return 1;
    }

    // Comparison between a dimensionless quantity and a number
    /// ditto
    int opCmp(T)(T scalar) const 
            if (isNumeric!T)
    {
        mixin checkDimensionless!unit;
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
        sink.formattedWrite!"%s"(unit.dimensions);
    }
}

/// Creates a new monodimensional unit as a QVariant
auto unit(N, string symbol)()
{
    import quantities.runtime.qvariant;

    enum u = quantities.runtime.qvariant.unit!N(symbol);
    return Quantity!(N, u).make(1);
}

/// Tests whether T is a quantity type
template isQuantity(T)
{
    import std.traits : Unqual;

    alias U = Unqual!T;
    static if (is(U == Quantity!X, X...))
        enum isQuantity = true;
    else
        enum isQuantity = false;
}

/// Basic math functions that work with Quantity.
auto square(Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    enum u = { return QVariant!(Q.valueType)(1, Q.dimensions.pow(2)); }();
    return Quantity!(Q.valueType, u).make(quantity._value ^^ 2);
}

/// ditto
auto sqrt(Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    enum u = { return QVariant!(Q.valueType)(1, Q.dimensions.powinverse(2)); }();
    return Quantity!(Q.valueType, u).make(std.math.sqrt(quantity._value));
}

/// ditto
auto cubic(Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    enum u = { return QVariant!(Q.valueType)(1, Q.dimensions.pow(3)); }();
    return Quantity!(Q.valueType, u).make(quantity._value ^^ 3);
}

/// ditto
auto cbrt(Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    enum u = { return QVariant!(Q.valueType)(1, Q.dimensions.powinverse(3)); }();
    return Quantity!(Q.valueType, u).make(std.math.cbrt(quantity._value));
}

/// ditto
auto pow(int n, Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    enum u = { return QVariant!(Q.valueType)(1, Q.dimensions.pow(n)); }();
    return Quantity!(Q.valueType, u).make(std.math.pow(quantity._value, n));
}

/// ditto
auto nthRoot(int n, Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    enum u = { return QVariant!(Q.valueType)(1, Q.dimensions.powinverse(n)); }();
    return Quantity!(Q.valueType, u).make(std.math.pow(quantity._value, 1.0 / n));
}

/// ditto
Q abs(Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    return Q.make(std.math.fabs(quantity._value));
}
