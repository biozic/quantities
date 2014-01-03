// Written in the D programming language
/++
This module defines the base types for unit and quantity handling.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.base;

import std.traits : isFloatingPoint, isNumeric, Unqual;

version (unittest)
{
    import std.math : approxEqual;
    import quantities.si;
}
version (Have_tested) import tested;
else private struct name { string dummy; }

/++
A quantity type, which holds a value and some dimensions.

The value is stored internally as a field of type N, which defaults to double.

A dimensionless quantity must be expressed with a built-in numeric type, e.g.
double. If an operation over quantities that have dimensions creates a quantity
with no dimensions (e.g. meter / meter), the result is converted to the
corresponding built-in type.

Arithmetic operators (+ - * /), as well as assignment and comparison operators,
are defined when the operations are dimensionally correct, otherwise an error
occurs at compile-time.
+/
struct Quantity(alias dim, N = double)
{
    /// The dimensions of the quantity.
    alias dimensions = dim;
    static assert(is(typeof(dim) == Dimensions));
    static assert(dim != Dimensions.init, "Use a built-in numeric type for dimensionless quantities.");

    /// The type of the underlying scalar value.
    alias valueType = N;
    static assert(isFloatingPoint!N);

    //*** The payload ***//
    private N _value;

    private string dimerror(D)(D d)
    {
        import std.string;
        return format("Dimension error: %s is not compatible with %s", d, dim);
    }

    /// Creates a new quantiy from another one that is dimensionally consistent.
    this(T)(T other)
        if (isQuantityType!T)
    {
        static assert(T.dimensions == dim, dimerror(T.dimensions));
        _value = other._value;
    }

    private this(T)(T value)
        if (isNumeric!T)
    {
        _value = value;
    }    

    /++
    Gets the scalar _value of this quantity expressed in the given target unit.
    +/
    N value(alias target)()
        if(isQuantity!target)
    {
        enum d = typeof(target).dimensions;
        static assert(d == dim, dimerror(d));
        return _value / target._value;
    }
    ///
    unittest
    {
        import std.math;
        auto speed = 100 * meter / (5 * second);
        assert(speed.value!(meter/second) == 20);
    }

    /++
    Returns a new quantity where the value is stored in a field of type T.
    +/
    auto store(T)()
    {
        return Quantity!(dimensions, T)(_value);
    }
    ///
    unittest
    {
        auto length = meter.store!real;
        assert(is(length.valueType == real));
    }

    void opAssign(T)(T other)
        if (isQuantityType!T)
    {
        static assert(T.dimensions == dim, dimerror(T.dimensions));
        _value = other._value;
    }

    auto opUnary(string op)() const
        if (op == "+" || op == "-")
    {
        return Quantity!(dim, N)(mixin(op ~ "_value"));
    }

    auto opBinary(string op, T)(T other) const
        if (isQuantityType!T && (op == "+" || op == "-"))
    {
        static assert(T.dimensions == dim, dimerror(T.dimensions));
        return Quantity!(dim, N)(mixin("_value" ~ op ~ "other._value"));
    }

    auto opBinary(string op, T)(T other) const
        if (isQuantityType!T && op == "*")
    {
        enum newdim = dim + T.dimensions;
        static if (newdim.empty)
            return _value * other._value;
        else
            return Quantity!(newdim, N)(_value * other._value);
    }

    auto opBinary(string op, T)(T other) const
        if (isQuantityType!T && op == "/")
    {
        enum newdim = dim - T.dimensions;
        static if (newdim.empty)
            return _value / other._value;
        else
            return Quantity!(newdim, N)(_value / other._value);
    }

    auto opBinary(string op, T)(T other) const
        if (isNumeric!T && (op == "*" || op == "/"))
    {
        return Quantity!(dim, N)(mixin("_value" ~ op ~ "other"));
    }

