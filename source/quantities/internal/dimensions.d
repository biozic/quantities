module quantities.internal.dimensions;

package:

struct Dim
{
    string symbol;
    int power;

    bool opEquals(Dim other) const pure @safe nothrow
    {
        return power == other.power && symbol == other.symbol;
    }

    string toString() const
    {
        import std.string;
        return "%s:%s".format(symbol, power);
    }

    int opCmp(Dim other) const pure @safe nothrow
    {
        if (symbol < other.symbol)
            return -1;
        else if (symbol > other.symbol)
            return 1;
        else
            return 0;
    }
}

struct DimList
{
    private Dim[] list;

    invariant()
    {
        import std.algorithm : isSorted;
        assert(list.isSorted);
    }

    DimList dup() const pure @safe nothrow
    {
        return DimList(list.dup);
    }

    void insert(bool invert = false)(string symbol, int power) pure @safe nothrow
    {
        import std.algorithm : countUntil, remove;
        import std.array : insertInPlace;

        if (power == 0)
            return;

        static if (invert)
            power = -power;

        if (!list.length)
        {
            list = [Dim(symbol, power)];
            return;
        }

        auto pos = list.countUntil!(d => d.symbol == symbol)();
        if (pos >= 0)
        {
            // Merge the dimensions
            list[pos].power += power;
            if (list[pos].power == 0)
            {
                try
                    () @trusted { list = list.remove(pos); } ();
                catch (Exception)
                    // remove only throws when it has multiple arguments
                    assert(false);

                // Necessary to compare dimensionless values
                if (!list.length)
                    list = null;
            }
        }
        else
        {
            // Insert the new dimension
            pos = list.countUntil!(d => d.symbol > symbol)();
            if (pos < 0)
                pos = list.length;
            list.insertInPlace(pos, Dim(symbol, power));
        }
    }

    void insert(bool invert = false)(in DimList other) pure @safe nothrow
    {
        foreach (dim; other.list)
            insert!invert(dim.symbol, dim.power);
    }

    bool opEquals(in DimList other) const pure @safe nothrow
    {
        return list == other.list;
    }

    string toString() const
    {
        import std.string;
        return "[%(%s, %)]".format(list);
    }
}

//debug import std.stdio;

unittest
{
    auto list = DimList([Dim("a", 1), Dim("c", 2), Dim("e", 1)]);
    list.insert("f", -1);
    assert(list.toString == "[a:1, c:2, e:1, f:-1]");
    list.insert("f", 1);
    assert(list.toString == "[a:1, c:2, e:1]");
    list.insert("b", 3);
    assert(list.toString == "[a:1, b:3, c:2, e:1]");
    list.insert("0", 1);
    assert(list.toString == "[0:1, a:1, b:3, c:2, e:1]");
    list.insert("0", -1);
    list.insert("a", -1);
    list.insert("b", -3);
    list.insert("c", -2);
    list.insert("e", -1);
    assert(list.toString == "[]");
    list.insert("x", 0);
    assert(list.toString == "[]");
    list.insert("x", 1);
    assert(list.toString == "[x:1]");
}

unittest // Compile-time
{
    enum list = {
        DimList list;
        list.insert("a", 1);
        return list;
    }();
}

struct Dimensions
{
private:
    DimList dimList;

    version (unittest)
    {
        this(DimList list) pure @safe nothrow
        {
            dimList = list;
        }

        this(int[string] dims) pure @safe
        {
            foreach (k, v; dims)
                dimList.insert(k, v);
        }
    }

public:
    static Dimensions mono(string symbol) pure @safe nothrow
    {
        DimList list;
        list.insert(symbol, 1);
        return Dimensions(list);
    }
    
    bool empty() const pure @safe nothrow
    {
        return !dimList.list.length;
    }

    Dimensions dup() const pure @safe nothrow
    {
        return Dimensions(dimList.dup);
    }
    
