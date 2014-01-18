import std.algorithm;
import std.datetime;
import std.file;
import std.getopt;
import std.random;
import std.stdio;
import std.string;
import quantities;

enum filename = "generated_values.txt";

alias Concentration = SI.Concentration!double;

void generate(size_t n)
{
    writefln("Generating n value of concentration...");
    string[] units = ["mol/L", "mol.L⁻¹", "(L mol⁻¹)⁻¹", "mmol/m³", "mmol/L", "µmol/cl"];
    auto file = File(filename, "w");
    foreach (i; 0 .. n)
        file.writefln("%.2f %s", uniform(0.0, 10.0), randomSample(units, 1).front);
    writeln("Values generated.");
}

long parseValuesTime()
{
    auto input = readText("generated_values.txt").splitter("\n");
    Concentration sum = 0 * mole/liter;
    size_t n = 1;
    StopWatch sw;
    sw.start();
    foreach (line; input)
    {
        try
        {
            if (line.length)
                sum += Concentration(parseQuantity(line));
            n++;
        }
        catch (Exception e)
        {
            writefln("Error line %s (%s): %s", n, line, e.msg);
        }
    }
    sw.stop();
    auto time = sw.peek.msecs();
    writefln("Mean: %.2f mol/L (done in %s ms)", sum.value(mole/liter) / n, time);
    return time;
}

void main(string[] args)
{
    size_t number = 10_000;
    size_t iterations = 10;

    getopt(args, "number|n", &number, "iterations|i", &iterations);

    generate(number);   

    long time = 0;
    foreach (_; 0..iterations)
        time += parseValuesTime();
    writefln("Iteration mean duration: %s ms", time / cast(double) iterations);

    writeln("Removing generated file...");
    std.file.remove(filename);
    writeln("Done.");
}