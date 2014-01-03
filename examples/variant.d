import std.stdio, std.variant;
import quantities;

alias Mass = Store!kilogram;
alias Length = Store!meter;
alias Time = Store!second;

alias VarQ = Algebraic!(Mass, Length, Time); 

void main()
{
    VarQ q;
    
    // Testing...
    q = 1 * meter;
    q = 60 * gram;
    static assert(!__traits(compiles, (q = 42 * volt)));
    
    // Pluviometry
    q = 3.8 * liter / (0.25 * square!meter);
    writefln("Height: %s mm", q.get!Length.value!(milli!meter));
    
    // Marathon
    q = 42 * kilo!meter / (12 * kilo!meter/hour);
    writefln("Time: %s", toDuration(q.get!Time));
}