    Dimensions invert() const pure @safe nothrow
    {
        auto list = dimList.dup;
        foreach (ref dim; list.list)
            dim.power = -dim.power;
        return Dimensions(list);
    }
    pure @safe unittest
    {
        auto dim = Dimensions(["a": 5, "b": -2]);
        assert(dim.invert == Dimensions(["a": -5, "b": 2]));
    }

    Dimensions binop(string op)(in Dimensions other) const pure @safe nothrow
        if (op == "*")
    {
        auto list = dimList.dup;
        list.insert(other.dimList);
        return Dimensions(list);
    }
    pure @safe unittest
    {
        auto dim1 = Dimensions(["a": 1, "b": -2]);
        auto dim2 = Dimensions(["a": -1, "c": 2]);
        assert(dim1.binop!"*"(dim2) == Dimensions(["b": -2, "c": 2]));
    }
    
    Dimensions binop(string op)(in Dimensions other) const pure @safe
        if (op == "/" || op == "%")
    {
        auto list = dimList.dup;
        list.insert!true(other.dimList);
        return Dimensions(list);
    }
    pure @safe unittest
    {
        auto dim1 = Dimensions(["a": 1, "b": -2]);
        auto dim2 = Dimensions(["a": 1, "c": 2]);
        assert(dim1.binop!"/"(dim2) == Dimensions(["b": -2, "c": -2]));
    }
    
    Dimensions pow(int n) const pure @safe
    {
        if (n == 0)
            return Dimensions.init;

        auto list = dimList.dup;
        foreach (ref dim; list.list)
            dim.power = dim.power * n;
        return Dimensions(list);
    }
    pure @safe unittest
    {
        auto dim = Dimensions(["a": 5, "b": -2]);
        assert(dim.pow(2) == Dimensions(["a": 10, "b": -4]));
        assert(dim.pow(0) == Dimensions.init);
    }
    
    Dimensions powinverse(int n) const pure @safe
    {
        import std.exception : enforce;
        import std.string : format;

        auto list = dimList.dup;
        foreach (ref dim; list.list)
        {
            enforce(dim.power % n == 0, 
                "Dimension error: '%s^%s' is not divisible by %s"
                .format(dim.symbol, dim.power, n));
            dim.power = dim.power / n;
        }
        return Dimensions(list);
    }
    pure @safe unittest
    {
        auto dim = Dimensions(["a": 6, "b": -2]);
        assert(dim.powinverse(2) == Dimensions(["a": 3, "b": -1]));
    }
    
    bool opEquals(in Dimensions other) const pure @safe  nothrow
    {
        return dimList == other.dimList;
    }
    pure @safe unittest
    {
        assert(Dimensions.init == Dimensions.init);
        assert(Dimensions(["a": 1, "b": 2]) == Dimensions(["a": 1, "b": 2]));
        assert(Dimensions(["a": 1, "b": 1]) != Dimensions(["a": 1, "b": 2]));
        assert(Dimensions(["a": 1]) != Dimensions(["a": 1, "b": 2]));
        assert(Dimensions(["a": 1, "b": 2]) != Dimensions(["a": 1]));
    }
    
    string toString() const pure @safe
    {
        import std.algorithm : filter;
        import std.array : appender, join;
        import std.conv : to;
        import std.string : format;
        
        static string stringize(string symbol, int power) pure
        {
            if (power == 0)
                return null;
            if (power == 1)
                return symbol;
            return symbol ~ "^" ~ to!string(power);
        }

        auto dimstrs = appender!(string[]);
        foreach (dim; dimList.list)
            dimstrs.put(stringize(dim.symbol, dim.power));

        return "[%-(%s %)]".format(dimstrs.data.filter!"a !is null");
    }
    unittest
    {
        assert(Dimensions(["a": 2, "b": -1, "c": 1, "d": 0]).toString == "[a^2 b^-1 c]");
    }
}

unittest // Compile-time
{
    enum dim = {
        DimList list;
        list.insert("a", 1);
        return Dimensions(list);
    }();

    int foo(Dimensions d)() { return 0; }
    enum a = foo!dim();
}
