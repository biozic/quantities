// Written in the D programming language
/++
This module defines the base types for unit and quantity handling.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.runtime.base;

import std.exception;
import std.traits : isFloatingPoint, isNumeric, Unqual;

version (unittest)
{
    import std.math : approxEqual;
    import quantities.runtime.si;
}
version (Have_tested) import tested;
else private struct name { string dummy; }

class DimensionException : Exception
{
    @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
    
    @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}


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
struct RTQuantity(N = double)
{
    // The type of the underlying scalar value.
    alias valueType = N;
    static assert(isFloatingPoint!N);

    // The payload
    private N _value;

    // The dimensions of the quantity.
    private Dimensions _dimensions;

    private void checkDim(Dimensions d)
    {
        import std.string;
        enforceEx!DimensionException(d == _dimensions,
            format("Dimension error: %s is not compatible with %s", d.toString, _dimensions.toString));
    }

    private this(T)(Dimensions dims, T value)
        if (isNumeric!T)
    {
        _dimensions = dims;
        _value = value;
    }    

    /++
    Gets the scalar _value of this quantity expressed in the given target unit.
    +/
    N value(T)(T target)
        if(isRTQuantity!T)
    {
        checkDim(target._dimensions);
        return _value / target._value;
    }
    ///
    unittest
    {
        auto speed = 100 * meter / (5 * second);
        assert(speed.value(meter/second) == 20);
    }

    /++
    Returns a new quantity where the value is stored in a field of type T.
    +/
    auto store(T)()
    {
        return RTQuantity!T(_dimensions, _value);
    }
    ///
    unittest
    {
        auto length = meter.store!real;
        assert(is(length.valueType == real));
    }

    void opAssign(T)(T other)
        if (isRTQuantity!T)
    {
        checkDim(other._dimensions);
        _value = other._value;
    }

    auto opUnary(string op)()
        if (op == "+" || op == "-")
    {
        return RTQuantity!N(_dimensions, mixin(op ~ "_value"));
    }

    auto opBinary(string op, T)(T other)
        if (isRTQuantity!T && (op == "+" || op == "-"))
    {
        checkDim(other._dimensions);
        return RTQuantity!N(_dimensions, mixin("_value" ~ op ~ "other._value"));
    }

    auto opBinary(string op, T)(T other)
        if (isRTQuantity!T && op == "*")
    {
        auto newdim = _dimensions + other._dimensions;
        return RTQuantity!N(newdim, _value * other._value);
    }

    auto opBinary(string op, T)(T other)
        if (isRTQuantity!T && op == "/")
    {
        auto newdim = _dimensions - other._dimensions;
        return RTQuantity!N(newdim, _value / other._value);
    }

    auto opBinary(string op, T)(T other)
        if (isNumeric!T && (op == "*" || op == "/"))
    {
        return RTQuantity!N(_dimensions, mixin("_value" ~ op ~ "other"));
    }

