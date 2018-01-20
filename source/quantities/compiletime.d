/++
This module defines quantities that are statically checked for dimensional
consistency at compile-time.

The dimensions are part of their types, so that the compilation fails if an
operation or a function call is not dimensionally consistent.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.compiletime;

///
unittest
{
    import quantities.compiletime;
    import quantities.si;
    import std.format : format;
    import std.math : approxEqual;

    // Introductory example
    {
        // Use the predefined quantity types (in module quantities.si)
        Volume volume;
        Concentration concentration;
        Mass mass;

        // Define a new quantity type
        alias MolarMass = typeof(kilogram / mole);

        // I have to make a new solution at the concentration of 5 mmol/L
        concentration = 5.0 * milli(mole) / liter;

        // The final volume is 100 ml.
        volume = 100.0 * milli(liter);

        // The molar mass of my compound is 118.9 g/mol
        MolarMass mm = 118.9 * gram / mole;

        // What mass should I weigh?
        mass = concentration * volume * mm;
        assert(format("%s", mass) == "5.945e-05 [M]");
        // Wait! That's not really useful!
        assert(siFormat!"%.1f mg"(mass) == "59.5 mg");
    }

    // Working with predefined units
    {
        auto distance = 384_400 * kilo(meter); // From Earth to Moon
        auto speed = 299_792_458 * meter / second; // Speed of light
        auto time = distance / speed;
        assert(time.siFormat!"%.3f s" == "1.282 s");
    }

    // Dimensional correctness is check at compile-time
    {
        Mass mass;
        assert(!__traits(compiles, mass = 15 * meter));
        assert(!__traits(compiles, mass = 1.2));
    }

    // Calculations can be done at compile-time
    {
        enum distance = 384_400 * kilo(meter); // From Earth to Moon
        enum speed = 299_792_458 * meter / second; // Speed of light
        enum time = distance / speed;
        /* static */
        assert(time.siFormat!"%.3f s" == "1.282 s");
        // NB. Phobos can't format floating point values at run-time.
    }

    // Create a new unit from the predefined ones
    {
        auto inch = 2.54 * centi(meter);
        auto mile = 1609 * meter;
        assert(mile.value(inch).approxEqual(63_346)); // inches in a mile
        // NB. Cannot use siFormatter, because inches are not SI units
    }

    // Create a new unit with new dimensions
    {
        // Create a new base unit of currency
        auto euro = unit!(double, "C"); // C is the chosen dimension symol (for currency...)

        auto dollar = euro / 1.35;
        auto price = 2000 * dollar;
        assert(price.value(euro).approxEqual(1481)); // Price in euros
    }

    // Compile-time parsing
    {
        enum distance = si!"384_400 km";
        enum speed = si!"299_792_458 m/s";
        assert(is(typeof(distance) == Length));
        assert(is(typeof(speed) == Speed));
    }

    // Run-time parsing of statically typed Quantities
    {
        auto data = ["distance-to-the-moon" : "384_400 km", "speed-of-light" : "299_792_458 m/s"];
        auto distance = parseSI!Length(data["distance-to-the-moon"]);
        auto speed = parseSI!Speed(data["speed-of-light"]);
    }
}

import quantities.internal.dimensions;
import quantities.common;
import quantities.runtime;
import std.format;
import std.math;
import std.traits : isNumeric, isIntegral;

/++
A quantity checked at compile-time for dimensional consistency.

Params:
    N = the numeric type of the quantity.

See_Also:
    QVariant has the same public members and overloaded operators as Quantity.
+/
struct Quantity(N, alias dims)
{
    static assert(isNumeric!N);
    static assert(is(typeof(dims) : Dimensions));
    static assert(Quantity.sizeof == N.sizeof);

private:
    N _value;

    // Creates a new quantity with non-empty dimensions
    static Quantity make(T)(T scalar)
            if (isNumeric!T)
    {
        Quantity result;
        result._value = scalar;
        return result;
    }

    void ensureSameDim(const Dimensions d)() const
    {
        static assert(dimensions == d,
                "Dimension error: %s is not consistent with %s".format(dimensions, d));
    }

    void ensureEmpty(const Dimensions d)() const
    {
        static assert(d.empty, "Dimension error: %s instead of no dimensions".format(d));
    }

package(quantities):
    alias valueType = N;

    N rawValue() const
    {
        return _value;
    }

public:
    /++
    Creates a new quantity from another one with the same dimensions.

    If Q is a QVariant, throws a DimensionException if the parsed quantity
    doesn't have the same dimensions as Q. If Q is a Quantity, inconsistent
    dimensions produce a compilation error.
    +/
    this(Q)(auto ref const Q qty)
            if (isQuantity!Q)
    {
        ensureSameDim!(Q.dimensions);
        _value = qty._value;
    }

