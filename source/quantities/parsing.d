// Written in the D programming language
/++
This module defines functions to parse units and quantities. The text
input is parsed according to the following grammar. For example:
$(DL
$(DT Prefixes and unit symbols must be joined:)
    $(DD "1 mm" = 1 millimeter)
    $(DD "1 m m" = 1 square meter)
$(BR)
$(DT Standalone units are preferred over prefixed ones:)
    $(DD "1 cd" = 1 candela, not 1 centiday)
$(BR)
$(DT Powers of units:)
    $(DD "1 m^2")
    $(DD "1 m²" $(I (superscript integer)))
$(BR)
$(DT Multiplication of to units:)
    $(DD "1 N m" $(I (whitespace)))
    $(DD "1 N . m")
    $(DD "1 N ⋅ m" $(I (centered dot)))
    $(DD "1 N * m")
    $(DD "1 N × m" $(I (times sign)))
$(BR)
$(DT Division of to units:)
    $(DD "1 mol / s")
    $(DD "1 mol ÷ s")
$(BR)
$(DT Grouping of units with parentheses:)
    $(DD "1 kg/(m.s^2)" = 1 kg m⁻¹ s⁻²)
)

Grammar: (whitespace not significant)
$(DL
$(DT Quantity:)
    $(DD Units)
    $(DD Number Units)
$(BR)
$(DT Number:)
    $(DD $(I Numeric value parsed by std.conv.parse!double))
$(BR)
$(DT Units:)
    $(DD Unit)
    $(DD Unit Units)
    $(DD Unit Operator Units)
$(BR)
$(DT Operator:)
    $(DD $(B *))
    $(DD $(B .))
    $(DD $(B ⋅))
    $(DD $(B ×))
    $(DD $(B /))
    $(DD $(B ÷))
$(BR)
$(DT Unit:)
    $(DD Base)
    $(DD Base $(B ^) Integer)
    $(DD Base SupInteger)
$(BR)
$(DT Base:)
    $(DD Symbol)
    $(DD Prefix Symbol)
    $(DD $(B $(LPAREN)) Units $(B $(RPAREN)))
$(BR)
$(DT Symbol:)
    $(DD $(I The symbol of a valid unit))
$(BR)
$(DT Prefix:)
    $(DD $(I The symbol of a valid prefix))
$(BR)
$(DT Integer:)
    $(DD $(I Integer value parsed by std.conv.parse!int))
$(BR)
$(DT SupInteger:)
    $(DD $(I Superscript version of Integer))
)

Copyright: Copyright 2013-2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.parsing;

import quantities.base;
import std.array;
import std.algorithm;
import std.conv;
import std.exception;
import std.math;
import std.range;
import std.string;
import std.traits;
import std.utf;

/++
Contains the symbols of the units and the prefixes that a parser can handle.
+/
struct SymbolList(N)
{
    static assert(isNumberLike!N, "Incompatible type: " ~ N.stringof);

    package
    {
        RTQuantity!N[string] units;
        N[string] prefixes;
        size_t maxPrefixLength;
    }

    /// Adds (or replaces) a unit in the list
    void addUnit(Q)(string symbol, Q unit)
        if (isQuantity!Q)
    {
        units[symbol] = unit.toRT;
    }

    /// Adds (or replaces) a prefix in the list
    void addPrefix(N)(string symbol, N factor)
        if (isNumberLike!N)
    {
        prefixes[symbol] = factor;
        if (symbol.length > maxPrefixLength)
            maxPrefixLength = symbol.length;
    }
}

/++
Helps build a SymbolList at compile-time.

Use with the global addUnit and addPrefix functions.
+/
SymbolList!N makeSymbolList(N, Sym...)(Sym list)
{
    SymbolList!N ret;
    foreach (sym; list)
    {
        static if (is(typeof(sym) == WithUnit!Q, Q))
        {
            static assert(is(Q.valueType : N), "Incompatible value types: %s and %s" 
                          .format(Q.valueType.stringof, N.stringof));
            ret.units[sym.symbol] = sym.unit;
        }
        else static if (is(typeof(sym) == WithPrefix!T, T))
        {
            static assert(is(T : N), "Incompatible value types: %s and %s" 
                          .format(T.stringof, N.stringof));
            ret.prefixes[sym.symbol] = sym.factor;
            if (sym.symbol.length > ret.maxPrefixLength)
                ret.maxPrefixLength = sym.symbol.length;
        }
        else
            static assert(false, "Unexpected symbol: " ~ sym.stringof);
    }
    return ret;
}
///
unittest
{
    enum euro = unit!(double, "C");
    alias Currency = typeof(euro);
    enum dollar = 1.35 * euro;

    enum symbolList = makeSymbolList!double(
        withUnit("€", euro),
        withUnit("$", dollar),
        withPrefix("doz", 12)
    );
}

