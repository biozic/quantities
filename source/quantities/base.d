/++
This module defines the base types for unit and quantity handling.

Copyright: Copyright 2013-2015, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.base;

import std.exception;
import std.format;
import std.string;
import std.traits;

version (unittest) 
{
    import std.math : approxEqual;
    // import std.conv : text;
}

/// The type of a set of dimensions.
alias Dimensions = int[string];

/++
A quantity  that can  be represented as  the product  of a number  and a  set of
dimensions. The  number is  stored internally as  a member of  type N,  which is
enforced to be a built-in numeric  type (isNumeric!N is true). The dimensions
are  stored as  an  associative array  where  keys are  symbols  and values  are
integral powers.
For  instance  length and  speed quantities can be stored as:
---
alias Length = Quantity!(double, ["L": 1]);
alias Speed  = Quantity!(double, ["L": 1, "T": -1]);
---
where "L" is the symbol for the length  dimension, "T" is the symbol of the time
dimensions,  and  1   and  -1  are  the  powers  of   those  dimensions  in  the
representation of the quantity.

Units are  just instances  of a  Quantity struct where  the value  is 1  and the
dimensions only  contain one symbol, with  the power 1. For  instance, the meter
unit can be defined using the template `unit` as:
---
enum meter = unit!(double, "L");
static assert(is(typeof(meter) == Quantity!(double, ["L": 1])));
---
The main  quantities compliant with the  international system of units  (SI) are
actually predefined  in  the module  quantities.si.

Any quantity can be expressed as the product  of a number ($(I n)) and a unit of
the right dimensions ($(I U)). For instance:
---
auto size = 9.5 * meter;
auto time = 120 * milli(second);
---
The unit  $(I U)  is not  actually stored along  with the  number in  a Quantity
struct,  only the  dimensions are.  This  is because  the same  quantity can  be
expressed in an  infinity of different units.  The value of $(I n)  is stored as
if the quantity was  expressed in the base units of the  same dimemsions. In the
example above,  $(I n) = 9.5  for the variable size  and $(I n) =  0.120 for the
variable time.

The method `value` can  be used  to  extract the  number  $(I n)  as  if it  was
expressed in  any possible  unit. The user  must pass this  unit to  the method.
This way, the user makes it clear in which unit the value was expressed.
---
auto size = 9.5 * meter;
auto valueMeter      = size.value(meter);        // valueMeter == 9.5
auto valueCentimeter = size.value(centi(meter)); // valueCentimeter == 950
---
Arithmetic operators (+ - * /),  as well as assignment and comparison operators,
are  defined when  the  operations are  dimensionally  consistent, otherwise  an
error occurs at compile-time:
---
auto time = 2 * hour + 17 * minute;
auto frequency = time / second;
time = time + 2 * meter; // Compilation error
---
Any kind  of quantities  and units  can be  defined with  this module,  not just
those  from the  SI. When  a quantity  that is  not predefined  has to  be used,
instead of instantiating the Quantity template  first, it is preferable to start
defining a new base unit (with only  one dimension) using the unit template, and
then the quantity type with the typeof operator:
---
enum euro = unit!"C"; // C for currency
alias Currency = typeof(euro);
assert(is(Currency == Quantity!(double, ["C": 1])));
---
This means that all currencies will be defined with respect to euro.

Params:
    N = The numeric type of the quantity used to store the value internally (e.g. `double`).
    dims = The dimensions of the quantity.
+/
struct Quantity(N, Dimensions dims)
{
    static assert(isNumeric!N, "Incompatible type: " ~ N.stringof);

private:
    N _value;

    static void checkDim(Dimensions dim)()
    {
        static assert(equals(dim, dimensions),
            "Dimension error: %s is not compatible with %s"
            .format(.toString(dim), .toString(dimensions)));
    }
    
    static void checkValueType(T)()
    {
        static assert(is(T : valueType), "%s is not implicitly convertible to %s"
            .format(T.stringof, valueType.stringof));
    }

package:
    // Should be a constructor
    // Workaround for @@BUG 5770@@
    // (https://d.puremagic.com/issues/show_bug.cgi?id=5770)
    // "Template constructor bypass access check"
    package static Quantity make(T)(T value)
        if (isNumeric!T)
    {
        checkValueType!T;
        Quantity ret;
        ret._value = value;
        return ret;
    }
    
