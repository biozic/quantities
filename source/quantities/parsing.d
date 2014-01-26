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
    import std.math : approxEqual;

    QuantityParser defaultParser()
    {
        return QuantityParser(defaultSymbolList);
    }
}

//debug import std.stdio;

/++
Parses a string for a quantity/unit at compile time.

Currently, only official SI units and prefixes can be parsed. These
are the units and prefixes available from $(D_PSYMBOL defaultSymbolList).
+/
template qty(string str, N = real)
{
    enum msg = () { return collectExceptionMsg(parseQuantity(str)); } ();
    static if (msg)
    {
        static assert(false, msg);
        enum qty = one;
    }
    else
    {
        enum q = parseQuantity(str);
        enum dimStr = dimTup(q.dimensions);
        mixin("alias dims = TypeTuple!(%s);".format(dimStr));
        enum qty = Quantity!(N, Sort!dims)(q.value);
    }
}
///
unittest
{
    enum min = qty!"min";
    enum inch = qty!"2.54 cm";

    Concentration c = qty!"1 µmol/L";
    Speed s = qty!"m s^-1";
    Dimensionless val = qty!"0.5";
}

private string dimTup(int[string] dims)
{
    return dims.keys
        .map!(x => `"%s", %s`.format(x, dims[x]))
        .join(", ");
}


/// Parses text for a unit or a quantity at runtime.
RTQuantity parseQuantity(S)(S text, SymbolList symbolList = defaultSymbolList())
{
    static assert(isForwardRange!S && isSomeChar!(ElementType!S),
                  "text must be a forward range of a character type");

    real value; // nan
    try
    {
        // This throws if there is no value ("no digits seen")
        value = std.conv.parse!real(text);
    }
    catch
    {
        value = 1;
    }
 
    if (text.empty)
        return RTQuantity(value, null);

    auto input = text.to!string;
    auto tokens = lex(input);
    auto parser = QuantityParser(symbolList);

    RTQuantity result = parser.parseCompoundUnit(tokens);
    result.value *= value;
    return result;
}
///
unittest
{
    alias Concentration = QuantityType!(mole/cubic(meter));
    alias Length = QuantityType!meter;
    
    // Parse a concentration value
    Concentration c = parseQuantity("11.2 µmol/L");
    assert(c.value(nano(mole)/liter).approxEqual(11200));
    
    // Below, 'second' is only a hint for dimensional analysis
    QuantityType!second t = parseQuantity("90 min");
    assert(t == 90 * minute);
    t = parseQuantity("h");
    assert(t == 1 * hour);

    // User-defined unit
    auto symbols = defaultSymbolList();
    symbols.unitSymbols["in"] = toRuntime(2.54 * centi(meter));
    Length len = parseQuantity("17 in", symbols);
    assert(len.value(centi(meter)).approxEqual(17 * 2.54));

    // User-defined symbols
    auto byte_ = unit!("B");
    SymbolList binSymbols;
    binSymbols.unitSymbols["B"] = byte_.toRuntime;
    binSymbols.prefixSymbols["Ki"] = 2^^10;
    binSymbols.prefixSymbols["Mi"] = 2^^20;
    // ...
    QuantityType!byte_ fileLength = parseQuantity("1.0 MiB", binSymbols);
    assert(fileLength.value(byte_).approxEqual(1_048_576));
}

unittest // Parsing a range of characters that is not a string
{
    Concentration c = parseQuantity(
        ["11.2", "<- value", "µmol/L", "<-unit"]
        .filter!(x => !x.startsWith("<"))
        .joiner(" ")
    );
    assert(c.value(nano(mole)/liter).approxEqual(11200));
}

unittest // Examples from the header
{
    auto J = toRuntime(joule);
    assert(parseQuantity("1 N m") == J);
    assert(parseQuantity("1 N.m") == J);
    assert(parseQuantity("1 N⋅m") == J);
    assert(parseQuantity("1 N * m") == J);
    assert(parseQuantity("1 N × m") == J);

    auto kat = toRuntime(katal);
    assert(parseQuantity("1 mol s^-1") == kat);
    assert(parseQuantity("1 mol s⁻¹") == kat);
    assert(parseQuantity("1 mol/s") == kat);

    auto Pa = toRuntime(pascal);
    assert(parseQuantity("1 kg m^-1 s^-2") == Pa);
    assert(parseQuantity("1 kg/(m s^2)") == Pa);
}

