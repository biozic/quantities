/++
This module defines dimensionally variant quantities, mainly for use at run-time.

The dimensions are stored in a field, along with the numerical value of the
quantity. Operations and function calls fail if they are not dimensionally
consistent, by throwing a `DimensionException`.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.runtime;

///
unittest
{
    import quantities.runtime;
    import quantities.si;
    import std.format : format;
    import std.math : approxEqual;

    // Note: the types of the predefined SI units (gram, mole, liter...)
    // are Quantity instances, not QVariant instance.

    // Introductory example
    {
        // I have to make a new solution at the concentration of 5 mmol/L
        QVariant!double concentration = 5.0 * milli(mole) / liter;

        // The final volume is 100 ml.
        QVariant!double volume = 100.0 * milli(liter);

        // The molar mass of my compound is 118.9 g/mol
        QVariant!double molarMass = 118.9 * gram / mole;

        // What mass should I weigh?
        QVariant!double mass = concentration * volume * molarMass;
        assert(format("%s", mass) == "5.945e-05 [M]");
        // Wait! That's not really useful!
        assert(siFormat!"%.1f mg"(mass) == "59.5 mg");
    }

    // Working with predefined units
    {
        QVariant!double distance = 384_400 * kilo(meter); // From Earth to Moon
        QVariant!double speed = 299_792_458 * meter / second; // Speed of light
        QVariant!double time = distance / speed;
        assert(time.siFormat!"%.3f s" == "1.282 s");
    }

    // Dimensional correctness
    {
        import std.exception : assertThrown;

        QVariant!double mass = 4 * kilogram;
        assertThrown!DimensionException(mass + meter);
        assertThrown!DimensionException(mass == 1.2);
    }

    // Create a new unit from the predefined ones
    {
        QVariant!double inch = 2.54 * centi(meter);
        QVariant!double mile = 1609 * meter;
        assert(mile.value(inch).approxEqual(63_346)); // inches in a mile
        // NB. Cannot use siFormatter, because inches are not SI units
    }

    // Create a new unit with new dimensions
    {
        // Create a new base unit of currency
        QVariant!double euro = unit!double("C"); // C is the chosen dimension symol (for currency...)

        QVariant!double dollar = euro / 1.35;
        QVariant!double price = 2000 * dollar;
        assert(price.value(euro).approxEqual(1481)); // Price in euros
    }

    // Run-time parsing
    {
        auto data = ["distance-to-the-moon" : "384_400 km", "speed-of-light" : "299_792_458 m/s"];
        QVariant!double distance = parseSI(data["distance-to-the-moon"]);
        QVariant!double speed = parseSI(data["speed-of-light"]);
        QVariant!double time = distance / speed;
    }
}

import quantities.internal.dimensions;
import quantities.common;
import quantities.compiletime;

import std.conv;
import std.exception;
import std.format;
import std.math;
import std.string;
import std.traits;

/++
Exception thrown when operating on two units that are not interconvertible.
+/
class DimensionException : Exception
{
    /// Holds the dimensions of the quantity currently operated on
    Dimensions thisDim;
    /// Holds the dimensions of the eventual other operand
    Dimensions otherDim;

    mixin basicExceptionCtors;

    this(string msg, Dimensions thisDim, Dimensions otherDim,
            string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        super(msg, file, line, next);
        this.thisDim = thisDim;
        this.otherDim = otherDim;
    }
}
///
unittest
{
    import std.exception : assertThrown;

    enum meter = unit!double("L");
    enum second = unit!double("T");
    assertThrown!DimensionException(meter + second);
}

/++
A dimensionnaly variant quantity.

Params:
    N = the numeric type of the quantity.

See_Also:
    QVariant has the same public members and overloaded operators as Quantity.
+/
struct QVariant(N)
{
    static assert(isNumeric!N, "Incompatible type: " ~ N.stringof);

private:
    N _value;
    Dimensions _dimensions;

