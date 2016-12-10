/+
Internal representation of dimensions.

Copyright: Copyright 2013-2016, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.internal.dimensions;

package(quantities):

struct DimImpl(N)
{
    string symbol;
    N power;

    bool opEquals(DimImpl!N other) const
    {
        return power == other.power && symbol == other.symbol;
    }

    int opCmp(DimImpl!N other) const
    {
        if (symbol < other.symbol)
            return -1;
        else if (symbol > other.symbol)
            return 1;
        else
            return 0;
    }

    string toString() const
    {
        import std.string : format;
        
        if (power == N(0))
            return null;
        else if (power == N(1))
            return symbol;
        else 
            return "%s^%s".format(symbol, power);
    }
}

struct DimListImpl(N)
{
    private DimImpl!N[] list;

    invariant()
    {
        import std.algorithm : isSorted;
        assert(list.isSorted);
    }

    DimListImpl!N dup() const
    {
        return DimListImpl!N(list.dup);
    }

    void insert(bool invert = false)(string symbol, N power)
    {
        import std.algorithm : countUntil, remove;
        import std.array : insertInPlace;

        if (power == N(0))
            return;

        static if (invert)
            power = -power;

        if (!list.length)
        {
            list = [DimImpl!N(symbol, power)];
            return;
        }

        auto pos = list.countUntil!(d => d.symbol == symbol)();
        if (pos >= 0)
        {
            // Merge the dimensions
            list[pos].power += power;
            if (list[pos].power == N(0))
            {
                if (__ctfe)
                {
                    auto d = list[pos];
                    DimImpl!N[] newList;
                    foreach (dim; list)
                        if (dim != d)
                            newList ~= dim;
                    list = newList;
                }
                else
                {
                    try
                        list = list.remove(pos);
                    catch (Exception)
                        // remove only throws when it has multiple arguments
                        assert(false);
                }

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
            list.insertInPlace(pos, DimImpl!N(symbol, power));
        }
    }

    void insert(bool invert = false)(in DimListImpl!N other)
    {
        foreach (dim; other.list)
            insert!invert(dim.symbol, dim.power);
    }

    bool opEquals(in DimListImpl!N other) const
    {
        return list == other.list;
    }

    string toString() const
    {
        import std.string;
        import std.stdio;
        return "[%(%s %)]".format(list);
    }

    // Unit tests

    unittest
    {
        auto list = DimListImpl!N([DimImpl!N("a", N(1)), DimImpl!N("c", N(2)), DimImpl!N("e", N(1))]);
        list.insert("f", N(-1));
        list.insert("f", N(1));
        list.insert("b", N(3));
        list.insert("0", N(1));
        list.insert("0", N(-1));
        list.insert("a", N(-1));
        list.insert("b", N(-3));
        list.insert("c", N(-2));
        list.insert("e", N(-1));
        list.insert("x", N(0));
        list.insert("x", N(1));
    }
    
    unittest // Compile-time
    {
        enum list = {
            DimListImpl!N list;
            list.insert("a", N(1));
            return list;
        }();
    }
}


struct DimensionsImpl(N)
{
private:
    DimListImpl!N dimList;

    version (unittest)
    {
        private this(DimListImpl!N list)
        {
            dimList = list;
        }

        private this(N[string] dims)
        {
            foreach (k, v; dims)
                dimList.insert(k, v);
        }
    }

public:
    static DimensionsImpl!N mono(string symbol)
    {
        DimListImpl!N list;
        list.insert(symbol, N(1));
        return DimensionsImpl(list);
    }
    
    bool empty() const
    {
        return !dimList.list.length;
    }

    DimensionsImpl!N invert() const
    {
        auto list = dimList.dup;
        foreach (ref dim; list.list)
            dim.power = -dim.power;
        return DimensionsImpl!N(list);
    }
    unittest
    {
        auto dim = DimensionsImpl!N(["a": N(5), "b": N(-2)]);
        assert(dim.invert == DimensionsImpl!N(["a": N(-5), "b": N(2)]));
    }

    DimensionsImpl!N binop(string op)(in DimensionsImpl!N other) const
        if (op == "*")
    {
        auto list = dimList.dup;
        list.insert(other.dimList);
        return DimensionsImpl(list);
    }
    unittest
    {
        auto dim1 = DimensionsImpl!N(["a": N(1), "b": N(-2)]);
        auto dim2 = DimensionsImpl!N(["a": N(-1), "c": N(2)]);
        assert(dim1.binop!"*"(dim2) == DimensionsImpl!N(["b": N(-2), "c": N(2)]));
    }

    DimensionsImpl!N binop(string op)(in DimensionsImpl!N other) const
        if (op == "/" || op == "%")
    {
        auto list = dimList.dup;
        list.insert!true(other.dimList);
        return DimensionsImpl(list);
    }
    unittest
    {
        auto dim1 = DimensionsImpl!N(["a": N(1), "b": N(-2)]);
        auto dim2 = DimensionsImpl!N(["a": N(1), "c": N(2)]);
        assert(dim1.binop!"/"(dim2) == DimensionsImpl!N(["b": N(-2), "c": N(-2)]));
    }
    
    DimensionsImpl!N pow(N n) const
    {
        if (n == N(0))
            return DimensionsImpl!N.init;

        auto list = dimList.dup;
        foreach (ref dim; list.list)
            dim.power = dim.power * n;
        return DimensionsImpl!N(list);
    }
    unittest
    {
        auto dim = DimensionsImpl!N(["a": N(5), "b": N(-2)]);
        assert(dim.pow(2) == DimensionsImpl!N(["a": N(10), "b": N(-4)]));
        assert(dim.pow(0) == DimensionsImpl!N.init);
    }

    DimensionsImpl!N pow(int i) const
    {
        return pow(N(i));
    }
    
    DimensionsImpl!N powinverse(N n) const
    {
        import std.exception : enforce;
        import std.string : format;

        auto list = dimList.dup;
        foreach (ref dim; list.list)
            dim.power = dim.power / n;

        return DimensionsImpl!N(list);
    }
    unittest
    {
        auto dim = DimensionsImpl!N(["a": N(6), "b": N(-2)]);
        assert(dim.powinverse(2) == DimensionsImpl!N(["a": N(3), "b": N(-1)]));
    }

    DimensionsImpl!N powinverse(int i) const
    {
        return powinverse(N(i));
    }
    
    bool opEquals(in DimensionsImpl!N other) const
    {
        return dimList == other.dimList;
    }
    unittest
    {
        assert(DimensionsImpl!N.init == DimensionsImpl!N.init);
        assert(DimensionsImpl!N(["a": N(1), "b": N(2)]) == DimensionsImpl!N(["a": N(1), "b": N(2)]));
        assert(DimensionsImpl!N(["a": N(1), "b": N(1)]) != DimensionsImpl!N(["a": N(1), "b": N(2)]));
        assert(DimensionsImpl!N(["a": N(1)]) != DimensionsImpl!N(["a": N(1), "b": N(2)]));
        assert(DimensionsImpl!N(["a": N(1), "b": N(2)]) != DimensionsImpl!N(["a": N(1)]));
    }

    string toString() const
    {
        return dimList.toString;
    }

    unittest // Compile time
    {
        enum dim = {
            DimListImpl!N list;
            list.insert("a", N(1));
            return DimensionsImpl!N(list);
        }();
        
        N foo(DimensionsImpl!N d)() { return N(0); }
        enum a = foo!dim();
    }
}
