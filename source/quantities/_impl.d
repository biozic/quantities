// Written in the D programming language
/++
Runtime version.

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities._impl;

import quantities.base : Dimensions;
import quantities.si : SI;
import quantities.parsing : DimensionException;
import std.exception;

version (unittest)
    import std.math : approxEqual;

version (Have_tested) import tested;
else private struct name { string dummy; }

package:

struct RTQuantity
{
    private immutable(Dimensions) _dimensions;
    private bool _initialized = false;
    private real _value;

    package void checkDim(const(Dimensions) d) const
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

    @property immutable(Dimensions) dimensions() const
    {
        return _dimensions;
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

    package void resetTo(const RTQuantity other)
    {
        _value = other._value;
        cast(Dimensions) _dimensions = cast(Dimensions) other._dimensions; // Oohoooh...
    }

    void opAssign(const RTQuantity other)
    {
        if (_initialized)
        {
            checkDim(other._dimensions);
            _value = other._value;
        }
        else
            resetTo(other);
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
    auto speed = 100 * RT.meter / (5 * RT.second);
    assert(speed.value(RT.meter / RT.second) == 20);
}

@name("RTQuantity.opAssign Q = Q")
unittest
{
    RTQuantity length = RT.meter;
    length = 2 * RT.meter;
    assert(length.value(RT.meter) == 2);
}

@name("RTQuantity.opUnary +Q -Q")
unittest
{
    auto length = + RT.meter;
    assert(length == 1 * RT.meter);
    length = - RT.meter;
    assert(length == -1 * RT.meter);
}

@name("RTQuantity.opBinary Q*N Q/N")
unittest
{
    auto time = RT.second * 60;
    assert(time.value(RT.second) == 60);
    time = RT.second / 2;
    assert(time.value(RT.second) == 1.0/2);
}

@name("RTQuantity.opBinary Q+Q Q-Q")
unittest
{
    auto length = RT.meter + RT.meter;
    assert(length.value(RT.meter) == 2);
    length = length - RT.meter;
    assert(length.value(RT.meter) == 1);
}

@name("RTQuantity.opBinary Q*Q Q/Q")
unittest
{
    auto length = RT.meter * 5;
    auto surface = length * length;
    assert(surface.value(square(RT.meter)) == 5*5);
    auto length2 = surface / length;
    assert(length2.value(RT.meter) == 5);
}

@name("RTQuantity.opBinaryRight N*Q")
unittest
{
    auto length = 100 * RT.meter;
    assert(length == RT.meter * 100);
}

@name("RTQuantity.opBinaryRight N/Q")
unittest
{
    auto x = 1 / (2 * RT.meter);
    assert(x.value(1/RT.meter) == 1.0/2);
}

@name("RTQuantity.opOpAssign Q+=Q Q-=Q")
unittest
{
    auto time = 10 * RT.second;
    time += 50 * RT.second;
    assert(approxEqual(time.value(RT.second), 60));
    time -= 40 * RT.second;
    assert(approxEqual(time.value(RT.second), 20));
}

@name("RTQuantity.opOpAssign Q*=N Q/=N")
unittest
{
    auto time = 20 * RT.second;
    time *= 2;
    assert(approxEqual(time.value(RT.second), 40));
    time /= 4;
    assert(approxEqual(time.value(RT.second), 10));
}

@name("RTQuantity.opEquals")
unittest
{
    assert(1 * RT.minute == 60 * RT.second);
}

@name("RTQuantity.opCmp")
unittest
{
    assert(RT.second < RT.minute);
    assert(RT.minute <= RT.minute);
    assert(RT.hour > RT.minute);
    assert(RT.hour >= RT.hour);
}

@name("RT immutable quantities")
unittest
{
    immutable length = 3e8 * RT.meter;
    immutable time = 1 * RT.second;
    immutable speedOfLight = length / time;
    assert(speedOfLight == 3e8 * RT.meter / RT.second);
    assert(speedOfLight > 1 * RT.meter / RT.minute);
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
    return pow(unit, 2);
}

RTQuantity cubic(RTQuantity unit)
{
    return pow(unit, 3);
}

RTQuantity pow(RTQuantity unit, int n)
{
    return RTQuantity(unit._dimensions * n, unit._value ^^ n);
}

@name("RT square, cubic, pow")
unittest
{
    auto surface = 1 * square(RT.meter);
    auto volume = 1 * cubic(RT.meter);
    volume = 1 * pow(RT.meter, 3);
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
    auto surface = 25 * square(RT.meter);
    auto side = sqrt(surface);
    assert(approxEqual(side.value(RT.meter), 5));
    
    auto volume = 1 * RT.liter;
    side = cbrt(volume);
    assert(approxEqual(nthRoot!3(volume).value(RT.meter), 0.1));
    assert(approxEqual(side.value(RT.meter), 0.1));
}

RTQuantity abs(RTQuantity quantity)
{
    import std.math;
    return RTQuantity(quantity._dimensions, std.math.fabs(quantity._value));
}
@name("RT abs")
unittest
{
    auto deltaT = -10 * RT.second;
    assert(abs(deltaT) == 10 * RT.second);
}

struct RT
{

    static immutable(RTQuantity)[string] SIUnitSymbols;
    static real[string] SIPrefixSymbols;
    
    static immutable
    {
        RTQuantity meter;
        alias metre = meter;
        RTQuantity kilogram;
        RTQuantity second;
        RTQuantity ampere;
        RTQuantity kelvin;
        RTQuantity mole;
        RTQuantity candela;
        RTQuantity radian;
        RTQuantity steradian;
        RTQuantity hertz;
        RTQuantity newton;
        RTQuantity pascal;
        RTQuantity joule;
        RTQuantity watt;
        RTQuantity coulomb;
        RTQuantity volt;
        RTQuantity farad;
        RTQuantity ohm;
        RTQuantity siemens;
        RTQuantity weber;
        RTQuantity tesla;
        RTQuantity henry;
        RTQuantity lumen;
        RTQuantity lux;
        RTQuantity becquerel;
        RTQuantity gray;
        RTQuantity sievert;
        RTQuantity katal;
        RTQuantity gram;
        RTQuantity minute;
        RTQuantity hour;
        RTQuantity day;
        RTQuantity liter;
        alias litre = liter;
        RTQuantity ton;
        RTQuantity electronVolt;
        RTQuantity dalton;
    }
    
    shared static this()
    {
        meter = unit(SI.length, "m");
        kilogram = unit(SI.mass, "kg");
        second = unit(SI.time, "s");
        ampere = unit(SI.electricCurrent, "A");
        kelvin = unit(SI.temperature, "K");
        mole = unit(SI.amountOfSubstance, "mol");
        candela = unit(SI.luminousIntensity, "cd");
        radian = meter / meter;
        steradian = square(meter) / square(meter);
        hertz = 1 / second;
        newton = kilogram * meter / square(second);
        pascal = newton / square(meter);
        joule = newton * meter;
        watt = joule / second;
        coulomb = second * ampere;
        volt = watt / ampere;
        farad = coulomb / volt;
        ohm = volt / ampere;
        siemens = ampere / volt;
        weber = volt * second;
        tesla = weber / square(meter);
        henry = weber / ampere;
        lumen = candela / steradian;
        lux = lumen / square(meter);
        becquerel = 1 / second;
        gray = joule / kilogram;
        sievert = joule / kilogram;
        katal = mole / second;
        gram = 1e-3 * kilogram;
        minute = 60 * second;
        hour = 60 * minute;
        day = 24 * hour;
        liter = 1e-3 * cubic(meter);
        ton = 1e3 * kilogram;
        electronVolt = 1.60217653e-19 * joule;
        dalton = 1.66053886e-27 * kilogram;
        
        SIUnitSymbols = [
            "m" : meter,
            "kg" : kilogram,
            "s" : second,
            "A" : ampere,
            "K" : kelvin,
            "mol" : mole,
            "cd" : candela,
            "rad" : radian,
            "sr" : steradian,
            "Hz" : hertz,
            "N" : newton,
            "Pa" : pascal,
            "J" : joule,
            "W" : watt,
            "C" : coulomb,
            "V" : volt,
            "F" : farad,
            "Ω" : ohm,
            "S" : siemens,
            "Wb" : weber,
            "T" : tesla,
            "H" : henry,
            "lm" : lumen,
            "lx" : lux,
            "Bq" : becquerel,
            "Gy" : gray,
            "Sv" : sievert,
            "kat" : katal,
            "g" : gram,
            "min" : minute,
            "h" : hour,
            "d" : day,
            "l" : liter,
            "L" : liter,
            "t" : ton,
            "eV" : electronVolt,
            "Da" : dalton,
        ];
        
        SIPrefixSymbols = [
            "Y" : 1e24,
            "Z" : 1e21,
            "E" : 1e18,
            "P" : 1e15,
            "T" : 1e12,
            "G" : 1e9,
            "M" : 1e6,
            "k" : 1e3,
            "h" : 1e2,
            "da": 1e1,
            "d" : 1e-1,
            "c" : 1e-2,
            "m" : 1e-3,
            "µ" : 1e-6,
            "n" : 1e-9,
            "p" : 1e-12,
            "f" : 1e-15,
            "a" : 1e-18,
            "z" : 1e-21,
            "y" : 1e-24
        ];
    }
}
