// Written in the D programming language
/++
This module defines the base types for unit and quantity handling.

Each  quantity can  be represented  as the  product  of a  number and  a set  of
dimensions,  and  the struct  Quantity  has  this  role.  The number  is  stored
internally as  a member of type  N, which is  enforced to be a  built-in numeric
type  (isNumeric!N is  true). The  dimensions are  stored as  template parameter
list (Dim)  in the  form of a  sequence of string  symbols and  integral powers.
Dimensionless  quantities have  an  empty  Dim. For  instance  length and  speed
quantities can be stored as:
---
alias Length = Quantity!(real, "L", 1);
alias Speed  = Quantity!(real, "L", 1, "T", -1);
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
enum meter = Quantity!(real, "L", 1)(1.0);
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
then the quantity type with the QuantityType template:
---
enum euro = unit!"C"; // C for currency
alias Currency = QuantityType!euro;
assert(is(Currency == Quantity!(real, "C", 1)));
---
This means that all currencies will be defined with respect to euro.

Copyright: Copyright 2013-2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.base;

import std.exception;
import std.string;
import std.traits;
import std.typetuple;

version (unittest)
{
    import quantities.si;
    import std.math : approxEqual;
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
		&& (__traits(compiles, { n1 = 1; }) || __traits(compiles, { n1 = N(1); }))
		&& __traits(compiles, { return cast(const) n1 + n2; } );
}
unittest
{
    static assert(isNumberLike!real);
    static assert(isNumberLike!int);
	static assert(!isNumberLike!string);

    import std.bigint, std.numeric, std.typecons;
    static assert(isNumberLike!BigInt);
    static assert(isNumberLike!(RefCounted!real));
}

template OperatorResultType(T, string op, U)
{
    T t;
    U u;
    alias OperatorResultType = typeof(mixin("t" ~ op ~ "u"));
}
unittest
{
    static assert(is(OperatorResultType!(real, "+", int) == real));
    static assert(is(OperatorResultType!(int, "*", int) == int));
}

/++
A quantity that can be expressed as the product of a number and a set of dimensions.
+/
struct Quantity(N, Dim...)
{
    static assert(isNumberLike!N, "Incompatible type: " ~ N.stringof);

    /// The type of the underlying numeric value.
    alias valueType = N;
    ///
    unittest
    {
        static assert(is(meter.valueType == real));
    }

    // The payload
    private N _value;

    /// The dimension tuple of the quantity.
    alias dimensions = Dim;

    template checkDim(string dim)
    {
        enum checkDim =
            `static assert(Is!(` ~ dim ~ `).equivalentTo!dimensions,
                "Dimension error: %s is not compatible with %s"
                .format(dimstr!(` ~ dim ~ `), dimstr!dimensions));`;
    }

	template checkValueType(string type)
	{
		enum checkValueType =
			`static assert(is(` ~ type ~ ` : N),
                "%s is not implicitly convertible to %s"
                .format(` ~ type ~ `.stringof, N.stringof));`;
	}

    /// Gets the base unit of this quantity.
    static @property Quantity baseUnit()
    {
		static if (isNumeric!N)
			return Quantity.make(1);
		else static if (__traits(compiles, N(1)))
			return Quantity.make(N(1));
		else
			static assert(false, "BUG");
    }

    // Creates a new quantity from another one with the same dimensions
    this(Q)(Q other)
        if (isQuantity!Q)
    {
        mixin(checkDim!"other.dimensions");
		mixin(checkValueType!"Q.valueType");
        _value = cast(N) other._value;
    }

