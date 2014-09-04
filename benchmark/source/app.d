import std.algorithm;
import std.datetime;
import std.file;
import std.getopt;
import std.random;
import std.stdio;
import std.string;
import quantities;

enum filename = "generated_values.txt";

void generate(size_t n)
{
    writefln("Generating n value of concentration...");
    string[] units = [
        "mol/L",
        "mol.L⁻¹",
        "(L mol⁻¹)⁻¹",
        "mmol/m³",
        "µmol/cl",
        "mol³/mol/mol*L⁻³*L*L*Hz/Hz*Pa/Pa*m/m*cd/cd",
        "(L mol⁻¹)⁻¹ * (L mol⁻¹)⁻¹ / (L mol⁻¹)⁻¹"
    ];
    auto file = File(filename, "w");
    foreach (i; 0 .. n)
        file.writefln("%.2f %s", uniform(0.0, 10.0), randomSample(units, 1).front);
    writeln("Values generated.");
}

void parseValues(string[] lines)
{
    auto sum = si!"0 mol/L";
    size_t n = 1;
    foreach (line; lines)
    {
        try
        {
            if (line.length)
                sum += parseSI!Concentration(line);
            n++;
        }
        catch (Exception e)
        {
            writefln("Error line %s (%s): %s", n, line, e.msg);
        }
    }
    writefln("Mean: %.3f mol/L", (sum / n).value(si!"mol/L"));
}

void main(string[] args)
{
    uint number = 10_000;
    uint iterations = 10;

    getopt(args, "number|n", &number, "iterations|i", &iterations);

    generate(number);
    auto input = readText(filename).splitLines;

    auto time = benchmark!({ parseValues(input); })(iterations);
    writefln("Iteration mean duration: %s ms", time[0].msecs / cast(real) iterations);

    writeln("Removing generated file...");
    std.file.remove(filename);
    writeln("Done.");
}
