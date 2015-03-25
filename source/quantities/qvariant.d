/++
This module defines dimensionnaly variant quantities.

Copyright: Copyright 2013-2015, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.qvariant;

import quantities.base;
import quantities.parsing : DimensionException;
import std.exception;
import std.format;
import std.string;
import std.traits;

version (unittest) import std.math : approxEqual;

alias Dimensions = immutable(int[string]);

/++
QVariant  is analog  to Quantity  except  that the  dimensions are  stored in  a
private field  instead of a  type parameter. This makes  QVariant "dimensionnaly
variant", so  that a variable of  type QVariant can hold  quantities of variable
dimensions.  Yet,  only operations  that  are  dimensionnaly consistent  can  be
performed on QVariant variables.

Warning:  Contrary to  Quantity, where  all dimensional  operations are  done at
compile-time,  the dimensions  of  QVariant  ate computed  at  runtime for  each
operation.  This  has a  significant  performance  cost.  Only use  QVariant  in
situation where using  Quantity is not possible, that is  when the dimensions of
the quantities are only known at runtime.

Params:
    N = the numeric type of the quantity.

See_Also:
    QVariant has the same public members and overloaded operators as Quantity.
+/
struct QVariant(N)
{
    static assert(isNumberLike!N, "Incompatible type: " ~ N.stringof);

    alias valueType = N;

    private
    {
        N _value;

        void checkDim(Dimensions dim) const
        {
            enforceEx!DimensionException(equals(dim, dimensions),
                    "Dimension error: [%s] is not compatible with [%s]"
                    .format(.toString(dim), .toString(dimensions)));
        }

        static void checkValueType(T)()
        {
            static assert(is(T : valueType), "%s is not implicitly convertible to %s"
                .format(T.stringof, valueType.stringof));
        }
    }

    Dimensions dimensions;

    package this(N value, Dimensions dim)
    {
        _value = value;
        dimensions = dim;
    }

    // Gets the base unit of this quantity.
    QVariant baseUnit()
    {
        N one = 1;
        return QVariant.make(one, dimensions.dup);
    }

    // Creates a new quantity from another one with the same dimensions
    this(Q)(Q other)
        if (isQVariant!Q || isQuantity!Q)
    {
        checkValueType!(Q.valueType);
        _value = other._value;
        dimensions = other.dimensions;
    }

    // Creates a new dimensionless quantity from a number
    this(T)(T value)
        if (isNumberLike!T)
    {
        checkValueType!T;
        dimensions = Dimensions.init;
        _value = value;
    }

    // Should be a constructor
    // Workaround for @@BUG 5770@@
    // (https://d.puremagic.com/issues/show_bug.cgi?id=5770)
    // "Template constructor bypass access check"
    package static QVariant make(T)(T value, Dimensions dim)
        if (isNumberLike!T)
    {
        checkValueType!T;
        return QVariant(cast(N) value, dim);
    }

    // Gets the internal number of this quantity.
    package N rawValue() const
    {
        return _value;
    }

    // Implicitly convert a dimensionless value to the value type
    N get() const
    {
        checkDim(Dimensions.init);
        return _value;
    }
    alias get this;

    /+
    Gets the _value of this quantity expressed in the given target unit.
    +/
    N value(Q)(Q target) const
        if (isQVariant!Q || isQuantity!Q)
    {
        checkDim(target.dimensions);
        checkValueType!(Q.valueType);
        return _value / target._value;
    }
    //
    @safe pure unittest
    {
        import quantities.si : minute, hour;

        QVariant!double time = 120 * minute;
        assert(time.value(hour) == 2);
        assert(time.value(minute) == 120);
    }

    /+
    Tests wheter this quantity has the same dimensions as another one.
    +/
    bool isConsistentWith(Q)(Q other) const
        if (isQVariant!Q || isQuantity!Q)
    {
        return equals(dimensions, other.dimensions);
    }
    //
    @safe pure unittest
    {
        import quantities.si : minute, second, meter;

        assert(minute.qVariant.isConsistentWith(second));
        assert(!meter.qVariant.isConsistentWith(second));
    }

    // Cast a QVariant to an equivalent Quantity
    Q opCast(Q)() const
        if (isQuantity!Q)
    {
        checkDim(Q.dimensions);
        checkValueType!(Q.valueType);
        return Q.make(_value);
    }

