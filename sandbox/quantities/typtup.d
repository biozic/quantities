module quantities.typtup;

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