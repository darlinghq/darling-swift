// Private C helpers for Darling's os Swift overlay.
#ifndef DARLING_OS_SHIMS_H
#define DARLING_OS_SHIMS_H

#include <os/log.h>
#include <os/signpost.h>
#include <stdint.h>

// The os module's API notes hide _os_log_impl from Swift; call it through a C wrapper.
static inline void _darling_os_log_impl(void *dso, os_log_t log, os_log_type_t type, const char *format,
		uint8_t *buffer, uint32_t size) {
	_os_log_impl(dso, log, type, format, buffer, size);
}

static inline os_log_t _Nonnull _darling_os_log_default(void) {
	return OS_LOG_DEFAULT;
}

extern struct os_log_s _os_log_disabled;
static inline os_log_t _Nonnull _darling_os_log_disabled(void) {
	return OS_OBJECT_GLOBAL_OBJECT(os_log_t, _os_log_disabled);
}

#endif
