// Written in the D programming language
/++
Runtime version.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.runtime;

import quantities.base;
import quantities.math;
import quantities.si;
import quantities.parsing;
import std.exception;

version (unittest)
    import std.math : approxEqual;

version (Have_tested) import tested;
else private struct name { string dummy; }

struct RTQuantity
{
    private immutable(Dimensions) _dimensions;
    private bool _initialized = false;
    private real _value;

    private void checkDim(const(Dimensions) d) const
    {
        import std.string;
        enforceEx!DimensionException(d == _dimensions,
            format("Dimension error: %s is not compatible with %s", d.toString, _dimensions.toString));
    }

    package this(const(Dimensions) dims, real value)
    {
        _dimensions = dims.idup;
        _value = value;
        _initialized = true;
    }

    this(T)(T other)
        if (isQuantityType!T)
    {
        _dimensions = T.dimensions;
        _value = other.rawValue;
        _initialized = true;
    }

    @property immutable(Dimensions) dimensions() const
    {
        return _dimensions;
    }

    @property real rawValue() const
    {
        return _value;
    }

    real value(T)(T target) const
        if (isRTQuantity!T || isQuantityType!T)
    {
        checkDim(target.dimensions);
        return _value / target.rawValue;
    }

    package void resetTo(T)(const T other)
        if (isRTQuantity!T || isQuantityType!T)
    {
        _value = other.rawValue;
        cast(Dimensions) _dimensions = cast(Dimensions) other.dimensions; // Oohoooh...
    }

    T opCast(T)() const
        if (isQuantityType!T)
    {
        T ret = this;
        return ret;
    }

    void opAssign(T)(T other)
        if (isRTQuantity!T || isQuantityType!T)
    {
        if (_initialized)
        {
            checkDim(other.dimensions);
            _value = other.rawValue;
        }
        else
            resetTo(other);
    }

    RTQuantity opUnary(string op)() const
        if (op == "+" || op == "-")
    {
        return RTQuantity(_dimensions, mixin(op ~ "_value"));
    }

    RTQuantity opBinary(string op, T)(T other) const
        if (op == "+" || op == "-")
    {
        checkDim(other.dimensions);
        return RTQuantity(_dimensions, mixin("_value" ~ op ~ "other.rawValue"));
    }

    RTQuantity opBinary(string op, T)(T other) const
        if (op == "*")
    {
        auto newdim = _dimensions + other.dimensions;
        return RTQuantity(newdim, _value * other.rawValue);
    }

    RTQuantity opBinary(string op, T)(T other) const
        if (op == "/")
    {
        auto newdim = _dimensions - other.dimensions;
        return RTQuantity(newdim, _value / other.rawValue);
    }

    RTQuantity opBinary(string op, T : real)(T other) const
        if (op == "*" || op == "/")
    {
        return RTQuantity(_dimensions, mixin("_value" ~ op ~ "other"));
    }

    RTQuantity opBinary(string op, T : real)(T other) const
        if (op == "+" || op == "-")
    {
        checkDim(Dimensions.init);
        return RTQuantity(_dimensions, mixin("_value" ~ op ~ "other"));
    }

    RTQuantity opBinaryRight(string op, T : real)(T other) const
        if (op == "*")
    {
        return this * other;
    }

    RTQuantity opBinaryRight(string op, T : real)(T other) const
        if (op == "/")
    {
        return RTQuantity(-_dimensions, other / _value);
    }

    RTQuantity opBinaryRight(string op, T : real)(T other) const
        if (op != "*" && op != "/")
    {
        return mixin("this " ~ op ~ " other");
    }

    void opOpAssign(string op, T)(T other)
        if (op == "+" || op == "-")
    {
        checkDim(other.dimensions);
        mixin("_value " ~ op ~ "= other.rawValue;");
    }

    void opOpAssign(string op, T)(T other)
        if (op == "*" || op == "/")
    {
        checkDim(op == "*" 
                 ? _dimensions + other.dimensions
                 : _dimensions - other.dimensions);
        mixin("_value " ~ op ~ "= other.rawValue;");
    }

    void opOpAssign(string op, T : real)(T other)
        if (op == "*" || op == "/")
    {
        mixin("_value" ~ op ~ "= other;");
    }

    void opOpAssign(string op, T : real)(T other)
        if (op == "+" || op == "-")
    {
        checkDim(Dimensions.init);
        mixin("_value " ~ op ~ "= other;");
    }