package struct WithUnit(Q)
{
    string symbol;
    RTQuantity!(Q.valueType) unit;
}

/// Creates a unit that can be added to a SymbolList via the SymbolList constuctor.
auto withUnit(Q)(string symbol, Q unit)
    if (isQuantity!Q)
{
    return WithUnit!Q(symbol, unit.toRT);
}

package struct WithPrefix(N)
{
    string symbol;
    N factor;
}

/// Creates a prefix that can be added to a SymbolList via the SymbolList constuctor.
auto withPrefix(N)(string symbol, N factor)
    if (isNumberLike!N)
{
    return WithPrefix!N(symbol, factor);
}

/++
Creates a runtime parser capable of working on user-defined units and prefixes.

Params:
    N = The type of the value type stored in the Quantity struct.
    symbolList = A prefilled SymbolList struct that contains all units and prefixes.
    parseFun = A function that can parse the beginning of a string to return a numeric value of type N.
        After this function returns, it must have consumed the numeric part and leave only the unit part.
    one = The value of type N that is equivalent to 1.
+/
template rtQuantityParser(
    N, 
    alias symbolList, 
    alias parseFun = (ref string s) => parse!N(s)
)
{
    auto rtQuantityParser(Q, S)(S str)
        if (isQuantity!Q)
    {
        static assert(is(N : Q.valueType), "Incompatible value type: " ~ Q.valueType.stringof);

        auto rtQuant = parseRTQuantity!(Q.valueType, parseFun)(str, symbolList);
        enforceEx!DimensionException(
            toAA!(Q.dimensions) == rtQuant.dimensions,
            "Dimension error: [%s] is not compatible with [%s]"
            .format(quantities.base.dimstr!(Q.dimensions), dimstr(rtQuant.dimensions)));
        return Q.make(rtQuant.value);
    }    
}
///
unittest
{
    import std.bigint;
    
    enum bit = unit!(BigInt, "bit");
    alias BinarySize = typeof(bit);

    SymbolList!BigInt symbolList;
    symbolList.addUnit("bit", bit);
    symbolList.addPrefix("hob", BigInt("1234567890987654321"));
    
    static BigInt parseFun(ref string input)
    {
        import std.exception, std.regex;
        enum rgx = ctRegex!`^(\d*)\s*(.*)$`;
        auto m = enforce(match(input, rgx));
        input = m.captures[2];
        return BigInt(m.captures[1]);
    }
    
    alias parse = rtQuantityParser!(BigInt, symbolList, parseFun);

    auto foo = BigInt("1234567890987654300") * bit;
    foo += BigInt(21) * bit;
    assert(foo == parse!BinarySize("1 hobbit"));
}

/++
Creates a compile-time parser capable of working on user-defined units and prefixes.

Contrary to a runtime parser, a compile-time parser infers the type of the parsed quantity
automatically from the dimensions of its components.

Params:
    N = The type of the value type stored in the Quantity struct.
    symbolList = A prefilled SymbolList struct that contains all units and prefixes.
    parseFun = A function that can parse the beginning of a string to return a numeric value of type N.
        After this function returns, it must have consumed the numeric part and leave only the unit part.
    one = The value of type N that is equivalent to 1.
+/
template ctQuantityParser(
    N, 
    alias symbolList, 
    alias parseFun = (ref string s) => parse!N(s)
)
{
    template ctQuantityParser(string str)
    {
        static string dimTup(int[string] dims)
        {
            return dims.keys.map!(x => `"%s", %s`.format(x, dims[x])).join(", ");
        }
        
        // This is for a nice compile-time error message
        enum msg = { return collectExceptionMsg(parseRTQuantity!(N, parseFun)(str, symbolList)); }();
        static if (msg)
        {
            static assert(false, msg);
        }
        else
        {
            enum q = parseRTQuantity!(N, parseFun)(str, symbolList);
            enum dimStr = dimTup(q.dimensions);
            mixin("alias dims = TypeTuple!(%s);".format(dimStr));
            enum ctQuantityParser = Quantity!(N, Sort!dims).make(q.value);
        }
    }
}
///
version (D_Ddoc) // DMD BUG? (Differents symbolLists but same template instantiation)
unittest
{
    enum bit = unit!("bit", ulong);
    alias BinarySize = typeof(bit);
    enum byte_ = 8 * bit;
    
    enum symbolList = makeSymbolList!ulong(
        withUnit("bit", bit),
        withUnit("B", byte_),
        withPrefix("hob", 7)
    );
    
    alias sz = ctQuantityParser!(ulong, symbolList);
    
    assert(sz!"1 hobbit".value(bit) == 7);
}