    auto opBinary(string op, T)(T other) const
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        static assert(false, dimerror(Dimensions.init));
    }

    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && op == "*")
    {
        return this * other;
    }

    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && op == "/")
    {
        return Quantity!(-dim, N)(other / _value);
    }

    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && op != "*" && op != "/")
    {
        return mixin("this " ~ op ~ " other");
    }

    auto opOpAssign(string op, T)(T other)
        if (isQuantityType!T && (op == "+" || op == "-"))
    {
        static assert(T.dimensions == dim, dimerror(T.dimensions));
        mixin("_value " ~ op ~ "= other._value;");
    }

    auto opOpAssign(string op, T)(T other)
        if (isQuantityType!T && (op == "*" || op == "/"))
    {
        static assert(false, dimerror(op == "*" ? dim + T.dimensions : dim - T.dimensions));
    }

    auto opOpAssign(string op, T)(T other)
        if (isNumeric!T && (op == "*" || op == "/"))
    {
        mixin("_value" ~ op ~ "= other;");
    }

    auto opOpAssign(string op, T)(T other)
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        static assert(false, dimerror(Dimensions.init));
    }

    bool opEquals(T)(T other) const
        if (isQuantityType!T)
    {
        import std.string;
        static assert(T.dimensions == dim, dimerror(T.dimensions));
        return _value == other._value;
    }

    bool opEquals(T)(T other) const
        if (isNumeric!T)
    {
        static assert(false, dimerror(Dimensions.init));
    }
    
    int opCmp(T)(T other) const
        if (isQuantityType!T)
    {
        static assert(T.dimensions == dim, dimerror(T.dimensions));
        if (_value == other._value)
            return 0;
        if (_value < other._value)
            return -1;
        return 1;
    }

    bool opCmp(T)(T other) const
        if (isNumeric!T)
    {
        static assert(false, dimerror(Dimensions.init));
    }

    void toString(scope void delegate(const(char)[]) sink) const
    {
        import std.format;
        formattedWrite(sink, "%s", _value);
        sink(dimensions.toString);
    }
}

version (SynopsisUnittest)
@name("Synopsis")
unittest
{
    import std.stdio;

    // ------------------
    // Working with units
    // ------------------

    // Caveat: work with units at compile-time

    alias m = meter;        // meter is a predefined SI unit
    alias cm = centi!meter; // centi is a predefined SI prefix

    // Define new units
    enum inch = 2.54 * centi!meter;
    enum mile = 1609 * meter;

    // Define new units with non-SI dimensions
    enum euro = unit!("currency", "€");
    enum dollar = euro / 1.35;

    writeln(meter);  // prints: 1[m]
    writeln(inch);   // prints: 0.0254[m]
    writeln(dollar); // prints: 0.740741[€]
    writeln(volt);   // prints: 1[kg^-1 s^-3 m^2 A^-1]

    // -----------------------
    // Working with quantities
    // -----------------------

    // Hint: work with quantities at runtime

    // I have to make a new solution at the concentration of 2.5 g/l.
    auto conc = 2.5 * gram/liter;
    // The final volume is 10 ml.
    auto volume = 10 * milli!liter;
    // What mass should I weigh?
    auto mass = conc * volume;
    writefln("Weigh %f kg of substance", mass.value!kilogram); 
    // prints: Weigh 0.000025 kg of substance
    // Wait! My scales graduations are 0.1 milligrams!
    writefln("Weigh %.1f mg of substance", mass.value!(milli!gram));
    // prints: Weigh 25.0 mg of substance
    // I knew the result would be 25 mg.
    assert(approxEqual(mass.value!(milli!gram), 25));

    // Optional: we could have defined new types to hold our quantities
    alias Mass = Store!kilogram; // Using a SI base unit.
    alias Volume = Store!liter; // Using a SI compatible unit.
    alias Concentration = Store!(kilogram/liter); // Using a derived unit.

    auto speedMPH = 30 * mile/hour;
    writefln("The speed limit is %s", speedMPH);
    // prints: The speed limit is 13.4083[s^-1 m]
    writefln("The speed limit is %.0f km/h", speedMPH.value!(kilo!meter/hour));
    // prints: The speed limit is 48 km/h
    writefln("The speed limit is %.0f in/s", speedMPH.value!(inch/second));
    // prints: The speed limit is 528 in/s

    auto wage = 65 * euro / hour;
    auto workTime = 1.6 * day;
    writefln("I've just earned %s!", wage * workTime);
    // prints: I've just earned 2496[€]!
    writefln("I've just earned $ %.2f!", (wage * workTime).value!dollar);
    // prints: I've just earned $ 3369.60!

    // Type checking prevents incorrect assignments and operations
    static assert(!__traits(compiles, mass = 10 * milli!liter));
    static assert(!__traits(compiles, conc = 1 * euro/volume));
}

