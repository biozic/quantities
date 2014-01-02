import quantities;
import std.stdio;

void main()
{
    import std.algorithm, std.array, std.range;

    auto lengths = (90 * kilo!meter).repeat(100000).array;
    auto times = (1 * hour).repeat(100000).array;
    auto speeds = zip(lengths, times).map!(a => a[0] / a[1]).array;
    
    auto mean = speeds.reduce!"a + b" / speeds.length;
    
    writeln(mean.value!(meter/second));
}
