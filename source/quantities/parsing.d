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
    $(DD $(I Numeric value parsed by std.conv.parse!real))
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

version (unittest)
{
    import quantities.si;
    import std.conv;
    import std.math : approxEqual;

    private QuantityParser!real _defaultParser()
    {
        return QuantityParser!real(siSymbolList);
    }
}

/++
Contains the symbols of the units and the prefixes that a parser can handle.
+/
struct SymbolList(N)
{
    static assert(isValue!N, "Incompatible type: " ~ N.stringof);

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
        if (isValue!N)
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
		static if (is(typeof(sym) == AddUnit!Q, Q))
		{
			static assert(is(Q.valueType : N), "Incompatible value types: %s and %s" 
			              .format(Q.valueType.stringof, N.stringof));
			ret.units[sym.symbol] = sym.unit;
		}
		else static if (is(typeof(sym) == AddPrefix!T, T))
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
	enum euro = unit!("C", double);
	alias Currency = QuantityType!euro;
	enum dollar = 1.35 * euro;

	enum symbolList = makeSymbolList!double(
		addUnit("€", euro),
		addUnit("$", dollar)
	);
}

package struct AddUnit(Q)
{
    string symbol;
    RTQuantity!(Q.valueType) unit;
}

/// Creates a unit that can be added to a SymbolList via the SymbolList constuctor.
auto addUnit(Q)(string symbol, Q unit)
    if (isQuantity!Q)
{
    return AddUnit!Q(symbol, unit.toRT);
}

package struct AddPrefix(N)
{
    string symbol;
    N factor;
}

/// Creates a prefix that can be added to a SymbolList via the SymbolList constuctor.
auto addPrefix(N)(string symbol, N factor)
    if (isValue!N)
{
    return AddPrefix!N(symbol, factor);
}

/++
Parses text for a quantity of type Q at runtime.

Params:
    text = The string to parse.
    symbolList = A prefilled SymbolList struct that contains all units and prefixes.
    Q = The type of the quantity that the function should return.
    parseFun = A function that can parse the beginning of text for a numeric value.
        This function must consume the parsed numeric value and leave only a unit to parse.
+/
auto parseQuantity(Q, alias parseFun = (ref string s) => parse!(Q.valueType)(s), S, SL)
    (S text, auto ref SL symbolList)
    if (isQuantity!Q)
{
    auto rtQuant = parseRTQuantity!(Q.valueType, parseFun)(text, symbolList);
    enforceEx!DimensionException(
        toAA!(Q.dimensions) == rtQuant.dimensions,
        "Dimension error: %s is not compatible with %s"
        .format(quantities.base.dimstr!(Q.dimensions)(true), dimstr(rtQuant.dimensions, true)));
    return Q.make(cast(Q.valueType) rtQuant.value);
}
///
unittest
{
    enum bit = unit!("bit", ulong);
    alias BinarySize = QuantityType!bit;
    enum byte_ = 8 * bit;

	SymbolList!ulong symbolList;
	symbolList.addUnit("bit", bit);
	symbolList.addUnit("B", byte_);
	symbolList.addPrefix("hob", 7);

    auto height = parseQuantity!BinarySize("1 hobbit", symbolList);
    assert(height.value(bit) == 7);
}

/++
Creates a compile-time parser capable of working on user-defined units and prefixes.

Params:
    N = The type of the value type stored in the Quantity struct.
    symbolList = A prefilled SymbolList struct that contains all units and prefixes.
    parseFun = A function that can parse the beginning of text for a numeric value.
        This function must consume the parsed numeric value and leave only a unit to parse.    
