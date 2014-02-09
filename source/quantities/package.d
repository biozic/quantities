// Written in the D programming language
/++
The purpose  of this  package is  to perform  automatic compile-time or runtime
dimensional checking when dealing with quantities and units.

Requires: DMD 2.065+
Copyright: Copyright 2013-2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities;

public import quantities.base;
public import quantities.math;
public import quantities.si;
public import quantities.parsing;
