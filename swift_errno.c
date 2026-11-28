// libswift_errno.dylib is the split-out home of Darwin.errno's accessors on newer macOS SDKs.
// Binaries built against those SDKs bind the mangled accessor symbols to this library by
// two-level namespace, so the dylib has to provide them itself.
//
// The documented Darwin contract is simple: errno is the int pointed to by __error()
// (see bsd/sys/errno.h of xnu). Implementing the two accessors here instead of
// re-exporting libswiftDarwin keeps this dylib usable in an installation that has no
// Swift toolchain and therefore no source-built Darwin overlay.

extern int *__error(void);

__attribute__((visibility("default")))
int swift_darwin_errno_get(void) __asm__("_$s6Darwin5errnos5Int32Vvg");

__attribute__((visibility("default")))
void swift_darwin_errno_set(int value) __asm__("_$s6Darwin5errnos5Int32Vvs");

int swift_darwin_errno_get(void) {
	return *__error();
}

void swift_darwin_errno_set(int value) {
	*__error() = value;
}
