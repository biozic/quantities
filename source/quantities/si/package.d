/++
This packages defines the SI units, prefixes and utility functions.

When importing `quantities.si` the SI units store their values as a `double`.

Copyright: Copyright 2013-2018, Nicolas Sicard
Authors: Nicolas Sicard
License: $(LINK www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Standards: $(LINK http://www.bipm.org/en/si/si_brochure/)
Source: $(LINK https://github.com/biozic/quantities)
+/
module quantities.si;

import quantities.si.definitions : SIDefinitions;
import quantities.compiletime.si.definitions;
import quantities.runtime.si.definitions;

mixin SIDefinitions!double;
mixin CompiletimeSI!double;
mixin RuntimeSI!double;
