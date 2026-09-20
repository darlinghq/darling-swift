// macOS split the Darwin overlay's `errno` accessors out of libswiftDarwin into
// libswift_errno.dylib (both report version 377.120.8). Apps link it non-weakly and
// bind the accessors to it by library ordinal, so the file has to exist for dyld to
// get past their load commands.
//
// The accessors are already in libswiftDarwin.dylib, so re-exporting it is the whole
// implementation; there is nothing to define here.
