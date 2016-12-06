module quantities.si.float_;

import quantities.base;
import quantities.math;
import quantities.parsing;
import quantities.format;
public import quantities.si.definitions;

import std.array;
import std.conv;
import std.format;
import std.math : PI;
import core.time : Duration, dur;

mixin SI!float;