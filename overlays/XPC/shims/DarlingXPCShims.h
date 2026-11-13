// Private C declarations for Darling's XPC Swift overlay: functions libxpc exports that
// Darling's public headers don't declare.
#ifndef DARLING_XPC_SHIMS_H
#define DARLING_XPC_SHIMS_H

#include <xpc/xpc.h>

extern xpc_object_t _Nullable xpc_copy(xpc_object_t _Nonnull object);

#endif