    // Gets the internal number of this quantity.
    package N rawValue() const
    {
        return _value;
    }

public:
    /// The type of the underlying numeric value.
    alias valueType = N;

    // Implicitly convert a dimensionless value to the value type
    static if (!dimensions.length)
    {
        // Gets the internal number of this quantity.
        N get() const
        {
            return _value;
        }
        alias get this;
    }

    /// The dimensions of the quantity.
    enum dimensions = dims;

    /// Gets the base unit of this quantity.
    static Quantity baseUnit()
    {
        N one = 1;
        return Quantity.make(one);
    }

    // Creates a new quantity from another one with the same dimensions
    this(Q)(Q other)
        if (isQuantity!Q)
    {
        checkDim!(other.dimensions);
        checkValueType!(Q.valueType);
        _value = other._value;
    }

    // Creates a new dimensionless quantity from a number
    this(T)(T value)
        if (isNumeric!T && dimensions.length == 0)
    {
        checkValueType!T;
        _value = value;
    }

    /++
    Gets the _value of this quantity expressed in the given target unit.
    +/
    N value(Q)(Q target) const
        if (isQuantity!Q)
    {
        checkDim!(target.dimensions);
        checkValueType!(Q.valueType);
        return _value / target._value;
    }
    ///
    pure nothrow @nogc @safe unittest
    {
        import quantities.si : minute, hour;

        auto time = 120 * minute;
        assert(time.value(hour) == 2);
        assert(time.value(minute) == 120);
    }

    /++
    Tests wheter this quantity has the same dimensions as another one.
    +/
    bool isConsistentWith(Q)(Q other) const
        if (isQuantity!Q)
    {
        enum ret = equals(dimensions, other.dimensions);
        return ret;
    }
    ///
    pure nothrow @nogc @safe unittest
    {
        import quantities.si : minute, second, meter;

        assert(minute.isConsistentWith(second));
        assert(!meter.isConsistentWith(second));
    }

    /// Overloaded operators.
    /// Only dimensionally correct operations will compile.

    // Cast a quantity to another quantity type with the same dimensions
    Q opCast(Q)() const
        if (isQuantity!Q)
    {
        checkDim!(Q.dimensions);
        checkValueType!(Q.valueType);
        return Q.make(_value);
    }

    // Cast a dimensionless quantity to a numeric type
    T opCast(T)() const
        if (isNumeric!T)
    {
        checkDim!(Dimensions.init);
        checkValueType!T;
        return _value;
    }


    // Assign from another quantity
    void opAssign(Q)(Q other)
        if (isQuantity!Q)
    {
        checkDim!(other.dimensions);
        checkValueType!(Q.valueType);
        _value = other._value;
    }

    // Assign from a numeric value if this quantity is dimensionless
    /// ditto
    void opAssign(T)(T other)
        if (isNumeric!T)
    {
        checkDim!(Dimensions.init);
        checkValueType!T;
        _value = other;
    }

    // Unary + and -
    /// ditto
    auto opUnary(string op)() const
        if (op == "+" || op == "-")
    {
        return Quantity.make(mixin(op ~ "_value"));
    }
    
    // Unary ++ and --
    /// ditto
    auto opUnary(string op)()
        if (op == "++" || op == "--")
    {
        mixin(op ~ "_value;");
        return this;
    }

    // Add (or substract) two quantities if they share the same dimensions
    /// ditto
    auto opBinary(string op, Q)(Q other) const
        if (isQuantity!Q && (op == "+" || op == "-"))
    {
        checkDim!(other.dimensions);
        checkValueType!(Q.valueType);
        return Quantity.make(mixin("_value" ~ op ~ "other._value"));
    }