+/
template ctQuantityParser(N, alias symbolList, alias parseFun)
{
    template ctQuantityParser(string str)
    {
        private string dimTup(int[string] dims)
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
unittest
{
	import quantities.si;

    enum bit = unit!"bit";
    enum byte_ = 8 * bit;
    enum symbolList = makeSymbolList!real(
        addUnit("bit", bit),
        addUnit("B", byte_),
        addPrefix("hob", 7),
		addAllSI
    );
    
    alias sz = ctQuantityParser!(real, symbolList, std.conv.parse!(real, string));

    auto height = sz!"1 hobbit";
    assert(height.value(sz!"bit") == 7);
	height = sz!"1 kB";
	assert(height.value(byte_) == 1000);
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

RTQuantity!N parseRTQuantity(N, alias parseFun, S, SL)(S text, auto ref SL symbolList)
{
    static assert(isForwardRange!S && isSomeChar!(ElementType!S),
                  "text must be a forward range of a character type");

    N value = N.init; // nan
    try
        value = parseFun(text);
    catch
        value = 1;

    if (text.empty)
        return RTQuantity!N(value, null);

    auto input = text.to!string;
    auto tokens = lex(input);
    auto parser = QuantityParser!N(symbolList);

    RTQuantity!N result = parser.parseCompoundUnit(tokens);
    result.value *= value;
    return result;
}

unittest // Examples from the header
{
    alias parseRTQ = parseRTQuantity!(real, std.conv.parse!(real, string), string, SymbolList!real);

    auto J = toRT(joule);
    assert(parseRTQ("1 N m", siSymbolList) == J);
    assert(parseRTQ("1 N.m", siSymbolList) == J);
    assert(parseRTQ("1 N⋅m", siSymbolList) == J);
    assert(parseRTQ("1 N * m", siSymbolList) == J);
    assert(parseRTQ("1 N × m", siSymbolList) == J);

    auto kat = toRT(katal);
    assert(parseRTQ("1 mol s^-1", siSymbolList) == kat);
    assert(parseRTQ("1 mol s⁻¹", siSymbolList) == kat);
    assert(parseRTQ("1 mol/s", siSymbolList) == kat);

    auto Pa = toRT(pascal);
    assert(parseRTQ("1 kg m^-1 s^-2", siSymbolList) == Pa);
    assert(parseRTQ("1 kg/(m s^2)", siSymbolList) == Pa);
}

unittest // Test parsing
{
    import std.math : approxEqual;

    alias parseRTQ = parseRTQuantity!(real, std.conv.parse!(real, string), string, SymbolList!real);

    assertThrown!ParsingException(parseRTQ("1 µ g", siSymbolList));
    assertThrown!ParsingException(parseRTQ("1 µ", siSymbolList));
    assertThrown!ParsingException(parseRTQ("1 g/", siSymbolList));
    assertThrown!ParsingException(parseRTQ("1 g^", siSymbolList));

    string test = "1    m    ";
    assert(parseRTQ(test, siSymbolList) == meter.toRT);
    assert(parseRTQ("1 µm", siSymbolList).value.approxEqual(micro(meter).rawValue));

    assert(parseRTQ("1 m^-1", siSymbolList) == toRT(1 / meter));
    assert(parseRTQ("1 m²", siSymbolList) == square(meter).toRT);
    assert(parseRTQ("1 m⁻¹", siSymbolList) == toRT(1 / meter));
    assert(parseRTQ("1 (m)", siSymbolList) == meter.toRT);
    assert(parseRTQ("1 (m^-1)", siSymbolList) == toRT(1 / meter));
    assert(parseRTQ("1 ((m)^-1)^-1", siSymbolList) == meter.toRT);

    assert(parseRTQ("1 m*m", siSymbolList) == square(meter).toRT);
    assert(parseRTQ("1 m m", siSymbolList) == square(meter).toRT);
    assert(parseRTQ("1 m.m", siSymbolList) == square(meter).toRT);
    assert(parseRTQ("1 m⋅m", siSymbolList) == square(meter).toRT);
    assert(parseRTQ("1 m×m", siSymbolList) == square(meter).toRT);
    assert(parseRTQ("1 m/m", siSymbolList) == toRT(meter / meter));
    assert(parseRTQ("1 m÷m", siSymbolList) == toRT(meter / meter));

    assert(parseRTQ("1 N.m", siSymbolList) == toRT(newton * meter));
    assert(parseRTQ("1 N m", siSymbolList) == toRT(newton * meter));

    assert(parseRTQ("6.3 L.mmol^-1.cm^-1", siSymbolList).value.approxEqual(630));
    assert(parseRTQ("6.3 L/(mmol*cm)", siSymbolList).value.approxEqual(630));
    assert(parseRTQ("6.3 L*(mmol*cm)^-1", siSymbolList).value.approxEqual(630));
    assert(parseRTQ("6.3 L/mmol/cm", siSymbolList).value.approxEqual(630));

    assert(parseRTQ("0.8", siSymbolList).value.approxEqual(0.8));
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
    unittest
    {
        assert(_defaultParser.parseCompoundUnit(lex("m * m")) == square(meter).toRT);
        assert(_defaultParser.parseCompoundUnit(lex("m m")) == square(meter).toRT);
        assert(_defaultParser.parseCompoundUnit(lex("m * m / m")) == meter.toRT);
        assertThrown!ParsingException(_defaultParser.parseCompoundUnit(lex("m ) m")));
        assertThrown!ParsingException(_defaultParser.parseCompoundUnit(lex("m * m) m")));
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

        return RTQ(std.math.pow(ret.value, n), ret.dimensions.exp(n));
    }
    unittest
    {
        assert(_defaultParser.parseExponentUnit(lex("m²")) == square(meter).toRT);
        assert(_defaultParser.parseExponentUnit(lex("m^2")) == square(meter).toRT);
        assertThrown!ParsingException(_defaultParser.parseExponentUnit(lex("m^²")));
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
    unittest
    {
        assert(_defaultParser.parseInteger(lex("-123")) == -123);
        assert(_defaultParser.parseInteger(lex("⁻¹²³")) == -123);
        assertThrown!ParsingException(_defaultParser.parseInteger(lex("1-⁺⁵")));
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
    unittest
    {
        assert(_defaultParser.parseUnit(lex("(m)")) == meter.toRT);
        assertThrown!ParsingException(_defaultParser.parseUnit(lex("(m")));
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
    unittest
    {
        assert(_defaultParser.parsePrefixUnit(lex("mm")).value.approxEqual(milli(meter).rawValue));
        assert(_defaultParser.parsePrefixUnit(lex("cd")).value.approxEqual(candela.rawValue));
        assertThrown!ParsingException(_defaultParser.parsePrefixUnit(lex("Lm")));
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
static __gshared dchar[dchar] supIntegerMap;
shared static this()
{
    supIntegerMap = ctSupIntegerMap;
}

Token[] lex(string input)
{
    enum State
    {
        none,
        symbol,
        integer,
        supinteger
    }

    Token[] tokens;
    auto original = input;
    size_t i, j;
    State state = State.none;

    void pushToken(Tok type)
    {
        tokens ~= Token(type, original[i .. j]);
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
        auto n = std.conv.parse!int(slice);
        enforceEx!ParsingException(slice.empty, "Unexpected integer format: " ~ slice);
        tokens ~= Token(type, original[i .. j], n);
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
            case ' ':
            case '\t':
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
int[string] exp(int[string] dim, int value)
{
    if (value == 0)
        return null;

    int[string] result;
    foreach (sym, pow; dim)
        result[sym] = pow * value;
    return result;
}

// Raise a dimension array to a rational power (1/value)
int[string] expInv(int[string] dim, int value)
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

// Returns the string representation of a dimension array
string dimstr(int[string] dim, bool complete = false)
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
    foreach (sym, pow; dim)
        dimstrs ~= stringize(sym, pow);

    string result = dimstrs.filter!"a !is null".join(" ");
    if (!result.length)
        return complete ? "scalar" : "";

    return result;
}
