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

Copyright: Copyright 2013-2015, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.parsing;

import quantities.internal.dimensions;
import quantities.base;
import quantities.qvariant;

import std.array;
import std.algorithm;
import std.conv;
import std.exception;
import std.math;
import std.range;
import std.string;
import std.traits;
import std.typetuple;
import std.utf;


/// Exception thrown when operating on two units that are not interconvertible.
class DimensionException : Exception
{
    pure @safe nothrow
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
    
    pure @safe nothrow
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}

/++
Contains the symbols of the units and the prefixes that a parser can handle.
+/
struct SymbolList(N)
{
    static assert(isNumeric!N, "Incompatible type: " ~ N.stringof);

    package
    {
        QVariant!N[string] units;
        N[string] prefixes;
        size_t maxPrefixLength;
    }

    /// Adds (or replaces) a unit in the list
    auto addUnit(Q)(string symbol, Q unit)
        if (isQVariant!Q)
    {
        units[symbol] = unit;
        return this;
    }
    /// ditto
    auto addUnit(Q)(string symbol, Q unit)
        if (isQuantity!Q)
    {
        return addUnit(symbol, unit.qVariant);
    }

    /// Adds (or replaces) a prefix in the list
    auto addPrefix(N)(string symbol, N factor)
        if (isNumeric!N)
    {
        prefixes[symbol] = factor;
        if (symbol.length > maxPrefixLength)
            maxPrefixLength = symbol.length;
        return this;
    }
}

/// Type of a function that can parse a string for a numeric value of type N.
alias NumberParser(N) = N function(ref string s) pure @safe;

/// A quantity parser
struct Parser(N)
{
    SymbolList!N symbolList; /// A list of registered symbols for units and prefixes.
    NumberParser!N numberParser; /// A function that can parse a string for a numeric value of type N.

    /++
    Parses a QVariant from a string.
    +/
    QVariant!N parseVariant(string str)
    {
        return parseQuantityImpl!N(str, symbolList, numberParser);
    }

    /++
    Parses a quantity of a known type Q from a string.
    +/
    Q parse(Q)(string str)
        if (isQuantity!Q)
    {
        static assert(is(N : Q.valueType), "Incompatible value type: " ~ Q.valueType.stringof);
        
        auto q = parseQuantityImpl!(Q.valueType)(str, symbolList, numberParser);
        enforceEx!DimensionException(Q.dimensions == q.dimensions,
            "Dimension error: [%s] is not compatible with [%s]".format(
                Q.dimensions.toString, q.dimensions.toString));
        return Q.make(q.rawValue);
    }
}
///
pure @safe unittest
{
    // From http://en.wikipedia.org/wiki/List_of_humorous_units_of_measurement

    auto century = unit!(real, "century");
    alias LectureLength = typeof(century);
    
    auto symbolList = SymbolList!real()
        .addUnit("Cy", century)
        .addPrefix("µ", 1e-6L);

    import std.conv;
    auto parser = Parser!real(symbolList, &std.conv.parse!(real, string));

    auto timing = 1e-6L * century;
    assert(timing == parser.parse!LectureLength("1 µCy"));
    assert(timing == parser.parseVariant("1 µCy"));
}

/// Creates a compile-time parser that parses a string for a quantity and
/// automatically deduces the quantity type.
template compileTimeParser(N, alias symbolList, alias numberParser)
{
    template compileTimeParser(string str)
    {
        enum q = parseQuantityImpl!N(str, symbolList, &numberParser); 
        enum compileTimeParser = Quantity!(N, cast(Dimensions) q.dimensions).make(q.rawValue);
    }
}
///
pure @safe unittest
{
    enum century = unit!(real, "century");
    alias LectureLength = typeof(century);
    
    enum symbolList = SymbolList!real()
        .addUnit("Cy", century)
        .addPrefix("µ", 1e-6L);
    
    alias ctParser = compileTimeParser!(real, symbolList, std.conv.parse!(real, string));
    enum timing = 1e-6L * century;
    static assert(timing == ctParser!"1 µCy");
}

