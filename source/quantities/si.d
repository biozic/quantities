/++
Importing `quantities.si` instantiate all the definitions of the SI units,
prefixes, parsing functions and formatting functions, both at run-time and
compile-time, storint their values as a `double`.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.si;

import quantities.internal.si;

mixin SIDefinitions!double;
