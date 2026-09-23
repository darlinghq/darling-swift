// Darling's libicucore (Apple ICU 66.1) as `_FoundationICU`, the module swift-foundation imports.
// Admit a header only when an overlay source calls into it.
#include <unicode/utypes.h>
#include <unicode/uameasureformat.h>
#include <unicode/uatimeunitformat.h>
#include <unicode/ucal.h>
#include <unicode/udat.h>
#include <unicode/udatpg.h>
#include <unicode/udisplaycontext.h>
#include <unicode/ufieldpositer.h>
#include <unicode/ulistformatter.h>
#include <unicode/uloc.h>
#include <unicode/ulocdata.h>
#include <unicode/unum.h>
#include <unicode/unumsys.h>
#include <unicode/ureldatefmt.h>
#include <unicode/uscript.h>
