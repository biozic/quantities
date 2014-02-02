// Written in the D programming language
/++
This module defines the base types for unit and quantity handling.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.base;

import quantities.parsing : qty, parseQuantity, RTQuantity, dimstr;
import std.exception;
import std.string;
import std.traits;
import std.typetuple;

version (unittest)
{
    import quantities.si;
    import std.math : approxEqual;
}

/++
A quantity which holds a value and some dimensions.

The value is stored internally as a field of type N.
A dimensionless quantity can be cast to a builtin numeric type.

Arithmetic operators (+ - * /), as well as assignment and comparison operators,
are defined when the operations are dimensionally correct, otherwise an error
occurs at compile-time.
+/
struct Quantity(N, Dim...)
{
    static assert(isNumeric!N);

    /// The type of the underlying numeric value.
    alias valueType = N;
    ///
    unittest
    {
        static assert(is(meter.valueType == real));
    }

    /// The payload
    private N _value;

    /// The dimension tuple of the quantity.
    alias dimensions = Dim;

    template checkDim(string dim)
    {
        enum checkDim = 
            `static assert(Is!(` ~ dim ~ `).equivalentTo!dimensions,
                "Dimension error: %s is not compatible with %s"
                .format(dimstr!(` ~ dim ~ `)(true), dimstr!(dimensions)(true)));`;
    }
    
    /// Gets the base unit of this quantity
    static @property Quantity baseUnit()
    {
        return Quantity(1);
    }

    /// Creates a new quantity from another one with the same dimensions
    this(Q)(Q other)
        if (isQuantity!Q)
    {
        mixin(checkDim!"other.dimensions");
        _value = other._value;
    }
    ///
    unittest
    {
        auto size = Length(42 * kilo(meter));
    }

    /// Creates a new quantity from a runtime-parsed one
    this(T)(T other)
        if (is(Unqual!T == RTQuantity))
    {
        enforceEx!DimensionException(toAA!dimensions == other.dimensions,
                                     "Dimension error: %s is not compatible with %s"
                                     .format(dimstr!dimensions(true), dimstr(other.dimensions, true)));
        _value = other.value;
    }
    ///
    unittest
    {
        auto size = Length(parseQuantity("42 km"));
    }
    
    /// Creates a new dimensionless quantity from a scalar value
    this(T)(T value)
        if (isNumeric!T && Dim.length == 0)
    {
        _value = value;
    }
    ///
    unittest
    {
        import std.math : PI;

        Angle angle = PI / 2;
        assert(angle.value(degreeOfAngle) == 90);
    }

    // Creates a new quantity from a scalar value
    package this(T)(T value)
        if (isNumeric!T && Dim.length != 0)
    {
        _value = value;
    }    
    
    /++
    Gets the internal scalar value of this quantity.

    The returned number is the value of the quantity when it is
    expressed in the corresponding base unit.
    +/
    @property N rawValue() const
    {
        return _value;
    }
    ///
    unittest
    {
        auto time = 10 * minute;
        assert(time.rawValue == 600); // There are 600 s in 10 min
    }

    // Implicitly convert a dimensionless value to the value type
    static if (!Dim.length)
        alias rawValue this;

    /++
    Gets the scalar _value of this quantity expressed in the given target unit.
    +/
    N value(Q)(Q target) const
        if (isQuantity!Q)
    {
        mixin(checkDim!"target.dimensions");
        return _value / target._value;
    }
    /// ditto
    N value(Q)(Q target) const
        if (is(Unqual!Q == RTQuantity))
    {
        return value(typeof(this)(target));
    }
    /// ditto
    N value(string target)() const
    {
        return value(qty!target);
    }
    ///
    unittest
    {
        auto time = 120 * minute;
        assert(time.value(hour) == 2);
        assert(time.value(minute) == 120);
        assert(time.value(second) == 7200);
        assert(time.value!"h" == 2);
    }

    /++
    Tests wheter this quantity has the same dimensions 
    +/
    bool isConsistentWith(Q)(Q other) const
        if (isQuantity!Q)
    {
        return AreConsistent!(typeof(this), Q);
    }
    /// ditto
    bool isConsistentWith(Q)(Q other) const
        if (is(Unqual!Q == RTQuantity))
    {
        return toAA!Dim == other.dimensions;
    }
    ///
    unittest
    {
        auto nm = (1.4 * newton) * (0.5 * centi(meter));
        auto kWh = (4000 * kilo(watt)) * (1200 * hour);
        assert(nm.isConsistentWith(kWh)); // Energy in both cases
        assert(!nm.isConsistentWith(second));
        assert(nm.isConsistentWith(qty!"kW h"));
    }

    /++
    Returns a new quantity where the value is stored in a field of type T.
    +/
    auto store(T)() const
        if (isNumeric!T)
    {
        return Quantity!(T, dimensions)(_value);
    }
    ///
    unittest
    {
        auto size = meter.store!float;
        static assert(is(size.valueType == float));
    }

