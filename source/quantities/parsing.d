/++
This module defines functions to parse units and quantities.

Copyright: Copyright 2013-2018, Nicolas Sicard  
Authors: Nicolas Sicard  
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)  
Source: $(LINK https://github.com/biozic/quantities)  
+/
module quantities.parsing;

import quantities.internal.dimensions;
import quantities.runtime;
import quantities.compiletime;
import std.conv : parse;
import std.exception : basicExceptionCtors, enforce;
import std.format : format;
import std.traits : isNumeric, isSomeString;

/++
Contains the symbols of the units and the prefixes that a parser can handle.
+/
struct SymbolList(N)
        if (isNumeric!N)
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
            if (isQVariantOrQuantity!Q)
    {
        static if (isQVariant!Q)
            units[symbol] = unit;
        else static if (isQuantity!Q)
            units[symbol] = unit.qVariant;
        else
            static assert(false);
        return this;
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

/++
A quantity parser.

Params:
    N = The numeric type of the quantities.
    numberParser = a function that takes a reference to any kind of string and
        returns the parsed number.
+/
struct Parser(N, alias numberParser = (ref s) => parse!N(s))
        if (isNumeric!N)
{
    /// A list of registered symbols for units and prefixes.
    SymbolList!N symbolList;

    /++
    Parses a QVariant from str.
    +/
    QVariant!N parse(S)(S str)
            if (isSomeString!S)
    {
        return parseQuantityImpl!(N, numberParser)(str, symbolList);
    }
}
///
unittest
{
    // From http://en.wikipedia.org/wiki/List_of_humorous_units_of_measurement

    import std.conv : parse;

    auto century = unit!real("T");
    alias LectureLength = typeof(century);

    auto symbolList = SymbolList!real().addUnit("Cy", century).addPrefix("µ", 1e-6L);
    alias numberParser = (ref s) => parse!real(s);
    auto parser = Parser!(real, numberParser)(symbolList);

    auto timing = 1e-6L * century;
    assert(timing == parser.parse("1 µCy"));
}

/// Exception thrown when parsing encounters an unexpected token.
class ParsingException : Exception
{
    mixin basicExceptionCtors;
}

package(quantities):

QVariant!N parseQuantityImpl(N, alias numberParser, S)(S input, SymbolList!N symbolList)
        if (isSomeString!S)
{
    import std.range.primitives : empty;

    N value;
    try
        value = numberParser(input);
    catch (Exception)
        value = 1;

    if (input.empty)
        return QVariant!N(value, Dimensions.init);

    auto parser = QuantityParser!(N, S)(input, symbolList);
    return value * parser.parsedQuantity();
}

// A parser that can parse a text for a unit or a quantity
struct QuantityParser(N, S)
        if (isNumeric!N && isSomeString!S)
{
    import std.conv : to;
    import std.exception : enforce;
    import std.format : format;
    import std.range.primitives : empty, front, popFront;

    private
    {
        S input;
        SymbolList!N symbolList;
        Token[] tokens;
    }

    this(S input, SymbolList!N symbolList)
    {
        this.input = input;
        this.symbolList = symbolList;
        lex(input);
    }

    QVariant!N parsedQuantity()
    {
        return parseCompoundUnit();
    }

    QVariant!N parseCompoundUnit(bool inParens = false)
    {
        QVariant!N ret = parseExponentUnit();
        if (tokens.empty || (inParens && tokens.front.type == Tok.rparen))
            return ret;

        do
        {
            check();
            auto cur = tokens.front;

            bool multiply = true;
            if (cur.type == Tok.div)
                multiply = false;

            if (cur.type == Tok.mul || cur.type == Tok.div)
            {
                advance();
                check();
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

    QVariant!N parseExponentUnit()
    {
        QVariant!N ret = parseUnit();

        // If no exponent is found
        if (tokens.empty)
            return ret;

        // The next token should be '^', an integer or a superior integer
        auto next = tokens.front;
        if (next.type != Tok.exp && next.type != Tok.integer && next.type != Tok.supinteger)
            return ret;

        // Skip the '^' if present, and expect an integer
        if (next.type == Tok.exp)
            advance(Tok.integer);

        Rational r = parseRationalOrInteger();
        return ret ^^ r;
    }

    Rational parseRationalOrInteger()
    {
        int num = parseInteger();
        int den = 1;
        if (tokens.length && tokens.front.type == Tok.div)
        {
            advance();
            den = parseInteger();
        }
        return Rational(num, den);
    }

    int parseInteger()
    {
        check(Tok.integer, Tok.supinteger);
        int n = tokens.front.integer;
        if (tokens.length)
            advance();
        return n;
    }

    QVariant!N parseUnit()
    {
        if (!tokens.length)
            return QVariant!N(1, Dimensions.init);

        if (tokens.front.type == Tok.lparen)
        {
            advance();
            auto ret = parseCompoundUnit(true);
            check(Tok.rparen);
            advance();
            return ret;
        }
        else
            return parsePrefixUnit();
    }

    QVariant!N parsePrefixUnit()
    {
        check(Tok.symbol);
        auto str = input[tokens.front.begin .. tokens.front.end].to!string;
        if (tokens.length)
            advance();

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
                    enforce!ParsingException(unit.length,
                            "Expecting a unit after the prefix " ~ prefix);
                    uptr = unit in symbolList.units;
                    if (uptr)
                        return *factor * *uptr;
                }
            }
        }

        throw new ParsingException("Unknown unit symbol: '%s'".format(str));
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
        size_t begin;
        size_t end;
        int integer = int.max;
    }

    void lex(S input) @safe
    {
        import std.array : appender;
        import std.conv : parse;
        import std.exception : enforce;
        import std.utf : codeLength;

        enum State
        {
            none,
            symbol,
            integer,
            supinteger
        }

        auto tokapp = appender(tokens);
        size_t i, j;
        State state = State.none;
        auto intapp = appender!string;

        void pushToken(Tok type)
        {
            tokapp.put(Token(type, i, j));
            i = j;
            state = State.none;
        }

        void pushInteger(Tok type)
        {
            int n;
            auto slice = intapp.data;
            try
            {
                n = parse!int(slice);
                assert(slice.empty);
            }
            catch (Exception)
                throw new ParsingException("Unexpected integer format: %s".format(slice));

            tokapp.put(Token(type, i, j, n));
            i = j;
            state = State.none;
            intapp = appender!string;
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

        foreach (dchar cur; input)
        {
            auto len = cur.codeLength!char;
            switch (cur)
            {
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

            case '*': // Asterisk
            case '.': // Dot
            case '\u00B7': // Middle dot (·)         
            case '\u00D7': // Multiplication sign (×)
            case '\u2219': // Bullet operator (∙)    
            case '\u22C5': // Dot operator (⋅)       
            case '\u2022': // Bullet (•)             
            case '\u2715': // Multiplication X (✕)   
                push();
                j += len;
                pushToken(Tok.mul);
                break;

            case '/': // Slash
            case '\u00F7': // Division sign (÷)
            case '\u2215': // Division slash (∕)
                push();
                j += len;
                pushToken(Tok.div);
                break;

            case '^':
                push();
                j += len;
                pushToken(Tok.exp);
                break;

            case '-': // Hyphen
            case '\u2212': // Minus sign (−)
            case '\u2012': // Figure dash (‒)
            case '\u2013': // En dash (–)
                intapp.put('-');
                goto PushIntChar;
            case '+': // Plus sign
                intapp.put('+');
                goto PushIntChar;
            case '0': .. case '9':
                intapp.put(cur);
            PushIntChar:
                if (state != State.integer)
                    push();
                state = State.integer;
                j += len;
                break;

            case '⁰':
                intapp.put('0');
                goto PushSupIntChar;
            case '¹':
                intapp.put('1');
                goto PushSupIntChar;
            case '²':
                intapp.put('2');
                goto PushSupIntChar;
            case '³':
                intapp.put('3');
                goto PushSupIntChar;
            case '⁴':
                intapp.put('4');
                goto PushSupIntChar;
            case '⁵':
                intapp.put('5');
                goto PushSupIntChar;
            case '⁶':
                intapp.put('6');
                goto PushSupIntChar;
            case '⁷':
                intapp.put('7');
                goto PushSupIntChar;
            case '⁸':
                intapp.put('8');
                goto PushSupIntChar;
            case '⁹':
                intapp.put('9');
                goto PushSupIntChar;
            case '⁻':
                intapp.put('-');
                goto PushSupIntChar;
            case '⁺':
                intapp.put('+');
            PushSupIntChar:
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
        }
        push();
        tokens = tokapp.data;
    }

    void advance(Types...)(Types types)
    {
        enforce!ParsingException(!tokens.empty, "Unexpected end of input");
        tokens.popFront();

        static if (Types.length)
            check(types);
    }

    void check()
    {
        enforce!ParsingException(tokens.length, "Unexpected end of input");
    }

    void check(Tok tok)
    {
        check();
        enforce!ParsingException(tokens[0].type == tok,
                format("Found '%s' while expecting %s", input[tokens[0].begin .. tokens[0].end],
                    tok));
    }

    void check(Tok tok1, Tok tok2)
    {
        check();
        enforce!ParsingException(tokens[0].type == tok1 || tokens[0].type == tok2,
                format("Found '%s' while expecting %s or %s",
                    input[tokens[0].begin .. tokens[0].end], tok1, tok2));
    }
}

// Tests

@("Generic parsing")
unittest
{
    import std.exception : assertThrown;

    auto meter = unit!double("L");
    auto kilogram = unit!double("M");
    auto second = unit!double("T");
    auto one = meter / meter;
    auto unknown = one;

    auto siSL = SymbolList!double().addUnit("m", meter).addUnit("kg", kilogram)
        .addUnit("s", second).addPrefix("c", 0.01L).addPrefix("m", 0.001L);

    bool checkParse(S, Q)(S input, Q quantity)
    {
        import std.conv : parse;

        return parseQuantityImpl!(double, (ref s) => parse!double(s))(input, siSL) == quantity;
    }

    assert(checkParse("1    m    ", meter));
    assert(checkParse("1m", meter));
    assert(checkParse("1 mm", 0.001 * meter));
    assert(checkParse("1 m2", meter * meter));
    assert(checkParse("1 m^-1", 1 / meter));
    assert(checkParse("1 m-1", 1 / meter));
    assert(checkParse("1 m^1/1", meter));
    assert(checkParse("1 m^-1/1", 1 / meter));
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