    auto opBinary(string op, T)(T other)
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDim(Dimensions.init);
        return RTQuantity!N(_dimensions, mixin("_value" ~ op ~ "other"));
    }

    auto opBinaryRight(string op, T)(T other)
        if (isNumeric!T && op == "*")
    {
        return this * other;
    }

    auto opBinaryRight(string op, T)(T other)
        if (isNumeric!T && op == "/")
    {
        return RTQuantity!N(-_dimensions, other / _value);
    }

    auto opBinaryRight(string op, T)(T other)
        if (isNumeric!T && op != "*" && op != "/")
    {
        return mixin("this " ~ op ~ " other");
    }

    auto opOpAssign(string op, T)(T other)
        if (isRTQuantity!T && (op == "+" || op == "-"))
    {
        checkDim(other._dimensions);
        mixin("_value " ~ op ~ "= other._value;");
    }

    auto opOpAssign(string op, T)(T other)
        if (isRTQuantity!T && (op == "*" || op == "/"))
    {
        checkDim(op == "*" 
                 ? _dimensions + other._dimensions
                 : _dimensions - other._dimensions);
        mixin("_value " ~ op ~ "= other._value;");
    }

    auto opOpAssign(string op, T)(T other)
        if (isNumeric!T && (op == "*" || op == "/"))
    {
        mixin("_value" ~ op ~ "= other;");
    }

    auto opOpAssign(string op, T)(T other)
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDim(Dimensions.init);
        mixin("_value " ~ op ~ "= other;");
    }

    bool opEquals(T)(T other)
        if (isRTQuantity!T)
    {
        checkDim(other._dimensions);
        return _value == other._value;
    }

    bool opEquals(T)(T other)
        if (isNumeric!T)
    {
        checkDim(Dimensions.init);
        return _value == other;
    }
    
    int opCmp(T)(T other)
        if (isRTQuantity!T)
    {
        checkDim(other._dimensions);
        if (_value == other._value)
            return 0;
        if (_value < other._value)
            return -1;
        return 1;
    }

    bool opCmp(T)(T other)
        if (isNumeric!T)
    {
        checkDim(Dimensions.init);
        if (_value == other)
            return 0;
        if (_value < other)
            return -1;
        return 1;
    }

    void toString(scope void delegate(const(char)[]) sink)
    {
        import std.format;
        formattedWrite(sink, "%s", _value);
        sink(_dimensions.toString);
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

    // Define new units
    auto inch = 2.54 * centi(meter);
    auto mile = 1609 * meter;

    // Define new units with non-SI dimensions
    auto euro = unit("currency", "€");
    auto dollar = euro / 1.35;

    writeln(meter);  // prints: 1[m]
    writeln(inch);   // prints: 0.0254[m]
    writeln(dollar); // prints: 0.740741[€]
    writeln(volt);   // prints: 1[kg^-1 s^-3 m^2 A^-1]

    // -----------------------
    // Working with quantities
    // -----------------------

    // I have to make a new solution at the concentration of 2.5 g/l.
    auto conc = 2.5 * gram/liter;
    // The final volume is 10 ml.
    auto volume = 10 * milli(liter);
    // What mass should I weigh?
    auto mass = conc * volume;
    writefln("Weigh %f kg of substance", mass.value(kilogram)); 
    // prints: Weigh 0.000025 kg of substance
    // Wait! My scales graduations are 0.1 milligrams!
    writefln("Weigh %.1f mg of substance", mass.value(milli(gram)));
    // prints: Weigh 25.0 mg of substance
    // I knew the result would be 25 mg.
    assert(approxEqual(mass.value(milli(gram)), 25));


    auto speedMPH = 30 * mile/hour;
    writefln("The speed limit is %s", speedMPH);
    // prints: The speed limit is 13.4083[s^-1 m]
    writefln("The speed limit is %.0f km/h", speedMPH.value(kilo(meter/hour)));
    // prints: The speed limit is 48 km/h
    writefln("The speed limit is %.0f in/s", speedMPH.value(inch/second));
    // prints: The speed limit is 528 in/s

    auto wage = 65 * euro / hour;
    auto workTime = 1.6 * day;
    writefln("I've just earned %s!", wage * workTime);
    // prints: I've just earned 2496[€]!
    writefln("I've just earned $ %.2f!", (wage * workTime).value(dollar));
    // prints: I've just earned $ 3369.60!
}

/// Checks that type T is an instance of the template Quantity
template isRTQuantity(T)
{
    alias U = Unqual!T;
    static if (is(U _ : RTQuantity!X, X...))
        enum isRTQuantity = true;
    else
        enum isRTQuantity = false;
}
///
@name("isRTQuantity")
unittest
{
    static assert(isRTQuantity!(typeof(meter)));
    static assert(isRTQuantity!(typeof(4.18 * joule)));
}

@name("Quantity.value")
unittest
{
    auto speed = 100 * meter / (5 * second);
    assert(speed.value(meter / second) == 20);
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
    length = 2.54 * centi(meter);
    assert(approxEqual(length.value(meter), 0.0254));
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
    assert(time.value(second) == 60);
    time = second / 2;
    assert(time.value(second) == 1.0/2);
}

@name("Quantity.opBinary Q+Q Q-Q")
unittest
{
    auto length = meter + meter;
    assert(length.value(meter) == 2);
    length = length - meter;
    assert(length.value(meter) == 1);
}

@name("Quantity.opBinary Q*Q Q/Q")
unittest
{
    auto length = meter * 5;
    auto surface = length * length;
    assert(surface.value(square(meter)) == 5*5);
    auto length2 = surface / length;
    assert(length2.value(meter) == 5);
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
    assert(x.value(1/meter) == 1.0/2);
}