    bool opEquals(T)(T other) const
        if (isRTQuantity!T || isQuantityType!T)
    {
        checkDim(other.dimensions);
        return _value == other.rawValue;
    }

    bool opEquals(T)(T other) const
        if (is(T : real))
    {
        checkDim(Dimensions.init);
        return _value == other;
    }
    
    int opCmp(T)(T other) const
        if (isRTQuantity!T || isQuantityType!T)
    {
        checkDim(other.dimensions);
        if (_value == other.rawValue)
            return 0;
        if (_value < other.rawValue)
            return -1;
        return 1;
    }

    int opCmp(T)(T other) const
        if (is(T : real))
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
        formattedWrite(sink, "%s ", _value);
        sink(_dimensions.toString);
    }
}

template isRTQuantity(T)
{
    import std.traits;
    static if (is(Unqual!T == RTQuantity))
        enum isRTQuantity = true;
    else
        enum isRTQuantity = false;
}

@name("RTQuantity.value")
unittest
{
    RTQuantity speed = 100 * meter / (5 * second);
    assert(speed.value(meter/second) == 20);
}

@name("RTQuantity.opCast(Quantity)")
unittest
{
    auto length = cast(Store!meter) RTQuantity(meter);
    assert(length == meter);
}

@name("RTQuantity.opAssign RTQ = RTQ")
unittest
{
    RTQuantity length = meter;
    length = 2 * meter;
    assert(length.value(meter) == 2);
}

@name("RTQuantity.opAssign RTQ = Q")
unittest
{
    RTQuantity length = meter;
    length = 2 * meter;
    assert(length.value(meter) == 2);
}

@name("RTQuantity.opUnary +Q -Q")
unittest
{
    RTQuantity length = meter;
    length = +length;
    assert(length == 1 * meter);
    length = -length;
    assert(length == -meter);
}

@name("RTQuantity.opBinary Q*N Q/N")
unittest
{
    RTQuantity time = second * 60;
    assert(time.value(second) == 60);
    time = second / 2;
    assert(time.value(second) == 1.0/2);
}

@name("RTQuantity.opBinary Q+Q Q-Q")
unittest
{
    RTQuantity length = meter;
    length = length + length;
    assert(length.value(meter) == 2);
    length = length - length;
    assert(length.value(meter) == 0);
}

@name("RTQuantity.opBinary Q*Q Q/Q")
unittest
{
    RTQuantity length = meter * 5;
    auto surface = length * length;
    assert(surface.value(square(meter)) == 5*5);
    auto length2 = surface / length;
    assert(length2.value(meter) == 5);
}

@name("RTQuantity.opBinaryRight N*Q")
unittest
{
    RTQuantity length = 100 * meter;
    assert(length == meter * 100);
}

@name("RTQuantity.opBinaryRight N/Q")
unittest
{
    RTQuantity x = 1 / (2 * RTQuantity(meter));
    assert(x.value(1/meter) == 1.0/2);
}

@name("RTQuantity.opOpAssign Q+=Q Q-=Q")
unittest
{
    RTQuantity time = 10 * second;
    time += 50 * second;
    assert(approxEqual(time.value(second), 60));
    time -= 40 * second;
    assert(approxEqual(time.value(second), 20));
}

@name("RTQuantity.opOpAssign Q*=N Q/=N")
unittest
{
    RTQuantity time = 20 * second;
    time *= 2;
    assert(approxEqual(time.value(second), 40));
    time /= 4;
    assert(approxEqual(time.value(second), 10));
}

@name("RTQuantity.opEquals")
unittest
{
    assert(1 * RTQuantity(minute) == 60 * RTQuantity(second));
}

@name("RTQuantity.opCmp")
unittest
{
    RTQuantity s = second, min = minute, h = hour;
    assert(s < min);
    assert(min <= min);
    assert(h > min);
    assert(h >= h);
}

@name("RT immutable quantities")
unittest
{
    immutable RTQuantity m = RTQuantity(meter);
    immutable RTQuantity s = RTQuantity(second);
    immutable RTQuantity length = 3e8 * m;
    immutable RTQuantity time = 1 * s;
    immutable RTQuantity speedOfLight = length / time;
    assert(speedOfLight == 3e8 * m/s);
    assert(speedOfLight > 1 * m/s);
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
