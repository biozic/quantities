/++
This module defines the base types for unit and quantity handling.

Copyright: Copyright 2013-2015, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.base;

import quantities.internal.dimensions;
import std.exception;
import std.format;
import std.string;
import std.traits;

version (unittest)
{
    import std.math : approxEqual;

    // import std.conv : text;
}

/++
A quantity  that can  be represented as  the product  of a number  and a  set of
dimensions. The  number is  stored internally as  a member of  type N,  which is
enforced to  be a built-in  numeric type  (isNumeric!N is true).  The dimensions
are stored as a private struct that  is equivalent to an associative array where
keys are dimension symbols (e.g. "L" for  length, "T" for time, etc.) and values
are dimension exponents.

Units are  just instances  of a  Quantity struct where  the value  is 1  and the
dimensions only  contain one symbol, with  the power 1. For  instance, the meter
unit can be defined using the template `unit` as:
---
enum meter = unit!(double, "L");
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
    static void checkDim(Dimensions dim)()
    {
        static assert(dim == dimensions,
                      "Dimension error: %s is not compatible with %s".format(dim.toString,
                                                                             dimensions.toString));
    }

    static void checkValueType(T)()
    {
        static assert(is(T : valueType),
                      "%s is not implicitly convertible to %s".format(T.stringof,
                                                                      valueType.stringof));
    }

