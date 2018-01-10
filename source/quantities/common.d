module quantities.common;

import quantities.runtime : isQVariantOrQuantity, unit;

/++
Creates a new prefix function that multiplies a QVariant by a factor.
+/
template prefix(alias fact)
{
    import std.traits : isNumeric;

    alias N = typeof(fact);
    static assert(isNumeric!N, "Incompatible type: " ~ N.stringof);

    /// The prefix factor
    enum factor = fact;

    /// The prefix function
    auto prefix(Q)(auto ref const Q base)
            if (isQVariantOrQuantity!Q)
    {
        return base * fact;
    }
}
///
@safe pure unittest
{
    auto meter = unit!double("L");
    alias milli = prefix!1e-3;
    assert(milli(meter) == 1e-3 * meter);
}
