// Written in the D programming language
/++
Enhanded unittests with tested
+/
import quantities.base;
import quantities.si;
public import tested;
import std.stdio;

shared static this() {
    version (Have_tested) {
        import core.runtime;
        Runtime.moduleUnitTester = () => true;
        assert(runUnitTests!(quantities.base, quantities.si)(new ConsoleTestResultWriter), "Unit tests failed.");
    }
}