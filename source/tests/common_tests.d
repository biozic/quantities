module tests.common_tests;

import quantities;
import quantities.internal.dimensions;
import std.exception;
import std.math : approxEqual;

mixin template CommonTests(alias Q)
{
    static if (__traits(isSame, Q, Quantity))
    {
        enum meter = unit!(double, "L");
        enum second = unit!(double, "T");
        enum radian = unit!(double, null);
    }
    else static if (__traits(isSame, Q, QVariant))
    {
        enum meter = unit!double("L");
        enum second = unit!double("T");
        enum radian = unit!double(null);

        void checkIncompatibleDimensions(E)(lazy E expression,
                QVariant!double lhs, QVariant!double rhs)
        {
            auto e = collectException!DimensionException(expression());
            assert(e, "No DimensionException was thrown");
            assert(e.thisDim == lhs.dimensions);
            assert(e.otherDim == rhs.dimensions);
            assert(e.msg == "Incompatible dimensions");
        }

        void checkNotDimensionless(E)(lazy E expression, QVariant!double operand)
        {
            auto e = collectException!DimensionException(expression());
            assert(e, "No DimensionException was thrown");
            assert(e.thisDim == operand.dimensions);
            assert(e.otherDim == Dimensions.init);
            assert(e.msg == "Not dimensionless");
        }
    }
    else
    {
        static assert(false);
    }

    alias Length = typeof(meter);
    alias Time = typeof(second);
    alias Angle = typeof(radian);

    @("this()")
    @safe unittest
    {
        enum distance = Length(meter);
        enum angle = Angle(3.14);

        static if (isQuantity!Length)
        {
            enum length = unit!double("L");
            static assert(length.dimensions == distance.dimensions);
            static assert(!__traits(compiles, Length(2.0)));
        }

        static if (isQVariant!Length)
        {
            enum distance2 = Length(2.0);
            static assert(distance2.isDimensionless);
        }
    }

    @("get/alias this for dimensionless values")
    @safe pure unittest
    {
        enum double scalar = radian;
        static assert(scalar == 1);
    }

    @("value(Q)")
    @safe pure unittest
    {
        enum distance = meter;
        static assert(distance.value(meter) == 1);
    }

    @("isDimensionless")
    @safe pure unittest
    {
        static assert(!meter.isDimensionless);
        static assert(radian.isDimensionless);
    }

    @("isConsistentWith")
    @safe pure unittest
    {
        static assert(meter.isConsistentWith(meter));
        static assert(!meter.isConsistentWith(second));
    }

    @("opCast")
    @safe pure unittest
    {
        enum value = cast(double) radian;
        static if (isQuantity!Length)
        {
            static assert(!__traits(compiles, cast(double) meter));
        }
        static if (isQVariant!Length)
        {
            checkNotDimensionless(cast(double) meter, meter);
        }
    }

    @("opAssign Q")
    @safe pure unittest
    {
        Length l1, l2;
        l1 = l2 = meter;

        static if (isQuantity!Length)
        {
            static assert(!__traits(compiles, l1 = second));
        }
        static if (isQVariant!Length)
        {
            // QVariant allows assignment to a quantity with different dimensions
            l1 = second;
        }
    }

    @("opAssign T")
    @safe pure unittest
    {
        Angle angle;
        angle = 1;
    }

    @("opUnary + -")
    @safe pure unittest
    {
        enum plus = +meter;
        static assert(plus.value(meter) == 1);
        enum minus = -meter;
        static assert(minus.value(meter) == -1);
    }

    @("opUnary ++ --")
    @safe pure unittest
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
    @safe pure unittest
    {
        enum plus = meter + meter;
        static assert(plus.value(meter) == 2);
        enum minus = meter - meter;
        static assert(minus.value(meter) == 0);

        static if (isQuantity!Length)
        {
            static assert(!__traits(compiles, meter + second));
            static assert(!__traits(compiles, meter - second));
        }
        static if (isQVariant!Length)
        {
            checkIncompatibleDimensions(meter + second, meter, second);
            checkIncompatibleDimensions(meter - second, meter, second);
        }
    }

    @("opBinary Q+N N+Q Q-N N-Q")
    @safe pure unittest
    {
        enum a1 = radian + 10;
        static assert(a1.value(radian).approxEqual(11));
        enum a2 = radian - 10;
        static assert(a2.value(radian).approxEqual(-9));

        enum a3 = 10 + radian;
        static assert(a3.value(radian).approxEqual(11));
        enum a4 = 10 - radian;
        static assert(a4.value(radian).approxEqual(9));

        static if (isQuantity!Length)
        {
            static assert(!__traits(compiles, meter + 1));
            static assert(!__traits(compiles, meter - 1));
            static assert(!__traits(compiles, 1 + meter));
            static assert(!__traits(compiles, 1 - meter));
        }
        static if (isQVariant!Length)
        {
            checkNotDimensionless(meter + 1, meter);
            checkNotDimensionless(meter - 1, meter);
            checkNotDimensionless(1 + meter, meter);
            checkNotDimensionless(1 - meter, meter);
        }
    }

    @("opBinary Q*N, N*Q, Q/N, N/Q, Q%N, N%Q")
    @safe pure unittest
    {
        enum m1 = meter * 10;
        static assert(m1.value(meter).approxEqual(10));
        enum m2 = 10 * meter;
        static assert(m2.value(meter).approxEqual(10));
        enum m3 = meter / 10;
        static assert(m3.value(meter).approxEqual(0.1));
        enum m4 = 10 / meter;
        static assert(m4.dimensions == ~meter.dimensions);
        static assert(m4.value(1 / meter).approxEqual(10));
        enum m5 = m1 % 2;
        static assert(m5.value(meter).approxEqual(0));
        enum m6 = 10 % (2 * radian);
        static assert(m6.value(radian).approxEqual(0));
    }

    @("opBinary Q*Q, Q/Q, Q%Q")
    @safe pure unittest
    {
        enum surface = (10 * meter) * (10 * meter);
        static assert(surface.value(meter * meter).approxEqual(100));
        static assert(surface.dimensions == meter.dimensions.pow(2));

        enum speed = (10 * meter) / (5 * second);
        static assert(speed.value(meter / second).approxEqual(2));
        static assert(speed.dimensions == meter.dimensions / second.dimensions);

        enum surfaceMod10 = surface % (10 * meter * meter);
        static assert(surfaceMod10.value(meter * meter).approxEqual(0));
        static assert(surfaceMod10.dimensions == surface.dimensions);

        static if (isQuantity!Length)
        {
            static assert(!__traits(compiles, meter % second));
        }
        static if (isQVariant!Length)
        {
            checkIncompatibleDimensions(meter % second, meter, second);
        }
    }

    @("opBinary Q^^I Q^^R")
    @safe pure unittest
    {
        // Operator ^^ is not available for Quantity
        static if (isQVariant!Length)
        {
            enum x = 2 * meter;
            static assert((x ^^ 3).value(meter * meter * meter).approxEqual(8));
            static assert((x ^^ Rational(3)).value(meter * meter * meter).approxEqual(8));
        }
    }

    @("opOpAssign Q+=Q Q-=Q")
    @safe pure unittest
    {
        auto time = 10 * second;
        time += 50 * second;
        assert(time.value(second).approxEqual(60));
        time -= 40 * second;
        assert(time.value(second).approxEqual(20));
    }

    @("opOpAssign Q*=N Q/=N Q%=N")
    @safe pure unittest
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

        static if (isQuantity!Time)
        {
            static assert(!__traits(compiles, time %= 3));
        }
        static if (isQVariant!Time)
        {
            checkNotDimensionless(time %= 3, time);
        }
    }

    @("opOpAssign Q*=Q Q/=Q Q%=Q")
    @safe pure unittest
    {
        static if (isQuantity!Time)
        {
            auto angle = 50 * radian;
            angle *= 2 * radian;
            assert(angle.value(radian).approxEqual(100));
            angle /= 2 * radian;
            assert(angle.value(radian).approxEqual(50));
            angle %= 5 * radian;
            assert(angle.value(radian).approxEqual(0));

            auto time = second;
            static assert(!__traits(compiles, time *= second));
            static assert(!__traits(compiles, time /= second));
            static assert(!__traits(compiles, time %= second));
        }

        static if (isQVariant!Time)
        {
            auto angle = 2 * radian;
            angle *= 2 * radian;
            assert(angle.value(radian).approxEqual(4));
            angle /= 2 * radian;
            assert(angle.value(radian).approxEqual(2));

            auto qty = 100 * meter;
            qty *= second;
            qty /= 20 * second;
            qty %= 5 * second;
            assert(qty.value(meter / second).approxEqual(0));
        }
    }

    @("opEquals Q==Q Q==N")
    @safe pure unittest
    {
        enum minute = 60 * second;
        static assert(minute == 60 * second);
        static assert(radian == 1);

        static if (isQuantity!Time)
        {
            static assert(!__traits(compiles, meter == second));
            static assert(!__traits(compiles, meter == 1));
        }
        static if (isQVariant!Time)
        {
            checkIncompatibleDimensions(meter == second, meter, second);
            checkNotDimensionless(meter == 1, meter);
        }
    }

    @("opCmp Q<Q")
    @safe pure unittest
    {
        enum minute = 60 * second;
        enum hour = 60 * minute;
        static assert(second < minute);
        static assert(minute <= minute);
        static assert(hour > minute);
        static assert(hour >= hour);

        static if (isQuantity!Time)
        {
            static assert(!__traits(compiles, second < meter));
        }
        static if (isQVariant!Time)
        {
            checkIncompatibleDimensions(meter < second, meter, second);
        }
    }

    @("opCmp Q<N")
    @safe pure unittest
    {
        enum angle = 2 * radian;
        static assert(angle < 4);
        static assert(angle <= 2);
        static assert(angle > 1);
        static assert(angle >= 2);

        static if (isQuantity!Time)
        {
            static assert(!__traits(compiles, meter < 1));
        }
        static if (isQVariant!Time)
        {
            checkNotDimensionless(meter < 1, meter);
        }
    }

    @("toString")
    unittest
    {
        import std.conv : text;

        auto length = 12 * meter;
        assert(length.text == "12 [L]", length.text);
    }

    @("immutable")
    @safe pure unittest
    {
        immutable inch = 0.0254 * meter;
        immutable minute = 60 * second;
        immutable speed = inch / minute;
    }

    @("square/sqrt")
    @safe unittest
    {
        enum m2 = square(3 * meter);
        static assert(m2.value(meter * meter).approxEqual(9));
        enum m = sqrt(m2);
        static assert(m.value(meter).approxEqual(3));
    }

    @("cubic/cbrt")
    @safe unittest
    {
        enum m3 = cubic(2 * meter);
        static assert(m3.value(meter * meter * meter).approxEqual(8));

        // Doesn't work at compile time
        auto m = cbrt(m3);
        assert(m.value(meter).approxEqual(2));
    }

    @("pow/nthRoot")
    @safe unittest
    {
        enum m5 = pow!5(2 * meter);
        static assert(m5.value(meter * meter * meter * meter * meter).approxEqual(2 ^^ 5));

        // Doesn't work at compile time
        auto m = nthRoot!5(m5);
        assert(m.value(meter).approxEqual(2));
    }

    @("abs")
    @safe unittest
    {
        static assert(abs(-meter) == meter);
    }

    // TODO: test generic parsing
}

mixin CommonTests!Quantity;
mixin CommonTests!QVariant;
