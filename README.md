# Darling Swift

Attention: This repository uses Git LFS!

Files found here come from official Swift releases from Swift.org. They are downloaded and extracted using the `build.sh` script before committing.

The runtime libraries (`libswiftCore`, `libswift_Concurrency`, `libswift_StringProcessing`, `libswiftObservation`, ...) come from the release in `version.txt` and are universal (arm64 and x86_64) binaries.

Swift.org toolchains no longer include the Darwin SDK overlays (`libswiftAppKit`, `libswiftFoundation`, `libswiftObjectiveC`, `libswiftDispatch`, ...). The copies of those still in this repository come from Swift 5.2.2 and are x86_64-only.