package:
    N _value;
    enum dimensions = dims;

    // Should be a constructor
    // Workaround for @@BUG 5770@@
    // (https://d.puremagic.com/issues/show_bug.cgi?id=5770)
    // "Template constructor bypass access check"
    package static Quantity make(T)(T value) if (isNumeric!T)
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
    static if (dimensions.empty)
    {
        // Gets the internal number of this quantity.
        N get() const
        {
            return _value;
        }

        alias get this;
    }

    /// Gets the base unit of this quantity.
    static Quantity baseUnit()
    {
        return Quantity.make(1);
    }

    // Creates a new quantity from another one with the same dimensions
    this(Q)(Q other) if (isQuantity!Q)
    {
        checkDim!(other.dimensions);
        checkValueType!(Q.valueType);
        _value = other._value;
    }

    // Creates a new dimensionless quantity from a number
    this(T)(T value) if (isNumeric!T && dimensions.empty)
    {
        checkValueType!T;
        _value = value;
    }

    /++
    Gets the _value of this quantity expressed in the given target unit.
    +/
    N value(Q)(Q target) const if (isQuantity!Q)
    {
        checkDim!(target.dimensions);
        checkValueType!(Q.valueType);
        return _value / target._value;
    }

    ///
    pure nothrow @nogc @safe unittest
    {
        enum second = unit!(int, "T");
        enum minute = 60 * second;
        enum hour = 60 * minute;

        auto time = 120 * minute;
        assert(time.value(hour) == 2);
        assert(time.value(minute) == 120);
    }

    /++
    Tests wheter this quantity has the same dimensions as another one.
    +/
    bool isConsistentWith(Q)(Q other) const if (isQuantity!Q)
    {
        enum ret = dimensions == other.dimensions;
        return ret;
    }

    ///
    pure nothrow @nogc @safe unittest
    {
        enum second = unit!(double, "T");
        enum minute = 60 * second;
        enum meter = unit!(double, "L");

        assert(minute.isConsistentWith(second));
        assert(!meter.isConsistentWith(second));
    }

    /++
    Convert a quantity to another one with the same dimensions.
    +/
    Q convert(Q)(Q target) const if (isQuantity!Q)
    {
        return Q.make(_value / target._value);
    }

    ///
    pure nothrow @nogc @safe unittest
    {
        enum second = unit!(int, "T");
        enum minute = 60 * second;

        auto min = 2 * minute;
        auto sec = min.convert(second);
        assert(sec.value(second) == 120);
    }

    /// Overloaded operators.
    /// Only dimensionally correct operations will compile.

    // Cast a quantity to another quantity type with the same dimensions
    Q opCast(Q)() const if (isQuantity!Q)
    {
        checkDim!(Q.dimensions);
        checkValueType!(Q.valueType);
        return Q.make(_value);
    }

    // Cast a dimensionless quantity to a numeric type
    T opCast(T)() const if (isNumeric!T)
    {
        import std.conv;

        checkDim!(Dimensions.init);
        checkValueType!T;
        return _value.to!T;
    }

    // Assign from another quantity
    void opAssign(Q)(Q other) if (isQuantity!Q)
    {
        checkDim!(other.dimensions);
        checkValueType!(Q.valueType);
        _value = other._value;
    }

    // Assign from a numeric value if this quantity is dimensionless
    /// ditto
    void opAssign(T)(T other) if (isNumeric!T)
    {
        checkDim!(Dimensions.init);
        checkValueType!T;
        _value = other;
    }

    // Unary + and -
    /// ditto
    auto opUnary(string op)() const if (op == "+" || op == "-")
    {
        return Quantity.make(mixin(op ~ "_value"));
    }

    // Unary ++ and --
    /// ditto
    auto opUnary(string op)() if (op == "++" || op == "--")
    {
        mixin(op ~ "_value;");
        return this;
    }

    // Add (or substract) two quantities if they share the same dimensions
    /// ditto
    auto opBinary(string op, Q)(Q other) const if (isQuantity!Q && (op == "+" || op == "-"))
    {
        checkDim!(other.dimensions);
        checkValueType!(Q.valueType);
        auto result = mixin("_value" ~ op ~ "other._value");
        return Quantity!(typeof(result), dimensions).make(result);
    }

    // Add (or substract) a dimensionless quantity and a number
    /// ditto
    auto opBinary(string op, T)(T other) const if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDim!(Dimensions.init);
        checkValueType!T;
        return Quantity.make(mixin("_value" ~ op ~ "other"));
    }

    /// ditto
    auto opBinaryRight(string op, T)(T other) const if (isNumeric!T && (op == "+" || op == "-"))
    {
        return opBinary!op(other);
    }

    // Multiply or divide two quantities
    /// ditto
    auto opBinary(string op, Q)(Q other) const if (isQuantity!Q && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!(Q.valueType);
        auto result = mixin("(_value" ~ op ~ "other._value)");
        return Quantity!(typeof(result), dimensions.binop!op(other.dimensions)).make(result);
    }

    // Multiply or divide a quantity by a number
    /// ditto
    auto opBinary(string op, T)(T other) const if (isNumeric!T && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!T;
        auto result = mixin("_value" ~ op ~ "other");
        return Quantity!(typeof(result), dimensions).make(result);
    }

    /// ditto
    auto opBinaryRight(string op, T)(T other) const if (isNumeric!T && op == "*")
    {
        checkValueType!T;
        return this * other;
    }

    /// ditto
    auto opBinaryRight(string op, T)(T other) const if (isNumeric!T && (op == "/" || op == "%"))
    {
        checkValueType!T;
        auto result = mixin("other" ~ op ~ "_value");
        return Quantity!(typeof(result), dimensions.invert()).make(result);
    }

    auto opBinary(string op, T)(T power) const if (op == "^^")
    {
        static assert(false, "Unsupported operator: ^^");
    }

    // Add/sub assign with a quantity that shares the same dimensions
    /// ditto
    void opOpAssign(string op, Q)(Q other) if (isQuantity!Q && (op == "+" || op == "-"))
    {
        checkDim!(other.dimensions);
        checkValueType!(Q.valueType);
        mixin("_value " ~ op ~ "= other._value;");
    }

    // Add/sub assign a number to a dimensionless quantity
    /// ditto
    void opOpAssign(string op, T)(T other) if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDim!(Dimensions.init);
        checkValueType!T;
        mixin("_value " ~ op ~ "= other;");
    }

    // Mul/div assign with a dimensionless quantity
    /// ditto
    void opOpAssign(string op, Q)(Q other) if (isQuantity!Q && (op == "*" || op == "/" || op == "%"))
    {
        Q.checkDim!(Dimensions.init);
        checkValueType!(Q.valueType);
        mixin("_value" ~ op ~ "= other._value;");
    }

    // Mul/div assign with a number
    /// ditto
    void opOpAssign(string op, T)(T other) if (isNumeric!T && (op == "*" || op == "/" || op == "%"))
    {
        checkValueType!T;
        mixin("_value" ~ op ~ "= other;");
    }

    // Exact equality between quantities
    /// ditto
    bool opEquals(Q)(Q other) const if (isQuantity!Q)
    {
        checkDim!(other.dimensions);
        return _value == other._value;
    }

    // Exact equality between a dimensionless quantity and a number
    /// ditto
    bool opEquals(T)(T other) const if (isNumeric!T)
    {
        checkValueType!T;
        checkDim!(Dimensions.init);
        return _value == other;
    }

    // Comparison between two quantities
    /// ditto
    int opCmp(Q)(Q other) const if (isQuantity!Q)
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
    int opCmp(T)(T other) const if (isNumeric!T)
    {
        checkValueType!T;
        checkDim!(Dimensions.init);
        if (_value < other)
            return -1;
        if (_value > other)
            return 1;
        return 0;
    }

    // Default string formatting function
    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        sink.formatValue(_value, fmt);
        sink(" ");
        sink(dimensions.toString);
    }
}

pure nothrow @nogc @safe unittest
{
    enum md = unit!(double, "L");
    enum mr = unit!(real, "L");
    enum mtu = md * mr;
    static assert(is(mtu.valueType == real)); // assert highest precision
    enum mdu = md / mr;
    static assert(is(mdu.valueType == real)); // assert highest precision
    enum mru = md % mr;
    static assert(is(mru.valueType == real)); // assert highest precision
}