    /// ditto
    this(Q)(auto ref const Q qty)
            if (isQVariant!Q)
    {
        import std.exception;

        enforce(dimensions == qty.dimensions,
                new DimensionException("Incompatible dimensions", dimensions, qty.dimensions));
        _value = qty.rawValue;
    }

    /// Creates a new dimensionless quantity from a number
    this(T)(T scalar)
            if (isNumeric!T && isDimensionless)
    {
        _value = scalar;
    }

    /// The dimensions of the quantity
    enum dimensions = dims;

    /++
    Implicitly convert a dimensionless value to the value type.
    +/
    static if (isDimensionless)
    {
        N get() const
        {
            return _value;
        }

        alias get this;
    }

    /++
    Gets the _value of this quantity when expressed in the given target unit.

    If Q is a QVariant, throws a DimensionException if the parsed quantity
    doesn't have the same dimensions as Q. If Q is a Quantity, inconsistent
    dimensions produce a compilation error.
    +/
    N value(Q)(auto ref const Q target) const 
            if (isQuantity!Q)
    {
        mixin ensureSameDim!(Q.dimensions);
        return _value / target._value;
    }

    /// ditto
    N value(Q)(auto ref const Q target) const 
            if (isQVariant!Q)
    {
        import std.exception;

        enforce(dimensions == target.dimensions,
                new DimensionException("Incompatible dimensions", dimensions, target.dimensions));
        return _value / target.rawValue;
    }

    /++
    Test whether this quantity is dimensionless
    +/
    enum bool isDimensionless = dimensions.length == 0;

    /++
    Tests wheter this quantity has the same dimensions as another one.
    +/
    bool isConsistentWith(Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q)
    {
        return dimensions == qty.dimensions;
    }

    /++
    Returns the base unit of this quantity.
    +/
    Quantity baseUnit() @property const
    {
        return Quantity.make(1);
    }

    /++
    Cast a dimensionless quantity to a numeric type.

    The cast operation will throw DimensionException if the quantity is not
    dimensionless.
    +/
    static if (isDimensionless)
    {
        T opCast(T)() const 
                if (isNumeric!T)
        {
            return _value;
        }
    }

    // Assign from another quantity
    /// Operator overloading
    ref Quantity opAssign(Q)(auto ref const Q qty)
            if (isQuantity!Q)
    {
        ensureSameDim!(Q.dimensions);
        _value = qty._value;
        return this;
    }

    /// ditto
    ref Quantity opAssign(Q)(auto ref const Q qty)
            if (isQVariant!Q)
    {
        import std.exception;

        enforce(dimensions == qty.dimensions,
                new DimensionException("Incompatible dimensions", dimensions, qty.dimensions));
        _value = qty.rawValue;
        return this;
    }

    // Assign from a numeric value if this quantity is dimensionless
    /// ditto
    ref Quantity opAssign(T)(T scalar)
            if (isNumeric!T)
    {
        ensureEmpty!dimensions;
        _value = scalar;
        return this;
    }

    // Unary + and -
    /// ditto
    Quantity opUnary(string op)() const 
            if (op == "+" || op == "-")
    {
        return Quantity.make(mixin(op ~ "_value"));
    }

    // Unary ++ and --
    /// ditto
    Quantity opUnary(string op)()
            if (op == "++" || op == "--")
    {
        mixin(op ~ "_value;");
        return this;
    }

