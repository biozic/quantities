// Written in the D programming language
/++
This module defines the base types for unit and quantity handling.

Each  quantity can  be represented  as the  product  of a  number and  a set  of
dimensions,  and  the struct  Quantity  has  this  role.  The number  is  stored
internally as  a member of type  N, which is  enforced to be a  built-in numeric
type  (isNumeric!N is  true). The  dimensions are stored as an associative array
where keys are symbols and values are integral powers.
For  instance  length and  speed quantities can be stored as:
---
alias Length = Quantity!(double, ["L": 1]);
alias Speed  = Quantity!(double, ["L": 1, "T": -1]);
---
where "L" is the symbol for the length  dimension, "T" is the symbol of the time
dimensions,  and  1   and  -1  are  the  powers  of   those  dimensions  in  the
representation of the quantity.

The main  quantities compliant with the  international system of units  (SI) are
predefined  in  the module  quantities.si.  In  the  same  way, units  are  just
instances of  a Quantity struct  where the number is  1 and the  dimensions only
contain  one  symbol,  with  the  power  1. For  instance,  the  meter  unit  is
predefined as something equivalent to:
---
enum meter = Quantity!(double, ["L": 1])(1.0);
---
(note that  the constructor  used here  has the  package access  protection: new
units should be defined with the unit template of this module).

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

The  value method  can  be used  to  extract the  number  $(I n)  as  if it  was
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
those  from the  SI. The  SI quantities  and units  are in  fact defined  in the
module quantities.si.  When a quantity  that is not  predefined has to  be used,
instead of instantiating the Quantity template  first, it is preferable to start
defining a new base unit (with only  one dimension) using the unit template, and
then the quantity type with the typeof operator:
---
enum euro = unit!"C"; // C for currency
alias Currency = typeof(euro);
assert(is(Currency == Quantity!(double, ["C": 1])));
---
This means that all currencies will be defined with respect to euro.

Copyright: Copyright 2013-2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.base;

import std.exception;
import std.format;
import std.string;
import std.traits;
import std.typetuple;

version (unittest)
{
	import std.math : approxEqual;

	enum second = unit!(double, "T");
	enum minute = 60 * second;
	enum hour = 60 * minute;
	enum meter = unit!(double, "L");
	enum radian = Quantity!(double, Dimensions.init).make(1);
}

template isNumberLike(N)
{
    N n1;
    N n2;
    enum isNumberLike = !isQuantity!N
        && __traits(compiles, { return -n1 + (+n2); })
        && __traits(compiles, { return n1 + n2; })
        && __traits(compiles, { return n1 - n2; })
        && __traits(compiles, { return n1 * n2; })
        && __traits(compiles, { return n1 / n2; })
        && __traits(compiles, { n1 = 1; })
        && __traits(compiles, { return cast(const) n1 + n2; } );
}
unittest
{
    static assert(isNumberLike!real);
    static assert(isNumberLike!int);
    static assert(!isNumberLike!string);

    import std.bigint, std.typecons;
    static assert(isNumberLike!BigInt);
    static assert(isNumberLike!(RefCounted!real));
}

alias Dimensions = int[string];

/++
A quantity that can be expressed as the product of a number and a set of dimensions.
+/
struct Quantity(N, Dimensions dims)
{
    static assert(isNumberLike!N, "Incompatible type: " ~ N.stringof);

    /// The type of the underlying numeric value.
    alias valueType = N;

    // The payload
    private N _value;

    /// The dimension tuple of the quantity.
    enum dimensions = dims;

	private {
	    template checkDim(string dim)
	    {
	        enum checkDim = `static assert(equals(` ~ dim ~ `, dimensions),
	                "Dimension error: [%s] is not compatible with [%s]"
	                .format(.toString(` ~ dim ~ `), .toString(dimensions)));`;
	    }

	    template checkValueType(string type)
	    {
			enum checkValueType = `static assert(is(` ~ type ~ ` : N),
	                "%s is not implicitly convertible to %s"
	                .format(` ~ type ~ `.stringof, N.stringof));`;
	    }
	}