    void checkDim(Dimensions dim) @safe pure const
    {
        enforce(_dimensions == dim,
                new DimensionException("Incompatible dimensions", _dimensions, dim));
    }

    void checkDimensionless() @safe pure const
    {
        enforce(_dimensions.empty, new DimensionException("Not dimensionless",
                _dimensions, Dimensions.init));
    }

package(quantities):
    alias valueType = N;

    N rawValue() const
    {
        return _value;
    }

public:
    // Creates a new quantity with non-empty dimensions
    this(T)(T scalar, const Dimensions dim)
            if (isNumeric!T)
    {
        _value = scalar;
        _dimensions = dim;
    }

    /// Creates a new quantity from another one with the same dimensions
    this(Q)(auto ref const Q qty)
            if (isQVariant!Q)
    {
        _value = qty._value;
        _dimensions = qty._dimensions;
    }

    /// ditto
    this(Q)(auto ref const Q qty)
            if (isQuantity!Q)
    {
        this = qty.qVariant;
    }

    /// Creates a new dimensionless quantity from a number
    this(T)(T scalar)
            if (isNumeric!T)
    {
        _dimensions = Dimensions.init;
        _value = scalar;
    }

    /// Returns the dimensions of the quantity
    Dimensions dimensions() @property const
    {
        return _dimensions;
    }

    /++
    Implicitly convert a dimensionless value to the value type.

    Calling get will throw DimensionException if the quantity is not
    dimensionless.
    +/
    N get() const
    {
        checkDimensionless;
        return _value;
    }

    alias get this;

    /++
    Gets the _value of this quantity when expressed in the given target unit.
    +/
    N value(Q)(auto ref const Q target) const 
            if (isQVariantOrQuantity!Q)
    {
        checkDim(target.dimensions);
        return _value / target.rawValue;
    }
    ///
    @safe pure unittest
    {
        auto minute = unit!int("T");
        auto hour = 60 * minute;

        QVariant!int time = 120 * minute;
        assert(time.value(hour) == 2);
        assert(time.value(minute) == 120);
    }

    /++
    Test whether this quantity is dimensionless
    +/
    bool isDimensionless() @property const
    {
        return _dimensions.empty;
    }

    /++
    Tests wheter this quantity has the same dimensions as another one.
    +/
    bool isConsistentWith(Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q)
    {
        return _dimensions == qty.dimensions;
    }
    ///
    @safe pure unittest
    {
        auto second = unit!double("T");
        auto minute = 60 * second;
        auto meter = unit!double("L");

        assert(minute.isConsistentWith(second));
        assert(!meter.isConsistentWith(second));
    }

    /++
    Returns the base unit of this quantity.
    +/
    QVariant baseUnit() @property const
    {
        return QVariant(1, _dimensions);
    }

    /++
    Cast a dimensionless quantity to a numeric type.

    The cast operation will throw DimensionException if the quantity is not
    dimensionless.
    +/
    T opCast(T)() const 
            if (isNumeric!T)
    {
        checkDimensionless;
        return _value;
    }

    // Assign from another quantity
    /// Operator overloading
    ref QVariant opAssign(Q)(auto ref const Q qty)
            if (isQVariantOrQuantity!Q)
    {
        _dimensions = qty.dimensions;
        _value = qty.rawValue;
        return this;
    }

    // Assign from a numeric value if this quantity is dimensionless
    /// ditto
    ref QVariant opAssign(T)(T scalar)
            if (isNumeric!T)
    {
        _dimensions = Dimensions.init;
        _value = scalar;
        return this;
    }

    // Unary + and -
    /// ditto
    QVariant!N opUnary(string op)() const 
            if (op == "+" || op == "-")
    {
        return QVariant(mixin(op ~ "_value"), _dimensions);
    }

    // Unary ++ and --
    /// ditto
    QVariant!N opUnary(string op)()
            if (op == "++" || op == "--")
    {
        mixin(op ~ "_value;");
        return this;
    }

