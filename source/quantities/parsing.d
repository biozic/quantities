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
alias NumberParser(N) = N function(ref string s) @safe pure;

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
        enforceEx!DimensionException(
            equals(Q.dimensions, q.dimensions),
            "Dimension error: [%s] is not compatible with [%s]"
            .format(quantities.base.toString(Q.dimensions), quantities.base.toString(q.dimensions)));
        return Q.make(q.rawValue);
    }
}
///
@safe pure unittest
{
    // From http://en.wikipedia.org/wiki/List_of_humorous_units_of_measurement

    enum century = unit!(real, "century");
    alias LectureLength = typeof(century);
    
    enum symbolList = SymbolList!real()
        .addUnit("Cy", century)
        .addPrefix("µ", 1e-6L);

    // At runtime
    {
        import std.conv;
        auto parser = Parser!real(symbolList, &std.conv.parse!(real, string));

        auto timing = 1e-6L * century;
        assert(timing == parser.parse!LectureLength("1 µCy"));
    }

    // At compile-time
    {
        import std.conv;
        enum parser = Parser!real(symbolList, &std.conv.parse!(real, string));
        
        enum timing = 1e-6L * century;
        static assert(timing == parser.parse!LectureLength("1 µCy"));
    }
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
@safe pure unittest
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

private:

QVariant!N parseQuantityImpl(N)(string input, auto ref SymbolList!N symbolList, NumberParser!N parseFun)
{
    N value;
    try
        value = parseFun(input);
    catch (Exception)
        value = 1;

    if (input.empty)
        return QVariant!N(value, null);

    auto tokens = lex(input);
    auto parser = QuantityParser!N(tokens, symbolList);

    return value * parser.parseCompoundUnit();
}

@safe pure unittest // Test parsing
{
    enum meter = unit!(double, "L");
    enum kilogram = unit!(double, "M");
    enum second = unit!(double, "T");
    enum one = meter / meter;

    enum siSL = SymbolList!double()
        .addUnit("m", meter)
        .addUnit("kg", kilogram)
        .addUnit("s", second)
        .addPrefix("c", 0.01L)
        .addPrefix("m", 0.001L);

    static bool checkParse(Q)(string input, Q quantity)
    {
        return parseQuantityImpl!double(input, siSL, &std.conv.parse!(double, string))
            == quantity.qVariant;
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

// A parser that can parse a text for a unit or a quantity
struct QuantityParser(N)
{
    private 
    {
        Token[] tokens;
        SymbolList!N symbolList;
    }

    QVariant!N parseCompoundUnit(bool inParens = false) @safe pure
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

    QVariant!N parseExponentUnit() @safe pure
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

    int parseInteger() @safe pure
    {
        tokens.check(Tok.integer, Tok.supinteger);
        int n = tokens.front.integer;
        if (tokens.length)
            tokens.advance();
        return n;
    }

    QVariant!N parseUnit() @safe pure
    {
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

    QVariant!N parsePrefixUnit() @safe pure
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

Token[] lex(string input) @safe pure
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
            slice = translate(slice, [
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
                ]);
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
