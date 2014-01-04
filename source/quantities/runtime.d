// Written in the D programming language
/++
Runtime version.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.runtime;

import quantities.base : Dimensions;
import std.exception;

version (unittest)
{
    import std.math : approxEqual;
    import quantities.parsing : meter, second, minute, hour, liter;
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

struct RTQuantity
{
    private real _value;

    private immutable(Dimensions) _dimensions;

    private void checkDim(const(Dimensions) d) const
    {
        import std.string;
        enforceEx!DimensionException(d == _dimensions,
            format("Dimension error: %s is not compatible with %s", d.toString, _dimensions.toString));
    }

    private this(const(Dimensions) dims, real value)
    {
        _dimensions = dims.idup;
        _value = value;
    }

    @property real rawValue() const
    {
        return _value;
    }

    real value(const RTQuantity target) const
    {
        checkDim(target._dimensions);
        return _value / target._value;
    }

    void opAssign(const RTQuantity other)
    {
        checkDim(other._dimensions);
        _value = other._value;
    }

    RTQuantity opUnary(string op)() const
        if (op == "+" || op == "-")
    {
        return RTQuantity(_dimensions, mixin(op ~ "_value"));
    }

    RTQuantity opBinary(string op)(const RTQuantity other) const
        if (op == "+" || op == "-")
    {
        checkDim(other._dimensions);
        return RTQuantity(_dimensions, mixin("_value" ~ op ~ "other._value"));
    }

    RTQuantity opBinary(string op)(const RTQuantity other) const
        if (op == "*")
    {
        auto newdim = _dimensions + other._dimensions;
        return RTQuantity(newdim, _value * other._value);
    }

    RTQuantity opBinary(string op)(const RTQuantity other) const
        if (op == "/")
    {
        auto newdim = _dimensions - other._dimensions;
        return RTQuantity(newdim, _value / other._value);
    }

    RTQuantity opBinary(string op)(real other) const
        if (op == "*" || op == "/")
    {
        return RTQuantity(_dimensions, mixin("_value" ~ op ~ "other"));
    }

    RTQuantity opBinary(string op)(real other) const
        if (op == "+" || op == "-")
    {
        checkDim(Dimensions.init);
        return RTQuantity(_dimensions, mixin("_value" ~ op ~ "other"));
    }

    RTQuantity opBinaryRight(string op)(real other) const
        if (op == "*")
    {
        return this * other;
    }

    RTQuantity opBinaryRight(string op)(real other) const
        if (op == "/")
    {
        return RTQuantity(-_dimensions, other / _value);
    }

    RTQuantity opBinaryRight(string op)(real other) const
        if (op != "*" && op != "/")
    {
        return mixin("this " ~ op ~ " other");
    }

    void opOpAssign(string op)(const RTQuantity other)
        if (op == "+" || op == "-")
    {
        checkDim(other._dimensions);
        mixin("_value " ~ op ~ "= other._value;");
    }

    void opOpAssign(string op)(const RTQuantity other)
        if (op == "*" || op == "/")
    {
        checkDim(op == "*" 
                 ? _dimensions + other._dimensions
                 : _dimensions - other._dimensions);
        mixin("_value " ~ op ~ "= other._value;");
    }

    void opOpAssign(string op)(real other)
        if (op == "*" || op == "/")
    {
        mixin("_value" ~ op ~ "= other;");
    }

    void opOpAssign(string op)(real other)
        if (op == "+" || op == "-")
    {
        checkDim(Dimensions.init);
        mixin("_value " ~ op ~ "= other;");
    }

    bool opEquals(const RTQuantity other) const
    {
        checkDim(other._dimensions);
        return _value == other._value;
    }

    bool opEquals(real other) const
    {
        checkDim(Dimensions.init);
        return _value == other;
    }
    
    int opCmp(const RTQuantity other) const
    {
        checkDim(other._dimensions);
        if (_value == other._value)
            return 0;
        if (_value < other._value)
            return -1;
        return 1;
    }

    int opCmp(real other) const
    {
        checkDim(Dimensions.init);
        if (_value == other)
            return 0;
        if (_value < other)
            return -1;
        return 1;
    }

    void toString(scope void delegate(const(char)[]) sink) const
    {
        import std.format;
        formattedWrite(sink, "%s", _value);
        sink(_dimensions.toString);
    }
}

@name("RTQuantity.value")
unittest
{
    auto speed = 100 * meter / (5 * second);
    assert(speed.value(meter / second) == 20);
}

@name("RTQuantity.opAssign Q = Q")
unittest
{
    RTQuantity length = meter;
    length = 2 * meter;
    assert(length.value(meter) == 2);
}

@name("RTQuantity.opUnary +Q -Q")
unittest
{
    auto length = + meter;
    assert(length == 1 * meter);
    length = - meter;
    assert(length == -1 * meter);
}

@name("RTQuantity.opBinary Q*N Q/N")
unittest
{
    auto time = second * 60;
    assert(time.value(second) == 60);
    time = second / 2;
    assert(time.value(second) == 1.0/2);
}

@name("RTQuantity.opBinary Q+Q Q-Q")
unittest
{
    auto length = meter + meter;
    assert(length.value(meter) == 2);
    length = length - meter;
    assert(length.value(meter) == 1);
}

@name("RTQuantity.opBinary Q*Q Q/Q")
unittest
{
    auto length = meter * 5;
    auto surface = length * length;
    assert(surface.value(square(meter)) == 5*5);
    auto length2 = surface / length;
    assert(length2.value(meter) == 5);
}

@name("RTQuantity.opBinaryRight N*Q")
unittest
{
    auto length = 100 * meter;
    assert(length == meter * 100);
}

@name("RTQuantity.opBinaryRight N/Q")
unittest
{
    auto x = 1 / (2 * meter);
    assert(x.value(1/meter) == 1.0/2);
}

@name("RTQuantity.opOpAssign Q+=Q Q-=Q")
unittest
{
    auto time = 10 * second;
    time += 50 * second;
    assert(approxEqual(time.value(second), 60));
    time -= 40 * second;
    assert(approxEqual(time.value(second), 20));
}

@name("RTQuantity.opOpAssign Q*=N Q/=N")
unittest
{
    auto time = 20 * second;
    time *= 2;
    assert(approxEqual(time.value(second), 40));
    time /= 4;
    assert(approxEqual(time.value(second), 10));
}

@name("RTQuantity.opEquals")
unittest
{
    assert(1 * minute == 60 * second);
}

@name("RTQuantity.opCmp")
unittest
{
    assert(second < minute);
    assert(minute <= minute);
    assert(hour > minute);
    assert(hour >= hour);
}

@name("RT immutable quantities")
unittest
{
    immutable length = 3e8 * meter;
    immutable time = 1 * second;
    immutable speedOfLight = length / time;
    assert(speedOfLight == 3e8 * meter / second);
    assert(speedOfLight > 1 * meter / minute);
}

RTQuantity unit(string name, string symbol = null)
{
    if (!symbol.length)
        symbol = name;
    return RTQuantity(Dimensions(name, symbol), 1);
}
@name(`unit("dim")`)
unittest
{
    auto euro = unit("currency");
    auto dollar = euro / 1.35;
    assert(approxEqual((1.35 * dollar).value(euro), 1));
}

RTQuantity square(RTQuantity unit)
{
    return pow!2(unit);
}

RTQuantity cubic(RTQuantity unit)
{
    return pow!3(unit);
}

RTQuantity pow(int n)(RTQuantity unit)
{
    return RTQuantity(unit._dimensions * n, unit._value ^^ n);
}

@name("RT square, cubic, pow")
unittest
{
    auto surface = 1 * square(meter);
    auto volume = 1 * cubic(meter);
    volume = 1 * pow!3(meter);
}

RTQuantity sqrt(RTQuantity quantity)
{
    import std.math;
    return RTQuantity(quantity._dimensions / 2, std.math.sqrt(quantity._value));
}

RTQuantity cbrt(RTQuantity quantity)
{
    import std.math;
    return RTQuantity(quantity._dimensions / 3, std.math.cbrt(quantity._value));
}

RTQuantity nthRoot(int n)(RTQuantity quantity)
{
    import std.math;
    return RTQuantity(quantity._dimensions / n, std.math.pow(quantity._value, 1.0 / n));
}

@name("RT Powers of a quantity")
unittest
{
    auto surface = 25 * square(meter);
    auto side = sqrt(surface);
    assert(approxEqual(side.value(meter), 5));
    
    auto volume = 1 * liter;
    side = cbrt(volume);
    assert(approxEqual(nthRoot!3(volume).value(meter), 0.1));
    assert(approxEqual(side.value(meter), 0.1));
}

RTQuantity abs(RTQuantity quantity)
{
    import std.math;
    return RTQuantity(quantity._dimensions, std.math.fabs(quantity._value));
}
@name("RT abs")
unittest
{
    auto deltaT = -10 * second;
    assert(abs(deltaT) == 10 * second);
}
