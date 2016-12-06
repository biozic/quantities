/++
This module only contains a template mixin used to generate
SI units, prefixes and utility functions.
+/
module quantities.si.definitions;

/// 
mixin template SI(Numeric)
{
    /++
    Predefined SI units.
    +/
    enum meter = unit!(Numeric, "L");
    alias metre = meter; /// ditto
    enum kilogram = unit!(Numeric, "M"); /// ditto
    enum second = unit!(Numeric, "T"); /// ditto
    enum ampere = unit!(Numeric, "I"); /// ditto
    enum kelvin = unit!(Numeric, "Θ"); /// ditto
    enum mole = unit!(Numeric, "N"); /// ditto
    enum candela = unit!(Numeric, "J"); /// ditto

    enum radian = meter / meter; // ditto
    enum steradian = square(meter) / square(meter); /// ditto
    enum hertz = 1 / second; /// ditto
    enum newton = kilogram * meter / square(second); /// ditto
    enum pascal = newton / square(meter); /// ditto
    enum joule = newton * meter; /// ditto
    enum watt = joule / second; /// ditto
    enum coulomb = second * ampere; /// ditto
    enum volt = watt / ampere; /// ditto
    enum farad = coulomb / volt; /// ditto
    enum ohm = volt / ampere; /// ditto
    enum siemens = ampere / volt; /// ditto
    enum weber = volt * second; /// ditto
    enum tesla = weber / square(meter); /// ditto
    enum henry = weber / ampere; /// ditto
    enum celsius = kelvin; /// ditto
    enum lumen = candela / steradian; /// ditto
    enum lux = lumen / square(meter); /// ditto
    enum becquerel = 1 / second; /// ditto
    enum gray = joule / kilogram; /// ditto
    enum sievert = joule / kilogram; /// ditto
    enum katal = mole / second; /// ditto

    enum gram = 1e-3 * kilogram; /// ditto
    enum minute = 60 * second; /// ditto
    enum hour = 60 * minute; /// ditto
    enum day = 24 * hour; /// ditto
    enum degreeOfAngle = PI / 180 * radian; /// ditto
    enum minuteOfAngle = degreeOfAngle / 60; /// ditto
    enum secondOfAngle = minuteOfAngle / 60; /// ditto
    enum hectare = 1e4 * square(meter); /// ditto
    enum liter = 1e-3 * cubic(meter); /// ditto
    alias litre = liter; /// ditto
    enum ton = 1e3 * kilogram; /// ditto
    enum electronVolt = 1.60217653e-19 * joule; /// ditto
    enum dalton = 1.66053886e-27 * kilogram; /// ditto

    enum one = Quantity!(Numeric, Dimensions.init)(1); /// The dimensionless unit 'one'

    alias Length = typeof(meter); /// Predefined quantity type templates for SI quantities
    alias Mass = typeof(kilogram); /// ditto
    alias Time = typeof(second); /// ditto
    alias ElectricCurrent = typeof(ampere); /// ditto
    alias Temperature = typeof(kelvin); /// ditto
    alias AmountOfSubstance = typeof(mole); /// ditto
    alias LuminousIntensity = typeof(candela); /// ditto

    alias Area = typeof(square(meter)); /// ditto
    alias Surface = Area;
    alias Volume = typeof(cubic(meter)); /// ditto
    alias Speed = typeof(meter/second); /// ditto
    alias Acceleration = typeof(meter/square(second)); /// ditto
    alias MassDensity = typeof(kilogram/cubic(meter)); /// ditto
    alias CurrentDensity = typeof(ampere/square(meter)); /// ditto
    alias MagneticFieldStrength = typeof(ampere/meter); /// ditto
    alias Concentration = typeof(mole/cubic(meter)); /// ditto
    alias MolarConcentration = Concentration; /// ditto
    alias MassicConcentration = typeof(kilogram/cubic(meter)); /// ditto
    alias Luminance = typeof(candela/square(meter)); /// ditto
    alias RefractiveIndex = typeof(kilogram); /// ditto

    alias Angle = typeof(radian); /// ditto
    alias SolidAngle = typeof(steradian); /// ditto
    alias Frequency = typeof(hertz); /// ditto
    alias Force = typeof(newton); /// ditto
    alias Pressure = typeof(pascal); /// ditto
    alias Energy = typeof(joule); /// ditto
    alias Work = Energy; /// ditto
    alias Heat = Energy; /// ditto
    alias Power = typeof(watt); /// ditto
    alias ElectricCharge = typeof(coulomb); /// ditto
    alias ElectricPotential = typeof(volt); /// ditto
    alias Capacitance = typeof(farad); /// ditto
    alias ElectricResistance = typeof(ohm); /// ditto
    alias ElectricConductance = typeof(siemens); /// ditto
    alias MagneticFlux = typeof(weber); /// ditto
    alias MagneticFluxDensity = typeof(tesla); /// ditto
    alias Inductance = typeof(henry); /// ditto
    alias LuminousFlux = typeof(lumen); /// ditto
    alias Illuminance = typeof(lux); /// ditto
    alias CelsiusTemperature = typeof(celsius); /// ditto
    alias Radioactivity = typeof(becquerel); /// ditto
    alias AbsorbedDose = typeof(gray); /// ditto
    alias DoseEquivalent = typeof(sievert); /// ditto
    alias CatalyticActivity = typeof(katal); /// ditto

    alias Dimensionless = typeof(meter/meter); /// The type of dimensionless quantities

    /// SI prefixes.
    alias yotta = prefix!1e24;
    alias zetta = prefix!1e21; /// ditto
    alias exa = prefix!1e18; /// ditto
    alias peta = prefix!1e15; /// ditto
    alias tera = prefix!1e12; /// ditto
    alias giga = prefix!1e9; /// ditto
    alias mega = prefix!1e6; /// ditto
    alias kilo = prefix!1e3; /// ditto
    alias hecto = prefix!1e2; /// ditto
    alias deca = prefix!1e1; /// ditto
    alias deci = prefix!1e-1; /// ditto
    alias centi = prefix!1e-2; /// ditto
    alias milli = prefix!1e-3; /// ditto
    alias micro = prefix!1e-6; /// ditto
    alias nano = prefix!1e-9; /// ditto
    alias pico = prefix!1e-12; /// ditto
    alias femto = prefix!1e-15; /// ditto
    alias atto = prefix!1e-18; /// ditto
    alias zepto = prefix!1e-21; /// ditto
    alias yocto = prefix!1e-24; /// ditto

    /// A list of common SI symbols and prefixes
    enum siSymbols = SymbolList!Numeric()
        .addUnit("m", meter)
        .addUnit("kg", kilogram)
        .addUnit("s", second)
        .addUnit("A", ampere)
        .addUnit("K", kelvin)
        .addUnit("mol", mole)
        .addUnit("cd", candela)
        .addUnit("rad", radian)
        .addUnit("sr", steradian)
        .addUnit("Hz", hertz)
        .addUnit("N", newton)
        .addUnit("Pa", pascal)
        .addUnit("J", joule)
        .addUnit("W", watt)
        .addUnit("C", coulomb)
        .addUnit("V", volt)
        .addUnit("F", farad)
        .addUnit("Ω", ohm)
        .addUnit("S", siemens)
        .addUnit("Wb", weber)
        .addUnit("T", tesla)
        .addUnit("H", henry)
        .addUnit("lm", lumen)
        .addUnit("lx", lux)
        .addUnit("Bq", becquerel)
        .addUnit("Gy", gray)
        .addUnit("Sv", sievert)
        .addUnit("kat", katal)
        .addUnit("g", gram)
        .addUnit("min", minute)
        .addUnit("h", hour)
        .addUnit("d", day)
        .addUnit("l", liter)
        .addUnit("L", liter)
        .addUnit("t", ton)
        .addUnit("eV", electronVolt)
        .addUnit("Da", dalton)
        .addPrefix("Y", 1e24)
        .addPrefix("Z", 1e21)
        .addPrefix("E", 1e18)
        .addPrefix("P", 1e15)
        .addPrefix("T", 1e12)
        .addPrefix("G", 1e9)
        .addPrefix("M", 1e6)
        .addPrefix("k", 1e3)
        .addPrefix("h", 1e2)
        .addPrefix("da", 1e1)
        .addPrefix("d", 1e-1)
        .addPrefix("c", 1e-2)
        .addPrefix("m", 1e-3)
        .addPrefix("µ", 1e-6)
        .addPrefix("n", 1e-9)
        .addPrefix("p", 1e-12)
        .addPrefix("f", 1e-15)
        .addPrefix("a", 1e-18)
        .addPrefix("z", 1e-21)
        .addPrefix("y", 1e-24)
        .addPrefix("Yi", 1024.0^^8)
        .addPrefix("Zi", 1024.0^^7)
        .addPrefix("Ei", 1024.0^^6)
        .addPrefix("Pi", 1024.0^^5)
        .addPrefix("Ti", 1024.0^^4)
        .addPrefix("Gi", 1024.0^^3)
        .addPrefix("Mi", 1024.0^^2)
        .addPrefix("Ki", 1024.0);

    private static SymbolList!Numeric _siSymbols;
    private static Parser!Numeric _siParser;
    static this()
    {
        _siSymbols = siSymbols;
        _siParser = Parser!Numeric(_siSymbols, &std.conv.parse!(Numeric, const(char)[]));
    } 

    /// Parses a string for a quantity of type Q at runtime
    Q parseSI(Q)(const(char)[] str)
        if (isQuantity!Q)
    {
        return _siParser.parse!Q(str);
    }
    ///
    unittest
    {
        auto t = parseSI!Time("90 min");
        assert(t == 90 * minute);
        t = parseSI!Time("h");
        assert(t == 1 * hour);

        auto v = parseSI!Dimensionless("2");
        assert(v == (2 * meter) / meter);
    }

    /// A compile-time parser with automatic type deduction for SI quantities.
    alias si = compileTimeParser!(Numeric, siSymbols, std.conv.parse!(Numeric, const(char)[]));
    ///
    unittest
    {
        enum min = si!"min";
        enum inch = si!"2.54 cm";
        auto conc = si!"1 µmol/L";
        auto speed = si!"m s^-1";
        auto value = si!"0.5";
        
        static assert(is(typeof(inch) == Length));
        static assert(is(typeof(conc) == Concentration));
        static assert(is(typeof(speed) == Speed));
        static assert(is(typeof(value) == Dimensionless));
    }
}