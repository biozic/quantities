// Written in the D programming language
/++
The purpose of this small D package is to perform automatic compile-time
dimensional checking when dealing with quantities and units.

In order to remain simple, there is no actual distinction between units and
_quantities, so there are no distinct quantity and unit types. All operations
are actually done on _quantities. For example, `meter` is both the unit _meter_
and the quantity _1 m_. New _quantities can be derived from other ones using
operators or dedicated functions.

By design, a dimensionless quantity must be expressed with a builtin numeric
type, e.g. double. If an operation over _quantities that have dimensions creates
a quantity with no dimensions (e.g. meter / meter), the result is converted to
the corresponding built-in type.

There is also no automatic generation of symbols. Actually, it is not possible
to do it right automatically because the same quantity can be expressed in many
different units with different symbols: how can the compiler choose the most
correct one without a hint. So, it is also not really needed, because if the
compiler must be given a hint to choose the proper unit, it is as simple to
give it the symbol directly.

The main SI units and prefixes are predefined. units with other dimensions can
be defined by the user.

Contains two modules:
<ol>
    <li><a href="/quantities/base.html">quantities.base</a>: general declarations</li>
    <li><a href="/quantities/si.html">quantities.si</a>: SI specific declarations</li>
</ol>

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