    /// Gets the base unit of this quantity.
    static @property Quantity baseUnit()
    {
        N one = 1;
        return Quantity.make(one);
    }

    // Creates a new quantity from another one with the same dimensions
    this(Q)(Q other)
        if (isQuantity!Q)
    {
        mixin(checkDim!"other.dimensions");
        mixin(checkValueType!"Q.valueType");
        _value = other._value;
    }

    // Creates a new dimensionless quantity from a number
    this(T)(T value)
        if (!isQuantity!T && dimensions.length == 0)
    {
        mixin(checkValueType!"T");
        _value = value;
    }

    // Should be a constructor
    // Workaround for @@BUG 5770@@
    // (https://d.puremagic.com/issues/show_bug.cgi?id=5770)
    // "Template constructor bypass access check"
    package static Quantity make(T)(T value)
        if (!isQuantity!T)
    {
        mixin(checkValueType!"T");
        Quantity ret;
        ret._value = value;
        return ret;
    }

	// Gets the internal number of this quantity.
    N rawValue() const
    {
        return _value;
    }
    // Implicitly convert a dimensionless value to the value type
	static if (!dimensions.length)
        alias rawValue this;

    /++
    Gets the _value of this quantity expressed in the given target unit.
    +/
    N value(Q)(Q target) const
        if (isQuantity!Q)
    {
        mixin(checkDim!"target.dimensions");
        mixin(checkValueType!"Q.valueType");
        return _value / target._value;
    }
    ///
    unittest
    {
        // import quantities.si : minute, hour;
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
    unittest
    {
        // import quantities.si : minute, second, meter;
        assert(minute.isConsistentWith(second));
        assert(!meter.isConsistentWith(second));
    }

    /// Cast a quantity to another quantity type with the same dimensions
    Q opCast(Q)() const
        if (isQuantity!Q)
    {
        mixin(checkDim!"Q.dimensions");
        mixin(checkValueType!"Q.valueType");
        return store!(Q.valueType);
    }

    /// Cast a dimensionless quantity to a numeric type
    T opCast(T)() const
        if (!isQuantity!T)
    {
        mixin(checkDim!"Dimensions.init");
        mixin(checkValueType!"T");
        return _value;
    }

    /// Overloaded operators.
    /// Only dimensionally correct operations will compile.

    // Assign from another quantity
    void opAssign(Q)(Q other)
        if (isQuantity!Q)
    {
        mixin(checkDim!"other.dimensions");
        mixin(checkValueType!"Q.valueType");
        _value = other._value;
    }

    // Assign from a numeric value if this quantity is dimensionless
    void opAssign(T)(T other) /// ditto
        if (!isQuantity!T)
    {
        mixin(checkDim!"");
        mixin(checkValueType!"T");
        _value = other;
    }

    // Unary + and -
    auto opUnary(string op)() const /// ditto
        if (op == "+" || op == "-")
    {
        return Quantity.make(mixin(op ~ "_value"));
    }
    
    // Unary ++ and --
    auto opUnary(string op)() /// ditto
        if (op == "++" || op == "--")
    {
        return Quantity.make(mixin(op ~ "_value"));
    }

    // Add (or substract) two quantities if they share the same dimensions
    auto opBinary(string op, Q)(Q other) const /// ditto
        if (isQuantity!Q && (op == "+" || op == "-"))
    {
        mixin(checkDim!"other.dimensions");
        mixin(checkValueType!"Q.valueType");
        return Quantity.make(mixin("_value" ~ op ~ "other._value"));
    }

    // Add (or substract) a dimensionless quantity and a number
    auto opBinary(string op, T)(T other) const /// ditto
        if (!isQuantity!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"Dimensions.init");
        mixin(checkValueType!"T");
        return Quantity.make(mixin("_value" ~ op ~ "other"));
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const /// ditto
        if (!isQuantity!T && (op == "+" || op == "-"))
    {
        return opBinary!op(other);
    }

    // Multiply or divide two quantities
    auto opBinary(string op, Q)(Q other) const /// ditto
        if (isQuantity!Q && (op == "*" || op == "/" || op == "%"))
    {
        mixin(checkValueType!"Q.valueType");
        return Quantity!(N, binop!op(dimensions, other.dimensions))
			.make(mixin("(_value" ~ op ~ "other._value)"));
    }

    // Multiply or divide a quantity by a number
    auto opBinary(string op, T)(T other) const /// ditto
        if (!isQuantity!T && (op == "*" || op == "/" || op == "%"))
    {
        mixin(checkValueType!"T");
        return Quantity.make(mixin("_value" ~ op ~ "other"));
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const /// ditto
        if (!isQuantity!T && op == "*")
    {
        mixin(checkValueType!"T");
        return this * other;
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const /// ditto
        if (!isQuantity!T && (op == "/" || op == "%"))
    {
        mixin(checkValueType!"T");
        return Quantity!(N, invert(dimensions)).make(mixin("other" ~ op ~ "_value"));
    }

    auto opBinary(string op, T)(T power) const
        if (op == "^^")
    {
        static assert(false, "Unsupporter operator: ^^");
    }

    // Add/sub assign with a quantity that shares the same dimensions
    void opOpAssign(string op, Q)(Q other) /// ditto
        if (isQuantity!Q && (op == "+" || op == "-"))
    {
        mixin(checkDim!"other.dimensions");
        mixin(checkValueType!"Q.valueType");
        mixin("_value " ~ op ~ "= other._value;");
    }

    // Add/sub assign a number to a dimensionless quantity
    void opOpAssign(string op, T)(T other) /// ditto
        if (!isQuantity!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"Dimensions.init");
        mixin(checkValueType!"T");
        mixin("_value " ~ op ~ "= other;");
    }

    // Mul/div assign with a dimensionless quantity
    void opOpAssign(string op, Q)(Q other) /// ditto
        if (isQuantity!Q && (op == "*" || op == "/" || op == "%"))
    {
        mixin(checkDim!"Dimensions.init");
        mixin(checkValueType!"Q.valueType");
        mixin("_value" ~ op ~ "= other._value;");
    }

    // Mul/div assign with a number
    void opOpAssign(string op, T)(T other) /// ditto
        if (!isQuantity!T && (op == "*" || op == "/" || op == "%"))
    {
        mixin(checkValueType!"T");
        mixin("_value" ~ op ~ "= other;");
    }

    // Exact equality between quantities
    bool opEquals(Q)(Q other) const /// ditto
        if (isQuantity!Q)
    {
        mixin(checkDim!"other.dimensions");
        return _value == other._value;
    }

    // Exact equality between a dimensionless quantity and a number
    bool opEquals(T)(T other) const /// ditto
        if (!isQuantity!T)
    {
		mixin(checkDim!"Dimensions.init");
        return _value == other;
    }

    // Comparison between two quantities
    int opCmp(Q)(Q other) const /// ditto
        if (isQuantity!Q)
    {
        mixin(checkDim!"other.dimensions");
        if (_value == other._value)
            return 0;
        if (_value < other._value)
            return -1;
        return 1;
    }

    // Comparison between a dimensionless quantity and a number
    int opCmp(T)(T other) const /// ditto
        if (!isQuantity!T)
    {
		mixin(checkDim!"Dimensions.init");
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

unittest // Quantity.baseUnit
{
    static assert(minute.baseUnit == second);
}

unittest // Quantity constructor
{
    enum time = typeof(second)(1 * minute);
    assert(time.value(second) == 60);
}

unittest // Quantity.opCast
{
    enum angle = 12 * radian;
    static assert(cast(double) angle == 12);
}

unittest // Quantity.opAssign Q = Q
{
    auto length = meter;
    length = 100 * meter;
    assert(length.value(meter).approxEqual(100));
}

unittest // Quantity.opUnary +Q -Q ++Q --Q
{
    enum length = + meter;
    static assert(length == 1 * meter);
    enum length2 = - meter;
    static assert(length2 == -1 * meter);
    
    auto len = ++meter;
    assert(len.value(meter).approxEqual(2));
    len = --meter;
    assert(len.value(meter).approxEqual(0));
    len++;
    assert(len.value(meter).approxEqual(1));    
}

unittest // Quantity.opBinary Q*N Q/N
{
    enum time = second * 60;
    static assert(time.value(second) == 60);
    enum time2 = second / 2;
    static assert(time2.value(second) == 1.0/2);
}

unittest // Quantity.opBinary Q+Q Q-Q
{
    enum length = meter + meter;
    static assert(length.value(meter) == 2);
    enum length2 = length - meter;
    static assert(length2.value(meter) == 1);
}

unittest // Quantity.opBinary Q*Q Q/Q
{
    enum hertz = 1 / second;

    enum length = meter * 5;
    enum surface = length * length;
    static assert(surface.value(meter * meter) == 5*5);
    enum length2 = surface / length;
    static assert(length2.value(meter) == 5);

    enum x = minute / second;
    static assert(x.rawValue == 60);

    enum y = minute * hertz;
    static assert(y.rawValue == 60);
}

unittest // Quantity.opBinaryRight N*Q
{
    enum length = 100 * meter;
    static assert(length == meter * 100);
}

unittest // Quantity.opBinaryRight N/Q
{
    enum x = 1 / (2 * meter);
    static assert(x.value(1/meter) == 1.0/2);
}

unittest // Quantity.opBinary Q%Q Q%N N%Q
{
    enum x = 258.1 * meter;
    enum y1 = x % (50 * meter);
    static assert((cast(double) y1).approxEqual(8.1));
    enum y2 = x % 50;
    static assert(y2.value(meter).approxEqual(8.1));
}

unittest // Quantity.opOpAssign Q+=Q Q-=Q
{
    auto time = 10 * second;
    time += 50 * second;
    assert(time.value(second).approxEqual(60));
    time -= 40 * second;
    assert(time.value(second).approxEqual(20));
}

unittest // Quantity.opOpAssign Q*=N Q/=N Q%=N
{
    auto time = 20 * second;
    time *= 2;
    assert(time.value(second).approxEqual(40));
    time /= 4;
    assert(time.value(second).approxEqual(10));
    time %= 3;
    assert(time.value(second).approxEqual(1));
}

unittest // Quantity.opEquals
{
    static assert(1 * minute == 60 * second);
    static assert((1 / second) * meter == meter / second);
}

unittest // Quantity.opCmp
{
	enum hour = 60 * minute;
    static assert(second < minute);
    static assert(minute <= minute);
    static assert(hour > minute);
    static assert(hour >= hour);
}

unittest // Compilation errors for incompatible dimensions
{
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

unittest // immutable Quantity
{
    immutable length = 3e8 * meter;
    immutable time = 1 * second;
    immutable speedOfLight = length / time;
    assert(speedOfLight == 3e8 * meter / second);
    assert(speedOfLight > 1 * meter / minute);
}

/// Tests whether T is a quantity type
template isQuantity(T)
{
    alias U = Unqual!T;
    static if (is(U == Quantity!X, X...))
        enum isQuantity = true;
    else
        enum isQuantity = false;
}

/// Creates a new monodimensional unit.
template unit(N, string symbol)
{
    static assert(isNumberLike!N, "Incompatible type: " ~ N.stringof);
    enum N one = 1;
    enum unit = Quantity!(N, [symbol: 1]).make(one);
}
///
unittest
{
    enum euro = unit!(double, "C"); // C for Currency
    static assert(isQuantity!(typeof(euro)));
    enum dollar = euro / 1.35;
    assert((1.35 * dollar).value(euro).approxEqual(1));
}


/// Creates a new quantity type where the payload is stored as another numeric type.
template Store(Q, N)
    if (isQuantity!Q && isNumberLike!N)
{
    alias Store = Quantity!(N, Q.dimensions);
}
///
unittest
{
	alias Time = typeof(second);
    alias TimeF = Store!(Time, float);
}


/++
Returns a new quantity where the value is stored in a field of type T.

By default, the value is converted to type T using a cast.
+/
auto store(T, Q)(Q quantity, T delegate(Q.valueType) convertDelegate = x => cast(T) x)
    if (!isQuantity!T && isQuantity!Q)
{
    static if (is(Q.ValueType : T))
        return Quantity!(T, Q.dimensions).make(quantity._value);
    else
    {
        if (convertDelegate)
            return Quantity!(T, Q.dimensions).make(convertDelegate(quantity._value));
        else
            assert(false, "%s is not implicitly convertible to %s: provide a conversion delegate)"
                   .format(Q.valueType.stringof, T.stringof));
    }
}
///
unittest
{
	// import quantities.si : meter;
    auto sizeF = meter.store!float;
    static assert(is(sizeF.valueType == float));
    auto sizeI = meter.store!ulong;
    static assert(is(sizeI.valueType == ulong));
}


/// Check that two quantity types are dimensionally consistent.
template AreConsistent(Q1, Q2)
    if (isQuantity!Q1 && isQuantity!Q2)
{
    enum AreConsistent = Q1.dimensions == Q2.dimensions;
}
///
unittest
{
    // import quantities.si : meter, second;
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
    static assert(isNumberLike!N, "Incompatible type: " ~ N.stringof);

    auto prefix(Q)(Q base)
        if (isQuantity!Q)
    {
        return base * factor;
    }
}
///
unittest
{
    // import quantities.si : meter;
    alias milli = prefix!1e-3;
    assert(milli(meter).value(meter).approxEqual(1e-3));
}


/// Exception thrown when operating on two units that are not interconvertible.
class DimensionException : Exception
{
    @safe pure nothrow
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }

    @safe pure nothrow
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}

package:

bool equals(const Dimensions dim1, const Dimensions dim2)
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
unittest
{
	assert(equals(Dimensions.init, Dimensions.init));
	assert(equals(["a": 1, "b": 0], ["a": 1, "b": 0]));
	assert(!equals(["a": 1, "b": 1], ["a": 1, "b": 0]));
	assert(!equals(["a": 1], ["a": 1, "b": 0]));
	assert(!equals(["a": 1, "b": 0], ["a": 1]));
}

Dimensions removeNull(const Dimensions dim)
{
	Dimensions ret;
	foreach (k, v; dim)
		if (v != 0)
			ret[k] = v;
	return ret;
}
unittest
{
	auto dim = ["a": 1, "b": 0, "c": 0, "d": 1];
	assert(dim.removeNull == ["a": 1, "d": 1]);
}

Dimensions invert(const Dimensions dim)
{
	Dimensions ret;
	foreach (k, v; dim)
	{
		assert(v != 0);
		ret[k] = -v;
	}
	return ret;
}
unittest
{
	auto dim = ["a": 5, "b": -2];
	assert(dim.invert == ["a": -5, "b": 2]);
}

Dimensions binop(string op)(const Dimensions dim1, const Dimensions dim2)
	if (op == "*")
{
	auto ret = cast(Dimensions) dim1.dup;
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
unittest
{
	auto dim1 = ["a": 1, "b": -2];
	auto dim2 = ["a": -1, "c": 2];
	assert(binop!"*"(dim1, dim2) == ["b": -2, "c": 2]);
}

Dimensions binop(string op)(const Dimensions dim1, const Dimensions dim2)
	if (op == "/" || op == "%")
{
	return binop!"*"(dim1, dim2.invert);
}
unittest
{
	auto dim1 = ["a": 1, "b": -2];
	auto dim2 = ["a": 1, "c": 2];
	assert(binop!"/"(dim1, dim2) == ["b": -2, "c": -2]);
}

Dimensions pow(const Dimensions dim, int power)
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
unittest
{
	auto dim = ["a": 5, "b": -2];
	assert(dim.pow(2) == ["a": 10, "b": -4]);
}

Dimensions powinverse(const Dimensions dim, int n)
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
unittest
{
	auto dim = ["a": 6, "b": -2];
	assert(dim.powinverse(2) == ["a": 3, "b": -1]);
}

string toString(const Dimensions dim) @safe pure
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
    
    return "%-(%s %)".format(dimstrs.filter!"a !is null");
}
