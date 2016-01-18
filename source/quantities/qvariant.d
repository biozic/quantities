/++
This module defines dimensionnaly variant quantities.

Copyright: Copyright 2013-2015, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.qvariant;

import quantities.internal.dimensions;
import quantities.base;
import quantities.parsing : DimensionException;
import std.exception;
import std.format;
import std.string;
import std.traits;

version (unittest) import std.math : approxEqual;

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
    static assert(isNumeric!N, "Incompatible type: " ~ N.stringof);

private:
    void checkDim(in Dimensions dim) const
    {
        enforceEx!DimensionException(dim == dimensions,
            "Dimension error: %s is not compatible with %s"
            .format(dim.toString, dimensions.toString));
    }
    
    static void checkValueType(T)()
    {
        static assert(is(T : valueType), "%s is not implicitly convertible to %s"
            .format(T.stringof, valueType.stringof));
    }
    
package:
    N _value;
    Dimensions dimensions;
    
    // Should be a constructor
    // Workaround for @@BUG 5770@@
    // (https://d.puremagic.com/issues/show_bug.cgi?id=5770)
    // "Template constructor bypass access check"
    static QVariant make(T)(T value, in Dimensions dim)
        if (isNumeric!T)
    {
        checkValueType!T;
        QVariant result = void;
        result._value = value;
        // The cast if safe: dim is a unique duplicate
        result.dimensions = cast(Dimensions) dim;
        return result;
    }
    
    // Gets the internal number of this quantity.
    N rawValue() const
    {
        return _value;
    }