    // Add (or substract) two quantities if they share the same dimensions
    /// ditto
    QVariant!N opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "+" || op == "-"))
    {
        checkDim(qty.dimensions);
        return QVariant(mixin("_value" ~ op ~ "qty.rawValue"), _dimensions);
    }

    /// ditto
    QVariant!N opBinaryRight(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "+" || op == "-"))
    {
        checkDim(qty.dimensions);
        return QVariant(mixin("qty.rawValue" ~ op ~ "_value"), _dimensions);
    }

    // Add (or substract) a dimensionless quantity and a number
    /// ditto
    QVariant!N opBinary(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDimensionless;
        return QVariant(mixin("_value" ~ op ~ "scalar"), _dimensions);
    }

    /// ditto
    QVariant!N opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDimensionless;
        return QVariant(mixin("scalar" ~ op ~ "_value"), _dimensions);
    }

    // Multiply or divide a quantity by a number
    /// ditto
    QVariant!N opBinary(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "*" || op == "/" || op == "%"))
    {
        return QVariant(mixin("_value" ~ op ~ "scalar"), _dimensions);
    }

    /// ditto
    QVariant!N opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && op == "*")
    {
        return QVariant(mixin("scalar" ~ op ~ "_value"), _dimensions);
    }

    /// ditto
    QVariant!N opBinaryRight(string op, T)(T scalar) const 
            if (isNumeric!T && (op == "/" || op == "%"))
    {
        return QVariant(mixin("scalar" ~ op ~ "_value"), ~_dimensions);
    }

    // Multiply or divide two quantities
    /// ditto
    QVariant!N opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "*" || op == "/"))
    {
        return QVariant(mixin("_value" ~ op ~ "qty.rawValue"),
                mixin("_dimensions" ~ op ~ "qty.dimensions"));
    }

    /// ditto
    QVariant!N opBinaryRight(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "*" || op == "/"))
    {
        return QVariant(mixin("qty.rawValue" ~ op ~ "_value"),
                mixin("qty.dimensions" ~ op ~ "_dimensions"));
    }

    /// ditto
    QVariant!N opBinary(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "%"))
    {
        checkDim(qty.dimensions);
        return QVariant(_value % qty.rawValue, _dimensions);
    }

    /// ditto
    QVariant!N opBinaryRight(string op, Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q && (op == "%"))
    {
        checkDim(qty.dimensions);
        return QVariant(qty.rawValue % _value, _dimensions);
    }

    /// ditto
    QVariant!N opBinary(string op, T)(T power) const 
            if (isIntegral!T && op == "^^")
    {
        return QVariant(_value ^^ power, _dimensions.pow(Rational(power)));
    }

    /// ditto
    QVariant!N opBinary(string op)(Rational power) const 
            if (op == "^^")
    {
        static if (isIntegral!N)
            auto newValue = std.math.pow(_value, cast(real) power).roundTo!N;
        else static if (isFloatingPoint!N)
            auto newValue = std.math.pow(_value, cast(real) power);
        else
            static assert(false, "Operation not defined for " ~ QVariant!N.stringof);
        return QVariant(newValue, _dimensions.pow(power));
    }

    // Add/sub assign with a quantity that shares the same dimensions
    /// ditto
    void opOpAssign(string op, Q)(auto ref const Q qty)
            if (isQVariantOrQuantity!Q && (op == "+" || op == "-"))
    {
        checkDim(qty.dimensions);
        mixin("_value " ~ op ~ "= qty.rawValue;");
    }

    // Add/sub assign a number to a dimensionless quantity
    /// ditto
    void opOpAssign(string op, T)(T scalar)
            if (isNumeric!T && (op == "+" || op == "-"))
    {
        checkDimensionless;
        mixin("_value " ~ op ~ "= scalar;");
    }

    // Mul/div assign another quantity to a quantity
    /// ditto
    void opOpAssign(string op, Q)(auto ref const Q qty)
            if (isQVariantOrQuantity!Q && (op == "*" || op == "/" || op == "%"))
    {
        mixin("_value" ~ op ~ "= qty.rawValue;");
        static if (op == "*")
            _dimensions = _dimensions * qty.dimensions;
        else
            _dimensions = _dimensions / qty.dimensions;
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
        checkDimensionless;
        mixin("_value" ~ op ~ "= scalar;");
    }

    // Exact equality between quantities
    /// ditto
    bool opEquals(Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q)
    {
        checkDim(qty.dimensions);
        return _value == qty.rawValue;
    }

    // Exact equality between a dimensionless quantity and a number
    /// ditto
    bool opEquals(T)(T scalar) const 
            if (isNumeric!T)
    {
        checkDimensionless;
        return _value == scalar;
    }

    // Comparison between two quantities
    /// ditto
    int opCmp(Q)(auto ref const Q qty) const 
            if (isQVariantOrQuantity!Q)
    {
        checkDim(qty.dimensions);
        if (_value == qty.rawValue)
            return 0;
        if (_value < qty.rawValue)
            return -1;
        return 1;
    }

    // Comparison between a dimensionless quantity and a number
    /// ditto
    int opCmp(T)(T scalar) const 
            if (isNumeric!T)
    {
        checkDimensionless;
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
        sink.formattedWrite!"%s"(_dimensions);
    }
}