pure nothrow @nogc @safe unittest
{
    enum md = unit!(double, "L");
    enum mr = unit!(real, "L");
    enum mpu = md + mr;
    static assert(is(mpu.valueType == real)); // assert highest precision
    enum mmu = md - mr;
    static assert(is(mmu.valueType == real)); // assert highest precision
}

pure nothrow @nogc @safe unittest  // Quantity.baseUnit
{
    enum second = unit!(double, "T");
    enum minute = 60 * second;
    static assert(is(minute.valueType == double));
    assert(minute.baseUnit == second);
}

pure nothrow @nogc @safe unittest  // Quantity constructor
{
    enum second = unit!(double, "T");
    enum minute = 60 * second;
    enum radian = unit!(double, "L") / unit!(double, "L");

    import std.math : approxEqual;

    auto time = typeof(second)(1 * minute);
    assert(time.value(second) == 60);

    auto angle = typeof(radian)(3.14);
    assert(angle.value(radian).approxEqual(3.14));
}

pure nothrow @nogc @safe unittest  // Quantity.alias this
{
    enum radian = unit!(double, "L") / unit!(double, "L");

    static double foo(double d) nothrow @nogc
    {
        return d;
    }

    assert(foo(2 * radian) == 2);
}

pure nothrow @nogc @safe unittest  // Quantity.opCast
{
    enum second = unit!(double, "T");
    enum radian = unit!(double, "L") / unit!(double, "L");

    auto fsec = unit!(float, "T");
    assert((cast(typeof(second)) fsec).value(second) == 1);
    auto angle = 12 * radian;
    assert(cast(double) angle == 12);
}

pure nothrow @nogc @safe unittest  // Quantity.opAssign Q = Q
{
    enum meter = unit!(double, "L");
    enum radian = meter / meter;

    auto length = meter;
    length = 100 * meter;
    assert(length.value(meter) == 100);
    auto angle = radian;
    angle = 2;
    assert(angle.value(radian) == 2);
}

pure nothrow @nogc @safe unittest  // Quantity.opUnary +Q -Q ++Q --Q
{
    enum meter = unit!(double, "L");

    auto length = +meter;
    assert(length == 1 * meter);
    auto length2 = -meter;
    assert(length2 == -1 * meter);

    auto len = ++meter;
    assert(len.value(meter).approxEqual(2));
    len = --meter;
    assert(len.value(meter).approxEqual(0));
    len++;
    assert(len.value(meter).approxEqual(1));
}

pure nothrow @nogc @safe unittest  // Quantity.opBinary Q*N Q/N
{
    enum second = unit!(double, "T");
    import std.math : approxEqual;

    auto time = second * 60;
    assert(time.value(second) == 60);
    auto time2 = second / 2;
    assert(time2.value(second).approxEqual(0.5));
}

pure nothrow @nogc @safe unittest  // Quantity.opBinary Q*Q Q/Q
{
    enum second = unit!(double, "T");
    enum minute = 60 * second;
    enum meter = unit!(double, "L");

    auto hertz = 1 / second;

    auto length = meter * 5;
    auto surface = length * length;
    assert(surface.value(meter * meter) == 5 * 5);
    auto length2 = surface / length;
    assert(length2.value(meter) == 5);

    auto x = minute / second;
    assert(x.rawValue == 60);

    auto y = minute * hertz;
    assert(y.rawValue == 60);
}

pure nothrow @nogc @safe unittest  // Quantity.opBinaryRight N*Q
{
    enum meter = unit!(double, "L");

    auto length = 100 * meter;
    assert(length == meter * 100);
}

pure nothrow @nogc @safe unittest  // Quantity.opBinaryRight N/Q
{
    enum meter = unit!(double, "L");
    import std.math : approxEqual;

    auto x = 1 / (2 * meter);
    assert(x.value(1 / meter).approxEqual(0.5));
}

pure nothrow @nogc @safe unittest  // Quantity.opBinary Q%Q Q%N N%Q
{
    enum meter = unit!(double, "L");

    auto x = 258.1 * meter;
    auto y1 = x % (50 * meter);
    assert((cast(double) y1).approxEqual(8.1));
    auto y2 = x % 50;
    assert(y2.value(meter).approxEqual(8.1));
}

pure nothrow @nogc @safe unittest  // Quantity.opBinary Q+Q Q-Q
{
    enum meter = unit!(double, "L");

    auto length = meter + meter;
    assert(length.value(meter) == 2);
    auto length2 = length - meter;
    assert(length2.value(meter) == 1);
}