public:
    alias valueType = N;
    
    // Gets the base unit of this quantity.
    QVariant baseUnit()
    {
        return QVariant.make(1, dimensions);
    }

    // Creates a new quantity from another one with the same dimensions
    this(Q)(Q other)
        if (isQVariant!Q || isQuantity!Q)
    {
        checkValueType!(Q.valueType);
        _value = other.rawValue;
        dimensions = other.dimensions;
    }

    // Creates a new dimensionless quantity from a number
    this(T)(T value)
        if (isNumeric!T)
    {
        checkValueType!T;
        dimensions = Dimensions.init;
        _value = value;
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
        return _value / target.rawValue;
    }
    //
    unittest
    {
        enum minute = unit!(int, "T");
        enum hour = 60 * minute;

        QVariant!double time = 120 * minute.qVariant;
        assert(time.value(hour) == 2);
        assert(time.value(minute) == 120);
    }

    /+
    Tests wheter this quantity has the same dimensions as another one.
    +/
    bool isConsistentWith(Q)(Q other) const
        if (isQVariant!Q || isQuantity!Q)
    {
        return dimensions == other.dimensions;
    }
    //
    unittest
    {
        enum second = unit!(double, "T");
        enum minute = 60 * second;
        enum meter = unit!(double, "L");

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
        if (isNumeric!T)
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
        checkValueType!(Q.valueType);
        dimensions = other.dimensions;
        _value = other.rawValue;
    }

    // Assign from a numeric value if this quantity is dimensionless
    // ditto
    void opAssign(T)(T other)
        if (isNumeric!T)
    {
        checkValueType!T;
        dimensions = Dimensions.init;
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
        return QVariant.make(mixin("_value" ~ op ~ "other.rawValue"), dimensions);
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
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDim(Dimensions.init);
        checkValueType!T;
        return QVariant.make(mixin("_value" ~ op ~ "other"), dimensions);
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        return opBinary!op(other);
    }

    // Multiply or divide two quantities
    // ditto
    auto opBinary(string op, Q)(Q other) const
        if ((isQVariant!Q || isQuantity!Q) && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!(Q.valueType);
        return QVariant.make(mixin("(_value" ~ op ~ "other.rawValue)"),
            dimensions.binop!op(other.dimensions));
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
        if (isNumeric!T && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!T;
        return QVariant.make(mixin("_value" ~ op ~ "other"), dimensions);
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && op == "*")
    {
        checkValueType!T;
        return this * other;
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && (op == "/" || op == "%"))
    {
        checkValueType!T;
        return QVariant.make(mixin("other" ~ op ~ "_value"), dimensions.invert());
    }

    // ditto
    auto opBinary(string op, T)(T power) const
        if (op == "^^")
    {
        if (__ctfe)
            assert(false, "QVariant operator ^^ is not supported at compile-time");

        checkValueType!T;
        return QVariant.make(_value^^power, dimensions.pow(power));
    }

    // Add/sub assign with a quantity that shares the same dimensions
    // ditto
    void opOpAssign(string op, Q)(Q other)
        if ((isQVariant!Q || isQuantity!Q) && (op == "+" || op == "-"))
    {
        checkDim(other.dimensions);
        checkValueType!(Q.valueType);
        mixin("_value " ~ op ~ "= other.rawValue;");
    }

    // Add/sub assign a number to a dimensionless quantity
    // ditto
    void opOpAssign(string op, T)(T other)
        if (isNumeric!T && (op == "+" || op == "-"))
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
        checkValueType!(Q.valueType);
        mixin("_value" ~ op ~ "= other.rawValue;");
        dimensions = dimensions.binop!op(other.dimensions);
    }

    // Mul/div assign with a number
    // ditto
    void opOpAssign(string op, T)(T other)
        if (isNumeric!T && (op == "*" || op == "/" || op == "%"))
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
        return _value == other.rawValue;
    }

    // Exact equality between a dimensionless quantity and a number
    // ditto
    bool opEquals(T)(T other) const
        if (isNumeric!T)
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
        if (_value == other.rawValue)
            return 0;
        if (_value < other.rawValue)
            return -1;
        return 1;
    }

    // Comparison between a dimensionless quantity and a number
    // ditto
    int opCmp(T)(T other) const
        if (isNumeric!T)
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
    return QVariant!(Q.valueType).make(quantity.rawValue, quantity.dimensions);
}
///
unittest
{
    enum second = unit!(double, "T");
    enum meter = unit!(double, "L");

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

unittest // QVariant constructor
{
    enum second = unit!(double, "T");
    enum minute = 60 * second;
    enum radian = unit!(double, "L") / unit!(double, "L");

    QVariant!double time = typeof(second)(1 * minute);
    assert(time.value(second) == 60);
    assert(time.baseUnit == qVariant(second));

    QVariant!double angle = 2;
    assert(angle.value(radian) == 2);
}

unittest // QVariant.alias this
{
    enum radian = unit!(double, "L") / unit!(double, "L");

    static double foo(double d) { return d; }
    assert(foo(2 * qVariant(radian)) == 2);
}

unittest // QVariant.opCast
{
    enum meter = unit!(double, "L");
    enum radian = meter / meter;
    alias Angle = typeof(radian);
   
    auto angle = cast(Angle) (12 * radian.qVariant);
    assert(angle.value(radian) == 12);

    QVariant!double angle2 = 12 * radian;
    assert(cast(double) angle2 == 12);
}

unittest // QVariant.opAssign Q = Q
{
    enum meter = unit!(double, "L");
    enum radian = meter / meter;
    enum second = unit!(double, "T");

    QVariant!double var = meter;
    var = 100 * meter;
    assert(var.value(meter) == 100);

    var /= 5 * second;
    assert(var.value(meter/second).approxEqual(20));

    var = 3.14 * radian;
}

unittest // QVariant.opAssign Q = N
{
    enum radian = unit!(double, "L") / unit!(double, "L");

    QVariant!double angle = radian;
    angle = 2;
    assert(angle.value(radian) == 2);
}

unittest // QVariant.opUnary +Q -Q ++Q --Q
{
    enum meter = unit!(double, "L");

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
    len++;
    assert(len.value(meter).approxEqual(2));
}

unittest // QVariant.opBinary Q*N Q/N
{
    enum second = unit!(double, "T");

    QVariant!double time = second * 60;
    assert(time.value(second) == 60);
    QVariant!double time2 = second / 2;
    assert(time2.value(second) == 1.0/2);
}

unittest // QVariant.opBinary Q+Q Q-Q
{
    enum meter = unit!(double, "L");

    QVariant!double length = meter + meter;
    assert(length.value(meter) == 2);
    QVariant!double length2 = length - meter;
    assert(length2.value(meter) == 1);
}

unittest // QVariant.opBinary Q+N Q-N
{
    enum radian = unit!(double, "L") / unit!(double, "L");
    
    QVariant!double angle = radian + 1;
    assert(angle.value(radian) == 2);
    QVariant!double angle2 = angle - 1;
    assert(angle2.value(radian) == 1);
}

unittest // QVariant.opBinary Q*Q Q/Q
{
    enum meter = unit!(double, "L");
    enum second = unit!(double, "T");
    enum minute = 60 * second;

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

unittest // QVariant.opBinaryRight N*Q
{
    enum meter = unit!(double, "L");

    QVariant!double length = 100 * meter;
    assert(length == meter * 100);
}

unittest // QVariant.opBinaryRight N/Q
{
    enum meter = unit!(double, "L");

    QVariant!double x = 1 / (2 * meter);
    assert(x.value(1/meter) == 1.0/2);
}

unittest // QVariant.opBinary Q%Q Q%N N%Q
{
    enum meter = unit!(double, "L");

    QVariant!double x = 258.1 * meter;
    QVariant!double y1 = x % (50 * meter);
    assert((cast(double) y1).approxEqual(8.1));
    QVariant!double y2 = x % 50;
    assert(y2.value(meter).approxEqual(8.1));
}

unittest // QVariant.opBinary Q^^N
{
    enum meter = unit!(double, "L");

    QVariant!double x = 2 * meter;
    assert((x^^3).value(meter * meter * meter).approxEqual(8));
}

unittest // QVariant.opOpAssign Q+=Q Q-=Q
{
    enum second = unit!(double, "T");

    QVariant!double time = 10 * second;
    time += 50 * second;
    assert(time.value(second).approxEqual(60));
    time -= 40 * second;
    assert(time.value(second).approxEqual(20));
}

unittest // QVariant.opOpAssign Q*=N Q/=N Q%=N
{
    enum second = unit!(double, "T");

    QVariant!double time = 20 * second;
    time *= 2;
    assert(time.value(second).approxEqual(40));
    time /= 4;
    assert(time.value(second).approxEqual(10));
    time %= 3;
    assert(time.value(second).approxEqual(1));
}

unittest // QVariant.opEquals
{
    enum meter = unit!(double, "L");
    enum radian = meter / meter;
    enum second = unit!(double, "T");
    enum minute = 60 * second;

    assert(qVariant(1 * minute) == qVariant(60 * second));
    assert(qVariant((1 / second) * meter) == qVariant(meter / second));
    assert(radian.qVariant == 1);
}

unittest // QVariant.opCmp
{
    enum second = unit!(double, "T");
    enum minute = 60 * second;

    QVariant!double hour = 60 * minute;
    assert(second.qVariant < minute.qVariant);
    assert(minute.qVariant <= minute.qVariant);
    assert(hour > minute);
    assert(hour >= hour);
}

unittest // Quantity.opCmp
{
    enum radian = unit!(double, "L") / unit!(double, "L");
    
    QVariant!double angle = 2 * radian;
    assert(angle < 4);
    assert(angle <= 2);
    assert(angle > 1);
    assert(angle >= 2);
}

unittest // Quantity.toString
{
    enum meter = unit!(double, "L");
    import std.conv : text;

    QVariant!double length = 12 * meter;
    assert(length.text == "12 [L]", length.text);
}

unittest // Exceptions for incompatible dimensions
{
    enum meter = unit!(double, "L");
    enum second = unit!(double, "T");

    import std.exception;

    QVariant!double m = meter;
    assertThrown!DimensionException(m.value(second));
    assertThrown!DimensionException(m + second);
    assertThrown!DimensionException(m - second);
    assertThrown!DimensionException(m + 1);
    assertThrown!DimensionException(m - 1);
    assertThrown!DimensionException(1 + m);
    assertThrown!DimensionException(1 - m);
    assertThrown!DimensionException(m += second);
    assertThrown!DimensionException(m -= second);
    assertThrown!DimensionException(m += 1);
    assertThrown!DimensionException(m -= 1);
    assertThrown!DimensionException(m == 1);
    assertThrown!DimensionException(m == second);
    assertThrown!DimensionException(m < second);
    assertThrown!DimensionException(m < 1);
}

unittest // Compile-time
{
    enum meter = unit!(double, "L");
    enum second = unit!(double, "T");
    enum radian = meter / meter;
        
    enum length = 100 * meter.qVariant;
    enum time = 5 * second.qVariant;
    enum speed = length / time;
    enum val = speed.value(meter/second);
    static assert(val.approxEqual(20));
}