@name("Quantity.opOpAssign Q+=Q Q-=Q")
unittest
{
    auto time = 10 * second;
    time += 50 * second;
    assert(approxEqual(time.value(second), 60));
    time -= 40 * second;
    assert(approxEqual(time.value(second), 20));
}

@name("Quantity.opOpAssign Q*=N Q/=N")
unittest
{
    auto time = 20 * second;
    time *= 2;
    assert(approxEqual(time.value(second), 40));
    time /= 4;
    assert(approxEqual(time.value(second), 10));
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

/+
@name("Immutable quantities")
unittest
{
    immutable length = 3e5 * kilo(meter);
    immutable time = 1 * second;
    immutable speedOfLight = length / time;
    assert(speedOfLight == 3e5 * kilo(meter) / second);
    assert(speedOfLight > 1 * meter / minute);
}
+/

/// Creates a new monodimensional unit.
RTQuantity!N unit(N = double)(string name, string symbol = null)
{
    if (!symbol.length)
        symbol = name;
    return RTQuantity!N(Dimensions(name, symbol), 1);
}
///
@name(`unit("dim")`)
unittest
{
    auto euro = unit("currency");
    assert(isRTQuantity!(typeof(euro)));
    auto dollar = euro / 1.35;
    assert(approxEqual((1.35 * dollar).value(euro), 1));
}

/// Transforms a unit at compile-time.
auto square(T)(T unit)
{
    return pow!2(unit);
}

/// ditto
auto cubic(T)(T unit)
{
    return pow!3(unit);
}

/// ditto
auto pow(int n, T)(T unit)
{
    return RTQuantity!(T.valueType)(unit._dimensions * n, unit._value ^^ n);
}

///
@name("square, cubic, pow")
unittest
{
    auto surface = 1 * square(meter);
    auto volume = 1 * cubic(meter);
    volume = 1 * pow!3(meter);
}

/// Returns the square root, the cubic root of the nth root of a quantity.
auto sqrt(Q)(Q quantity)
{
    import std.math;
    return RTQuantity!(Q.valueType)(quantity._dimensions / 2, std.math.sqrt(quantity._value));
}

/// ditto
auto cbrt(Q)(Q quantity)
{
    import std.math;
    return RTQuantity!(Q.valueType)(quantity._dimensions / 3, std.math.cbrt(quantity._value));
}

/// ditto
auto nthRoot(int n, Q)(Q quantity)
{
    import std.math;
    return RTQuantity!(Q.valueType)(quantity._dimensions / n, std.math.pow(quantity._value, 1.0 / n));
}

///
@name("Powers of a quantity")
unittest
{
    auto surface = 25 * square(meter);
    auto side = sqrt(surface);
    assert(approxEqual(side.value(meter), 5));
    
    auto volume = 1 * liter;
    side = cbrt(volume);
    assert(approxEqual(nthRoot!3(volume).value(deci(meter)), 1));
    assert(approxEqual(side.value(deci(meter)), 1));
}

/// Returns the absolute value of a quantity
Q abs(Q)(Q quantity)
{
    import std.math;
    return Q(quantity._dimensions, std.math.fabs(quantity._value));
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
Dimensions rtDim(string name, string symbol = null)
{
    if (!symbol.length)
        symbol = name;
    return Dimensions(name, symbol);
}

@name("Dimension")
unittest
{
    import std.exception;

    auto test = Dimensions(SI.length) + Dimensions(SI.mass);
    assert(collectException(test / 2));

    auto d = rtDim("foo");
    auto e = rtDim("bar");
    auto f = rtDim("bar");
    assert(e == f);
    auto g = -test;
    assert(-g == test);
    auto h = +test;
    assert(h == test);
    auto i = test + test;
    assert(i == test * 2);
    auto j = test - test;
    assert(j.empty);
    assert(j.toString == "scalar");
    auto k = i / 2;
    assert(k == test);
    assert(d + e == e + d);

    auto m = rtDim("mdim", "m");
    auto n = rtDim("ndim", "n");
    assert(m.toString == "[m]");
    assert((m*2).toString == "[m^2]");
    assert((-m).toString == "[m^-1]");
    assert((m+n).toString == "[m n]" || (m+n).toString == "[n m]");
}