/// Exception thrown when parsing encounters an unexpected token.
class ParsingException : Exception
{
    pure @safe nothrow
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }

    pure @safe nothrow
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}

private:

QVariant!N parseQuantityImpl(N)(string input, SymbolList!N symbolList, NumberParser!N parseFun)
{
    N value;
    try
        value = parseFun(input);
    catch (Exception)
        value = 1;

    if (input.empty)
        return QVariant!N.make(value, Dimensions.init);

    auto tokens = lex(input);
    auto parser = QuantityParser!N(tokens, symbolList);

    return value * parser.parseCompoundUnit();
}

pure @safe unittest // Test parsing
{
    auto meter = unit!(double, "L");
    auto kilogram = unit!(double, "M");
    auto second = unit!(double, "T");
    auto one = meter / meter;
    auto unknown = one;

    auto siSL = SymbolList!double()
        .addUnit("m", meter)
        .addUnit("kg", kilogram)
        .addUnit("s", second)
        .addPrefix("c", 0.01L)
        .addPrefix("m", 0.001L);

    bool checkParse(Q)(string input, Q quantity)
    {
        return parseQuantityImpl!double(input, siSL, &std.conv.parse!(double, string))
            == quantity.qVariant;
    }

    assert(checkParse("1    m    ", meter));
    assert(checkParse("1m", meter));
    assert(checkParse("1 mm", 0.001 * meter));
    assert(checkParse("1 m^-1", 1 / meter));
    assert(checkParse("1 m²", meter * meter));
    assert(checkParse("1 m⁺²", meter * meter));
    assert(checkParse("1 m⁻¹", 1 / meter));
    assert(checkParse("1 (m)", meter));
    assert(checkParse("1 (m^-1)", 1 / meter));
    assert(checkParse("1 ((m)^-1)^-1", meter));
    assert(checkParse("1 (s/(s/m))", meter));
    assert(checkParse("1 m*m", meter * meter));
    assert(checkParse("1 m m", meter * meter));
    assert(checkParse("1 m.m", meter * meter));
    assert(checkParse("1 m⋅m", meter * meter));
    assert(checkParse("1 m×m", meter * meter));
    assert(checkParse("1 m/m", meter / meter));
    assert(checkParse("1 m÷m", meter / meter));
    assert(checkParse("1 m.s", second * meter));
    assert(checkParse("1 m s", second * meter));
    assert(checkParse("1 m²s", meter * meter * second));
    assert(checkParse("1 m*m/m", meter));
    assert(checkParse("0.8 m⁰", 0.8 * one));
    assert(checkParse("0.8", 0.8 * one));
    assert(checkParse("0.8 ", 0.8 * one));

    assertThrown!ParsingException(checkParse("1 c m", unknown));
    assertThrown!ParsingException(checkParse("1 c", unknown));
    assertThrown!ParsingException(checkParse("1 Qm", unknown));
    assertThrown!ParsingException(checkParse("1 m + m", unknown));
    assertThrown!ParsingException(checkParse("1 m/", unknown));
    assertThrown!ParsingException(checkParse("1 m^", unknown));
    assertThrown!ParsingException(checkParse("1 m^m", unknown));
    assertThrown!ParsingException(checkParse("1 m ) m", unknown));
    assertThrown!ParsingException(checkParse("1 m * m) m", unknown));
    assertThrown!ParsingException(checkParse("1 m^²", unknown));
    assertThrown!ParsingException(checkParse("1-⁺⁵", unknown));
}

// A parser that can parse a text for a unit or a quantity
struct QuantityParser(N)
{
    private 
    {
        Token[] tokens;
        SymbolList!N symbolList;
    }

    QVariant!N parseCompoundUnit(bool inParens = false) pure @safe
    {
        QVariant!N ret = parseExponentUnit();
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

            QVariant!N rhs = parseExponentUnit();
            if (multiply)
                ret *= rhs;
            else
                ret /= rhs;

            if (tokens.empty || (inParens && tokens.front.type == Tok.rparen))
                break;

            cur = tokens.front;
        }
        while (!tokens.empty);

