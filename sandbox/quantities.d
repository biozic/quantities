module quantities;

import std.exception;
import std.string;
import std.traits;

version (unittest)
{
    import std.math : approxEqual;
}

/++
Quantity types which holds a value and some dimensions.

The value is stored internally as a field of type N.
A dimensionless quantity can be cast to a builtin numeric type.

Arithmetic operators (+ - * /), as well as assignment and comparison operators,
are defined when the operations are dimensionally correct, otherwise an error
occurs at compile-time.
+/
struct Quantity(N, Dim...)
{
    static assert(isFloatingPoint!N);

    /// The type of the underlying scalar value.
    alias valueType = N;
    
    /// The payload
    private N _value;
    
    /// The dimensions of the quantity.
    alias dimensions = Dim;

    template checkDim(string dim)
    {
        enum checkDim = 
            `static assert(Is!(` ~ dim ~ `).equalTo!dimensions,
                "Dimension error: %s is not compatible with %s"
                .format(.toString!(` ~ dim ~ `)(true), .toString!(dimensions)(true)));`;
    }

    // Creates a new quantity from another one that is dimensionally consistent
    package this(T)(T other)
        if (isQuantity!T)
    {
        mixin(checkDim!"other.dimensions");
        _value = other._value;
    }

    // Creates a new compile-time quantity from a raw numeric value
    package this(T)(T value)
        if (isNumeric!T)
    {
        _value = value;
    }    

    /++
    Get the scalar value of this quantity expressed in a combination of
    the base dimensions. This value is actually the payload of the Quantity struct.
    +/
    @property N rawValue() const
    {
        return _value;
    }
    
    /++
    Gets the scalar _value of this quantity expressed in the given target unit.
    +/
    N value(Q)(Q target) const
    {
        static assert(isQuantity!Q, "Unexpected type: " ~ Q.stringof);
        mixin(checkDim!"target.dimensions");
        return _value / target._value;
    }

    /++
    Tests wheter this quantity has the same dimensions 
    +/
    bool isConsistentWith(Q)(Q other) const
    {
        static assert(isQuantity!Q, "Unexpected type: " ~ Q.stringof);
        return Is!dimensions.equalTo!(other.dimensions);
    }

    /++
    Returns a new quantity where the value is stored in a field of type T.
    +/
    auto store(T)() const
    {
        static assert(isFloatingPoint!T, "Unexpected floating point type: " ~ T.stringof);
        return Quantity!(T, dimensions)(_value);
    }

    // Cast a dimensionless quantity to a scalar numeric type
    T opCast(T)()
        if (isNumeric!T)
    {
        mixin(checkDim!"TypeTuple!()");
        return _value;
    }

    // Assign from another quantity
    void opAssign(T)(T other)
        if (isQuantity!T)
    {
        mixin(checkDim!"other.dimensions");
        _value = other._value;
    }

    // Unary + and -
    auto opUnary(string op)() const
        if (op == "+" || op == "-")
    {
        return Quantity!(N, dimensions)(mixin(op ~ "_value"));
    }

