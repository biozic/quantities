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
import quantities.math;
import quantities.si;
import std.algorithm;
import std.conv;
import std.exception;
import std.range;
import std.string;
import std.traits;
import std.utf;

// TODO: Add possibility to add user-defined units and prefix (make the SI ones appendable)

version (unittest)
    import std.math : approxEqual;

// debug import std.stdio;

/// Parses text for a unit or a quantity (with a numerical value) at runtime.
RTQuantity parseQuantity(S)(S text)
{
    static assert(isForwardRange!S && isSomeChar!(ElementType!S),
                  "text must be a forward range of a character type");

    real value = 1;
    try
    {
        // This throws if there is no value ("no digits seen")
        value = std.conv.parse!real(text);
    }
    catch {} // Explore the rest...
 
    if (text.empty)
        return RTQuantity(value, Dimensions.init);

    auto tokens = lex(text);
    return value * parseCompoundUnit(tokens);
}
///
@name("Example of " ~ fullyQualifiedName!parseQuantity)
unittest
{
    alias Concentration = Store!(mole/cubic(meter));
    
    // Parse a concentration value
    Concentration c = parseQuantity("11.2 µmol/L");
    assert(approxEqual(c.value(nano(mole)/liter), 11200));
    
    // Below, 'second' is only a hint for dimensional analysis
    Store!second t = parseQuantity("90 min");
    assert(t == 90 * minute);
    t = parseQuantity("h");
    assert(t == 1 * hour);
}

@name(moduleName!parseQuantity ~ " header examples")
unittest
{
    auto c = parseQuantity(
        ["11.2", "<- value", "µmol/L", "<-unit"]
        .filter!(x => !x.startsWith("<"))
        .joiner(" ")
    );
    assert(approxEqual(c.value(nano(mole)/liter), 11200));
}

unittest
{
    auto J = RTQuantity(joule);
    assert(parseQuantity("1 N m") == J);
    assert(parseQuantity("1 N.m") == J);
    assert(parseQuantity("1 N⋅m") == J);
    assert(parseQuantity("1 N * m") == J);
    assert(parseQuantity("1 N × m") == J);

    auto kat = RTQuantity(katal);
    assert(parseQuantity("1 mol s^-1") == kat);
    assert(parseQuantity("1 mol s⁻¹") == kat);
    assert(parseQuantity("1 mol/s") == kat);

    auto Pa = RTQuantity(pascal);
    assert(parseQuantity("1 kg m^-1 s^-2") == Pa);
    assert(parseQuantity("1 kg/(m s^2)") == Pa);
}

@name(fullyQualifiedName!parseQuantity)
unittest
{
    import std.math : approxEqual;
    
    assertThrown!ParsingException(parseQuantity("1 µ m"));
    assertThrown!ParsingException(parseQuantity("1 µ"));

    string test = "1    m    ";
    assert(parseQuantity(test) == meter);
    assert(approxEqual(parseQuantity("1 µm").rawValue, micro(meter).rawValue));
    
    assert(parseQuantity("1 m^-1") == 1 / meter);
    assert(parseQuantity("1 m²") == square(meter));
    assert(parseQuantity("1 m⁻¹") == 1 / meter);
    assert(parseQuantity("1 (m)") == meter);
    assert(parseQuantity("1 (m^-1)") == 1 / meter);
    assert(parseQuantity("1 ((m)^-1)^-1") == meter);
    
    assert(parseQuantity("1 m * m") == square(meter));
    assert(parseQuantity("1 m m") == square(meter));
    assert(parseQuantity("1 m . m") == square(meter));
    assert(parseQuantity("1 m ⋅ m") == square(meter));
    assert(parseQuantity("1 m × m") == square(meter));
    assert(parseQuantity("1 m / m") == meter / meter);
    assert(parseQuantity("1 m ÷ m") == meter / meter);
    
    assert(parseQuantity("1 N.m") == (newton * meter));
    assert(parseQuantity("1 N m") == (newton * meter));
    
    assert(approxEqual(parseQuantity("6.3 L.mmol^-1.cm^-1").value(square(meter)/mole), 630));
    assert(approxEqual(parseQuantity("6.3 L/(mmol*cm)").value(square(meter)/mole), 630));
    assert(approxEqual(parseQuantity("6.3 L*(mmol*cm)^-1").value(square(meter)/mole), 630));
    assert(approxEqual(parseQuantity("6.3 L/mmol/cm").value(square(meter)/mole), 630));
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
    assert(parseCompoundUnit(lex("m * m")) == square(RTQuantity(meter)));
    assert(parseCompoundUnit(lex("m m")) == square(RTQuantity(meter)));
    assert(parseCompoundUnit(lex("m * m / m")) == RTQuantity(meter));
    assertThrown!ParsingException(parseCompoundUnit(lex("m ) m")));
    assertThrown!ParsingException(parseCompoundUnit(lex("m * m) m")));
}

RTQuantity parseExponentUnit(T)(auto ref T[] tokens)
    if (is(T : Token))
{
    RTQuantity ret = parseUnit(tokens);

    if (tokens.empty)
        return ret;

    auto next = tokens.front;
    if (next.type != Tok.exp && next.type != Tok.supinteger)
        return ret;

    if (next.type == Tok.exp)
        tokens.advance(Tok.integer);

    int n = parseInteger(tokens);
    ret.resetTo(ret.pow(n));
    return ret;
}
@name(fullyQualifiedName!parseExponentUnit)
unittest
{
    assert(parseExponentUnit(lex("m²")) == square(RTQuantity(meter)));
    assert(parseExponentUnit(lex("m^2")) == square(RTQuantity(meter)));
    assertThrown!ParsingException(parseExponentUnit(lex("m^²")));
}