    // Add (or substract) two quantities if they share the same dimensions
    /// ditto
    Quantity opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQuantity!Q && (op == "+" || op == "-"))
    {
        ensureSameDim!(Q.dimensions);
        return Quantity.make(mixin("_value" ~ op ~ "qty._value"));
    }

    // Add (or substract) a dimensionless quantity and a number
    /// ditto
    Quantity opBinary(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        ensureEmpty!dimensions;
        return Quantity.make(mixin("_value" ~ op ~ "scalar"));
    }

    /// ditto
    Quantity opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        ensureEmpty!dimensions;
        return Quantity.make(mixin("scalar" ~ op ~ "_value"));
    }

    // Multiply or divide a quantity by a number
    /// ditto
    Quantity opBinary(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "*" || op == "/" || op == "%"))
    {
        return Quantity.make(mixin("_value" ~ op ~ "scalar"));
    }

    /// ditto
    Quantity opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && op == "*")
    {
        return Quantity.make(mixin("scalar" ~ op ~ "_value"));
    }

    /// ditto
    auto opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "/" || op == "%"))
    {
        alias RQ = Quantity!(N, dimensions.inverted());
        return RQ.make(mixin("scalar" ~ op ~ "_value"));
    }

    // Multiply or divide two quantities
    /// ditto
    auto opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQuantity!Q && (op == "*" || op == "/"))
    {
        alias RQ = Quantity!(N, mixin("dimensions" ~ op ~ "Q.dimensions"));
        return RQ.make(mixin("_value" ~ op ~ "qty._value"));
    }

    /// ditto
    Quantity opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQuantity!Q && (op == "%"))
    {
        ensureSameDim!(Q.dimensions);
        return Quantity.make(mixin("_value" ~ op ~ "qty._value"));
    }

    // Add/sub assign with a quantity that shares the same dimensions
    /// ditto
    void opOpAssign(string op, Q)(auto ref const Q qty)
            if (isQuantity!Q && (op == "+" || op == "-"))
    {
        ensureSameDim!(Q.dimensions);
        mixin("_value " ~ op ~ "= qty._value;");
    }

    // Add/sub assign a number to a dimensionless quantity
    /// ditto
    void opOpAssign(string op, T)(T scalar)
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        ensureEmpty!dimensions;
        mixin("_value " ~ op ~ "= scalar;");
    }

    // Mul/div assign another dimensionless quantity to a dimensionsless quantity
    /// ditto
    void opOpAssign(string op, Q)(auto ref const Q qty)
            if (isQuantity!Q && (op == "*" || op == "/" || op == "%"))
    {
        ensureEmpty!dimensions;
        mixin("_value" ~ op ~ "= qty._value;");
    }

    // Mul/div assign a number to a quantity
    /// ditto
    void opOpAssign(string op, T)(T scalar)
            if (isNumeric!T && (op == "*" || op == "/"))
    {
        mixin("_value" ~ op ~ "= scalar;");
    }

    /// ditto
    void opOpAssign(string op, T)(T scalar)
            if (isNumeric!T && op == "%")
    {
        ensureEmpty!dimensions;
        mixin("_value" ~ op ~ "= scalar;");
    }

    // Exact equality between quantities
    /// ditto
    bool opEquals(Q)(auto ref const Q qty) const 
            if (isQuantity!Q)
    {
        ensureSameDim!(Q.dimensions);
        return _value == qty._value;
    }

    // Exact equality between a dimensionless quantity and a number
    /// ditto
    bool opEquals(T)(T scalar) const 
            if (isNumeric!T)
    {
        ensureEmpty!dimensions;
        return _value == scalar;
    }

    // Comparison between two quantities
    /// ditto
    int opCmp(Q)(auto ref const Q qty) const 
            if (isQuantity!Q)
    {
        ensureSameDim!(Q.dimensions);
        if (_value == qty._value)
            return 0;
        if (_value < qty._value)
            return -1;
        return 1;
    }

    // Comparison between a dimensionless quantity and a number
    /// ditto
    int opCmp(T)(T scalar) const 
            if (isNumeric!T)
    {
        ensureEmpty!dimensions;
        if (_value < scalar)
            return -1;
        if (_value > scalar)
            return 1;
        return 0;
    }

    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        sink.formatValue(_value, fmt);
        sink(" ");
        sink.formattedWrite!"%s"(dimensions);
    }
}

/++
Creates a new monodimensional unit as a Quantity.

Params:
    N = The numeric type of the value part of the quantity.

    dimSymbol = The symbol of the dimension of this quantity.

    rank = The rank of the dimensions of this quantity in the dimension vector,
           when combining this quantity with other oned.
+/
auto unit(N, string dimSymbol, size_t rank = size_t.max)()
{
    enum dims = Dimensions.mono(dimSymbol, rank);
    return Quantity!(N, dims).make(1);
}
///
unittest
{
    enum meter = unit!(double, "L", 1);
    enum kilogram = unit!(double, "M", 2);
    // Dimensions will be in this order: L M
}

/// Tests whether T is a quantity type.
template isQuantity(T)
{
    import std.traits : Unqual;

    alias U = Unqual!T;
    static if (is(U == Quantity!X, X...))
        enum isQuantity = true;
    else
        enum isQuantity = false;
}

/// Basic math functions that work with Quantity.
auto square(Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.pow(2)).make(quantity._value ^^ 2);
}

/// ditto
auto sqrt(Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.powinverse(2)).make(std.math.sqrt(quantity._value));
}

/// ditto
auto cubic(Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.pow(3)).make(quantity._value ^^ 3);
}

/// ditto
auto cbrt(Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.powinverse(3)).make(std.math.cbrt(quantity._value));
}

/// ditto
auto pow(int n, Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.pow(n)).make(std.math.pow(quantity._value, n));
}

/// ditto
auto nthRoot(int n, Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    return Quantity!(Q.valueType, Q.dimensions.powinverse(n)).make(
            std.math.pow(quantity._value, 1.0 / n));
}

/// ditto
Q abs(Q)(auto ref const Q quantity)
        if (isQuantity!Q)
{
    return Q.make(std.math.fabs(quantity._value));
}