        return ret;
    }

    QVariant!N parseExponentUnit() pure @safe
    {
        QVariant!N ret = parseUnit();

        if (tokens.empty)
            return ret;

        auto next = tokens.front;
        if (next.type != Tok.exp && next.type != Tok.supinteger)
            return ret;

        if (next.type == Tok.exp)
            tokens.advance(Tok.integer);

        int n = parseInteger();

        // Cannot use ret ^^ n because of CTFE limitation
        static if (__traits(compiles, std.math.pow(ret.value, n)))
            ret._value = std.math.pow(ret.value, n);
        else
            foreach (i; 1 .. n)
                ret._value *= ret._value;
        ret.dimensions = ret.dimensions.pow(n);
        return ret;
    }

    int parseInteger() pure @safe
    {
        tokens.check(Tok.integer, Tok.supinteger);
        int n = tokens.front.integer;
        if (tokens.length)
            tokens.advance();
        return n;
    }

    QVariant!N parseUnit() pure @safe
    {
        if (!tokens.length)
            return QVariant!N.make(1, Dimensions.init);

        QVariant!N ret;        
        if (tokens.front.type == Tok.lparen)
        {
            tokens.advance();
            ret = parseCompoundUnit(true);
            tokens.check(Tok.rparen);
            tokens.advance();
        }
        else
            ret = parsePrefixUnit();

        return ret;
    }

    QVariant!N parsePrefixUnit() pure @safe
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
                        return *factor * *uptr;
                }
            }
        }

        throw new ParsingException("Unknown unit symbol: '%s'".format(str));
    }
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

Token[] lex(string input) pure @safe
{
    enum State
    {
        none,
        symbol,
        integer,
        supinteger
    }

    Token[] tokens;
    auto tokapp = appender(tokens);

    auto original = input;
    size_t i, j;
    State state = State.none;

    void pushToken(Tok type)
    {
        tokapp.put(Token(type, original[i .. j]));
        i = j;
        state = State.none;
    }

    void pushInteger(Tok type)
    {
        auto slice = original[i .. j];

        if (type == Tok.supinteger)
        {
            auto a = appender!string;
            foreach (dchar c; slice)
            {
                switch (c)
                {
                    case '⁰': a.put('0'); break;
                    case '¹': a.put('1'); break;
                    case '²': a.put('2'); break;
                    case '³': a.put('3'); break;
                    case '⁴': a.put('4'); break;
                    case '⁵': a.put('5'); break;
                    case '⁶': a.put('6'); break;
                    case '⁷': a.put('7'); break;
                    case '⁸': a.put('8'); break;
                    case '⁹': a.put('9'); break;
                    case '⁺': a.put('+'); break;
                    case '⁻': a.put('-'); break;
                    default: assert(false, "Error in pushInteger()");
                }
            }
            slice = a.data;
        }

        int n;
        try
        {
            n = std.conv.parse!int(slice);
            enforce(slice.empty);
        }
        catch (Exception)
            throw new ParsingException("Unexpected integer format: " ~ original[i .. j]);
            
        tokapp.put(Token(type, original[i .. j], n));
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

    return tokapp.data;
}

void advance(Types...)(ref Token[] tokens, Types types)
{
    enforceEx!ParsingException(!tokens.empty, "Unexpected end of input");
    tokens.popFront();

    static if (Types.length)
        check(tokens, types);
}

void check(Token[] tokens) pure @safe
{
    enforceEx!ParsingException(tokens.length, "Unexpected end of input");
}

void check(Token[] tokens, Tok tok) pure @safe
{
    tokens.check();
    enforceEx!ParsingException(tokens[0].type == tok,
        format("Found '%s' while expecting %s", 
            tokens[0].slice, tok));
}

void check(Token[] tokens, Tok tok1, Tok tok2) pure @safe
{
    tokens.check();
    enforceEx!ParsingException(tokens[0].type == tok1 || tokens[0].type == tok2,
        format("Found '%s' while expecting %s or %s", 
            tokens[0].slice, tok1, tok2));
}