    // Add (or substract) two quantities if they share the same dimensions
    auto opBinary(string op, T)(T other) const
        if (isQuantity!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"other.dimensions");
        return Quantity!(N, dimensions)(mixin("_value" ~ op ~ "other._value"));
    }

    // Add (or substract) a dimensionless quantity and a scalar
    auto opBinary(string op, T)(T other) const
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"TypeTuple!()");
        return Quantity!(N, dimensions)(mixin("_value" ~ op ~ "other"));
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        return opBinary!op(other);
    }

    // Multiply or divide two quantities
    auto opBinary(string op, T)(T other) const
        if (isQuantity!T && (op == "*" || op == "/"))
    {
        return mixin(`Quantity!(N, OpBinary!(dimensions, "` ~ op ~ `", other.dimensions))
                      (_value` ~ op ~ `other._value)`);
    }

    // Multiply or divide a quantity by a scalar factor
    auto opBinary(string op, T)(T other) const
        if (isNumeric!T && (op == "*" || op == "/"))
    {
        return Quantity!(N, dimensions)(mixin("_value" ~ op ~ "other"));
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && op == "*")
    {
        return this * other;
    }

    // ditto
    auto opBinaryRight(string op, T)(T other) const
        if (isNumeric!T && op == "/")
    {
        return Quantity!(N, Invert!dimensions)(other / _value);
    }

    // Add/sub assign with a quantity that shares the same dimensions
    void opOpAssign(string op, T)(T other)
        if (isQuantity!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"other.dimensions");
        mixin("_value " ~ op ~ "= other._value;");
    }

    // Add/sub assign a scalar to a dimensionless quantity
    void opOpAssign(string op, T)(T other)
        if (isNumeric!T && (op == "+" || op == "-"))
    {
        mixin(checkDim!"TypeTuple!()");
        mixin("_value " ~ op ~ "= other;");
    }
    
    // Mul/div assign with a dimensionless quantity
    void opOpAssign(string op, T)(T other)
        if (isQuantity!T && (op == "*" || op == "/"))
    {
        mixin(checkDim!"TypeTuple!()");
        mixin("_value" ~ op ~ "= other._value;");
    }

    // Mul/div assign with a scalar factor
    void opOpAssign(string op, T)(T other)
        if (isNumeric!T && (op == "*" || op == "/"))
    {
        mixin("_value" ~ op ~ "= other;");
    }

    // Exact equality between quantities
    bool opEquals(T)(T other) const
        if (isQuantity!T)
    {
        mixin(checkDim!"other.dimensions");
        return _value == other._value;
    }

    // Exact equality between a dimensionless quantity and a scalar
    bool opEquals(T)(T other) const
        if (isNumeric!T)
    {
        mixin(checkDim!"TypeTuple!()");
        return _value == other;
    }

    // Comparison between two quantities
    int opCmp(T)(T other) const
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
    int opCmp(T)(T other) const
        if (isNumeric!T)
    {
        mixin(checkDim!"TypeTuple!()");
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
        sink(.toString!dimensions());
    }
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

unittest // Quantity constructor
{
    enum time = Store!second(1 * minute);
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
}

unittest // Quantity.opCmp
{
    assert(second < minute);
    assert(minute <= minute);
    assert(hour > minute);
    assert(hour >= hour);
}