/// Exception thrown when parsing encounters an unexpected token.
class ParsingException : Exception
{
    @safe pure nothrow
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }

    @safe pure nothrow
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}

package:

RTQuantity!N parseRTQuantity(N, alias parseFun, S, SL)(S str, auto ref SL symbolList)
{
    static assert(isForwardRange!S && isSomeChar!(ElementType!S),
                  "input must be a forward range of a character type");

    N value;
    try
        value = parseFun(str);
    catch
        value = 1;

    if (str.empty)
        return RTQuantity!N(value, null);

    auto input = str.to!string;
    auto tokens = lex(input);
    auto parser = QuantityParser!N(symbolList);
    
    RTQuantity!N result = parser.parseCompoundUnit(tokens);
    result.value *= value;
    return result;
}

unittest // Test parsing
{
    enum meter = unit!(double, "L");
    enum kilogram = unit!(double, "M");
    enum second = unit!(double, "T");
    enum one = meter / meter;

    enum siSL = makeSymbolList!double(
        withUnit("m", meter),
        withUnit("kg", kilogram),
        withUnit("s", second),
        withPrefix("c", 0.01L),
        withPrefix("m", 0.001L)
    );

    static bool checkParse(Q)(string input, Q quantity)
    {
        return parseRTQuantity!(double, std.conv.parse!(double, string))(input, siSL)
            == quantity.toRT;
    }

    assert(checkParse("1    m    ", meter));
    assert(checkParse("1 mm", 0.001 * meter));
    assert(checkParse("1 m^-1", 1 / meter));
    assert(checkParse("1 m²", meter * meter));
    assert(checkParse("1 m⁺²", meter * meter));
    assert(checkParse("1 m⁻¹", 1 / meter));
    assert(checkParse("1 (m)", meter));
    assert(checkParse("1 (m^-1)", 1 / meter));
    assert(checkParse("1 ((m)^-1)^-1", meter));
    assert(checkParse("1 m*m", meter * meter));
    assert(checkParse("1 m m", meter * meter));
    assert(checkParse("1 m.m", meter * meter));
    assert(checkParse("1 m⋅m", meter * meter));
    assert(checkParse("1 m×m", meter * meter));
    assert(checkParse("1 m/m", meter / meter));
    assert(checkParse("1 m÷m", meter / meter));
    assert(checkParse("1 m.s", second * meter));
    assert(checkParse("1 m s", second * meter));
    assert(checkParse("1 m*m/m", meter));
    assert(checkParse("0.8", 0.8 * one));

    assertThrown!ParsingException(checkParse("1 c m", meter * meter));
    assertThrown!ParsingException(checkParse("1 c", 0.01 * meter));
    assertThrown!ParsingException(checkParse("1 Qm", meter));
    assertThrown!ParsingException(checkParse("1 m/", meter));
    assertThrown!ParsingException(checkParse("1 m^", meter));
    assertThrown!ParsingException(checkParse("1 m ) m", meter * meter));
    assertThrown!ParsingException(checkParse("1 m * m) m", meter * meter * meter));
    assertThrown!ParsingException(checkParse("1 m^²", meter * meter));
    assertThrown!ParsingException(checkParse("1-⁺⁵", one));
}

// Holds a value and a dimensions for parsing
struct RTQuantity(N)
{
    // The payload
    N value;

    // The dimensions of the quantity
    int[string] dimensions;
}

// A parser that can parse a text for a unit or a quantity
struct QuantityParser(N)
{
    alias RTQ = RTQuantity!N;

    private SymbolList!N symbolList;

    RTQ parseCompoundUnit(T)(auto ref T[] tokens, bool inParens = false)
        if (is(T : Token))
    {
        RTQ ret = parseExponentUnit(tokens);
        if (tokens.empty || (inParens && tokens.front.type == Tok.rparen))
            return ret;

        do {
            tokens.check();
            auto cur = tokens.front;

            bool multiply = true;
            if (cur.type == Tok.div)
                multiply = false;

            if (cur.type == Tok.mul || cur.type == Tok.div)
            {
                tokens.advance();
                tokens.check();
                cur = tokens.front;
            }

            RTQ rhs = parseExponentUnit(tokens);
            if (multiply)
            {
                ret.dimensions = ret.dimensions.binop!"*"(rhs.dimensions);
                ret.value = ret.value * rhs.value;
            }
            else
            {
                ret.dimensions = ret.dimensions.binop!"/"(rhs.dimensions);
                ret.value = ret.value / rhs.value;
            }

            if (tokens.empty || (inParens && tokens.front.type == Tok.rparen))
                break;

            cur = tokens.front;
        }
        while (!tokens.empty);

        return ret;
    }