/++
Creates a new monodimensional unit as a QVariant.

Params:
    N = The numeric type of the value part of the quantity.

    dimSymbol = The symbol of the dimension of this quantity.

    rank = The rank of the dimensions of this quantity in the dimension vector,
           when combining this quantity with other oned.
+/
QVariant!N unit(N)(string dimSymbol, size_t rank = size_t.max)
{
    return QVariant!N(N(1), Dimensions.mono(dimSymbol, rank));
}
///
unittest
{
    enum meter = unit!double("L", 1);
    enum kilogram = unit!double("M", 2);
    // Dimensions will be in this order: L M
}

// Tests whether T is a quantity type
template isQVariant(T)
{
    alias U = Unqual!T;
    static if (is(U == QVariant!X, X...))
        enum isQVariant = true;
    else
        enum isQVariant = false;
}

enum isQVariantOrQuantity(T) = isQVariant!T || isQuantity!T;

/// Turns a Quantity into a QVariant
auto qVariant(Q)(auto ref const Q qty)
        if (isQuantity!Q)
{
    return QVariant!(Q.valueType)(qty.rawValue, qty.dimensions);
}

/// Turns a scalar into a dimensionless QVariant
auto qVariant(N)(N scalar)
        if (isNumeric!N)
{
    return QVariant!N(scalar, Dimensions.init);
}

/// Basic math functions that work with QVariant.
auto square(Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(quantity._value ^^ 2, quantity._dimensions.pow(2));
}

/// ditto
auto sqrt(Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(std.math.sqrt(quantity._value), quantity._dimensions.powinverse(2));
}

/// ditto
auto cubic(Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(quantity._value ^^ 3, quantity._dimensions.pow(3));
}

/// ditto
auto cbrt(Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(std.math.cbrt(quantity._value), quantity._dimensions.powinverse(3));
}

/// ditto
auto pow(Q)(auto ref const Q quantity, Rational r)
        if (isQVariant!Q)
{
    return quantity ^^ r;
}

auto pow(Q, I)(auto ref const Q quantity, I n)
        if (isQVariant!Q && isIntegral!I)
{
    return quantity ^^ Rational(n);
}

/// ditto
auto nthRoot(Q)(auto ref const Q quantity, Rational r)
        if (isQVariant!Q)
{
    return quantity ^^ r.inverted;
}

auto nthRoot(Q, I)(auto ref const Q quantity, I n)
        if (isQVariant!Q && isIntegral!I)
{
    return nthRoot(quantity, Rational(n));
}

/// ditto
Q abs(Q)(auto ref const Q quantity)
        if (isQVariant!Q)
{
    return Q(std.math.fabs(quantity._value), quantity._dimensions);
}