    // Cast a dimensionless quantity to a numeric type
    T opCast(T)() const
        if (isNumberLike!T)
    {
        checkDim(Dimensions.init);
        checkValueType!T;
        return _value;
    }

    // Overloaded operators.
    // Only dimensionally correct operations will compile.

    // Assign from another quantity
    void opAssign(Q)(Q other)
        if (isQVariant!Q || isQuantity!Q)
    {
        checkDim(other.dimensions);
        checkValueType!(Q.valueType);
        _value = other._value;
    }

    // Assign from a numeric value if this quantity is dimensionless
    // ditto
    void opAssign(T)(T other)
        if (isNumberLike!T)
    {
        checkDim(Dimensions.init);
        checkValueType!T;
        _value = other;
    }

    // Unary + and -
    // ditto
    auto opUnary(string op)() const
        if (op == "+" || op == "-")
    {
        return QVariant.make(mixin(op ~ "_value"), dimensions);
    }
    
    // Unary ++ and --
    // ditto
    auto opUnary(string op)()
        if (op == "++" || op == "--")
    {
        mixin(op ~ "_value;");
        return this;
    }

    // Add (or substract) two quantities if they share the same dimensions
    // ditto
    auto opBinary(string op, Q)(Q other) const
        if ((isQVariant!Q || isQuantity!Q) && (op == "+" || op == "-"))
    {
        checkDim(other.dimensions);
        checkValueType!(Q.valueType);
        return QVariant.make(mixin("_value" ~ op ~ "other._value"), dimensions);
    }

    // ditto
    auto opBinaryRight(string op, Q)(Q other) const
        if ((isQVariant!Q || isQuantity!Q) && (op == "+" || op == "-"))
    {
        return opBinary!op(other);
    }

    // Add (or substract) a dimensionless quantity and a number
    // ditto
    auto opBinary(string op, T)(T other) const
        if (isNumberLike!T && (op == "+" || op == "-"))
    {
        checkDim(Dimensions.init);
        checkValueType!T;
        return QVariant.make(mixin("_value" ~ op ~ "other"), dimensions);
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumberLike!T && (op == "+" || op == "-"))
    {
        return opBinary!op(other);
    }

    // Multiply or divide two quantities
    // ditto
    auto opBinary(string op, Q)(Q other) const
        if ((isQVariant!Q || isQuantity!Q) && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!(Q.valueType);
        return QVariant.make(mixin("(_value" ~ op ~ "other._value)"),
            binop!op(dimensions, other.dimensions));
    }

    // ditto
    auto opBinaryRight(string op, Q)(Q other) const
        if ((isQVariant!Q || isQuantity!Q) && (op == "*" || op == "/" || op == "%"))
    {
        return this * other;
    }

    // Multiply or divide a quantity by a number
    // ditto
    auto opBinary(string op, T)(T other) const
        if (isNumberLike!T && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!T;
        return QVariant.make(mixin("_value" ~ op ~ "other"), dimensions);
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumberLike!T && op == "*")
    {
        checkValueType!T;
        return this * other;
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumberLike!T && (op == "/" || op == "%"))
    {
        checkValueType!T;
        return QVariant.make(mixin("other" ~ op ~ "_value"), invert(dimensions));
    }

    auto opBinary(string op, T)(T power) const
        if (op == "^^")
    {
        checkValueType!T;
        return QVariant.make(_value^^power, pow(dimensions, power));
    }

    // Add/sub assign with a quantity that shares the same dimensions
    // ditto
    void opOpAssign(string op, Q)(Q other)
        if ((isQVariant!Q || isQuantity!Q) && (op == "+" || op == "-"))
    {
        checkDim(other.dimensions);
        checkValueType!(Q.valueType);
        mixin("_value " ~ op ~ "= other._value;");
    }

    // Add/sub assign a number to a dimensionless quantity
    // ditto
    void opOpAssign(string op, T)(T other)
        if (isNumberLike!T && (op == "+" || op == "-"))
    {
        checkDim(Dimensions.init);
        checkValueType!T;
        mixin("_value " ~ op ~ "= other;");
    }

    // Mul/div assign with a dimensionless quantity
    // ditto
    void opOpAssign(string op, Q)(Q other)
        if ((isQVariant!Q || isQuantity!Q) && (op == "*" || op == "/" || op == "%"))
    {
        checkDim(Dimensions.init);
        checkValueType!(Q.valueType);
        mixin("_value" ~ op ~ "= other._value;");
    }