    /// Cast a quantity to another quantity type with the same dimensions
    Q opCast(Q)() const
        if (isQuantity!Q)
    {
        mixin(checkDim!"Q.dimensions");
        return store!(Q.valueType);
    }
    ///
    unittest
    {
        alias Length = QuantityType!(meter, float);
        auto m = cast(Length) meter;
        static assert(is(meter.valueType == real));
        static assert(is(m.valueType == float));

        static assert(!__traits(compiles, cast(Time) meter));
    }

    /// Cast a dimensionless quantity to a scalar numeric type
    T opCast(T)() const
        if (isNumeric!T)
    {
        mixin(checkDim!"");
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
    void opAssign(T)(T other)
        if (isQuantity!T)
    {
        mixin(checkDim!"other.dimensions");
        _value = other._value;
    }

    // Assign from a runtime quantity
    void opAssign(T)(T other) /// ditto
        if (is(Unqual!T == RTQuantity))
    {
        enforceEx!DimensionException(toAA!dimensions == other.dimensions);
        _value = other.value;
    }

    // Assign from a numeric value if this quantity is dimensionless
    void opAssign(T)(T other) /// ditto
        if (isNumeric!T)
    {
        mixin(checkDim!"");
        _value = other;
    }

    // Unary + and -
    auto opUnary(string op)() const /// ditto
        if (op == "+" || op == "-")
    {
        return Quantity!(N, dimensions)(mixin(op ~ "_value"));
    }

    // Add (or substract) two quantities if they share the same dimensions
    auto opBinary(string op, T)(T other) const /// ditto
        if (isQuantity!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"other.dimensions");
        return Quantity!(CommonType!(N, T.valueType), dimensions)(mixin("_value" ~ op ~ "other._value"));
    }

