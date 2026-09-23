// Darling's libicucore (Apple ICU 66.1) as `_FoundationICU`, the module swift-foundation imports.
// Admit a header only when an overlay source calls into it.
#include <unicode/utypes.h>
#include <unicode/uloc.h>
#include <unicode/unumsys.h>
