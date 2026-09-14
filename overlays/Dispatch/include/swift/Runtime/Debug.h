// Minimal stand-in for swift/Runtime/Debug.h (not shipped in the swift.org toolchain pkg).
// The overlay sources only need swift_reportError, which libswiftCore exports with C linkage.
#ifndef SWIFT_DARLING_RUNTIME_DEBUG_H
#define SWIFT_DARLING_RUNTIME_DEBUG_H

#include <stdint.h>

namespace swift {
extern "C" void swift_reportError(uint32_t flags, const char *message);
}

#endif
