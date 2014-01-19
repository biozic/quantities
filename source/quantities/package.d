// Written in the D programming language
/++
The purpose of this small D package is to perform automatic compile-time or
runtime dimensional checking when dealing with quantities and units.

In order to remain simple, there is no actual distinction between units and
quantities, so there are no distinct quantity and unit types. All operations
are actually done on quantities. For example, `meter` is both the unit _meter_
and the quantity _1 m_. New quantities can be derived from other ones using
operators or dedicated functions.

Quantities can be parsed from strings at runtime and compile-time (with
limitations).

The main SI units and prefixes are predefined. Units with other dimensions can
be defined by the user.

Requires: DMD 2.065+
Copyright: Copyright 2013, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities;

public import quantities.base;
public import quantities.si;
public import quantities.parsing;