unittest // Compilation errors for incompatible dimensions
{
    static assert(!__traits(compiles, Store!meter(1 * second)));
    Store!meter m;
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

/// Creates a new monodimensional unit.
template unit(string symbol, N = double)
{
    enum unit = Quantity!(N, symbol, 1)(1.0);
}
///
unittest
{
    enum euro = unit!"€";
    static assert(isQuantity!(typeof(euro)));
    enum dollar = euro / 1.35;
    assert((1.35 * dollar).value(euro).approxEqual(1));
}

/++
Utility templates to create quantity types. The unit is only used to set the
dimensions, it doesn't bind the stored value to a particular unit. Use in 
conjunction with the store method of quantities.
+/
template Store(Q, N = double)
    if (isQuantity!Q)
{
    alias Store = Quantity!(N, Q.dimensions);
}

/// ditto
template Store(alias unit, N = double)
    if (isQuantity!(typeof(unit)))
{
    alias Store = Quantity!(N, unit.dimensions);
}

///
unittest // Store example
{
    alias Mass = Store!kilogram;
    Mass mass = 15 * ton;
    
    alias Surface = Store!(square(meter), float);
    assert(is(Surface.valueType == float));
    Surface s = 4 * square(meter);
}

unittest // Type conservation
{
    Store!(meter, float) length; 
    Store!(second, double) time;
    Store!(meter/second, real) speed;
    length = 1 * kilo(meter);
    time = 2 * hour;
    speed = length / time;
    assert(is(speed.valueType == real));
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

unittest // CT square, cubic, pow
{
    auto surface = 1 * square(meter);
    auto volume = 1 * cubic(meter);
    volume = 1 * pow!3(meter);
}

/// Returns the square root, the cubic root of the nth root of a quantity.
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
unittest // CT Powers of a quantity
{
    auto surface = 25 * square(meter);
    auto side = sqrt(surface);
    assert(side.value(meter).approxEqual(5));
    
    auto volume = 1 * liter;
    side = cbrt(volume);
    assert(nthRoot!3(volume).value(deci(meter)).approxEqual(1));
    assert(side.value(deci(meter)).approxEqual(1));
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


import std.math : PI;
import core.time : Duration, dur;

/// Converts a quantity of time to or from a core.time.Duration
auto fromDuration(Duration d)
{
    return d.total!"hnsecs" * hecto(nano(second));
}

/// ditto
Duration toDuration(Q)(Q quantity)
{
    import std.conv;
    auto hns = quantity.value(hecto(nano(second)));
    return dur!"hnsecs"(roundTo!long(hns));
}

///
unittest // Durations
{
    auto d = 4.dur!"msecs";
    auto t = fromDuration(d);
    assert(t.value(milli(second)).approxEqual(4));
    
    auto t2 = 3.5 * minute;
    auto d2 = t2.toDuration;
    assert(d2.get!"minutes" == 3 && d2.get!"seconds" == 30);
}

/++
Predefined SI units
+/
enum meter = unit!("m");
alias metre = meter; /// ditto
enum kilogram = unit!("kg"); /// ditto
enum second = unit!("s"); /// ditto
enum ampere = unit!("A"); /// ditto
enum kelvin = unit!("K"); /// ditto
enum mole = unit!("mol"); /// ditto
enum candela = unit!("cd"); /// ditto

enum radian = meter / meter; // ditto
enum steradian = square(meter) / square(meter); /// ditto
enum hertz = 1 / second; /// ditto
enum newton = kilogram * meter / square(second); /// ditto
enum pascal = newton / square(meter); /// ditto
enum joule = newton * meter; /// ditto
enum watt = joule / second; /// ditto
enum coulomb = second * ampere; /// ditto
enum volt = watt / ampere; /// ditto
enum farad = coulomb / volt; /// ditto
enum ohm = volt / ampere; /// ditto
enum siemens = ampere / volt; /// ditto
enum weber = volt * second; /// ditto
enum tesla = weber / square(meter); /// ditto
enum henry = weber / ampere; /// ditto
enum celsius = kelvin; /// ditto
enum lumen = candela / steradian; /// ditto
enum lux = lumen / square(meter); /// ditto
enum becquerel = 1 / second; /// ditto
enum gray = joule / kilogram; /// ditto
enum sievert = joule / kilogram; /// ditto
enum katal = mole / second; /// ditto

enum gram = 1e-3 * kilogram; /// ditto
enum minute = 60 * second; /// ditto
enum hour = 60 * minute; /// ditto
enum day = 24 * hour; /// ditto
enum degreeOfAngle = PI / 180 * radian; /// ditto
enum minuteOfAngle = degreeOfAngle / 60; /// ditto
enum secondOfAngle = minuteOfAngle / 60; /// ditto
enum hectare = 1e4 * square(meter); /// ditto
enum liter = 1e-3 * cubic(meter); /// ditto
alias litre = liter; /// ditto
enum ton = 1e3 * kilogram; /// ditto
enum electronVolt = 1.60217653e-19 * joule; /// ditto
enum dalton = 1.66053886e-27 * kilogram; /// ditto

/++
Predefined quantity type templates for SI quantities
+/
template Length(T) { alias Length = Store!(meter, T); }
template Mass(T) { alias Mass = Store!(kilogram, T); } /// ditto
template Time(T) { alias Time = Store!(second, T); } /// ditto
template ElectricCurrent(T) { alias ElectricCurrent = Store!(ampere, T); } /// ditto
template Temperature(T) { alias Temperature = Store!(kelvin, T); } /// ditto
template AmountOfSubstance(T) { alias AmountOfSubstance = Store!(mole, T); } /// ditto
template LuminousIntensity(T) { alias LuminousIntensity = Store!(candela, T); } /// ditto

template Area(T) { alias Area = Store!(square(meter), T); } /// ditto
template Volume(T) { alias Volume = Store!(cubic(meter), T); } /// ditto
template Speed(T) { alias Speed = Store!(meter/second, T); } /// ditto
template Acceleration(T) { alias Acceleration = Store!(meter/square(second), T); } /// ditto
template MassDensity(T) { alias MassDensity = Store!(kilogram/cubic(meter), T); } /// ditto
template CurrentDensity(T) { alias CurrentDensity = Store!(ampere/square(meter), T); } /// ditto
template MagneticFieldStrength(T) { alias MagneticFieldStrength = Store!(ampere/meter, T); } /// ditto
template Concentration(T) { alias Concentration = Store!(mole/cubic(meter), T); } /// ditto
template MolarConcentration(T) { alias MolarConcentration = Concentration!T; } /// ditto
template MassicConcentration(T) { alias MassicConcentration = Store!(kilogram/cubic(meter)); } /// ditto
template Luminance(T) { alias Luminance = Store!(candela/square(meter), T); } /// ditto
template RefractiveIndex(T) { alias RefractiveIndex = Store!(kilogram, T); } /// ditto

template Angle(T) { alias Angle = Store!(radian, T); } /// ditto
template SolidAngle(T) { alias SolidAngle = Store!(steradian, T); } /// ditto
template Frequency(T) { alias Frequency = Store!(hertz, T); } /// ditto
template Force(T) { alias Force = Store!(newton, T); } /// ditto
template Pressure(T) { alias Pressure = Store!(pascal, T); } /// ditto
template Energy(T) { alias Energy = Store!(joule, T); } /// ditto
template Work(T) { alias Work = Energy!T; } /// ditto
template Heat(T) { alias Heat = Energy!T; } /// ditto
template Power(T) { alias Power = Store!(watt, T); } /// ditto
template ElectricCharge(T) { alias ElectricCharge = Store!(coulomb, T); } /// ditto
template ElectricPotential(T) { alias ElectricPotential = Store!(volt, T); } /// ditto
template Capacitance(T) { alias Capacitance = Store!(farad, T); } /// ditto
template ElectricResistance(T) { alias ElectricResistance = Store!(ohm, T); } /// ditto
template ElectricConductance(T) { alias ElectricConductance = Store!(siemens, T); } /// ditto
template MagneticFlux(T) { alias MagneticFlux = Store!(weber, T); } /// ditto
template MagneticFluxDensity(T) { alias MagneticFluxDensity = Store!(tesla, T); } /// ditto
template Inductance(T) { alias Inductance = Store!(henry, T); } /// ditto
template LuminousFlux(T) { alias LuminousFlux = Store!(lumen, T); } /// ditto
template Illuminance(T) { alias Illuminance = Store!(lux, T); } /// ditto
template CelsiusTemperature(T) { alias CelsiusTemperature = Store!(celsius, T); } /// ditto
template Radioactivity(T) { alias Radioactivity = Store!(becquerel, T); } /// ditto
template AbsorbedDose(T) { alias AbsorbedDose = Store!(gray, T); } /// ditto
template DoseEquivalent(T) { alias DoseEquivalent = Store!(sievert, T); } /// ditto
template CatalyticActivity(T) { alias CatalyticActivity = Store!(katal, T); } /// ditto

/// Functions that apply a SI prefix to a unit.
auto yotta(Q)(Q base) { return base * 1e24; }
/// ditto
auto zetta(Q)(Q base) { return base * 1e21; }
/// ditto
auto exa(Q)(Q base) { return base * 1e18; }
/// ditto
auto peta(Q)(Q base) { return base * 1e15; }
/// ditto
auto tera(Q)(Q base) { return base * 1e12; }
/// ditto
auto giga(Q)(Q base) { return base * 1e9; }
/// ditto
auto mega(Q)(Q base) { return base * 1e6; }
/// ditto
auto kilo(Q)(Q base) { return base * 1e3; }
/// ditto
auto hecto(Q)(Q base) { return base * 1e2; }
/// ditto
auto deca(Q)(Q base) { return base * 1e1; }
/// ditto
auto deci(Q)(Q base) { return base * 1e-1; }
/// ditto
auto centi(Q)(Q base) { return base * 1e-2; }
/// ditto
auto milli(Q)(Q base) { return base * 1e-3; }
/// ditto
auto micro(Q)(Q base) { return base * 1e-6; }
/// ditto
auto nano(Q)(Q base) { return base * 1e-9; }
/// ditto
auto pico(Q)(Q base) { return base * 1e-12; }
/// ditto
auto femto(Q)(Q base) { return base * 1e-15; }
/// ditto
auto atto(Q)(Q base) { return base * 1e-18; }
/// ditto
auto zepto(Q)(Q base) { return base * 1e-21; }
/// ditto
auto yocto(Q)(Q base) { return base * 1e-24; }


import std.string;
public import std.typetuple;

// Adapted from std.typetuple
template Is(T...)
{
    alias T tuple;

    template equalTo(U...)
    {
        static if (T.length == U.length)
        {
            static if (T.length == 0)
                enum equalTo = true;
            else
                enum equalTo = T[0] == U[0] && Is!(T[1 .. $]).equalTo!(U[1 .. $]);
        }
        else
            enum equalTo = false;
    }
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", -1);
    alias U = TypeTuple!("a", 1, "b", -1);
    static assert(Is!T.equalTo!U);
}


template RemoveNull(Dim...)
{
    static assert(Dim.length % 2 == 0);

    static if (Dim.length == 0)
        alias RemoveNull = Dim;
    else static if (Dim[1] == 0)
        alias RemoveNull = RemoveNull!(Dim[2 .. $]);
    else
        alias RemoveNull = TypeTuple!(Dim[0], Dim[1], RemoveNull!(Dim[2 .. $]));
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", 0, "c", -1);
    assert(Is!(RemoveNull!T).equalTo!("a", 1, "c", -1));
}


template Filter(string s, Dim...)
{
    static assert(Dim.length % 2 == 0);
    
    static if (Dim.length == 0)
        alias Filter = Dim;
    else static if (Dim[0] == s)
        alias Filter = TypeTuple!(Dim[0], Dim[1], Filter!(s, Dim[2 .. $]));
    else
        alias Filter = Filter!(s, Dim[2 .. $]);
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", 0, "a", -1, "c", 2);
    assert(Is!(Filter!("a", T)).equalTo!("a", 1, "a", -1));
}


template FilterOut(string s, Dim...)
{
    static assert(Dim.length % 2 == 0);
    
    static if (Dim.length == 0)
        alias FilterOut = Dim;
    else static if (Dim[0] != s)
        alias FilterOut = TypeTuple!(Dim[0], Dim[1], FilterOut!(s, Dim[2 .. $]));
    else
        alias FilterOut = FilterOut!(s, Dim[2 .. $]);
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", 0, "a", -1, "c", 2);
    assert(Is!(FilterOut!("a", T)).equalTo!("b", 0, "c", 2));
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
    assert(Is!(Reduce!(0, T)).equalTo!("a", 2));
    alias U = TypeTuple!("a", 1, "a", -1);
    assert(Is!(Reduce!(0, U)).equalTo!("a", 0));
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
    assert(Is!(Simplify!T).equalTo!("a", 0, "b", 3, "c", 4));
}


template OpBinary(Dim...)
{
    static assert(Dim.length % 2 == 1);

    static if (staticIndexOf!("/", Dim) > 0)
    {
        // Division
        enum op = staticIndexOf!("/", Dim);
        alias numerator = Dim[0 .. op];
        alias denominator = Dim[op+1 .. $];
        alias OpBinary = RemoveNull!(Simplify!(TypeTuple!(numerator, Invert!(denominator))));
    }
    else static if (staticIndexOf!("*", Dim) > 0)
    {
        // Multiplication
        enum op = staticIndexOf!("*", Dim);
        alias OpBinary = RemoveNull!(Simplify!(TypeTuple!(Dim[0 .. op], Dim[op+1 .. $])));
    }
    else
        static assert(false, "No valid operator");
}
unittest
{
    alias T = TypeTuple!("a", 1, "b", 2, "c", -1);
    alias U = TypeTuple!("a", 1, "b", -2, "c", 2);
    assert(Is!(OpBinary!(T, "*", U)).equalTo!("a", 2, "c", 1));
    assert(Is!(OpBinary!(T, "/", U)).equalTo!("b", 4, "c", -3));
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
    assert(Is!(Invert!T).equalTo!("a", -1, "b", 1));
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
    assert(Is!(Pow!(2, T)).equalTo!("a", 2, "b", -2));
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
    assert(Is!(PowInverse!(2, T)).equalTo!("a", 2, "b", -1));
}


int[string] toAA(Dim...)()
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
unittest
{
    alias T = TypeTuple!("a", 1, "b", -1);
    assert(toAA!T == ["a":1, "b":-1]);
}


string toString(Dim...)(bool complete = false)
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
    string sym;
    foreach (i, d; Dim)
    {
        static if (i % 2 == 0)
            sym = d;
        else
            dimstrs ~= stringize(sym, d);
    }
    
    string result = dimstrs.filter!"a !is null".join(" ");
    if (!result.length)
        return complete ? "scalar" : "";
    
    return result;
}
