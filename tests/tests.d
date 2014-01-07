// Written in the D programming language
/++
Enhanded unittests with tested
+/
import synopsis;
public import tested;
import std.stdio;

shared static this() {
    version (Have_tested) {
        import core.runtime;
        Runtime.moduleUnitTester = () => true;
        assert(runUnitTests!(synopsis)(
            new ConsoleTestResultWriter), "Unit tests failed."
        );
    }
}