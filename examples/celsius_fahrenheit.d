import std.stdio;
import quantities;

enum celsius = unit!("°C");
enum fahrenheit = unit!("°F");

auto toSI(T)(T degC)
    if (T.dimensions == celsius.dimensions)
{
    return kelvin * (degC.value(celsius) + 273.15);
}

auto toSI(T)(T degF)
    if (T.dimensions == fahrenheit.dimensions)
{
    return kelvin * ((degF.value(fahrenheit) - 32) / 1.8 + 273.15);
}

auto toCelsius(T)(T kelv)
{
    return celsius * (kelv.value(kelvin) - 273.15);
}

auto toFahrenheit(T)(T kelv)
{
    return fahrenheit * ((kelv.value(kelvin) - 273.15) * 1.8 + 32);
}

unittest
{
    auto boiling = 100 * celsius;
    writefln("Water boils at %s K", boiling.toSI.value(kelvin));
    writefln("Water boils at %s °F", boiling.toSI.toFahrenheit.value(fahrenheit));

    auto sun = 5750 * kelvin;
    writefln("Sun's surface temperature is %s °C", sun.toCelsius.value(celsius));
    writefln("Sun's surface temperature is %s °F", sun.toFahrenheit.value(fahrenheit));
}