    // Add (or substract) a dimensionless quantity and a number
    /// ditto
    auto opBinary(string op, T)(T other) const
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDim!(Dimensions.init);
        checkValueType!T;
        return Quantity.make(mixin("_value" ~ op ~ "other"));
    }

    /// ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        return opBinary!op(other);
    }

    // Multiply or divide two quantities
    /// ditto
    auto opBinary(string op, Q)(Q other) const
        if (isQuantity!Q && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!(Q.valueType);
        return Quantity!(N, binop!op(dimensions, other.dimensions))
            .make(mixin("(_value" ~ op ~ "other._value)"));
    }

    // Multiply or divide a quantity by a number
    /// ditto
    auto opBinary(string op, T)(T other) const
        if (isNumeric!T && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!T;
        return Quantity.make(mixin("_value" ~ op ~ "other"));
    }

    /// ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && op == "*")
    {
        checkValueType!T;
        return this * other;
    }

    /// ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && (op == "/" || op == "%"))
    {
        checkValueType!T;
        return Quantity!(N, invert(dimensions)).make(mixin("other" ~ op ~ "_value"));
    }

    auto opBinary(string op, T)(T power) const
        if (op == "^^")
    {
        static assert(false, "Unsupporter operator: ^^");
    }

    // Add/sub assign with a quantity that shares the same dimensions
    /// ditto
    void opOpAssign(string op, Q)(Q other)
        if (isQuantity!Q && (op == "+" || op == "-"))
    {
        checkDim!(other.dimensions);
        checkValueType!(Q.valueType);
        mixin("_value " ~ op ~ "= other._value;");
    }

    // Add/sub assign a number to a dimensionless quantity
    /// ditto
    void opOpAssign(string op, T)(T other)
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDim!(Dimensions.init);
        checkValueType!T;
        mixin("_value " ~ op ~ "= other;");
    }

    // Mul/div assign with a dimensionless quantity
    /// ditto
    void opOpAssign(string op, Q)(Q other)
        if (isQuantity!Q && (op == "*" || op == "/" || op == "%"))
    {
        Q.checkDim!(Dimensions.init);
        checkValueType!(Q.valueType);
        mixin("_value" ~ op ~ "= other._value;");
    }

    // Mul/div assign with a number
    /// ditto
    void opOpAssign(string op, T)(T other)
        if (isNumeric!T && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!T;
        mixin("_value" ~ op ~ "= other;");
    }

    // Exact equality between quantities
    /// ditto
    bool opEquals(Q)(Q other) const
        if (isQuantity!Q)
    {
        checkDim!(other.dimensions);
        return _value == other._value;
    }

    // Exact equality between a dimensionless quantity and a number
    /// ditto
    bool opEquals(T)(T other) const
        if (isNumeric!T)
    {
        checkValueType!T;
        checkDim!(Dimensions.init);
        return _value == other;
    }

    // Comparison between two quantities
    /// ditto
    int opCmp(Q)(Q other) const
        if (isQuantity!Q)
    {
        checkDim!(other.dimensions);
        if (_value == other._value)
            return 0;
        if (_value < other._value)
            return -1;
        return 1;
    }

    // Comparison between a dimensionless quantity and a number
    /// ditto
    int opCmp(T)(T other) const
        if (isNumeric!T)
    {
        checkValueType!T;
        checkDim!(Dimensions.init);
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

pure nothrow @nogc @safe unittest // Quantity.baseUnit
{
    import quantities.si : minute, second;

    assert(minute.baseUnit == second);
}

pure nothrow @nogc @safe unittest // Quantity constructor
{
    import quantities.si : minute, second, radian;

    auto time = typeof(second)(1 * minute);
    assert(time.value(second) == 60);


    auto angle = typeof(radian)(3.14);
    assert(angle.value(radian) == 3.14);
}

pure nothrow @nogc @safe unittest // QVariant.alias this
{
    import quantities.si : radian;

    static double foo(double d) nothrow @nogc { return d; }
    assert(foo(2 * radian) == 2);
}

pure nothrow @nogc @safe unittest // Quantity.opCast
{
    import quantities.si : second, radian;

    auto fsec = unit!(float, "T");
    assert((cast(typeof(second)) fsec).value(second) == 1);
    auto angle = 12 * radian;
    assert(cast(double) angle == 12);
}

pure nothrow @nogc @safe unittest // Quantity.opAssign Q = Q
{
    import quantities.si : meter, radian;

    auto length = meter;
    length = 100 * meter;
    assert(length.value(meter) == 100);
    auto angle = radian;
    angle = 2;
    assert(angle.value(radian) == 2);
}

pure nothrow @nogc @safe unittest // Quantity.opUnary +Q -Q ++Q --Q
{
    import quantities.si : meter;

    auto length = + meter;
    assert(length == 1 * meter);
    auto length2 = - meter;
    assert(length2 == -1 * meter);
    
    auto len = ++meter;
    assert(len.value(meter).approxEqual(2));
    len = --meter;
    assert(len.value(meter).approxEqual(0));
    len++;
    assert(len.value(meter).approxEqual(1));    
}

pure nothrow @nogc @safe unittest // Quantity.opBinary Q*N Q/N
{
    import quantities.si : second;

    auto time = second * 60;
    assert(time.value(second) == 60);
    auto time2 = second / 2;
    assert(time2.value(second) == 1.0/2);
}

pure nothrow @nogc @safe unittest // Quantity.opBinary Q*Q Q/Q
{
    import quantities.si : meter, minute, second;

    auto hertz = 1 / second;

    auto length = meter * 5;
    auto surface = length * length;
    assert(surface.value(meter * meter) == 5*5);
    auto length2 = surface / length;
    assert(length2.value(meter) == 5);

    auto x = minute / second;
    assert(x.rawValue == 60);

    auto y = minute * hertz;
    assert(y.rawValue == 60);
}

pure nothrow @nogc @safe unittest // Quantity.opBinaryRight N*Q
{
    import quantities.si : meter;

    auto length = 100 * meter;
    assert(length == meter * 100);
}

pure nothrow @nogc @safe  unittest // Quantity.opBinaryRight N/Q
{
    import quantities.si : meter;

    auto x = 1 / (2 * meter);
    assert(x.value(1/meter) == 1.0/2);
}

pure nothrow @nogc @safe unittest // Quantity.opBinary Q%Q Q%N N%Q
{
    import quantities.si : meter;

    auto x = 258.1 * meter;
    auto y1 = x % (50 * meter);
    assert((cast(double) y1).approxEqual(8.1));
    auto y2 = x % 50;
    assert(y2.value(meter).approxEqual(8.1));
}

pure nothrow @nogc @safe unittest // Quantity.opBinary Q+Q Q-Q
{
    import quantities.si : meter;
    
    auto length = meter + meter;
    assert(length.value(meter) == 2);
    auto length2 = length - meter;
    assert(length2.value(meter) == 1);
}

pure nothrow @nogc @safe unittest // Quantity.opBinary Q+N Q-N
{
    import quantities.si : radian;
    
    auto angle = radian + 1;
    assert(angle.value(radian) == 2);
    angle = angle - 1;
    assert(angle.value(radian) == 1);
    angle = 1 + angle;
    assert(angle.value(radian) == 2);
}

pure nothrow @nogc @safe unittest // Quantity.opOpAssign Q+=Q Q-=Q
{
    import quantities.si : second;

    auto time = 10 * second;
    time += 50 * second;
    assert(time.value(second).approxEqual(60));
    time -= 40 * second;
    assert(time.value(second).approxEqual(20));
}

pure nothrow @nogc @safe unittest // Quantity.opBinary Q+N Q-N
{
    import quantities.si : radian;
    
    auto angle = 1 * radian;
    angle += 1;
    assert(angle.value(radian) == 2);
    angle -= 1;
    assert(angle.value(radian) == 1);
}

pure nothrow @nogc @safe unittest // Quantity.opOpAssign Q*=N Q/=N Q%=N
{
    import quantities.si : second;

    auto time = 20 * second;
    time *= 2;
    assert(time.value(second).approxEqual(40));
    time /= 4;
    assert(time.value(second).approxEqual(10));
    time %= 3;
    assert(time.value(second).approxEqual(1));
}

pure nothrow @nogc @safe unittest // Quantity.opOpAssign Q*=N Q/=N Q%=N
{
    import quantities.si : meter, second;
    
    auto time = 20 * second;
    time *= (2 * meter) / meter;
    assert(time.value(second).approxEqual(40));
    time /= (4 * meter) / meter;
    assert(time.value(second).approxEqual(10));
    time %= (3 * meter) / meter;
    assert(time.value(second).approxEqual(1));
}

pure nothrow @nogc @safe unittest // Quantity.opEquals
{
    import quantities.si : radian, minute, second;

    assert(1 * minute == 60 * second);
    assert(1 * radian == 1);
}

pure nothrow @nogc @safe unittest // Quantity.opCmp
{
    import quantities.si : minute, second;

    auto hour = 60 * minute;
    assert(second < minute);
    assert(minute <= minute);
    assert(hour > minute);
    assert(hour >= hour);
}

pure nothrow @nogc @safe unittest // Quantity.opCmp
{
    import quantities.si : radian;
    
    auto angle = 2 * radian;
    assert(angle < 4);
    assert(angle <= 2);
    assert(angle > 1);
    assert(angle >= 2);
}

unittest // Quantity.toString
{
    import quantities.si : meter;
    import std.conv : text;

    auto length = 12 * meter;
    assert(length.text == "12 [L]", length.text);
}

pure nothrow @nogc @safe unittest // Compilation errors for incompatible dimensions
{
    import quantities.si : meter, second;

    auto m = meter;
    static assert(!__traits(compiles, m.value(second)));
    static assert(!__traits(compiles, m = second));
    static assert(!__traits(compiles, m + second));
    static assert(!__traits(compiles, m - second));
    static assert(!__traits(compiles, m + 1));
    static assert(!__traits(compiles, m - 1));
    static assert(!__traits(compiles, 1 + m));
    static assert(!__traits(compiles, 1 - m));
    static assert(!__traits(compiles, m += second));
    static assert(!__traits(compiles, m -= second));
    static assert(!__traits(compiles, m *= second));
    static assert(!__traits(compiles, m /= second));
    static assert(!__traits(compiles, m *= meter));
    static assert(!__traits(compiles, m /= meter));
    static assert(!__traits(compiles, m += 1));
    static assert(!__traits(compiles, m -= 1));
    static assert(!__traits(compiles, m == 1));
    static assert(!__traits(compiles, m == second));
    static assert(!__traits(compiles, m < second));
    static assert(!__traits(compiles, m < 1));
}

pure nothrow @nogc @safe unittest // immutable Quantity
{
    import quantities.si : meter, minute, second;

    immutable length = 3e8 * meter;
    immutable time = 1 * second;
    immutable speedOfLight = length / time;
    assert(speedOfLight == 3e8 * meter / second);
    assert(speedOfLight > 1 * meter / minute);
}

/// Tests whether T is a quantity type
template isQuantity(T)
{
    static if (is(Unqual!T == Quantity!X, X...))
        enum isQuantity = true;
    else
        enum isQuantity = false;
}

/// Creates a new monodimensional unit.
template unit(N, string symbol)
{
    static assert(isNumeric!N, "Incompatible type: " ~ N.stringof);
    enum N one = 1;
    enum unit = Quantity!(N, [symbol: 1]).make(one);
}
///
pure nothrow @nogc @safe unittest
{
    auto euro = unit!(double, "C"); // C for Currency
    assert(isQuantity!(typeof(euro)));
    auto dollar = euro / 1.35;
    assert((1.35 * dollar).value(euro).approxEqual(1));
}

/// Check that two quantity types are dimensionally consistent.
template AreConsistent(Q1, Q2)
    if (isQuantity!Q1 && isQuantity!Q2)
{
    enum AreConsistent = Q1.dimensions == Q2.dimensions;
}
///
pure nothrow @nogc @safe unittest
{
    import quantities.si : meter, second;

    alias Speed = typeof(meter/second);
    alias Velocity = typeof((1/second * meter));
    static assert(AreConsistent!(Speed, Velocity));
}

/++
Creates a new prefix function that mutlpy a Quantity by _factor factor.
+/
template prefix(alias factor)
{
    alias N = typeof(factor);
    static assert(isNumeric!N, "Incompatible type: " ~ N.stringof);

    auto prefix(Q)(Q base)
        if (isQuantity!Q)
    {
        return base * factor;
    }
}
///
pure nothrow @nogc @safe unittest
{
    import quantities.si : meter;

    alias milli = prefix!1e-3;
    assert(milli(meter).value(meter).approxEqual(1e-3));
}

package:

Dimensions dimdup(in Dimensions dim) @trusted pure
{
    return cast(Dimensions) dim.dup;
}

// Necessary because of bugs with dim1 == dim2 at compile time.
bool equals(in Dimensions dim1, in Dimensions dim2) pure @safe
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
pure @safe unittest
{
    assert(equals(Dimensions.init, Dimensions.init));
    assert(equals(["a": 1, "b": 0], ["a": 1, "b": 0]));
    assert(!equals(["a": 1, "b": 1], ["a": 1, "b": 0]));
    assert(!equals(["a": 1], ["a": 1, "b": 0]));
    assert(!equals(["a": 1, "b": 0], ["a": 1]));
}

Dimensions removeNull(in Dimensions dim) pure @safe
{
    Dimensions ret;
    foreach (k, v; dim)
        if (v != 0)
            ret[k] = v;
    return ret;
}
pure @safe unittest
{
    auto dim = ["a": 1, "b": 0, "c": 0, "d": 1];
    assert(dim.removeNull == ["a": 1, "d": 1]);
}

Dimensions invert(in Dimensions dim) pure @safe
{
    Dimensions ret;
    foreach (k, v; dim)
    {
        assert(v != 0);
        ret[k] = -v;
    }
    return ret;
}
pure @safe unittest
{
    auto dim = ["a": 5, "b": -2];
    assert(dim.invert == ["a": -5, "b": 2]);
}

Dimensions binop(string op)(in Dimensions dim1, in Dimensions dim2) pure @safe
    if (op == "*")
{
    auto ret = dim1.dimdup;
    foreach (k, v2; dim2)
    {
        auto v1 = k in ret;
        if (v1)
            ret[k] = *v1 + v2;
        else
            ret[k] = v2;
    }
    return ret.removeNull;
}
pure @safe unittest
{
    auto dim1 = ["a": 1, "b": -2];
    auto dim2 = ["a": -1, "c": 2];
    assert(binop!"*"(dim1, dim2) == ["b": -2, "c": 2]);
}

Dimensions binop(string op)(in Dimensions dim1, in Dimensions dim2) pure @safe
    if (op == "/" || op == "%")
{
    return binop!"*"(dim1, dim2.invert);
}
pure @safe unittest
{
    auto dim1 = ["a": 1, "b": -2];
    auto dim2 = ["a": 1, "c": 2];
    assert(binop!"/"(dim1, dim2) == ["b": -2, "c": -2]);
}

Dimensions pow(in Dimensions dim, int power) pure @safe
{
    if (dim.length == 0 || power == 0)
        return Dimensions.init;

    Dimensions ret;
    foreach (k, v; dim)
    {
        assert(v != 0);
        ret[k] = v * power;
    }
    return ret;
}
pure @safe unittest
{
    auto dim = ["a": 5, "b": -2];
    assert(dim.pow(2) == ["a": 10, "b": -4]);
    assert(dim.pow(0) is null);
}

Dimensions powinverse(in Dimensions dim, int n) pure @safe
{
    assert(n != 0);
    Dimensions ret;
    foreach (k, v; dim)
    {
        assert(v != 0);
        enforce(v % n == 0, "Dimension error: '%s^%s' is not divisible by %s".format(k, v, n));
        ret[k] = v / n;
    }
    return ret;
}
pure @safe unittest
{
    auto dim = ["a": 6, "b": -2];
    assert(dim.powinverse(2) == ["a": 3, "b": -1]);
}

string toString(in Dimensions dim) pure @safe
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