/// Checks that type T is an instance of the template Quantity
template isQuantityType(T)
{
    alias U = Unqual!T;
    static if (is(U _ : Quantity!X, X...))
        enum isQuantityType = true;
    else
        enum isQuantityType = false;
}

/// Checks that sym is a quantity
template isQuantity(alias sym)
{
    enum isQuantity = isQuantityType!(typeof(sym));
}
///
@name("isQuantity")
unittest
{
    static assert(isQuantity!meter);
    static assert(isQuantity!(4.18 * joule));
}

@name("Quantity.__ctor")
unittest
{
    Store!second time;
    time = Store!second(1 * minute);
    assert(time.value!second == 60);
}

@name("Quantity.value")
unittest
{
    auto speed = 100 * meter / (5 * second);
    assert(speed.value!(meter / second) == 20);
}

@name("Quantity.store")
unittest
{
    auto length = meter.store!real;
    assert(is(length.valueType == real));
}

@name("Quantity.opAssign Q = Q")
unittest
{
    auto length = meter;
    length = 2.54 * centi!meter;
    assert(approxEqual(length.value!meter, 0.0254));
}

@name("Quantity.opUnary +Q -Q")
unittest
{
    auto length = + meter;
    assert(length == 1 * meter);
    length = - meter;
    assert(length == -1 * meter);
}

@name("Quantity.opBinary Q*N Q/N")
unittest
{
    auto time = second * 60;
    assert(time.value!second == 60);
    time = second / 2;
    assert(time.value!second == 1.0/2);
}

@name("Quantity.opBinary Q+Q Q-Q")
unittest
{
    auto length = meter + meter;
    assert(length.value!meter == 2);
    length = length - meter;
    assert(length.value!meter == 1);
}

@name("Quantity.opBinary Q*Q Q/Q")
unittest
{
    auto length = meter * 5;
    auto surface = length * length;
    assert(surface.value!(square!meter) == 5*5);
    auto length2 = surface / length;
    assert(length2.value!meter == 5);

    auto x = minute / second;
    assert(is(typeof(x) == double));
    assert(x == 60);

    auto y = minute * hertz;
    assert(is(typeof(y) == double));
    assert(y == 60);
}

@name("Quantity.opBinaryRight N*Q")
unittest
{
    auto length = 100 * meter;
    assert(length == meter * 100);
}

@name("Quantity.opBinaryRight N/Q")
unittest
{
    auto x = 1 / (2 * meter);
    assert(x.value!(1/meter) == 1.0/2);
}

@name("Quantity.opOpAssign Q+=Q Q-=Q")
unittest
{
    auto time = 10 * second;
    time += 50 * second;
    assert(approxEqual(time.value!second, 60));
    time -= 40 * second;
    assert(approxEqual(time.value!second, 20));
}

@name("Quantity.opOpAssign Q*=N Q/=N")
unittest
{
    auto time = 20 * second;
    time *= 2;
    assert(approxEqual(time.value!second, 40));
    time /= 4;
    assert(approxEqual(time.value!second, 10));
}

@name("Quantity.opEquals")
unittest
{
    assert(1 * minute == 60 * second);
}

@name("Quantity.opCmp")
unittest
{
    assert(second < minute);
    assert(minute <= minute);
    assert(hour > minute);
    assert(hour >= hour);
}

@name("Compilation errors")
unittest
{
    Store!meter m;
    static assert(!__traits(compiles, Store!meter(1 * second)));
    static assert(!__traits(compiles, m.value!second));
    static assert(!__traits(compiles, m = second));
    static assert(!__traits(compiles, meter + second));
    static assert(!__traits(compiles, meter - second));
    static assert(!__traits(compiles, meter + 1));
    static assert(!__traits(compiles, meter - 1));
    static assert(!__traits(compiles, 1 + meter));
    static assert(!__traits(compiles, 1 - meter));
    static assert(!__traits(compiles, meter += second));
    static assert(!__traits(compiles, meter -= second));
    static assert(!__traits(compiles, meter *= second));
    static assert(!__traits(compiles, meter /= second));
    static assert(!__traits(compiles, meter *= meter));
    static assert(!__traits(compiles, meter /= meter));
    static assert(!__traits(compiles, meter += 1));
    static assert(!__traits(compiles, meter -= 1));
    static assert(!__traits(compiles, meter == 1));
    static assert(!__traits(compiles, meter == second));
    static assert(!__traits(compiles, meter < second));
    static assert(!__traits(compiles, meter < 1));
}

