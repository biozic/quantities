/++
Structs used to define units: rational numbers and dimensions.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.internal.dimensions;

import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.format;
import std.math;
import std.string;
import std.traits;

/// Reduced implementation of a rational number
struct Rational
{
private:
    int num = 0;
    int den = 1;

    invariant()
    {
        assert(den != 0);
    }

    void normalize() @safe pure nothrow
    {
        if (den == 1)
            return;
        if (den < 0)
        {
            num = -num;
            den = -den;
        }
        immutable g = gcd(num, den);
        num /= g;
        den /= g;
    }

    bool isNormalized() @safe pure nothrow const
    {
        return den >= 0 && gcd(num, den) == 1;
    }

public:
    /++
    Create a rational number.

    Params:
        num = The numerator
        den = The denominator
    +/
    this(int num, int den = 1) @safe pure nothrow
    {
        assert(den != 0, "Denominator is zero");
        this.num = num;
        this.den = den;
        normalize();
    }

    bool isInt() @property @safe pure nothrow const
    {
        return den == 1;
    }

    Rational inverted() @property @safe pure nothrow const
    {
        Rational result;
        result.num = den;
        result.den = num;
        assert(isNormalized);
        return result;
    }

    void opOpAssign(string op)(Rational other) @safe pure nothrow 
            if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        mixin("this = this" ~ op ~ "other;");
        assert(isNormalized);
    }

    void opOpAssign(string op)(int value) @safe pure nothrow 
            if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        mixin("this = this" ~ op ~ "value;");
        assert(isNormalized);
    }

    Rational opUnary(string op)() @safe pure nothrow const 
            if (op == "+" || op == "-")
    out (result)
    {
        assert(result.isNormalized);
    }
    body
    {
        return Rational(mixin(op ~ "num"), den);
    }

    Rational opBinary(string op)(Rational other) @safe pure nothrow const 
            if (op == "+" || op == "-")
    {
        auto ret = Rational(mixin("num * other.den" ~ op ~ "other.num * den"), den * other.den);
        ret.normalize();
        return ret;
    }

    Rational opBinary(string op)(Rational other) @safe pure nothrow const 
            if (op == "*")
    {
        auto ret = Rational(num * other.num, den * other.den);
        ret.normalize();
        return ret;
    }

    Rational opBinary(string op)(Rational other) @safe pure nothrow const 
            if (op == "/")
    {
        auto ret = Rational(num * other.den, den * other.num);
        ret.normalize();
        return ret;
    }

    Rational opBinary(string op)(int value) @safe pure nothrow const 
            if (op == "+" || op == "-" || op == "*" || op == "/")
    out
    {
        assert(isNormalized);
    }
    body
    {
        return mixin("this" ~ op ~ "Rational(value)");
    }

    bool opEquals(Rational other) @safe pure nothrow const
    {
        return num == other.num && den == other.den;
    }

    bool opEquals(int value) @safe pure nothrow const
    {
        return num == value && den == 1;
    }

    int opCmp(Rational other) @safe pure nothrow const
    {
        immutable diff = (num / cast(double) den) - (other.num / cast(double) other.den);
        if (diff == 0)
            return 0;
        if (diff > 0)
            return 1;
        return -1;
    }

    int opCmp(int value) @safe pure nothrow const
    {
        return opCmp(Rational(value));
    }

    T opCast(T)() @safe pure nothrow const 
            if (isNumeric!T)
    {
        return num / cast(T) den;
    }

    void toString(scope void delegate(const(char)[]) sink) const
    {
        sink.formattedWrite!"%d"(num);
        if (den != 1)
        {
            sink("/");
            sink.formattedWrite!"%d"(den);
        }
    }
}

private int gcd(int x, int y) @safe pure nothrow
{
    if (x == 0 || y == 0)
        return 1;

    int tmp;
    int a = abs(x);
    int b = abs(y);
    while (a > 0)
    {
        tmp = a;
        a = b % a;
        b = tmp;
    }
    return b;
}

/// Struct describing properties of a dimension in a dimension vector.
struct Dim
{
    string symbol; /// The symbol of the dimension
    Rational power; /// The power of the dimension
    size_t rank = size_t.max; /// The rank of the dimension in the vector

