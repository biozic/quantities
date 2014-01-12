import std.algorithm;
import std.datetime;
import std.file;
import std.random;
import std.stdio;
import std.string;
import quantities;

void generate()
{
    string[] units = ["mol/L", "mol.L⁻¹", "(L mol⁻¹)⁻¹", "mmol/m³", "mmol/L", "µmol/cl"];
    auto file = File("generated_values.txt", "w");
    foreach (i; 0 .. 10_000)
        file.writefln("%.2f %s", uniform(-10.0, 10.0), randomSample(units, 1).front);
}

void parseValues()
{
    auto input = readText("generated_values.txt").splitter("\n");
    Concentration!double c = 0 * mole/liter;
    size_t n = 1;
    StopWatch sw;
    sw.start();
    foreach (line; input)
    {
        try
        {
            if (line.length)
                c += parseQuantity(line);
            n++;
        }
        catch (Exception e)
        {
            writefln("Error line %s (%s): %s", n, line, e.msg);
        }
    }
    sw.stop();
    writefln("Mean: %.2f mol/L (done in %s ms)", c.value(mole/liter), sw.peek.msecs());
}

void main(string[] args)
{
    if (args.length > 1 && args[1] == "generate")
        generate();    
    else foreach (_; 0..10)
        parseValues();
}