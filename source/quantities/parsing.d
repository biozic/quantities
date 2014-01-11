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

version (unittest)
{
    import std.math : approxEqual;

    QuantityParser defaultParser()
    {
        return QuantityParser(defaultSymbolList);
    }
}

 debug import std.stdio;

/// Parses text for a unit or a quantity at runtime.
RTQuantity parseQuantity(S)(S text, SymbolList symbolList = defaultSymbolList())
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
    auto parser = QuantityParser(symbolList);
    return value * parser.parseCompoundUnit(tokens);
}
///
unittest
{
    alias Concentration = Store!(mole/cubic(meter));
    
    // Parse a concentration value
    Concentration c = parseQuantity("11.2 µmol/L");
    assert(c.value(nano(mole)/liter).approxEqual(11200));
    
    // Below, 'second' is only a hint for dimensional analysis
    Store!second t = parseQuantity("90 min");
    assert(t == 90 * minute);
    t = parseQuantity("h");
    assert(t == 1 * hour);

    // User-defined unit
    auto symbols = defaultSymbolList();
    symbols.unitSymbols["in"] = 2.54 * centi(meter);
    assert(parseQuantity("17 in", symbols).value(centi(meter)).approxEqual(17 * 2.54));

    // User-defined symbols
    auto byte_ = unit!("byte", "B");
    SymbolList binSymbols;
    binSymbols.unitSymbols["B"] = byte_;
    binSymbols.prefixSymbols["Ki"] = 2^^10;
    binSymbols.prefixSymbols["Mi"] = 2^^20;
    // ...
    auto fileLength = parseQuantity("1.0 MiB", binSymbols);
    assert(fileLength.value(byte_).approxEqual(1_048_576));
}

unittest // Parsing a range of characters that is not a string
{
    auto c = parseQuantity(
        ["11.2", "<- value", "µmol/L", "<-unit"]
        .filter!(x => !x.startsWith("<"))
        .joiner(" ")
    );
    assert(c.value(nano(mole)/liter).approxEqual(11200));
}

unittest // Examples from the header
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

unittest // Test parsing
{
    import std.math : approxEqual;
    
    assertThrown!ParsingException(parseQuantity("1 µ m"));
    assertThrown!ParsingException(parseQuantity("1 µ"));

    string test = "1    m    ";
    assert(parseQuantity(test) == meter);
    assert(parseQuantity("1 µm").rawValue.approxEqual(micro(meter).rawValue));
    
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
    
    assert(parseQuantity("6.3 L.mmol^-1.cm^-1").value(square(meter)/mole).approxEqual(630));
    assert(parseQuantity("6.3 L/(mmol*cm)").value(square(meter)/mole).approxEqual(630));
    assert(parseQuantity("6.3 L*(mmol*cm)^-1").value(square(meter)/mole).approxEqual(630));
    assert(parseQuantity("6.3 L/mmol/cm").value(square(meter)/mole).approxEqual(630));
}

// A parser that can parse a text for a unit or a quantity
struct QuantityParser
{
    private SymbolList symbolList;
    size_t maxPrefixLength; // TODO: keep this memoized in the SymbolList

    this(SymbolList symbolList)
    {
        this.symbolList = symbolList;
        foreach (prefix; symbolList.prefixSymbols.keys)
            if (prefix.length > maxPrefixLength)
                maxPrefixLength = prefix.length;
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
    unittest
    {
        assert(defaultParser.parseCompoundUnit(lex("m * m")) == square(RTQuantity(meter)));
        assert(defaultParser.parseCompoundUnit(lex("m m")) == square(RTQuantity(meter)));
        assert(defaultParser.parseCompoundUnit(lex("m * m / m")) == RTQuantity(meter));
        assertThrown!ParsingException(defaultParser.parseCompoundUnit(lex("m ) m")));
        assertThrown!ParsingException(defaultParser.parseCompoundUnit(lex("m * m) m")));
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
    unittest
    {
        assert(defaultParser.parseExponentUnit(lex("m²")) == square(RTQuantity(meter)));
        assert(defaultParser.parseExponentUnit(lex("m^2")) == square(RTQuantity(meter)));
        assertThrown!ParsingException(defaultParser.parseExponentUnit(lex("m^²")));
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
    unittest
    {
        assert(defaultParser.parseInteger(lex("-123")) == -123);
        assert(defaultParser.parseInteger(lex("⁻¹²³")) == -123);
        assertThrown!ParsingException(defaultParser.parseInteger(lex("1-⁺⁵")));
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
    unittest
    {
        assert(defaultParser.parseUnit(lex("(m)")) == RTQuantity(meter));
        assertThrown!ParsingException(defaultParser.parseUnit(lex("(m")));
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
            // Try with prefixes, the longest prefix first
            real* factor;
            for (size_t i = maxPrefixLength; i > 0; i--)
            {
                if (str.length >= i)
                {
                    string prefix = str[0 .. i].to!string;
                    factor = prefix in symbolList.prefixSymbols;
                    if (factor)
                    {
                        string unit = str[i .. $].to!string;
                        enforceEx!ParsingException(unit.length, "Expecting a unit after the prefix " ~ prefix);
                        return *factor * parseUnitSymbol(unit);
                    }
                }
            }
            return parseUnitSymbol(str);
        }
    }
    unittest
    {
        assert(defaultParser.parsePrefixUnit(lex("mm")).rawValue.approxEqual(milli(meter).rawValue));
        assert(defaultParser.parsePrefixUnit(lex("cd")).rawValue.approxEqual(candela.rawValue));
        assertThrown!ParsingException(defaultParser.parsePrefixUnit(lex("Lm")));
    }
    
    RTQuantity parseUnitSymbol(string str)
    {
        assert(str.length, "Symbol with no length");
        auto uptr = str in symbolList.unitSymbols;
        enforceEx!ParsingException(uptr, "Unknown unit symbol: " ~ str);
        return *uptr;
    }
    unittest
    {
        assert(defaultParser.parseUnitSymbol("m") == RTQuantity(meter));
        assert(defaultParser.parseUnitSymbol("K") == RTQuantity(kelvin));
        assertThrown!ParsingException(defaultParser.parseUnitSymbol("jZ"));
    }
}

/// This struct contains the symbols of the units and the prefixes
/// that the parser can handle.
struct SymbolList
{
    /// An associative arrays of quantities (units) keyed by their symbol
    RTQuantity[string] unitSymbols;

    /// An associative arrays of prefix factors keyed by their prefix symbol
    real[string] prefixSymbols;
}

/// Returns the default list, consisting of the main SI units and prefixes.
SymbolList defaultSymbolList()
{
    return SymbolList(SIUnitSymbols, SIPrefixSymbols);
}

static RTQuantity[string] SIUnitSymbols;
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
unittest
{
    auto k = convert("3 min", "s");
    assert(k == 180);
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

