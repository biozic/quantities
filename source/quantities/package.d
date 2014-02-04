// Written in the D programming language
/++
The purpose  of this  package is  to perform  automatic compile-time  or runtime
dimensional checking when dealing with quantities and units.

The  base   functionality  (creating  quantities  and   units,  performing  math
operations on  them) is defined  in the module quantities.base.  General parsing
functions and  templates are defined  in quantities.parsing, so  that quantities
can be parsed  from strings at runtime  and compile-time. The main  SI units and
prefixes are predefined in quantites.si.

Requires: DMD 2.065+
Copyright: Copyright 2013-2014, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities;

public import quantities.base;
public import quantities.si;
public import quantities.parsing;