    // Creates a new dimensionless quantity from a number
    this(T)(T value)
        if (!isQuantity!T && Dim.length == 0)
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
    @property N rawValue() const
    {
        return _value;
    }
    // Implicitly convert a dimensionless value to the value type
    static if (!Dim.length)
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
        return AreConsistent!(Quantity, Q);
    }
    ///
    unittest
    {
        auto nm = (1.4 * newton) * (0.5 * centi(meter));
        auto kWh = (4000 * kilo(watt)) * (1200 * hour);
        assert(nm.isConsistentWith(kWh)); // Energy in both cases
        assert(!nm.isConsistentWith(second));
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
        mixin(checkDim!"");
		mixin(checkValueType!"T");
        return _value;
    }
    ///
    unittest
    {
        auto proportion = 12 * gram / (4.5 * kilogram);
        static assert(is(QuantityType!proportion == Dimensionless));
        auto prop = cast(real) proportion;

        static assert(!__traits(compiles, cast(real) meter));
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
        return Quantity!(N, dimensions).make(mixin(op ~ "_value"));
    }

    // Add (or substract) two quantities if they share the same dimensions
    auto opBinary(string op, Q)(Q other) const /// ditto
        if (isQuantity!Q && (op == "+" || op == "-"))
    {
        mixin(checkDim!"other.dimensions");
		mixin(checkValueType!"Q.valueType");
        return Quantity!(OperatorResultType!(N, "+", Q.valueType), dimensions)
            .make(mixin("_value" ~ op ~ "other._value"));
    }

    // Add (or substract) a dimensionless quantity and a number
    auto opBinary(string op, T)(T other) const /// ditto
        if (!isQuantity!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"");
		mixin(checkValueType!"T");
        return Quantity!(OperatorResultType(N, "+", T), dimensions)
            .make(mixin("_value" ~ op ~ "other"));
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const /// ditto
        if (!isQuantity!T && (op == "+" || op == "-"))
    {
        return opBinary!op(other);
    }

    // Multiply or divide two quantities
    auto opBinary(string op, Q)(Q other) const /// ditto
        if (isQuantity!Q && (op == "*" || op == "/"))
    {
		mixin(checkValueType!"Q.valueType");
        return Quantity!(OperatorResultType!(N, "*", Q.valueType),
                         OpBinary!(dimensions, op, other.dimensions))
            .make(mixin("(_value" ~ op ~ "other._value)"));
    }

    // Multiply or divide a quantity by a factor
    auto opBinary(string op, T)(T other) const /// ditto
        if (!isQuantity!T && (op == "*" || op == "/"))
    {
		mixin(checkValueType!"T");
        return Quantity!(OperatorResultType!(N, "*", T), dimensions)
            .make(mixin("_value" ~ op ~ "other"));
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
        if (!isQuantity!T && op == "/")
    {
		mixin(checkValueType!"T");
        return Quantity!(OperatorResultType!(T, "/", N), Invert!dimensions)
            .make(other / _value);
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
        mixin(checkDim!"");
		mixin(checkValueType!"T");
        mixin("_value " ~ op ~ "= other;");
    }

    // Mul/div assign with a dimensionless quantity
    void opOpAssign(string op, Q)(Q other) /// ditto
        if (isQuantity!Q && (op == "*" || op == "/"))
    {
        mixin(checkDim!"");
		mixin(checkValueType!"Q.valueType");
        mixin("_value" ~ op ~ "= other._value;");
    }

    // Mul/div assign with a number
    void opOpAssign(string op, T)(T other) /// ditto
        if (!isQuantity!T && (op == "*" || op == "/"))
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
        mixin(checkDim!"");
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
        mixin(checkDim!"");
        if (_value == other)
            return 0;
        if (_value < other)
            return -1;
        return 1;
    }

    /++
    Returns the default string representation of the quantity.

    By default, a quantity is represented as a string by a number
    followed by the set of dimensions between brackets.
    +/
    string toString() const
    {
        return "%s [%s]".format(_value, dimstr!dimensions);
    }
    ///
    unittest
    {
        enum inch = 2.54 * centi(meter);
        assert(inch.toString == "0.0254 [L]", inch.toString);
    }
}

unittest // Quantity.baseUnit
{
    static assert(minute.baseUnit == second);
}

unittest // Quantity constructor
{
    enum time = QuantityType!second(1 * minute);
    assert(time.value(second) == 60);
}

unittest // Quantity.value
{
    enum speed = 100 * meter / (5 * second);
    static assert(speed.value(meter / second) == 20);
}

unittest // Quantity.opCast
{
    enum angle = 12 * radian;
    static assert(cast(double) angle == 12);
}

unittest // Quantity.opAssign Q = Q
{
    auto length = meter;
    length = 2.54 * centi(meter);
    assert(length.value(meter).approxEqual(0.0254));
}

