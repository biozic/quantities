module tests.quantity_tests;

import quantities;
import quantities.internal.dimensions;
import std.exception;
import std.math : approxEqual;

enum meter = unit!(double, "L");
enum second = unit!(double, "T");
enum radian = unit!(double, null);

alias Length = typeof(meter);
alias Time = typeof(second);
alias Angle = typeof(radian);

@("this()")
@safe pure nothrow unittest
{
    auto distance = Length(meter);
    auto angle = Angle(3.14);
    auto length = unit!double("L");
    assert(length.dimensions == distance.dimensions);
    assert(!__traits(compiles, Length(2.0)));
}

@("get/alias this for dimensionless values")
@safe pure nothrow unittest
{
    double scalar = radian;
    assert(scalar == 1);
}

@("value(Q)")
@safe pure nothrow unittest
{
    auto distance = meter;
    assert(distance.value(meter) == 1);
}

@("isDimensionless")
@safe pure nothrow unittest
{
    assert(!meter.isDimensionless);
    assert(radian.isDimensionless);
}

@("isConsistentWith")
@safe pure nothrow unittest
{
    assert(meter.isConsistentWith(meter));
    assert(!meter.isConsistentWith(second));
}

@("opCast")
@safe pure nothrow unittest
{
    auto value = cast(double) radian;
    assert(!__traits(compiles, cast(double) meter));
}

@("opAssign Q")
@safe pure nothrow unittest
{
    Length l1, l2;
    l1 = l2 = meter;

    assert(!__traits(compiles, l1 = second));
}

@("opAssign T")
@safe pure nothrow unittest
{
    Angle angle;
    angle = 1;
}

@("opUnary + -")
@safe pure nothrow unittest
{
    auto plus = +meter;
    assert(plus.value(meter) == 1);
    auto minus = -meter;
    assert(minus.value(meter) == -1);
}

@("opUnary ++ --")
@safe pure nothrow unittest
{
    auto len = meter;
    ++len;
    assert(len.value(meter).approxEqual(2));
    assert((len++).value(meter).approxEqual(2));
    assert(len.value(meter).approxEqual(3));
    --len;
    assert(len.value(meter).approxEqual(2));
    assert((len--).value(meter).approxEqual(2));
    assert(len.value(meter).approxEqual(1));
}

@("opBinary Q+Q Q-Q")
@safe pure nothrow unittest
{
    auto plus = meter + meter;
    assert(plus.value(meter) == 2);
    auto minus = meter - meter;
    assert(minus.value(meter) == 0);

    assert(!__traits(compiles, meter + second));
    assert(!__traits(compiles, meter - second));
}

@("opBinary Q+N N+Q Q-N N-Q")
@safe pure nothrow unittest
{
    auto a1 = radian + 10;
    assert(a1.value(radian).approxEqual(11));
    auto a2 = radian - 10;
    assert(a2.value(radian).approxEqual(-9));

    auto a3 = 10 + radian;
    assert(a3.value(radian).approxEqual(11));
    auto a4 = 10 - radian;
    assert(a4.value(radian).approxEqual(9));

    assert(!__traits(compiles, meter + 1));
    assert(!__traits(compiles, meter - 1));
    assert(!__traits(compiles, 1 + meter));
    assert(!__traits(compiles, 1 - meter));
}

@("opBinary Q*N, N*Q, Q/N, N/Q, Q%N, N%Q")
@safe pure nothrow unittest
{
    auto m1 = meter * 10;
    assert(m1.value(meter).approxEqual(10));
    auto m2 = 10 * meter;
    assert(m2.value(meter).approxEqual(10));
    auto m3 = meter / 10;
    assert(m3.value(meter).approxEqual(0.1));
    auto m4 = 10 / meter;
    assert(m4.dimensions == ~meter.dimensions);
    assert(m4.value(1 / meter).approxEqual(10));
    auto m5 = m1 % 2;
    assert(m5.value(meter).approxEqual(0));
    auto m6 = 10 % (2 * radian);
    assert(m6.value(radian).approxEqual(0));
}
version(LDC)
{
    @("opBinary Q*Q, Q/Q, Q%Q")
    @safe pure unittest
    {
        auto surface = (10 * meter) * (10 * meter);
        assert(surface.value(meter * meter).approxEqual(100));
        assert(surface.dimensions == meter.dimensions.pow(2));

        auto speed = (10 * meter) / (5 * second);
        assert(speed.value(meter / second).approxEqual(2));
        assert(speed.dimensions == meter.dimensions / second.dimensions);

        auto surfaceMod10 = surface % (10 * meter * meter);
        assert(surfaceMod10.value(meter * meter).approxEqual(0));
        assert(surfaceMod10.dimensions == surface.dimensions);

        assert(!__traits(compiles, meter % second));
    }
}
else
{
    @("opBinary Q*Q, Q/Q, Q%Q")
    @safe pure nothrow unittest
    {
        auto surface = (10 * meter) * (10 * meter);
        assert(surface.value(meter * meter).approxEqual(100));
        assert(surface.dimensions == meter.dimensions.pow(2));

        auto speed = (10 * meter) / (5 * second);
        assert(speed.value(meter / second).approxEqual(2));
        assert(speed.dimensions == meter.dimensions / second.dimensions);

        auto surfaceMod10 = surface % (10 * meter * meter);
        assert(surfaceMod10.value(meter * meter).approxEqual(0));
        assert(surfaceMod10.dimensions == surface.dimensions);

        assert(!__traits(compiles, meter % second));
    }
}
@("opBinary Q^^I Q^^R")
@safe pure nothrow unittest
{
    // Operator ^^ is not available for Quantity
}

