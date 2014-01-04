// Written in the D programming language
/++
Enhanded unittests with tested
+/
import quantities.base;
import quantities.si;
import quantities.runtime.base;
import quantities.runtime.si;
import quantities.parsing;
public import tested;
import std.stdio;

shared static this() {
    version (Have_tested) {
        import core.runtime;
        Runtime.moduleUnitTester = () => true;
        assert(runUnitTests!(
            quantities.base,
            quantities.si,
            quantities.runtime.base,
            quantities.runtime.si,
            quantities.parsing
        )(new ConsoleTestResultWriter), "Unit tests failed.");
    }
}