    this(string symbol, Rational power, size_t rank = size_t.max) @safe pure nothrow
    {
        this.symbol = symbol;
        this.power = power;
        this.rank = rank;
    }

    this(string symbol, int power, size_t rank = size_t.max) @safe pure nothrow
    {
        this(symbol, Rational(power), rank);
    }

    int opCmp(Dim other) @safe pure nothrow const
    {
        if (rank == other.rank)
        {
            if (symbol < other.symbol)
                return -1;
            else if (symbol > other.symbol)
                return 1;
            else
                return 0;
        }
        else
        {
            if (rank < other.rank)
                return -1;
            else if (rank > other.rank)
                return 1;
            else
                assert(false);
        }
    }

    ///
    void toString(scope void delegate(const(char)[]) sink) const
    {
        if (power == 0)
            return;
        if (power == 1)
            sink(symbol);
        else
        {
            sink.formattedWrite!"%s"(symbol);
            sink("^");
            sink.formattedWrite!"%s"(power);
        }
    }
}

private immutable(Dim)[] inverted(immutable(Dim)[] source) @safe pure nothrow
{
    Dim[] target = source.dup;
    foreach (ref dim; target)
        dim.power = -dim.power;
    return target.immut;
}

private void insertAndSort(ref Dim[] list, string symbol, Rational power, size_t rank) @safe pure
{
    auto pos = list.countUntil!(d => d.symbol == symbol)();
    if (pos >= 0)
    {
        // Merge the dimensions
        list[pos].power += power;
        if (list[pos].power == 0)
        {
            try
                list = list.remove(pos);
            catch (Exception) // remove only throws when it has multiple arguments
                assert(false);

            // Necessary to compare dimensionless values
            if (!list.length)
                list = null;
        }
    }
    else
    {
        // Insert the new dimension
        auto dim = Dim(symbol, power, rank);
        pos = list.countUntil!(d => d > dim);
        if (pos < 0)
            pos = list.length;
        list.insertInPlace(pos, dim);
    }
    assert(list.isSorted);
}

private immutable(Dim)[] immut(Dim[] source) @trusted pure nothrow
{
    if (__ctfe)
        return source.idup;
    else
        return source.assumeUnique;
}

private immutable(Dim)[] insertSorted(immutable(Dim)[] source, string symbol,
        Rational power, size_t rank) @safe pure
{
    if (power == 0)
        return source;

    if (!source.length)
        return [Dim(symbol, power, rank)].immut;

    Dim[] list = source.dup;
    insertAndSort(list, symbol, power, rank);
    return list.immut;
}
private immutable(Dim)[] insertSorted(immutable(Dim)[] source, immutable(Dim)[] other) @safe pure
{
    Dim[] list = source.dup;
    foreach (dim; other)
        insertAndSort(list, dim.symbol, dim.power, dim.rank);
    return list.immut;
}

/// A vector of dimensions
struct Dimensions
{
private:
    immutable(Dim)[] _dims;

package(quantities):
    static Dimensions mono(string symbol, size_t rank) @safe pure nothrow
    {
        if (!symbol.length)
            return Dimensions(null);
        return Dimensions([Dim(symbol, 1, rank)].immut);
    }

public:
    this(this) @safe pure nothrow
    {
        _dims = _dims.idup;
    }

    ref Dimensions opAssign()(auto ref const Dimensions other) @safe pure nothrow
    {
        _dims = other._dims.idup;
        return this;
    }

    /// The dimensions stored in this vector
    immutable(Dim)[] dims() @safe pure nothrow const
    {
        return _dims;
    }

    alias dims this;

    bool empty() @safe pure nothrow const
    {
        return _dims.empty;
    }

    Dimensions inverted() @safe pure nothrow const
    {
        return Dimensions(_dims.inverted);
    }

    Dimensions opUnary(string op)() @safe pure nothrow const 
            if (op == "~")
    {
        return Dimensions(_dims.inverted);
    }
    Dimensions opBinary(string op)(const Dimensions other) @safe pure const 
            if (op == "*")
    {
        return Dimensions(_dims.insertSorted(other._dims));
    }

    Dimensions opBinary(string op)(const Dimensions other) @safe pure const 
            if (op == "/")
    {
        return Dimensions(_dims.insertSorted(other._dims.inverted));
    }
    Dimensions pow(Rational n) @safe pure nothrow const
    {
        if (n == 0)
            return Dimensions.init;

        auto list = _dims.dup;
        foreach (ref dim; list)
            dim.power = dim.power * n;
        return Dimensions(list.immut);
    }