unittest // Quantity.opUnary +Q -Q
{
    enum length = + meter;
    static assert(length == 1 * meter);
    enum length2 = - meter;
    static assert(length2 == -1 * meter);
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
    enum length = meter * 5;
    enum surface = length * length;
    static assert(surface.value(square(meter)) == 5*5);
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

unittest // Quantity.opOpAssign Q+=Q Q-=Q
{
    auto time = 10 * second;
    time += 50 * second;
    assert(time.value(second).approxEqual(60));
    time -= 40 * second;
    assert(time.value(second).approxEqual(20));
}

unittest // Quantity.opOpAssign Q*=N Q/=N
{
    auto time = 20 * second;
    time *= 2;
    assert(time.value(second).approxEqual(40));
    time /= 4;
    assert(time.value(second).approxEqual(10));
}

unittest // Quantity.opEquals
{
    assert(1 * minute == 60 * second);
    assert((1 / second) * meter == meter / second);
}

unittest // Quantity.opCmp
{
    assert(second < minute);
    assert(minute <= minute);
    assert(hour > minute);
    assert(hour >= hour);
}

unittest // Compilation errors for incompatible dimensions
{
    static assert(!__traits(compiles, QuantityType!meter(1 * second)));
    QuantityType!meter m;
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
    immutable length = 3e5 * kilo(meter);
    immutable time = 1 * second;
    immutable speedOfLight = length / time;
    assert(speedOfLight == 3e5 * kilo(meter) / second);
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
///
unittest
{
    static assert(isQuantity!Time);
    static assert(isQuantity!(QuantityType!meter));
    static assert(!isQuantity!real);
}


/// Creates a new monodimensional unit.
template unit(string symbol, N = real)
{
    static assert(isNumberLike!N, "Incompatible type: " ~ N.stringof);
	static if (isNumeric!N)
    	enum unit = Quantity!(N, symbol, 1).make(1);
	else static if (__traits(compiles, N(1)))
		enum unit = Quantity!(N, symbol, 1).make(N(1));
	else
		static assert(false, "BUG");
}
///
unittest
{
    enum euro = unit!"C"; // C for Currency
    static assert(isQuantity!(typeof(euro)));
    enum dollar = euro / 1.35;
    assert((1.35 * dollar).value(euro).approxEqual(1));
}


/++
Math functions operating on a quantity.

Note that these functions use std.math internally, and therefore
only work for quantities storing a builtin numeric type.
+/
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
	static assert(__traits(compiles, unit.rawValue ^^ n),
	              U.valueType.stringof ~ " doesn't overload operator ^^");
    return Quantity!(U.valueType, Pow!(n, U.dimensions)).make(unit.rawValue ^^ n);
}

/// ditto
auto sqrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
	static assert(__traits(compiles, sqrt(quantity.rawValue)),
	              "No overload of sqrt for an argument of type " ~ Q.valueType.stringof);
	return Quantity!(Q.valueType, PowInverse!(2, Q.dimensions)).make(sqrt(quantity.rawValue));
}