@("opOpAssign Q+=Q Q-=Q")
@safe pure nothrow unittest
{
    auto time = 10 * second;
    time += 50 * second;
    assert(time.value(second).approxEqual(60));
    time -= 40 * second;
    assert(time.value(second).approxEqual(20));
}

@("opOpAssign Q*=N Q/=N Q%=N")
@safe pure nothrow unittest
{
    auto time = 20 * second;
    time *= 2;
    assert(time.value(second).approxEqual(40));
    time /= 4;
    assert(time.value(second).approxEqual(10));

    auto angle = 2 * radian;
    angle += 4;
    assert(angle.value(radian).approxEqual(6));
    angle -= 1;
    assert(angle.value(radian).approxEqual(5));
    angle %= 2;
    assert(angle.value(radian).approxEqual(1));

    assert(!__traits(compiles, time %= 3));
}

@("opOpAssign Q*=Q Q/=Q Q%=Q")
@safe pure nothrow unittest
{
    auto angle = 50 * radian;
    angle *= 2 * radian;
    assert(angle.value(radian).approxEqual(100));
    angle /= 2 * radian;
    assert(angle.value(radian).approxEqual(50));
    angle %= 5 * radian;
    assert(angle.value(radian).approxEqual(0));

    auto time = second;
    assert(!__traits(compiles, time *= second));
    assert(!__traits(compiles, time /= second));
    assert(!__traits(compiles, time %= second));
}

@("opEquals Q==Q Q==N")
@safe pure nothrow unittest
{
    auto minute = 60 * second;
    assert(minute == 60 * second);
    assert(radian == 1);

    assert(!__traits(compiles, meter == second));
    assert(!__traits(compiles, meter == 1));
}

@("opCmp Q<Q")
@safe pure nothrow unittest
{
    auto minute = 60 * second;
    auto hour = 60 * minute;
    assert(second < minute);
    assert(minute <= minute);
    assert(hour > minute);
    assert(hour >= hour);

    assert(!__traits(compiles, second < meter));
}

@("opCmp Q<N")
@safe pure nothrow unittest
{
    auto angle = 2 * radian;
    assert(angle < 4);
    assert(angle <= 2);
    assert(angle > 1);
    assert(angle >= 2);

    assert(!__traits(compiles, meter < 1));
}

@("toString")
unittest
{
    import std.conv : text;

    auto length = 12 * meter;
    assert(length.text == "12 [L]", length.text);
}

@("immutable")
@safe pure nothrow unittest
{
    immutable inch = 0.0254 * meter;
    immutable minute = 60 * second;
    immutable speed = inch / minute;
}

@("square/sqrt")
@safe nothrow unittest
{
    auto m2 = square(3 * meter);
    assert(m2.value(meter * meter).approxEqual(9));
    auto m = sqrt(m2);
    assert(m.value(meter).approxEqual(3));
}

@("cubic/cbrt")
@safe nothrow unittest
{
    auto m3 = cubic(2 * meter);
    assert(m3.value(meter * meter * meter).approxEqual(8));

    // Doesn't work at compile time
    auto m = cbrt(m3);
    assert(m.value(meter).approxEqual(2));
}

@("pow/nthRoot")
@safe nothrow unittest
{
    auto m5 = pow!5(2 * meter);
    assert(m5.value(meter * meter * meter * meter * meter).approxEqual(2 ^^ 5));

    auto m = nthRoot!5(m5);
    assert(m.value(meter).approxEqual(2));
}

@("abs")
@safe nothrow unittest
{
    assert(abs(-meter) == meter);
}

@("parseSI string")
unittest
{
    import quantities.si;

    auto resistance = parseSI("1000 m^2 kg s^-3 A^-2");
    assert(resistance == 1000 * ohm);
}

@("parseSI wstring")
unittest
{
    import quantities.si;

    auto resistance = parseSI("1000 m^2 kg s^-3 A^-2"w);
    assert(resistance == 1000 * ohm);
}

@("parseSI dstring")
unittest
{
    import quantities.si;

    auto resistance = parseSI("1000 m^2 kg s^-3 A^-2"d);
    assert(resistance == 1000 * ohm);
}