int parseInteger(T)(auto ref T[] tokens)
    if (is(T : Token))
{
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
    assert(parseUnit(lex("(m)")) == RTQuantity(meter));
    assertThrown!ParsingException(parseUnit(lex("(m")));
}

RTQuantity parsePrefixUnit(T)(auto ref T[] tokens)
    if (is(T : Token))
{
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

        // Special case of "da" that is a 2-letter prefix
        if (str.startsWith("da"))
        {
            string unit = str.dropExactly(2).to!string;
            enforceEx!ParsingException(unit.length, "Expecting a unit after the prefix da");
            return SIPrefixSymbols["da"] * parseUnitSymbol(unit);
        }

        // Try 1-letter prefixes
        string prefix = str.takeExactly(1).to!string;
        assert(prefix.length, "Prefix with no length");
        auto factor = prefix in SIPrefixSymbols;
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
    assert(approxEqual(parsePrefixUnit(lex("mm")).rawValue, milli(meter).rawValue));
    assert(approxEqual(parsePrefixUnit(lex("cd")).rawValue, candela.rawValue));
    assertThrown!ParsingException(parsePrefixUnit(lex("Lm")));
}

RTQuantity parseUnitSymbol(string str)
{
    assert(str.length, "Symbol with no length");
    auto uptr = str in SIUnitSymbols;
    enforceEx!ParsingException(uptr, "Unknown unit symbol: " ~ str);
    return *uptr;
}
@name(fullyQualifiedName!parseUnitSymbol)
unittest
{
    assert(parseUnitSymbol("m") == RTQuantity(meter));
    assert(parseUnitSymbol("K") == RTQuantity(kelvin));
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
{
    enum State
    {
        none,
        symbol,
        integer,
        supinteger
    }

    Token[] tokapp;
    auto buf = appender!string;
    State state = State.none;
    
    void pushToken(Tok type)
    {
        tokapp ~= Token(type, buf.data);
        buf.clear();
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
        switch (cur)
        {
            case ' ':
            case '\t':
                push();
                break;
                
            case '(':
                push();
                buf.put(cur);
                pushToken(Tok.lparen);
                break;
                
            case ')':
                push();
                buf.put(cur);
                pushToken(Tok.rparen);
                break;
                
            case '*':
            case '.':
            case '⋅':
            case '×':
                push();
                buf.put(cur);
                pushToken(Tok.mul);
                break;
                
            case '/':
            case '÷':
                push();
                buf.put(cur);
                pushToken(Tok.div);
                break;
                
            case '^':
                push();
                buf.put(cur);
                pushToken(Tok.exp);
                break;
                
            case '0': .. case '9':
            case '-':
            case '+':
                if (state != State.integer)
                    push();
                state = State.integer;
                buf.put(cur);
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
                buf.put(cur);
                break;

            default:
                if (state == State.integer || state == State.supinteger)
                    push();
                state = State.symbol;
                buf.put(cur);
                break;
        }
        input.popFront();
    }
    push();
    return tokapp;
}

static immutable(RTQuantity)[string] SIUnitSymbols;
static real[string] SIPrefixSymbols;

shared static this()
{   
    SIUnitSymbols = [
        "m" : RTQuantity(meter),
        "kg" : RTQuantity(kilogram),
        "s" : RTQuantity(second),
        "A" : RTQuantity(ampere),
        "K" : RTQuantity(kelvin),
        "mol" : RTQuantity(mole),
        "cd" : RTQuantity(candela),
        "rad" : RTQuantity(radian),
        "sr" : RTQuantity(steradian),
        "Hz" : RTQuantity(hertz),
        "N" : RTQuantity(newton),
        "Pa" : RTQuantity(pascal),
        "J" : RTQuantity(joule),
        "W" : RTQuantity(watt),
        "C" : RTQuantity(coulomb),
        "V" : RTQuantity(volt),
        "F" : RTQuantity(farad),
        "Ω" : RTQuantity(ohm),
        "S" : RTQuantity(siemens),
        "Wb" : RTQuantity(weber),
        "T" : RTQuantity(tesla),
        "H" : RTQuantity(henry),
        "lm" : RTQuantity(lumen),
        "lx" : RTQuantity(lux),
        "Bq" : RTQuantity(becquerel),
        "Gy" : RTQuantity(gray),
        "Sv" : RTQuantity(sievert),
        "kat" : RTQuantity(katal),
        "g" : RTQuantity(gram),
        "min" : RTQuantity(minute),
        "h" : RTQuantity(hour),
        "d" : RTQuantity(day),
        "l" : RTQuantity(liter),
        "L" : RTQuantity(liter),
        "t" : RTQuantity(ton),
        "eV" : RTQuantity(electronVolt),
        "Da" : RTQuantity(dalton),
    ];
    
    SIPrefixSymbols = [
        "Y" : 1e24,
        "Z" : 1e21,
        "E" : 1e18,
        "P" : 1e15,
        "T" : 1e12,
        "G" : 1e9,
        "M" : 1e6,
        "k" : 1e3,
        "h" : 1e2,
        "da": 1e1,
        "d" : 1e-1,
        "c" : 1e-2,
        "m" : 1e-3,
        "µ" : 1e-6,
        "n" : 1e-9,
        "p" : 1e-12,
        "f" : 1e-15,
        "a" : 1e-18,
        "z" : 1e-21,
        "y" : 1e-24
    ];
}

