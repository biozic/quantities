module quantities.format;

import quantities.base;
import quantities.parsing;

import std.array : appender;
import std.conv;
import std.format;
import std.string;
import std.typetuple;

/++
Helper struct that formats a quantity.
+/
struct FormatWrapper(Q, alias quantityParser)
    if (isQuantity!Q || isQVariant!Q)
{
private:
    string fmt;
    FormatSpec!char spec;
    string head;
    const(char)[] target;
    Q unit;

public:
    /++
    Creates a new formatter from a format string.
    +/
    this(string fmt)
    {
        this.fmt = fmt;
        spec = FormatSpec!char(fmt);
        auto app = appender!string;
        spec.writeUpToNextSpec(app);
        head = app.data;
        target = spec.trailing;
        unit = quantityParser!Q(target);
    }

    /++
    Returns a wrapper struct that defines a `toString` method, so that
    quantity can be formatted by `std.string.format` or `std.format` functions.
    +/
    auto opCall(T)(T quantity) const
    {
        auto instance = this; // So that Wrapper.toString accesses this

        struct Wrapper
        {
            void toString(scope void delegate(const(char)[]) sink) const
            {
                FormatSpec!char spec = instance.spec;
                sink(instance.head);
                sink.formatValue(quantity.value(instance.unit), spec);
                sink(instance.target);
            }
        }

        return Wrapper();
    }
}
///
unittest
{
    import quantities.si;
    import std.string;

    auto sf = FormatWrapper!(Speed, parseSI)("Speed: %.1f km/h");
    auto speed = 343.4 * meter/second;
    assert(format("%s", sf(speed)) == "Speed: 1236.2 km/h");
}

// TODO: scaled formatter
