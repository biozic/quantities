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

Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.parsing;

import quantities.base;
import quantities.si;
import quantities._impl;
import std.conv;
import std.exception;
import std.range;
import std.string;
import std.traits;
import std.utf;

// TODO: Parse an ForwardRange of Char: stop at position where there is a parsing error and go back to last known good position
// TODO: Add possibility to add user-defined units in the parser (make the parser an aggregate and make a default one available
// TODO: Make the runtime quantities available to the user

version (Have_tested) import tested;
else private struct name { string dummy; }

version (unittest)
    import std.math : approxEqual;

// debug import std.stdio;

/// Parses text for a unit or a quantity (with a numerical value) at runtime.
RTQuantity parseQuantity(S)(S text)
    if (isSomeString!S)
{
    real value = 1;
    try
        value = std.conv.parse!real(text);
    catch {}
 
    if (text.empty)
        return RTQuantity(Dimensions.init, value);

    auto tokens = lex(text);
    return value * parseCompoundUnit(tokens);
}
///
@name(fullyQualifiedName!parseQuantity)
unittest
{
    alias Concentration = Store!(mole/cubic!meter);
    
    // Parse a concentration value
    Concentration c = parseQuantity("11.2 µmol/L");
    assert(approxEqual(c.value(nano(mole)/liter), 11200));
    
    // Below, 'second' is only a hint for dimensional analysis
    Store!second t = parseQuantity("90 min");
    assert(t == 90 * minute);

    // Below, 'second' is only a hint for dimensional analysis
    t = parseQuantity("h");
    assert(t == 1 * hour);
}

@name(moduleName!parseQuantity ~ " header examples")
unittest
{
    assert(parseQuantity("1 N m") == RT.joule);
    assert(parseQuantity("1 N.m") == RT.joule);
    assert(parseQuantity("1 N⋅m") == RT.joule);
    assert(parseQuantity("1 N * m") == RT.joule);
    assert(parseQuantity("1 N × m") == RT.joule);
    
    assert(parseQuantity("1 mol s^-1") == RT.katal);
    assert(parseQuantity("1 mol s⁻¹") == RT.katal);
    assert(parseQuantity("1 mol/s") == RT.katal);
    
    assert(parseQuantity("1 kg m^-1 s^-2") == RT.pascal);
    assert(parseQuantity("1 kg/(m s^2)") == RT.pascal);
}

@name(fullyQualifiedName!parseQuantity)
unittest
{
    import std.math : approxEqual;
    
    assertThrown!ParsingException(parseQuantity("1 µ m"));
    assertThrown!ParsingException(parseQuantity("1 µ"));
    
    string test = "1    m    ";
    assert(parseQuantity(test) == RT.meter);
    assert(parseQuantity("1 µm") == 1e-6 * RT.meter);
    
    assert(parseQuantity("1 m^-1") == 1 / RT.meter);
    assert(parseQuantity("1 m²") == square(RT.meter));
    assert(parseQuantity("1 m⁻¹") == 1 / RT.meter);
    assert(parseQuantity("1 (m)") == RT.meter);
    assert(parseQuantity("1 (m^-1)") == 1 / RT.meter);
    assert(parseQuantity("1 ((m)^-1)^-1") == RT.meter);
    
    assert(parseQuantity("1 m * m") == square(RT.meter));
    assert(parseQuantity("1 m m") == square(RT.meter));
    assert(parseQuantity("1 m . m") == square(RT.meter));
    assert(parseQuantity("1 m ⋅ m") == square(RT.meter));
    assert(parseQuantity("1 m × m") == square(RT.meter));
    assert(parseQuantity("1 m / m") == RT.meter / RT.meter);
    assert(parseQuantity("1 m ÷ m") == RT.meter / RT.meter);
    
    assert(parseQuantity("1 N.m") == (RT.newton * RT.meter));
    assert(parseQuantity("1 N m") == (RT.newton * RT.meter));
    
    assert(approxEqual(parseQuantity("6.3 L.mmol^-1.cm^-1").value(square(RT.meter)/RT.mole), 630));
    assert(approxEqual(parseQuantity("6.3 L/(mmol*cm)").value(square(RT.meter)/RT.mole), 630));
    assert(approxEqual(parseQuantity("6.3 L*(mmol*cm)^-1").value(square(RT.meter)/RT.mole), 630));
    assert(approxEqual(parseQuantity("6.3 L/mmol/cm").value(square(RT.meter)/RT.mole), 630));
}