@name("Immutable quantities")
unittest
{
    immutable length = 3e5 * kilo!meter;
    immutable time = 1 * second;
    immutable speedOfLight = length / time;
    assert(speedOfLight == 3e5 * kilo!meter / second);
    assert(speedOfLight > 1 * meter / minute);
}

/// Creates a new monodimensional unit.
template unit(string name, string symbol = name, N = double)
{
    enum unit = Quantity!(Dimensions(name, symbol), N)(1);
}
///
@name(`unit!"dim"`)
unittest
{
    enum euro = unit!"currency";
    static assert(isQuantity!euro);
    enum dollar = euro / 1.35;
    assert(approxEqual((1.35 * dollar).value!euro, 1));
}

/// Transforms a unit at compile-time.
template square(alias unit)
{
    alias square = pow!(2, unit);
}

/// ditto
template cubic(alias unit)
{
    alias cubic = pow!(3, unit);
}

/// ditto
template pow(int n, alias unit)
{
    enum pow = Quantity!(unit.dimensions * n, unit.valueType)(unit._value ^^ n);
}

///
@name("square, cubic, pow")
unittest
{
    auto surface = 1 * square!meter;
    auto volume = 1 * cubic!meter;
    volume = 1 * pow!(3, meter);
}

/// Equivalent of the method Quantity.value for dimensionless quantities.
auto value(alias target, T)(T quantity)
    if (isFloatingPoint!(typeof(target)) && isNumeric!T)
{
    return quantity / target;
}
///
@name("Dimensionless value")
unittest
{
    import std.math : PI, approxEqual;
    auto angle = 2 * PI * radian;
    assert(approxEqual(angle.value!degreeOfAngle, 360));
}

/++
Utility template to create quantity types. The unit is only used to set the
dimensions, it doesn't bind the stored value to a particular unit. Use in 
conjunction with the store method of quantities.
+/
template Store(alias unit, N = double)
    if (isQuantity!unit)
{
    alias Store = Quantity!(unit.dimensions, N);
}
///
@name("Store example")
unittest
{
    alias Mass = Store!kilogram;
    Mass mass = 15 * ton;
    
    alias Surface = Store!(square!meter, float);
    assert(is(Surface.valueType == float));
    Surface s = 4 * square!meter;
}

/// Equivalent of the method Quantity.store for dimensionless quantities.
auto store(T, Q)(Q quantity)
    if (isFloatingPoint!T)
{
    return cast(T) quantity;
}
///
@name("Dimensionless store")
unittest
{
    auto angle = 90 * degreeOfAngle.store!float;
    assert(is(typeof(angle) == float));
}

@name("Type conservation")
unittest
{
    Store!(meter, float) length; 
    Store!(second, double) time;
    Store!(meter/second, real) speed;
    length = 1 * kilo!meter;
    time = 2 * hour;
    speed = length / time;
    assert(is(speed.valueType == real));
}

/// Returns the square root, the cubic root of the nth root of a quantity.
auto sqrt(Q)(Q quantity)
{
    import std.math;
    static if (isQuantity!quantity)
        return Quantity!(Q.dimensions / 2, Q.valueType)(std.math.sqrt(quantity._value));
    else
        return std.math.sqrt(quantity);
}