/// ditto
auto cbrt(Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
	static assert(__traits(compiles, cbrt(quantity.rawValue)),
	              "No overload of cbrt for an argument of type " ~ Q.valueType.stringof);
	return Quantity!(Q.valueType, PowInverse!(3, Q.dimensions)).make(cbrt(quantity.rawValue));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
    if (isQuantity!Q)
{
    import std.math;
	static assert(__traits(compiles, pow(quantity.rawValue, 1.0 / n)),
	              "No overload of pow for an argument of type " ~ Q.valueType.stringof);
	return Quantity!(Q.valueType, PowInverse!(n, Q.dimensions)).make(pow(quantity.rawValue, 1.0 / n));
}

/// ditto
Q abs(Q)(Q quantity)
	if (isQuantity!Q)
{
	import std.math;
	static assert(__traits(compiles, fabs(quantity.rawValue)),
	              "No overload of fabs for an argument of type " ~ Q.valueType.stringof);
	return Q.make(fabs(quantity.rawValue));
}

///
unittest
{
    auto surface = 25 * square(meter);
    auto side = sqrt(surface);
    assert(side.value(meter).approxEqual(5));

    auto volume = 27 * liter;
    side = cbrt(volume);
    assert(side.value(deci(meter)).approxEqual(3));

	auto deltaT = -10 * second;
	assert(abs(deltaT) == 10 * second);
}


/// Returns the quantity type of a unit
template QuantityType(alias unit)
    if (isQuantity!(typeof(unit)))
{
    alias QuantityType = Quantity!(unit.valueType, unit.dimensions);
}
///
unittest // QuantityType example
{
    alias Mass = QuantityType!kilogram;
    Mass mass = 15 * ton;
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
	auto sizeF = meter.store!float;
	static assert(is(sizeF.valueType == float));
	auto sizeI = meter.store!ulong;
	static assert(is(sizeI.valueType == ulong));
}


/// Check that two quantity types are dimensionally consistent.
template AreConsistent(Q1, Q2)
    if (isQuantity!Q1 && isQuantity!Q2)
{
    enum AreConsistent = Is!(Q1.dimensions).equivalentTo!(Q2.dimensions);
}
///
unittest
{
    alias Speed = QuantityType!(meter/second);
    alias Velocity = QuantityType!((1/second * meter));
    static assert(AreConsistent!(Speed, Velocity));
}


/// Utility templates to manipulate quantity types.
template Inverse(Q, N = real)
    if (isQuantity!Q)
{
    alias Inverse = Quantity!(N, typeof(1 / Q.init).dimensions);
}

/// ditto
template Product(Q1, Q2, N = real)
    if (isQuantity!Q1 && isQuantity!Q2)
{
    alias Product = Quantity!(N, typeof(Q1.init * Q2.init).dimensions);
}

/// ditto
template Quotient(Q1, Q2, N = real)
    if (isQuantity!Q1 && isQuantity!Q2)
{
    alias Quotient = Quantity!(N, typeof(Q1.init / Q2.init).dimensions);
}

/// ditto
template Square(Q, N = real)
    if (isQuantity!Q)
{
    alias Square = Quantity!(N, typeof(square(Q.init)).dimensions);
}

/// ditto
template Cubic(Q, N = real)
    if (isQuantity!Q)
{
    alias Cubic = Quantity!(N, typeof(cubic(Q.init)).dimensions);
}

///
unittest
{
    static assert(is(Inverse!Time == Frequency));
    static assert(is(Product!(Power, Time) == Energy));
    static assert(is(Quotient!(Length, Time) == Speed));
    static assert(is(Square!Length == Area));
    static assert(is(Cubic!Length == Volume));
    static assert(AreConsistent!(Product!(Inverse!Time, Length), Speed));
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

// Inspired from std.typetuple.Pack
template Is(T...)
{
    static assert(T.length % 2 == 0);

    template equalTo(U...)
    {
        static if (T.length == U.length)
        {
            static if (T.length == 0)
                enum equalTo = true;
            else
                enum equalTo = IsDim!(T[0..2]).equalTo!(U[0..2]) && Is!(T[2..$]).equalTo!(U[2..$]);
        }
        else
            enum equalTo = false;
    }

    template equivalentTo(U...)
    {
        alias equivalentTo = Is!(Sort!T).equalTo!(Sort!U);
    }
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", -1);
    alias U = TypeTuple!("a", 1, "b", -1);
    alias V = TypeTuple!("b", -1, "a", 1);
    static assert(Is!T.equalTo!U);
    static assert(!Is!T.equalTo!V);
    static assert(Is!T.equivalentTo!V);
}

template IsDim(string d1, int p1)
{
    template equalTo(string d2, int p2)
    {
        enum equalTo = (d1 == d2 && p1 == p2);
    }

    template dimEqualTo(string d2, int p2)
    {
        enum dimEqualTo = (d1 == d2);
    }

    template dimLessOrEqual(string d2, int p2)
    {
        alias siInOrder = TypeTuple!("L", "M", "T", "I", "Θ", "N", "J");
        enum id1 = staticIndexOf!(d1, siInOrder);
        enum id2 = staticIndexOf!(d2, siInOrder);

        static if (id1 >= 0 && id2 >= 0) // both SI
            enum dimLessOrEqual = id1 < id2;
        else static if (id1 >= 0 && id2 == -1) // SI before non-SI
            enum dimLessOrEqual = true;
        else static if (id1 == -1 && id2 >= 0) // non-SI after SI
            enum dimLessOrEqual = false;
        else
            enum dimLessOrEqual = d1 <= d2; // Usual comparison
    }

    template powEqualTo(string d2, int p2)
    {
        enum powEqualTo = (p1 == p2);
    }
}
unittest
{
    static assert(IsDim!("a", 0).equalTo!("a", 0));
    static assert(!IsDim!("a", 0).equalTo!("a", 1));
    static assert(!IsDim!("a", 0).equalTo!("b", 0));
    static assert(!IsDim!("a", 0).equalTo!("b", 1));

    static assert(IsDim!("a", 0).dimEqualTo!("a", 1));
    static assert(!IsDim!("a", 0).dimEqualTo!("b", 1));

    static assert(IsDim!("a", 0).powEqualTo!("b", 0));
    static assert(!IsDim!("a", 0).powEqualTo!("b", 1));

    static assert(IsDim!("L", 0).dimLessOrEqual!("M", 0));
    static assert(!IsDim!("M", 0).dimLessOrEqual!("L", 1));
    static assert(IsDim!("L", 0).dimLessOrEqual!("U", 0));
    static assert(!IsDim!("U", 0).dimLessOrEqual!("M", 0));
    static assert(IsDim!("U", 0).dimLessOrEqual!("V", 0));
}

template FilterPred(alias pred, Dim...)
{
    static assert(Dim.length % 2 == 0);

    static if (Dim.length == 0)
        alias FilterPred = Dim;
    else static if (pred!(Dim[0], Dim[1]))
        alias FilterPred = TypeTuple!(Dim[0], Dim[1], FilterPred!(pred, Dim[2 .. $]));
    else
        alias FilterPred = FilterPred!(pred, Dim[2 .. $]);
}

template RemoveNull(Dim...)
{
    alias RemoveNull = FilterPred!(templateNot!(IsDim!("_", 0).powEqualTo), Dim);
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", 0, "c", -1);
    static assert(Is!(RemoveNull!T).equalTo!("a", 1, "c", -1));
}

template Filter(string s, Dim...)
{
    alias Filter = FilterPred!(IsDim!(s, 0).dimEqualTo, Dim);
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", 0, "a", -1, "c", 2);
    static assert(Is!(Filter!("a", T)).equalTo!("a", 1, "a", -1));
}

template FilterOut(string s, Dim...)
{
    alias FilterOut = FilterPred!(templateNot!(IsDim!(s, 0).dimEqualTo), Dim);
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", 0, "a", -1, "c", 2);
    static assert(Is!(FilterOut!("a", T)).equalTo!("b", 0, "c", 2));
}

template Reduce(int seed, Dim...)
{
    static assert(Dim.length >= 2);
    static assert(Dim.length % 2 == 0);

    static if (Dim.length == 2)
        alias Reduce = TypeTuple!(Dim[0], seed + Dim[1]);
    else
        alias Reduce = Reduce!(seed + Dim[1], Dim[2 .. $]);
}
unittest
{
    alias T = TypeTuple!("a", 1, "a", 0, "a", -1, "a", 2);
    static assert(Is!(Reduce!(0, T)).equalTo!("a", 2));
    alias U = TypeTuple!("a", 1, "a", -1);
    static assert(Is!(Reduce!(0, U)).equalTo!("a", 0));
}

template Simplify(Dim...)
{
    static assert(Dim.length % 2 == 0);

    static if (Dim.length == 0)
        alias Simplify = Dim;
    else
    {
        alias head = Dim[0 .. 2];
        alias tail = Dim[2 .. $];
        alias hret = Reduce!(0, head, Filter!(Dim[0], tail));
        alias tret = FilterOut!(Dim[0], tail);
        alias Simplify = TypeTuple!(hret, Simplify!tret);
    }
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", 2, "a", -1, "b", 1, "c", 4);
    static assert(Is!(Simplify!T).equalTo!("a", 0, "b", 3, "c", 4));
}

template Sort(Dim...)
{
    static assert(Dim.length % 2 == 0);

    static if (Dim.length <= 2)
        alias Sort = Dim;
    else
    {
        enum i = (Dim.length / 4) * 2; // Pivot index
        alias list = TypeTuple!(Dim[0..i], Dim[i+2..$]);
        alias less = FilterPred!(templateNot!(IsDim!(Dim[i], 0).dimLessOrEqual), list);
        alias greater = FilterPred!(IsDim!(Dim[i], 0).dimLessOrEqual, list);
        alias Sort = TypeTuple!(Sort!less, Dim[i], Dim[i+1], Sort!greater);
    }
}
unittest
{
    alias T = TypeTuple!("d", -1, "c", 2, "a", 4, "e", 0, "b", -3);
    static assert(Is!(Sort!T).equalTo!("a", 4, "b", -3, "c", 2, "d", -1, "e", 0));
}

template OpBinary(Dim...)
{
    static assert(Dim.length % 2 == 1);

    static if (staticIndexOf!("/", Dim) >= 0)
    {
        // Division
        enum op = staticIndexOf!("/", Dim);
        alias numerator = Dim[0 .. op];
        alias denominator = Dim[op+1 .. $];
        alias OpBinary = Sort!(RemoveNull!(Simplify!(TypeTuple!(numerator, Invert!(denominator)))));
    }
    else static if (staticIndexOf!("*", Dim) >= 0)
    {
        // Multiplication
        enum op = staticIndexOf!("*", Dim);
        alias OpBinary = Sort!(RemoveNull!(Simplify!(TypeTuple!(Dim[0 .. op], Dim[op+1 .. $]))));
    }
    else
        static assert(false, "No valid operator");
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", 2, "c", -1);
    alias U = TypeTuple!("a", 1, "b", -2, "c", 2);
    static assert(Is!(OpBinary!(T, "*", U)).equalTo!("a", 2, "c", 1));
    static assert(Is!(OpBinary!(T, "/", U)).equalTo!("b", 4, "c", -3));
}

template Invert(Dim...)
{
    static assert(Dim.length % 2 == 0);

    static if (Dim.length == 0)
        alias Invert = Dim;
    else
        alias Invert = TypeTuple!(Dim[0], -Dim[1], Invert!(Dim[2 .. $]));
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", -1);
    static assert(Is!(Invert!T).equalTo!("a", -1, "b", 1));
}

template Pow(int n, Dim...)
{
    static assert(Dim.length % 2 == 0);

    static if (Dim.length == 0)
        alias Pow = Dim;
    else
        alias Pow = TypeTuple!(Dim[0], Dim[1] * n, Pow!(n, Dim[2 .. $]));
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", -1);
    static assert(Is!(Pow!(2, T)).equalTo!("a", 2, "b", -2));
}

template PowInverse(int n, Dim...)
{
    static assert(Dim.length % 2 == 0);

    static if (Dim.length == 0)
        alias PowInverse = Dim;
    else
    {
        static assert(Dim[1] % n == 0, "Dimension error: '%s^%s' is not divisible by %s"
                                       .format(Dim[0], Dim[1], n));
        alias PowInverse = TypeTuple!(Dim[0], Dim[1] / n, PowInverse!(n, Dim[2 .. $]));
    }
}
unittest
{
    alias T = TypeTuple!("a", 4, "b", -2);
    static assert(Is!(PowInverse!(2, T)).equalTo!("a", 2, "b", -1));
}

int[string] toAA(Dim...)()
{
    static if (Dim.length == 0)
        return null;
    else
    {
        static assert(Dim.length % 2 == 0);
        int[string] ret;
        string sym;
        foreach (i, d; Dim)
        {
            static if (i % 2 == 0)
                sym = d;
            else
                ret[sym] = d;
        }
        return ret;
    }
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", -1);
    static assert(toAA!T == ["a":1, "b":-1]);
}

string dimstr(Dim...)()
{
    import std.algorithm : filter;
    import std.array : join;
    import std.conv : to;

    static string stringize(string base, int power)
    {
        if (power == 0)
            return null;
        if (power == 1)
            return base;
        return base ~ "^" ~ to!string(power);
    }

    string[] dimstrs;
    string sym;
    foreach (i, d; Dim)
    {
        static if (i % 2 == 0)
            sym = d;
        else
            dimstrs ~= stringize(sym, d);
    }
    return format("%-(%s %)", dimstrs);
}