    Dimensions pow(int n) @safe pure nothrow const
    {
        return pow(Rational(n));
    }

    Dimensions powinverse(Rational n) @safe pure nothrow const
    {
        import std.exception : enforce;
        import std.string : format;

        auto list = _dims.dup;
        foreach (ref dim; list)
            dim.power = dim.power / n;
        return Dimensions(list.immut);
    }

    Dimensions powinverse(int n) @safe pure nothrow const
    {
        return powinverse(Rational(n));
    }

    void toString(scope void delegate(const(char)[]) sink) const
    {
        sink.formattedWrite!"[%(%s %)]"(_dims);
    }
}

// Tests

@("Rational")
unittest
{
    const r = Rational(6, -8);
    assert(r.text == "-3/4");
    assert((+r).text == "-3/4");
    assert((-r).text == "3/4");

    const r1 = Rational(4, 3) + Rational(2, 5);
    assert(r1.text == "26/15");
    const r2 = Rational(4, 3) - Rational(2, 5);
    assert(r2.text == "14/15");
    const r3 = Rational(8, 7) * Rational(3, -2);
    assert(r3.text == "-12/7");
    const r4 = Rational(8, 7) / Rational(3, -2);
    assert(r4.text == "-16/21");

    auto r5 = Rational(4, 3);
    r5 += Rational(2, 5);
    assert(r5.text == "26/15");

    auto r6 = Rational(8, 7);
    r6 /= Rational(2, -3);
    assert(r6.text == "-12/7");

    assert(Rational(8, 7) == Rational(-16, -14));
    assert(Rational(2, 5) < Rational(3, 7));
}

@("Dim[].inverted")
@safe pure nothrow unittest
{
    auto list = [Dim("A", 2), Dim("B", -2)].idup;
    auto inv = [Dim("A", -2), Dim("B", 2)].idup;
    assert(list.inverted == inv);
}
@("Dim[].insertAndSort")
@safe pure unittest
{
    Dim[] list;
    list.insertAndSort("A", Rational(1), 1);
    assert(list == [Dim("A", 1, 1)]);
    list.insertAndSort("A", Rational(1), 1);
    assert(list == [Dim("A", 2, 1)]);
    list.insertAndSort("A", Rational(-2), 1);
    assert(list.length == 0);
    list.insertAndSort("B", Rational(1), 3);
    assert(list == [Dim("B", 1, 3)]);
    list.insertAndSort("C", Rational(1), 1);
    assert(Dim("C", 1, 1) < Dim("B", 1, 3));
    assert(list == [Dim("C", 1, 1), Dim("B", 1, 3)]);
}

@("Dimensions *")
@safe pure unittest
{
    auto dim1 = Dimensions([Dim("a", 1), Dim("b", -2)]);
    auto dim2 = Dimensions([Dim("a", -1), Dim("c", 2)]);
    assert(dim1 * dim2 == Dimensions([Dim("b", -2), Dim("c", 2)]));
}
@("Dimensions /")
@safe pure unittest
{
    auto dim1 = Dimensions([Dim("a", 1), Dim("b", -2)]);
    auto dim2 = Dimensions([Dim("a", 1), Dim("c", 2)]);
    assert(dim1 / dim2 == Dimensions([Dim("b", -2), Dim("c", -2)]));
}
@("Dimensions pow")
@safe pure nothrow unittest
{
    auto dim = Dimensions([Dim("a", 5), Dim("b", -2)]);
    assert(dim.pow(Rational(2)) == Dimensions([Dim("a", 10), Dim("b", -4)]));
    assert(dim.pow(Rational(0)) == Dimensions.init);
}

@("Dimensions.powinverse")
@safe pure nothrow unittest
{
    auto dim = Dimensions([Dim("a", 6), Dim("b", -2)]);
    assert(dim.powinverse(Rational(2)) == Dimensions([Dim("a", 3), Dim("b", -1)]));
}

@("Dimensions.toString")
unittest
{
    auto dim = Dimensions([Dim("a", 1), Dim("b", -2)]);
    assert(dim.text == "[a b^-2]");
    assert(Dimensions.init.text == "[]");
}
