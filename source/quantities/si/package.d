// Written in the D programming language
/++
This packages defines the SI units, prefixes and utility functions.

When importing `quantities.si` or `quantities.si.double_`,
the SI units store their values as a `double`. Use `quantities.si.real_`
or `quantites.si.float_` otherwise. 

Copyright: Copyright 2013-2016, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.si;

public import quantities.si.double_;