pure nothrow @nogc @safe unittest  // Quantity.opBinary Q+N Q-N
{
    enum radian = unit!(double, "L") / unit!(double, "L");

    auto angle = radian + 1;
    assert(angle.value(radian) == 2);
    angle = angle - 1;
    assert(angle.value(radian) == 1);
    angle = 1 + angle;
    assert(angle.value(radian) == 2);
}

pure nothrow @nogc @safe unittest  // Quantity.opOpAssign Q+=Q Q-=Q
{
    enum second = unit!(double, "T");

    auto time = 10 * second;
    time += 50 * second;
    assert(time.value(second).approxEqual(60));
    time -= 40 * second;
    assert(time.value(second).approxEqual(20));
}

pure nothrow @nogc @safe unittest  // Quantity.opBinary Q+N Q-N
{
    enum radian = unit!(double, "L") / unit!(double, "L");

    auto angle = 1 * radian;
    angle += 1;
    assert(angle.value(radian) == 2);
    angle -= 1;
    assert(angle.value(radian) == 1);
}

pure nothrow @nogc @safe unittest  // Quantity.opOpAssign Q*=N Q/=N Q%=N
{
    enum second = unit!(double, "T");

    auto time = 20 * second;
    time *= 2;
    assert(time.value(second).approxEqual(40));
    time /= 4;
    assert(time.value(second).approxEqual(10));
    time %= 3;
    assert(time.value(second).approxEqual(1));
}

pure nothrow @nogc @safe unittest  // Quantity.opOpAssign Q*=N Q/=N Q%=N
{
    enum second = unit!(double, "T");
    enum meter = unit!(double, "L");

    auto time = 20 * second;
    time *= (2 * meter) / meter;
    assert(time.value(second).approxEqual(40));
    time /= (4 * meter) / meter;
    assert(time.value(second).approxEqual(10));
    time %= (3 * meter) / meter;
    assert(time.value(second).approxEqual(1));
}

pure nothrow @nogc @safe unittest  // Quantity.opEquals
{
    enum second = unit!(double, "T");
    enum minute = 60 * second;
    enum radian = unit!(double, "L") / unit!(double, "L");

    assert(1 * minute == 60 * second);
    assert(1 * radian == 1);
}

pure nothrow @nogc @safe unittest  // Quantity.opCmp
{
    enum second = unit!(double, "T");
    enum minute = 60 * second;

    auto hour = 60 * minute;
    assert(second < minute);
    assert(minute <= minute);
    assert(hour > minute);
    assert(hour >= hour);
}

pure nothrow @nogc @safe unittest  // Quantity.opCmp
{
    enum radian = unit!(double, "L") / unit!(double, "L");

    auto angle = 2 * radian;
    assert(angle < 4);
    assert(angle <= 2);
    assert(angle > 1);
    assert(angle >= 2);
}

unittest  // Quantity.toString
{
    enum meter = unit!(double, "L");
    import std.conv : text;

    auto length = 12 * meter;
    assert(length.text == "12 [L]", length.text);
}

pure nothrow @nogc @safe unittest  // Compilation errors for incompatible dimensions
{
    enum second = unit!(double, "T");
    enum meter = unit!(double, "L");

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

pure nothrow @nogc @safe unittest  // immutable Quantity
{
    enum second = unit!(double, "T");
    enum minute = 60 * second;
    enum meter = unit!(double, "L");

    immutable length = 3e8 * meter;
    immutable time = 1 * second;
    immutable speedOfLight = length / time;
    assert(speedOfLight == 3e8 * meter / second);
    assert(speedOfLight > 1 * meter / minute);
}

/// Tests whether T is a quantity type
enum isQuantity(T) = is(Unqual!T == Quantity!X, X...);

/// Creates a new monodimensional unit.
template unit(N, string symbol)
{
    enum dim = Dimensions.mono(symbol);
    enum unit = { return Quantity!(N, dim).make(1); }();
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
template AreConsistent(Q1, Q2) if (isQuantity!Q1 && isQuantity!Q2)
{
    enum AreConsistent = Q1.dimensions == Q2.dimensions;
}

///
pure nothrow @nogc @safe unittest
{
    enum second = unit!(double, "T");
    enum meter = unit!(double, "L");

    alias Speed = typeof(meter / second);
    alias Velocity = typeof((1 / second * meter));
    static assert(AreConsistent!(Speed, Velocity));
}

/++
Creates a new prefix function that multiplies a Quantity by a _factor.
+/
template prefix(alias factor)
{
    alias N = typeof(factor);
    static assert(isNumeric!N, "Incompatible type: " ~ N.stringof);

    auto prefix(Q)(Q base) if (isQuantity!Q)
    {
        return base * factor;
    }
}

///
pure nothrow @nogc @safe unittest
{
    enum meter = unit!(double, "L");

    alias milli = prefix!1e-3;
    assert(milli(meter).value(meter).approxEqual(1e-3));
}