    // Mul/div assign with a number
    // ditto
    void opOpAssign(string op, T)(T other)
        if (isNumberLike!T && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!T;
        mixin("_value" ~ op ~ "= other;");
    }

    // Exact equality between quantities
    // ditto
    bool opEquals(Q)(Q other) const
        if (isQVariant!Q || isQuantity!Q)
    {
        checkDim(other.dimensions);
        return _value == other._value;
    }

    // Exact equality between a dimensionless quantity and a number
    // ditto
    bool opEquals(T)(T other) const
        if (isNumberLike!T)
    {
        checkDim(Dimensions.init);
        return _value == other;
    }

    // Comparison between two quantities
    // ditto
    int opCmp(Q)(Q other) const
        if (isQVariant!Q || isQuantity!Q)
    {
        checkDim(other.dimensions);
        if (_value == other._value)
            return 0;
        if (_value < other._value)
            return -1;
        return 1;
    }

    // Comparison between a dimensionless quantity and a number
    // ditto
    int opCmp(T)(T other) const
        if (isNumberLike!T)
    {
        checkDim(Dimensions.init);
        if (_value < other)
            return -1;
        if (_value > other)
            return 1;
        return 0;
    }

    // String formatting function
    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        sink.formatValue(_value, fmt);
        sink(" ");
        sink(dimensions.toString);
    }
}