unittest // Test parsing
{
    import std.math : approxEqual;
    
    assertThrown!ParsingException(parseQuantity("1 µ m"));
    assertThrown!ParsingException(parseQuantity("1 µ"));

    string test = "1    m    ";
    assert(parseQuantity(test) == meter.toRuntime);
    assert(parseQuantity("1 µm").value.approxEqual(micro(meter).rawValue));
    
    assert(parseQuantity("1 m^-1") == toRuntime(1 / meter));
    assert(parseQuantity("1 m²") == square(meter).toRuntime);
    assert(parseQuantity("1 m⁻¹") == toRuntime(1 / meter));
    assert(parseQuantity("1 (m)") == meter.toRuntime);
    assert(parseQuantity("1 (m^-1)") == toRuntime(1 / meter));
    assert(parseQuantity("1 ((m)^-1)^-1") == meter.toRuntime);

    assert(parseQuantity("1 m * m") == square(meter).toRuntime);
    assert(parseQuantity("1 m m") == square(meter).toRuntime);
    assert(parseQuantity("1 m . m") == square(meter).toRuntime);
    assert(parseQuantity("1 m ⋅ m") == square(meter).toRuntime);
    assert(parseQuantity("1 m × m") == square(meter).toRuntime);
    assert(parseQuantity("1 m / m") == toRuntime(meter / meter));
    assert(parseQuantity("1 m ÷ m") == toRuntime(meter / meter));
    
    assert(parseQuantity("1 N.m") == toRuntime(newton * meter));
    assert(parseQuantity("1 N m") == toRuntime(newton * meter));
    
    assert(parseQuantity("6.3 L.mmol^-1.cm^-1").value.approxEqual(630));
    assert(parseQuantity("6.3 L/(mmol*cm)").value.approxEqual(630));
    assert(parseQuantity("6.3 L*(mmol*cm)^-1").value.approxEqual(630));
    assert(parseQuantity("6.3 L/mmol/cm").value.approxEqual(630));
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
        assert(defaultParser.parseCompoundUnit(lex("m * m")) == square(meter).toRuntime);
        assert(defaultParser.parseCompoundUnit(lex("m m")) == square(meter).toRuntime);
        assert(defaultParser.parseCompoundUnit(lex("m * m / m")) == meter.toRuntime);
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

        return RTQuantity(std.math.pow(ret.value, n), ret.dimensions.exp(n));
    }
    unittest
    {
        assert(defaultParser.parseExponentUnit(lex("m²")) == square(meter).toRuntime);
        assert(defaultParser.parseExponentUnit(lex("m^2")) == square(meter).toRuntime);
        assertThrown!ParsingException(defaultParser.parseExponentUnit(lex("m^²")));
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
        assert(defaultParser.parseUnit(lex("(m)")) == meter.toRuntime);
        assertThrown!ParsingException(defaultParser.parseUnit(lex("(m")));
    }
    
    RTQuantity parsePrefixUnit(T)(auto ref T[] tokens)
        if (is(T : Token))
    {
        tokens.check(Tok.symbol);
        auto str = tokens.front.slice;
        if (tokens.length)
            tokens.advance();

        // Try a standalone unit symbol (no prefix)
        auto uptr = str in symbolList.unitSymbols;
        if (uptr)
            return *uptr;

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
                    uptr = unit in symbolList.unitSymbols;
                    if (uptr)
                        return RTQuantity(*factor * uptr.value, uptr.dimensions);
                }
            }
        }

        throw new ParsingException("Unknown unit symbol: '%s'".format(str));
    }
    unittest
    {
        assert(defaultParser.parsePrefixUnit(lex("mm")).value.approxEqual(milli(meter).rawValue));
        assert(defaultParser.parsePrefixUnit(lex("cd")).value.approxEqual(candela.rawValue));
        assertThrown!ParsingException(defaultParser.parsePrefixUnit(lex("Lm")));
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
    if (__ctfe)
        return SymbolList(eSIUnitSymbols, eSIPrefixSymbols);
    return SymbolList(SIUnitSymbols, SIPrefixSymbols);
}