    // Add (or substract) a dimensionless quantity and a scalar
    auto opBinary(string op, T)(T other) const /// ditto
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"");
        return Quantity!(CommonType!(N, T), dimensions)(mixin("_value" ~ op ~ "other"));
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const /// ditto
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        return opBinary!op(other);
    }

    // Multiply or divide two quantities
    auto opBinary(string op, T)(T other) const /// ditto
        if (isQuantity!T && (op == "*" || op == "/"))
    {
        return Quantity!(CommonType!(N, T.valueType), OpBinary!(dimensions, op, other.dimensions))
            (mixin("(_value" ~ op ~ "other._value)"));
    }

    // Multiply or divide a quantity by a scalar factor
    auto opBinary(string op, T)(T other) const /// ditto
        if (isNumeric!T && (op == "*" || op == "/"))
    {
        return Quantity!(CommonType!(N, T), dimensions)(mixin("_value" ~ op ~ "other"));
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const /// ditto
        if (isNumeric!T && op == "*")
    {
        return this * other;
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const /// ditto
        if (isNumeric!T && op == "/")
    {
        return Quantity!(CommonType!(N, T), Invert!dimensions)(other / _value);
    }

    // Add/sub assign with a quantity that shares the same dimensions
    void opOpAssign(string op, T)(T other) /// ditto
        if (isQuantity!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"other.dimensions");
        mixin("_value " ~ op ~ "= other._value;");
    }

    // Add/sub assign a scalar to a dimensionless quantity
    void opOpAssign(string op, T)(T other) /// ditto
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"");
        mixin("_value " ~ op ~ "= other;");
    }
    
    // Mul/div assign with a dimensionless quantity
    void opOpAssign(string op, T)(T other) /// ditto
        if (isQuantity!T && (op == "*" || op == "/"))
    {
        mixin(checkDim!"");
        mixin("_value" ~ op ~ "= other._value;");
    }

    // Mul/div assign with a scalar factor
    void opOpAssign(string op, T)(T other) /// ditto
        if (isNumeric!T && (op == "*" || op == "/"))
    {
        mixin("_value" ~ op ~ "= other;");
    }

    // Exact equality between quantities
    bool opEquals(T)(T other) const /// ditto
        if (isQuantity!T)
    {
        mixin(checkDim!"other.dimensions");
        return _value == other._value;
    }

    // Exact equality between a dimensionless quantity and a scalar
    bool opEquals(T)(T other) const /// ditto
        if (isNumeric!T)
    {
        mixin(checkDim!"");
        return _value == other;
    }

    // Comparison between two quantities
    int opCmp(T)(T other) const /// ditto
        if (isQuantity!T)
    {
        mixin(checkDim!"other.dimensions");
        if (_value == other._value)
            return 0;
        if (_value < other._value)
            return -1;
        return 1;
    }

    // Comparision between a dimensionless quantity and a scalar
    int opCmp(T)(T other) const /// ditto
        if (isNumeric!T)
    {
        mixin(checkDim!"");
        if (_value == other)
            return 0;
        if (_value < other)
            return -1;
        return 1;
    }

    /// Returns the default string representation of the quantity.
    string toString() const
    {
        return "%s %s".format(_value, dimstr!dimensions);
    }
    ///
    unittest
    {
        enum inch = qty!"2.54 cm";
        assert(inch.toString == "0.0254 m");
    }

    /++
    Returns a formatted string from the quantity.

    The format string must be formed of a format specifier for the numeric value
    (e.g %s, %g, %.2f, etc.), followed by a unit. The whitespace between the
    format specifier and the unit is not significant.

    The unit present in the format is parsed each time the function is called, in
    order to calculate the value. If this quantity can be known at runtime,
    the template version of this function is more efficient.
    +/
    string toString(string fmt) const
    {
        import std.array, std.format;
        auto app = appender!string;
        auto spec = FormatSpec!char(fmt);
        spec.writeUpToNextSpec(app);
        app.formatValue(value(parseQuantity(spec.trailing)), spec);
        app.put(spec.trailing);
        return app.data;
    }
    /// ditto
    string toString(string fmt)() const
    {
        static assert(fmt.startsWith("%"), "Expecting a format specifier starting with '%'");

        // Get the unit at compile time
        static string extractUnit(string fmt)
        {
            import std.algorithm, std.array;
            auto ret = fmt.findAmong([
                's', 'c', 'b', 'd', 'o', 'x', 'X', 'e', 
                'E', 'f', 'F', 'g', 'G', 'a', 'A']);
            ret.popFront();
            return ret;
        }

        return fmt.format(value(qty!(extractUnit(fmt))));
    }
    ///
    unittest
    {
        enum inch = qty!"2.54 cm";

        // Format parsed at runtime
        assert(inch.toString("%s cm") == "2.54 cm");
        assert(inch.toString("%.2f mm") == "25.40 mm");

        // Format parsed at compile-time
        assert(inch.toString!"%s cm" == "2.54 cm");
        assert(inch.toString!"%.2f mm" == "25.40 mm");
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

unittest // Quantity.store
{
    enum length = meter.store!real;
    static assert(is(length.valueType == real));
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

unittest // Quantity.toString
{
    import quantities.utils.locale;
    auto loc = ScopedLocale("fr_FR");

    enum inch = qty!"2.54 cm";
    
    // Format parsed at runtime
    assert(inch.toString("%s cm") == "2,54 cm");
    assert(inch.toString("%.2f mm") == "25,40 mm");
    
    // Format parsed at compile-time
    assert(inch.toString!"%s cm" == "2,54 cm");
    assert(inch.toString!"%.2f mm" == "25,40 mm");
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
    static if (is(U _ : Quantity!X, X...))
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
    enum unit = Quantity!(N, symbol, 1)(1);
}
///
unittest
{
    enum euro = unit!"€";
    static assert(isQuantity!(typeof(euro)));
    enum dollar = euro / 1.35;
    assert((1.35 * dollar).value(euro).approxEqual(1));
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

/// ditto
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
unittest
{
    auto surface = 25 * square(meter);
    auto side = sqrt(surface);
    assert(side.value(meter).approxEqual(5));

    auto volume = 27 * liter;
    side = cbrt(volume);
    assert(side.value(deci(meter)).approxEqual(3));
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


/// Returns the quantity type of a unit
template QuantityType(alias unit, N = real)
    if (isQuantity!(typeof(unit)))
{
    alias QuantityType = Quantity!(N, unit.dimensions);
}
///
unittest // QuantityType example
{
    alias Mass = QuantityType!kilogram;
    Mass mass = 15 * ton;
    
    alias Surface = QuantityType!(square(meter), float);
    assert(is(Surface.valueType == float));
    Surface s = 4 * square(meter);
}

/// The type of a quantity where the payload is stored as another numeric type.
template Store(Q, N)
    if (isQuantity!Q)
{
    alias Store = Quantity!(N, Q.dimensions);
}
///
unittest
{
    alias TimeF = Store!(Time, float);
}

/// Check that two quantity types are dimensionally consistent
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


/// Utility templates to manipulate quantity types
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
        alias siInOrder = TypeTuple!("m", "kg", "s", "A", "K", "mol", "cd");
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

    static assert(IsDim!("m", 0).dimLessOrEqual!("kg", 0));
    static assert(!IsDim!("kg", 0).dimLessOrEqual!("m", 1));
    static assert(IsDim!("m", 0).dimLessOrEqual!("U", 0));
    static assert(!IsDim!("U", 0).dimLessOrEqual!("kg", 0));
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

string dimstr(Dim...)(bool complete = false)
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

    static if (Dim.length == 0)
        return complete ? "scalar" : "";
    else
   	{
	    string[] dimstrs;
	    string sym;
	    foreach (i, d; Dim)
	    {
	        static if (i % 2 == 0)
	            sym = d;
	        else
	            dimstrs ~= stringize(sym, d);
	    }
	    return dimstrs.join(" ");
	}
}