    RTQ parseExponentUnit(T)(auto ref T[] tokens)
        if (is(T : Token))
    {
        RTQ ret = parseUnit(tokens);

        if (tokens.empty)
            return ret;

        auto next = tokens.front;
        if (next.type != Tok.exp && next.type != Tok.supinteger)
            return ret;

        if (next.type == Tok.exp)
            tokens.advance(Tok.integer);

        int n = parseInteger(tokens);

        static if (__traits(compiles, std.math.pow(ret.value, n)))
            ret.value = std.math.pow(ret.value, n);
        else
            foreach (i; 1 .. n)
                ret.value *= ret.value;
        ret.dimensions = ret.dimensions.exp(n);
        return ret;
    }

    int parseInteger(T)(auto ref T[] tokens)
        if (is(T : Token))
    {
        tokens.check(Tok.integer, Tok.supinteger);
        int n = tokens.front.integer;
        if (tokens.length)
            tokens.advance();
        return n;
    }

    RTQ parseUnit(T)(auto ref T[] tokens)
        if (is(T : Token))
    {
        RTQ ret;

        if (tokens.front.type == Tok.lparen)
        {
            tokens.advance();
            ret = parseCompoundUnit(tokens, true);
            tokens.check(Tok.rparen);
            tokens.advance();
        }
        else
            ret = parsePrefixUnit(tokens);

        return ret;
    }

    RTQ parsePrefixUnit(T)(auto ref T[] tokens)
        if (is(T : Token))
    {
        tokens.check(Tok.symbol);
        auto str = tokens.front.slice;
        if (tokens.length)
            tokens.advance();

        // Try a standalone unit symbol (no prefix)
        auto uptr = str in symbolList.units;
        if (uptr)
            return *uptr;

        // Try with prefixes, the longest prefix first
        N* factor;
        for (size_t i = symbolList.maxPrefixLength; i > 0; i--)
        {
            if (str.length >= i)
            {
                string prefix = str[0 .. i].to!string;
                factor = prefix in symbolList.prefixes;
                if (factor)
                {
                    string unit = str[i .. $].to!string;
                    enforceEx!ParsingException(unit.length, "Expecting a unit after the prefix " ~ prefix);
                    uptr = unit in symbolList.units;
                    if (uptr)
                        return RTQ(*factor * uptr.value, uptr.dimensions);
                }
            }
        }

        throw new ParsingException("Unknown unit symbol: '%s'".format(str));
    }
}

// Convert a compile-time quantity to its runtime equivalent.
auto toRT(Q)(Q quantity)
    if (isQuantity!Q)
{
    return RTQuantity!(Q.valueType)(quantity.rawValue, toAA!(Q.dimensions));
}

enum Tok
{
    none,
    symbol,
    mul,
    div,
    exp,
    integer,
    supinteger,
    rparen,
    lparen
}

struct Token
{
    Tok type;
    string slice;
    int integer = int.max;
}

enum ctSupIntegerMap = [
    '⁰':'0',
    '¹':'1',
    '²':'2',
    '³':'3',
    '⁴':'4',
    '⁵':'5',
    '⁶':'6',
    '⁷':'7',
    '⁸':'8',
    '⁹':'9',
    '⁺':'+',
    '⁻':'-'
];
static dchar[dchar] supIntegerMap;
static this()
{
    supIntegerMap = ctSupIntegerMap;
}