/++
Convert a quantity parsed from a string into target unit, also parsed from
a string.
Parameters:
  from = A string representing the quantity to convert
  target = A string representing the target unit
Returns:
    The conversion factor (a scalar value)
+/
real convert(S, U)(S from, U target)
    if (isSomeString!S && isSomeString!U)
{
    RTQuantity base = parseQuantity(from);
    RTQuantity unit = parseQuantity("1" ~ target);
    return base.value(unit);
}
///
@name(fullyQualifiedName!convert)
unittest
{
    auto k = convert("3 min", "s");
    assert(k == 180);
}

/// Exception thrown when parsing encounters an unexpected token.
class ParsingException : Exception
{
    @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
    
    @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}

/// Exception thrown when operating on two units that are not interconvertible.
class DimensionException : Exception
{
    @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
    
    @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}

package:

void advance(Types...)(ref Token[] tokens, Types types)
{
    enforceEx!ParsingException(!tokens.empty, "Unexpected end of input");
    tokens.popFront();
    if (Types.length)
        check(tokens, types);
}

void check(Types...)(Token[] tokens, Types types)
{
    enforceEx!ParsingException(!tokens.empty, "Unexpected end of input");
    auto token = tokens.front;

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

RTQuantity parseCompoundUnit(T)(auto ref T[] tokens, bool inParens = false)
    if (is(T : Token))
{
    //debug writeln(__FUNCTION__);

    RTQuantity ret = parseExponentUnit(tokens);
    if (tokens.empty || (inParens && tokens.front.type == Tok.rparen))
        return ret;

    do {
        auto cur = tokens.front;

        bool multiply = true;
        if (cur.type == Tok.div)
            multiply = false;

        if (cur.type == Tok.mul || cur.type == Tok.div)
        {
            tokens.advance();
            cur = tokens.front;
        }

        RTQuantity rhs = parseExponentUnit(tokens);
        ret.resetTo(multiply ? (ret * rhs) : (ret / rhs));

        if (tokens.empty || (inParens && tokens.front.type == Tok.rparen))
            break;

        cur = tokens.front;
    } 
    while (!tokens.empty);

    return ret;
}
@name(fullyQualifiedName!parseCompoundUnit)
unittest
{
    assert(parseCompoundUnit(lex("m * m")) == square(RT.meter));
    assert(parseCompoundUnit(lex("m m")) == square(RT.meter));
    assert(parseCompoundUnit(lex("m * m / m")) == RT.meter);
    assertThrown!ParsingException(parseCompoundUnit(lex("m ) m")));
    assertThrown!ParsingException(parseCompoundUnit(lex("m * m) m")));
}

RTQuantity parseExponentUnit(T)(auto ref T[] tokens)
    if (is(T : Token))
{
    //debug writeln(__FUNCTION__);

    RTQuantity ret = parseUnit(tokens);

    if (tokens.empty)
        return ret;

    auto next = tokens.front;
    if (next.type != Tok.exp && next.type != Tok.supinteger)
        return ret;

    if (next.type == Tok.exp)
        tokens.advance(Tok.integer);

    int n = parseInteger(tokens);
    ret.resetTo(pow(ret, n));
    return ret;
}
@name(fullyQualifiedName!parseExponentUnit)
unittest
{
    assert(parseExponentUnit(lex("m²")) == square(RT.meter));
    assert(parseExponentUnit(lex("m^2")) == square(RT.meter));
    assertThrown!ParsingException(parseExponentUnit(lex("m^²")));
}

int parseInteger(T)(auto ref T[] tokens)
    if (is(T : Token))
{
    //debug writeln(__FUNCTION__);

    tokens.check(Tok.integer, Tok.supinteger);
    auto i = tokens.front;
    auto slice = i.slice;
    if (i.type == Tok.supinteger)
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
    auto n = std.conv.parse!int(slice);
    enforceEx!ParsingException(slice.empty, "Unexpected integer format: " ~ slice);

    if (tokens.length)
        tokens.advance();
    return n;
}
@name(fullyQualifiedName!parseInteger)
unittest
{
    assert(parseInteger(lex("-123")) == -123);
    assert(parseInteger(lex("⁻¹²³")) == -123);
    assertThrown!ParsingException(parseInteger(lex("1-⁺⁵")));
}

RTQuantity parseUnit(T)(auto ref T[] tokens)
    if (is(T : Token))
{
    //debug writeln(__FUNCTION__);

    RTQuantity ret;
    
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
@name(fullyQualifiedName!parseUnit)
unittest
{
    assert(parseUnit(lex("(m)")) == RT.meter);
    assertThrown!ParsingException(parseUnit(lex("(m")));
}

RTQuantity parsePrefixUnit(T)(auto ref T[] tokens)
    if (is(T : Token))
{
    // debug writeln(__FUNCTION__);

    tokens.check(Tok.symbol);
    auto str = tokens.front.slice;
    if (tokens.length)
        tokens.advance();

    try
    {   
        // Try a standalone unit symbol (no prefix)
        return parseUnitSymbol(str);
    }
    catch (ParsingException e)
    {
        // Try with a prefix
        string prefix = str.takeExactly(1).to!string;
        assert(prefix.length, "Prefix with no length");
        auto factor = prefix in RT.SIPrefixSymbols;
        if (factor)
        {
            string unit = str.dropOne.to!string;
            enforceEx!ParsingException(unit.length, "Expecting a unit after the prefix " ~ prefix);
            return *factor * parseUnitSymbol(unit);
        }
        else
            return parseUnitSymbol(str);
    }
}
@name(fullyQualifiedName!parsePrefixUnit)
unittest
{
    assert(parsePrefixUnit(lex("mm")) == 1e-3 * RT.meter);
    assert(parsePrefixUnit(lex("cd")) == RT.candela);
    assertThrown!ParsingException(parsePrefixUnit(lex("Lm")));
}

RTQuantity parseUnitSymbol(string str)
{
    assert(str.length, "Symbol with no length");
    return *enforceEx!ParsingException(str in RT.SIUnitSymbols, "Unknown unit symbol: " ~ str);
}
@name(fullyQualifiedName!parseUnitSymbol)
unittest
{
    assert(parseUnitSymbol("m") == RT.meter);
    assert(parseUnitSymbol("K") == RT.kelvin);
    assertThrown!ParsingException(parseUnitSymbol("jZ"));
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
}

Token[] lex(S)(S input)
    if (isSomeString!S)
{
    alias C = Unqual!(ElementEncodingType!S);

    enum State
    {
        none,
        symbol,
        integer,
        supinteger
    }
    
    auto original = input;
    Token[] tokapp;
    size_t i, j;
    State state = State.none;
    
    void pushToken(Tok type)
    {
        tokapp ~= Token(type, original[i .. j].to!string);
        i = j;
        state = State.none;
    }
    
    void push()
    {
        if (state == State.symbol)
            pushToken(Tok.symbol);
        else if (state == State.integer)
            pushToken(Tok.integer);
        else if (state == State.supinteger)
            pushToken(Tok.supinteger);
    }
    
    while (!input.empty)
    {
        auto cur = input.front;
        auto len = cur.codeLength!C;
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
    return tokapp;
}
