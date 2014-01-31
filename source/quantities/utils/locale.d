module quantities.utils.locale;

import std.string, std.conv;
import core.stdc.locale;

struct ScopedLocale
{
    private string old;

    this(string locale)
    {
        old = setlocale(LC_ALL, null).to!string;
        setlocale(LC_ALL, toStringz(locale));
    }

    @disable this();
    @disable this(this);

    ~this()
    {
        setlocale(LC_ALL, toStringz(old));
    }
}