enum eSupintegerMap = [
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

enum eSIUnitSymbols = [
    "m" : meter.toRuntime,
    "kg" : kilogram.toRuntime,
    "s" : second.toRuntime,
    "A" : ampere.toRuntime,
    "K" : kelvin.toRuntime,
    "mol" : mole.toRuntime,
    "cd" : candela.toRuntime,
    "rad" : radian.toRuntime,
    "sr" : steradian.toRuntime,
    "Hz" : hertz.toRuntime,
    "N" : newton.toRuntime,
    "Pa" : pascal.toRuntime,
    "J" : joule.toRuntime,
    "W" : watt.toRuntime,
    "C" : coulomb.toRuntime,
    "V" : volt.toRuntime,
    "F" : farad.toRuntime,
    "Ω" : ohm.toRuntime,
    "S" : siemens.toRuntime,
    "Wb" : weber.toRuntime,
    "T" : tesla.toRuntime,
    "H" : henry.toRuntime,
    "lm" : lumen.toRuntime,
    "lx" : lux.toRuntime,
    "Bq" : becquerel.toRuntime,
    "Gy" : gray.toRuntime,
    "Sv" : sievert.toRuntime,
    "kat" : katal.toRuntime,
    "g" : gram.toRuntime,
    "min" : minute.toRuntime,
    "h" : hour.toRuntime,
    "d" : day.toRuntime,
    "l" : liter.toRuntime,
    "L" : liter.toRuntime,
    "t" : ton.toRuntime,
    "eV" : electronVolt.toRuntime,
    "Da" : dalton.toRuntime,
];

enum eSIPrefixSymbols = [
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

static dchar[dchar] supintegerMap;
static RTQuantity[string] SIUnitSymbols;
static real[string] SIPrefixSymbols;

shared static this()
{   
    supintegerMap = eSupintegerMap;
    SIUnitSymbols = eSIUnitSymbols;
    SIPrefixSymbols = eSIPrefixSymbols;
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
    RTQuantity unit = parseQuantity(target);
    enforceEx!DimensionException(base.dimensions == unit.dimensions,
                                 "Dimension error: %s is not compatible with %s"
                                 .format(dimstr(base.dimensions, true), dimstr(unit.dimensions, true)));
    return base.value / unit.value;
}
///
unittest
{
    auto k = convert("3 min", "s");
    assert(k == 3 * 60);
}

/// Convert a compile-time quantity to its runtime equivalent.
RTQuantity toRuntime(Q)(Q quantity)
    if (isQuantity!Q)
{
    return RTQuantity(quantity.rawValue, toAA!(Q.dimensions));
}
///
unittest
{
    auto distance = toRuntime(42 * kilo(meter));
    assert(distance == parseQuantity("42 km"));
}

/// Holds a value and a dimensions for parsing
struct RTQuantity
{
    // The payload
    real value;
    
    // The dimensions of the quantity
    int[string] dimensions;
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
    int integer = int.max;
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
    
    Token[] tokapp;
    auto original = input;
    size_t i, j;
    State state = State.none;
    
    void pushToken(Tok type)
    {
        tokapp ~= Token(type, original[i .. j]);
        i = j;
        state = State.none;
    }

    void pushInteger(Tok type)
    {
        auto slice = original[i .. j];
        if (type == Tok.supinteger)
        {
            if (__ctfe)
                slice = translate(slice, eSupintegerMap);
            else
                slice = translate(slice, supintegerMap);
        }
        auto n = std.conv.parse!int(slice);
        enforceEx!ParsingException(slice.empty, "Unexpected integer format: " ~ slice);
        tokapp ~= Token(type, original[i .. j], n);
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