/// ditto
auto cbrt(Q)(Q quantity)
{
    import std.math;
    static if (isQuantity!quantity)
        return Quantity!(Q.dimensions / 3, Q.valueType)(std.math.cbrt(quantity._value));
    else
        return std.math.cbrt(quantity);
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
{
    import std.math;
    static if (isQuantity!quantity)
        return Quantity!(Q.dimensions / n, Q.valueType)(std.math.pow(quantity._value, 1.0 / n));
    else
        return std.math.pow(quantity, 1.0 / n);
}

///
@name("Powers of a quantity")
unittest
{
    auto surface = 25 * square!meter;
    auto side = sqrt(surface);
    assert(approxEqual(side.value!meter, 5));
    
    auto volume = 1 * liter;
    side = cbrt(volume);
    assert(approxEqual(nthRoot!3(volume).value!(deci!meter), 1));
    assert(approxEqual(side.value!(deci!meter), 1));
}

/// Returns the absolute value of a quantity
Q abs(Q)(Q quantity)
{
    import std.math;
    static if (isQuantity!quantity)
        return Q(std.math.fabs(quantity._value));
    else
        return std.math.abs(quantity);
}
///
@name("abs")
unittest
{
    auto deltaT = -10 * second;
    assert(abs(deltaT) == 10 * second);
}

/++
This struct represents the dimensions of a quantity/unit. Instances of this
type are only created and used at compile-time to check the correctness of
operation on quantities.
+/
struct Dimensions
{
    private static struct Dim
    {
        int power;
        string symbol;
    }

    private Dim[string] dims;

package:
    // Create a new monodimensional Dimensions
    this(string name, string symbol = null)
    {
        if (!name.length)
            throw new Exception("The name of a dimension cannot be empty");
        if (!symbol.length)
            symbol = name;

        dims[name] = Dim(1, symbol);
    }

    // Tests if the dimensions are empty.
    @property bool empty() const
    {
        return dims.length == 0;
    }

    Dimensions opUnary(string op)() const
        if (op == "+" || op == "-")
    {
        Dimensions result;
        foreach (k; dims.keys)
            result.dims[k] = Dim(mixin(op ~ "dims[k].power"), dims[k].symbol);
        return result;
    }
    
    Dimensions opBinary(string op)(Dimensions other) const
        if (op == "+" || op == "-")
    {
        Dimensions result;
        foreach (k, v; dims)
            result.dims[k] = Dim(v.power, v.symbol);
        foreach (k; other.dims.keys)
        {
            if (k in dims)
            {
                auto p = mixin("dims[k].power" ~ op ~ "other.dims[k].power");
                if (p == 0)
                    result.dims.remove(k);
                else
                    result.dims[k] = Dim(p, other.dims[k].symbol);
            }
            else
                result.dims[k] = Dim(mixin(op ~ "other.dims[k].power"), other.dims[k].symbol);
        }
        return result;
    }
    
    Dimensions opBinary(string op)(int value) const
        if (op == "*" || op == "/")
    {
        Dimensions result;
        foreach (k; dims.keys)
        {
            static if (op == "/")
            {
                if (dims[k].power % value != 0)
                    throw new Exception("Operation results in a non-integral dimension");
            }
            result.dims[k] = Dim(mixin("dims[k].power" ~ op ~ "value"), dims[k].symbol);
        }
        return result;
    }
    
    bool opEquals(Dimensions other)
    {
        import std.algorithm : sort, equal;
        
        bool same = (dims.keys.length == other.dims.keys.length)
            && (sort(dims.keys).equal(sort(other.dims.keys)));
        if (!same)
            return false;
        
        foreach (k, v; dims)
        {
            auto ov = k in other.dims;
            assert(ov);
            if (v.power != ov.power)
            {
                same = false;
                break;
            }
        }
        return same;
    }
    
    string toString()
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
        foreach (k, v; dims)
            dimstrs ~= stringize(v.symbol, v.power);
        
        string result = dimstrs.filter!"a !is null".join(" ");
        if (!result.length)
            return "scalar";
        
        return "[" ~ result ~ "]";
    }
}

// Creates a new dimension
private template dim(string name, string symbol = name)
{
    enum dim = Dimensions(name, symbol);
}

@name("Dimension")
unittest
{
    import std.exception;

    enum test = Dimensions(SI.length) + Dimensions(SI.mass);
    assert(collectException(test / 2));

    enum d = dim!"foo";
    enum e = dim!"bar";
    enum f = dim!"bar";
    static assert(e == f);
    enum g = -test;
    static assert(-g == test);
    enum h = +test;
    static assert(h == test);
    enum i = test + test;
    static assert(i == test * 2);
    enum j = test - test;
    static assert(j.empty);
    static assert(j.toString == "scalar");
    enum k = i / 2;
    static assert(k == test);
    static assert(d + e == e + d);

    enum m = dim!("mdim", "m");
    enum n = dim!("ndim", "n");
    static assert(m.toString == "[m]");
    static assert((m*2).toString == "[m^2]");
    static assert((-m).toString == "[m^-1]");
    static assert((m+n).toString == "[m n]" || (m+n).toString == "[n m]");
}