/// Converts a Quantity to an equivalent QVariant
auto qVariant(Q)(Q quantity)
{
    return QVariant!(Q.valueType).make(quantity._value, quantity.dimensions);
}
///
@safe pure unittest
{
    import quantities.si : meter, second;

    auto speed = 42 * meter/second;
    auto qspeed = speed.qVariant;
    assert(qspeed.value(meter/second) == 42);
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

@safe pure unittest // QVariant constructor
{
    import quantities.si : minute, second, radian;

    QVariant!double time = typeof(second)(1 * minute);
    assert(time.value(second) == 60);
    assert(time.baseUnit == qVariant(second));

    QVariant!double angle = 2;
    assert(angle.value(radian) == 2);
}

@safe pure unittest // QVariant.alias this
{
    import quantities.si : radian;

    static double foo(double d) { return d; }
    assert(foo(2 * qVariant(radian)) == 2);
}

@safe pure unittest // QVariant.opCast
{
    import quantities.si : meter, radian, Angle;
   
    auto angle = cast(Angle) (12 * radian.qVariant);
    assert(angle.value(radian) == 12);

    QVariant!double angle2 = 12 * radian;
    assert(cast(double) angle2 == 12);
}

@safe pure unittest // QVariant.opAssign Q = Q
{
    import quantities.si : meter;

    QVariant!double length = meter;
    length = 100 * meter;
    assert(length.value(meter) == 100);
}

@safe pure unittest // QVariant.opAssign Q = N
{
    import quantities.si : radian;
    
    QVariant!double angle = radian;
    angle = 2;
    assert(angle.value(radian) == 2);
}

@safe pure unittest // QVariant.opUnary +Q -Q ++Q --Q
{
    import quantities.si : meter;

    QVariant!double length = + meter.qVariant;
    assert(length == 1 * meter);
    QVariant!double length2 = - meter.qVariant;
    assert(length2 == -1 * meter);
    
    QVariant!double len = ++meter;
    assert(len.value(meter).approxEqual(2));
    len = --meter;
    assert(len.value(meter).approxEqual(0));
    ++len;
    assert(len.value(meter).approxEqual(1));    
}

@safe pure unittest // QVariant.opBinary Q*N Q/N
{
    import quantities.si : second;

    QVariant!double time = second * 60;
    assert(time.value(second) == 60);
    QVariant!double time2 = second / 2;
    assert(time2.value(second) == 1.0/2);
}

@safe pure unittest // QVariant.opBinary Q+Q Q-Q
{
    import quantities.si : meter;

    QVariant!double length = meter + meter;
    assert(length.value(meter) == 2);
    QVariant!double length2 = length - meter;
    assert(length2.value(meter) == 1);
}

@safe pure unittest // QVariant.opBinary Q+N Q-N
{
    import quantities.si : radian;
    
    QVariant!double angle = radian + 1;
    assert(angle.value(radian) == 2);
    QVariant!double angle2 = angle - 1;
    assert(angle2.value(radian) == 1);
}

@safe pure unittest // QVariant.opBinary Q*Q Q/Q
{
    import quantities.si : meter, minute, second;

    QVariant!double hertz = 1 / second;

    QVariant!double length = meter * 5;
    QVariant!double surface = length * length;
    assert(surface.value(meter * meter) == 5*5);
    QVariant!double length2 = surface / length;
    assert(length2.value(meter) == 5);

    QVariant!double x = minute / second;
    assert(x.rawValue == 60);

    QVariant!double y = minute * hertz;
    assert(y.rawValue == 60);
}

@safe pure unittest // QVariant.opBinaryRight N*Q
{
    import quantities.si : meter;

    QVariant!double length = 100 * meter;
    assert(length == meter * 100);
}

@safe pure unittest // QVariant.opBinaryRight N/Q
{
    import quantities.si : meter;

    QVariant!double x = 1 / (2 * meter);
    assert(x.value(1/meter) == 1.0/2);
}

@safe pure unittest // QVariant.opBinary Q%Q Q%N N%Q
{
    import quantities.si : meter;

    QVariant!double x = 258.1 * meter;
    QVariant!double y1 = x % (50 * meter);
    assert((cast(double) y1).approxEqual(8.1));
    QVariant!double y2 = x % 50;
    assert(y2.value(meter).approxEqual(8.1));
}

@safe pure unittest // QVariant.opBinary Q^^N
{
    import quantities.si : meter;
    import quantities.si : cubic;

    QVariant!double x = 2 * meter;
    assert((x^^3).value(cubic(meter)).approxEqual(8));
}

@safe pure unittest // QVariant.opOpAssign Q+=Q Q-=Q
{
    import quantities.si : second;

    QVariant!double time = 10 * second;
    time += 50 * second;
    assert(time.value(second).approxEqual(60));
    time -= 40 * second;
    assert(time.value(second).approxEqual(20));
}

@safe pure unittest // QVariant.opOpAssign Q*=N Q/=N Q%=N
{
    import quantities.si : second;

    QVariant!double time = 20 * second;
    time *= 2;
    assert(time.value(second).approxEqual(40));
    time /= 4;
    assert(time.value(second).approxEqual(10));
    time %= 3;
    assert(time.value(second).approxEqual(1));
}

@safe pure unittest // QVariant.opEquals
{
    import quantities.si : meter, minute, second, radian;

    assert(qVariant(1 * minute) == qVariant(60 * second));
    assert(qVariant((1 / second) * meter) == qVariant(meter / second));
    assert(radian.qVariant == 1);
}

@safe pure unittest // QVariant.opCmp
{
    import quantities.si : minute, second;

    QVariant!double hour = 60 * minute;
    assert(second.qVariant < minute.qVariant);
    assert(minute.qVariant <= minute.qVariant);
    assert(hour > minute);
    assert(hour >= hour);
}

@safe pure unittest // Quantity.opCmp
{
    import quantities.si : radian;
    
    QVariant!double angle = 2 * radian;
    assert(angle < 4);
    assert(angle <= 2);
    assert(angle > 1);
    assert(angle >= 2);
}

unittest // Quantity.toString
{
    import quantities.si : meter;
    import std.conv : text;

    QVariant!double length = 12 * meter;
    assert(length.text == "12 [L]", length.text);
}

@safe pure unittest // Exceptions for incompatible dimensions
{
    import quantities.si : meter, second;
    import std.exception;

    QVariant!double m = meter;
    assertThrown!DimensionException(m.value(second));
    assertThrown!DimensionException(m = second);
    assertThrown!DimensionException(m + second);
    assertThrown!DimensionException(m - second);
    assertThrown!DimensionException(m + 1);
    assertThrown!DimensionException(m - 1);
    assertThrown!DimensionException(1 + m);
    assertThrown!DimensionException(1 - m);
    assertThrown!DimensionException(m += second);
    assertThrown!DimensionException(m -= second);
    assertThrown!DimensionException(m *= second);
    assertThrown!DimensionException(m /= second);
    assertThrown!DimensionException(m *= meter);
    assertThrown!DimensionException(m /= meter);
    assertThrown!DimensionException(m += 1);
    assertThrown!DimensionException(m -= 1);
    assertThrown!DimensionException(m == 1);
    assertThrown!DimensionException(m == second);
    assertThrown!DimensionException(m < second);
    assertThrown!DimensionException(m < 1);
}

package:

Dimensions freeze(T)(T exp) @trusted
{
    return cast(Dimensions) exp;
}

// Necessary because of bugs with dim1 == dim2 at compile time.
bool equals(Dimensions dim1, Dimensions dim2) @safe pure
{
    if (dim1.length != dim2.length)
        return false;
    
    foreach (k, v1; dim1)
    {
        auto v2 = k in dim2;
        if (v2 is null || v1 != *v2)
            return false;
    }
    return true;
}
@safe pure unittest
{
    assert(equals(Dimensions.init, Dimensions.init));
    assert(equals(["a": 1, "b": 0], ["a": 1, "b": 0]));
    assert(!equals(["a": 1, "b": 1], ["a": 1, "b": 0]));
    assert(!equals(["a": 1], ["a": 1, "b": 0]));
    assert(!equals(["a": 1, "b": 0], ["a": 1]));
}

Dimensions removeNull(Dimensions dim) @safe pure
{
    int[string] ret;
    foreach (k, v; dim)
        if (v != 0)
            ret[k] = v;
    return ret.freeze;
}
@safe pure unittest
{
    auto dim = ["a": 1, "b": 0, "c": 0, "d": 1].freeze;
    assert(dim.removeNull == ["a": 1, "d": 1].freeze);
}

Dimensions invert(Dimensions dim) @safe pure
{
    int[string] ret;
    foreach (k, v; dim)
    {
        assert(v != 0);
        ret[k] = -v;
    }
    return ret.freeze;
}
@safe pure unittest
{
    auto dim = ["a": 5, "b": -2].freeze;
    assert(dim.invert == ["a": -5, "b": 2].freeze);
}

Dimensions binop(string op)(Dimensions dim1, Dimensions dim2) @safe pure
    if (op == "*")
{
    auto ret = (() @trusted => cast(int[string]) dim1.dup)();
    foreach (k, v2; dim2)
    {
        auto v1 = k in ret;
        if (v1)
            ret[k] = *v1 + v2;
        else
            ret[k] = v2;
    }
    return ret.freeze.removeNull;
}
@safe pure unittest
{
    auto dim1 = ["a": 1, "b": -2].freeze;
    auto dim2 = ["a": -1, "c": 2].freeze;
    assert(binop!"*"(dim1, dim2) == ["b": -2, "c": 2].freeze);
}

Dimensions binop(string op)(Dimensions dim1, Dimensions dim2) @safe pure
    if (op == "/" || op == "%")
{
    return binop!"*"(dim1, dim2.invert);
}
@safe pure unittest
{
    auto dim1 = ["a": 1, "b": -2].freeze;
    auto dim2 = ["a": 1, "c": 2].freeze;
    assert(binop!"/"(dim1, dim2) == ["b": -2, "c": -2].freeze);
}

Dimensions pow(Dimensions dim, int power) @safe pure
{
    if (dim.length == 0 || power == 0)
        return Dimensions.init;
    
    int[string] ret;
    foreach (k, v; dim)
    {
        assert(v != 0);
        ret[k] = v * power;
    }
    return ret.freeze;
}
@safe pure unittest
{
    auto dim = ["a": 5, "b": -2].freeze;
    assert(dim.pow(2) == ["a": 10, "b": -4].freeze);
    assert(dim.pow(0) is null);
}

Dimensions powinverse(Dimensions dim, int n) @safe pure
{
    assert(n != 0);
    int[string] ret;
    foreach (k, v; dim)
    {
        assert(v != 0);
        enforce(v % n == 0, "Dimension error: '%s^%s' is not divisible by %s".format(k, v, n));
        ret[k] = v / n;
    }
    return ret.freeze;
}
@safe pure unittest
{
    auto dim = ["a": 6, "b": -2].freeze;
    assert(dim.powinverse(2) == ["a": 3, "b": -1].freeze);
}

string toString(Dimensions dim) @safe pure
{
    import std.algorithm : filter;
    import std.array : join;
    import std.conv : to;
    
    static string stringize(string symbol, int power) pure
    {
        if (power == 0)
            return null;
        if (power == 1)
            return symbol;
        return symbol ~ "^" ~ to!string(power);
    }
    
    string[] dimstrs;
    foreach (sym, pow; dim)
        dimstrs ~= stringize(sym, pow);
    
    return "[%-(%s %)]".format(dimstrs.filter!"a !is null");
}
unittest
{
    assert(["a": 2, "b": -1, "c": 1, "d": 0].toString == "[a^2 b^-1 c]");
}