Token[] lex(string input) @safe
{
    enum State
    {
        none,
        symbol,
        integer,
        supinteger
    }

    Token[] tokens;
    auto tokapp = appender(tokens); // Only for runtime

    void appendToken(Token token)
    {
        if (!__ctfe)
            tokapp.put(token);
        else
            tokens ~= token;
    }

    auto original = input;
    size_t i, j;
    State state = State.none;

    void pushToken(Tok type)
    {
        appendToken(Token(type, original[i .. j]));
        i = j;
        state = State.none;
    }

    void pushInteger(Tok type)
    {
        auto slice = original[i .. j];

        if (type == Tok.supinteger)
        {
            if (__ctfe)
                slice = translate(slice, ctSupIntegerMap);
            else
                slice = translate(slice, supIntegerMap);
        }

        int n;
        try
            n = std.conv.parse!int(slice);
        catch (Exception)
            throw new ParsingException("Unexpected integer format: " ~ original[i .. j]);

        enforceEx!ParsingException(slice.empty, "Unexpected integer format: " ~ slice);

        appendToken(Token(type, original[i .. j], n));
        i = j;
        state = State.none;
    }

    void push()
    {
        if (state == State.symbol)
            pushToken(Tok.symbol);
        else if (state == State.integer)
            pushInteger(Tok.integer);
        else if (state == State.supinteger)
            pushInteger(Tok.supinteger);
    }

    while (!input.empty)
    {
        auto cur = input.front;
        auto len = cur.codeLength!char;
        switch (cur)
        {
            // Whitespace
            case ' ':
            case '\t':
            case '\u00A0':
            case '\u2000': .. case '\u200A':
            case '\u202F':
            case '\u205F':
                push();
                j += len;
                i = j;
                break;

            case '(':
                push();
                j += len;
                pushToken(Tok.lparen);
                break;

            case ')':
                push();
                j += len;
                pushToken(Tok.rparen);
                break;

            case '*':
            case '.':
            case '⋅':
            case '×':
                push();
                j += len;
                pushToken(Tok.mul);
                break;

            case '/':
            case '÷':
                push();
                j += len;
                pushToken(Tok.div);
                break;

            case '^':
                push();
                j += len;
                pushToken(Tok.exp);
                break;

            case '0': .. case '9':
            case '-':
            case '+':
                if (state != State.integer)
                    push();
                state = State.integer;
                j += len;
                break;

            case '⁰':
            case '¹':
            case '²':
            case '³':
            case '⁴':
            case '⁵':
            case '⁶':
            case '⁷':
            case '⁸':
            case '⁹':
            case '⁻':
            case '⁺':
                if (state != State.supinteger)
                    push();
                state = State.supinteger;
                j += len;
                break;

            default:
                if (state == State.integer || state == State.supinteger)
                    push();
                state = State.symbol;
                j += len;
                break;
        }
        input.popFront();
    }
    push();

    if (!__ctfe)
        return tokapp.data;
    else
        return tokens;
}

void advance(Types...)(ref Token[] tokens, Types types)
{
    enforceEx!ParsingException(!tokens.empty, "Unexpected end of input");
    tokens.popFront();

    static if (Types.length)
        check(tokens, types);
}

void check(Types...)(Token[] tokens, Types types)
{
    enforceEx!ParsingException(!tokens.empty, "Unexpected end of input");
    auto token = tokens.front;

    static if (Types.length)
    {
        bool ok = false;
        Tok[] valid = [types];
        foreach (type; types)
        {
            if (token.type == type)
            {
                ok = true;
                break;
            }
        }
        import std.string : format;
        enforceEx!ParsingException(ok, valid.length > 1
                                   ? format("Found '%s' while expecting one of [%(%s, %)]", token.slice, valid)
                                   : format("Found '%s' while expecting %s", token.slice, valid.front)
                                   );
    }
}

// Mul or div two dimension arrays
int[string] binop(string op)(int[string] dim1, int[string] dim2)
{
    static assert(op == "*" || op == "/", "Unsupported dimension operator: " ~ op);

    int[string] result;

    // Clone these dimensions in the result
    if (__ctfe)
    {
        foreach (key; dim1.keys)
            result[key] = dim1[key];
    }
    else
        result = dim1.dup;

    // Merge the other dimensions
    foreach (sym, pow; dim2)
    {
        enum powop = op == "*" ? "+" : "-";

        if (sym in dim1)
        {
            // A dimension is common between this one and the other:
            // add or sub them
            auto p = mixin("dim1[sym]" ~ powop ~ "pow");

            // If the power becomes 0, remove the dimension from the list
            // otherwise, set the new power
            if (p == 0)
                result.remove(sym);
            else
                result[sym] = p;
        }
        else
        {
            // Add this new dimensions to the result
            // (with a negative power if op == "/")
            result[sym] = mixin(powop ~ "pow");
        }
    }

    return result;
}

// Raise a dimension array to a integer power (value)
int[string] exp(int[string] dim, int value) @safe pure
{
    if (value == 0)
        return null;

    int[string] result;
    foreach (sym, pow; dim)
        result[sym] = pow * value;
    return result;
}

// Raise a dimension array to a rational power (1/value)
int[string] expInv(int[string] dim, int value) @safe pure
{
    assert(value > 0, "Bug: using Dimensions.expInv with a value <= 0");

    int[string] result;
    foreach (sym, pow; dim)
    {
        enforce(pow % value == 0, "Operation results in a non-integral dimension");
        result[sym] = pow / value;
    }
    return result;
}
