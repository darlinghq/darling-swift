# Copyright (C) 2026 Lubos Dolezel
#
# The files of apple/swift-crypto (tag 5.1.2, commit 3280a5f72874d2f73bf25551bbb64f524c76d834) that
# CryptoKit.framework compiles, relative to the Sources directory of the checkout (SWIFT_CRYPTO_SOURCE_DIR,
# see cryptokit.cmake). Generated from the checkout, not edited by hand. To regenerate it after a bump, list in
# the new checkout:
#
#   Crypto and CryptoBoringWrapper: every .swift file of the directory
#   CCryptoBoringSSL: every .cc file; the Apple assembly (*-apple.S) guarded for x86_64 or arm64; the files of
#       third_party/fiat/asm
#   CXKCP and CXKCPShims: every .c file
#
# minus the files named below, then compare the result with the lists in Package.swift and in the CMakeLists.txt
# of each target directory (CMakeLists.txt of CCryptoBoringSSL for its Darwin x86_64 and arm64 assembly). Those
# lists have these files that this one leaves out:
#
#   Crypto/CryptoError_boring.swift          the CryptoError and CryptoASN1Error typealiases are not CryptoKit API
#   Crypto/Util/BoringSSL/_CryptoModuleAnchor.swift
#                                            a symbol for the Apple build of swift-crypto, where its Crypto module
#                                            is empty
#   crypto/bio/connect.cc, socket.cc, socket_helper.cc
#                                            excluded by Package.swift (the networking BIOs are not used)
#   crypto/hrss/asm/poly_rq_mul.S            guarded for Linux
#
# Files for other platforms and for the 32-bit slices are not listed.

# Sources/Crypto: the CryptoKit module (96 files)
set(SWIFT_CRYPTO_SWIFT_FILES
	"AEADs/AES/GCM/AES-GCM.swift"
	"AEADs/AES/GCM/BoringSSL/AES-GCM_boring.swift"
	"AEADs/ChachaPoly/BoringSSL/ChaChaPoly_boring.swift"
	"AEADs/ChachaPoly/ChaChaPoly.swift"
	"AEADs/Cipher.swift"
	"AEADs/Nonces.swift"
	"ASN1/ASN1.swift"
	"ASN1/Basic ASN1 Types/ASN1Any.swift"
	"ASN1/Basic ASN1 Types/ASN1BitString.swift"
	"ASN1/Basic ASN1 Types/ASN1Boolean.swift"
	"ASN1/Basic ASN1 Types/ASN1Identifier.swift"
	"ASN1/Basic ASN1 Types/ASN1Integer.swift"
	"ASN1/Basic ASN1 Types/ASN1Null.swift"
	"ASN1/Basic ASN1 Types/ASN1OctetString.swift"
	"ASN1/Basic ASN1 Types/ASN1Strings.swift"
	"ASN1/Basic ASN1 Types/ArraySliceBigint.swift"
	"ASN1/Basic ASN1 Types/GeneralizedTime.swift"
	"ASN1/Basic ASN1 Types/ObjectIdentifier.swift"
	"ASN1/ECDSASignature.swift"
	"ASN1/PEMDocument.swift"
	"ASN1/PKCS8PrivateKey.swift"
	"ASN1/SEC1PrivateKey.swift"
	"ASN1/SubjectPublicKeyInfo.swift"
	"CryptoKitErrors.swift"
	"Digests/BoringSSL/Digest_boring.swift"
	"Digests/Digest.swift"
	"Digests/Digests.swift"
	"Digests/HashFunctions.swift"
	"Digests/HashFunctions_SHA2.swift"
	"Digests/HashFunctions_SHA3.swift"
	"Digests/XKCP/Digest_xkcp.swift"
	"HPKE/Ciphersuite/HPKE-AEAD.swift"
	"HPKE/Ciphersuite/HPKE-Ciphersuite.swift"
	"HPKE/Ciphersuite/HPKE-KDF.swift"
	"HPKE/Ciphersuite/HPKE-KexKeyDerivation.swift"
	"HPKE/Ciphersuite/HPKE-LabeledExtract.swift"
	"HPKE/Ciphersuite/HPKE-Utils.swift"
	"HPKE/Ciphersuite/KEM/Conformances/DHKEM.swift"
	"HPKE/Ciphersuite/KEM/Conformances/HPKE-KEM-Curve25519.swift"
	"HPKE/Ciphersuite/KEM/Conformances/HPKE-NIST-EC-KEMs.swift"
	"HPKE/Ciphersuite/KEM/HPKE-KEM.swift"
	"HPKE/HPKE-Errors.swift"
	"HPKE/HPKE.swift"
	"HPKE/Key Schedule/HPKE-Context.swift"
	"HPKE/Key Schedule/HPKE-KeySchedule.swift"
	"HPKE/Modes/HPKE-Modes.swift"
	"Insecure/Insecure.swift"
	"Insecure/Insecure_HashFunctions.swift"
	"KEM/BoringSSL/MLKEM_boring.swift"
	"KEM/BoringSSL/MLKEM_wrapper.swift"
	"KEM/BoringSSL/XWing_boring.swift"
	"KEM/KEM-Errors.swift"
	"KEM/KEM.swift"
	"KEM/MLKEM.swift"
	"KEM/XWing.swift"
	"Key Agreement/BoringSSL/ECDH_boring.swift"
	"Key Agreement/DH.swift"
	"Key Agreement/ECDH.swift"
	"Key Derivation/ANSIx963.swift"
	"Key Derivation/HKDF.swift"
	"Key Wrapping/AESWrap.swift"
	"Key Wrapping/BoringSSL/AESWrap_boring.swift"
	"Keys/EC/BoringSSL/Ed25519_boring.swift"
	"Keys/EC/BoringSSL/NISTCurvesKeys_boring.swift"
	"Keys/EC/BoringSSL/X25519Keys_boring.swift"
	"Keys/EC/Curve25519.swift"
	"Keys/EC/Ed25519Keys.swift"
	"Keys/EC/NISTCurvesKeys.swift"
	"Keys/EC/X25519Keys.swift"
	"Keys/Symmetric/SymmetricKeys.swift"
	"Message Authentication Codes/HMAC/HMAC.swift"
	"Message Authentication Codes/MACFunctions.swift"
	"Message Authentication Codes/MessageAuthenticationCode.swift"
	"PRF/AES.swift"
	"Signatures/BoringSSL/ECDSASignature_boring.swift"
	"Signatures/BoringSSL/ECDSA_boring.swift"
	"Signatures/BoringSSL/EdDSA_boring.swift"
	"Signatures/BoringSSL/MLDSA_boring.swift"
	"Signatures/BoringSSL/MLDSA_wrapper.swift"
	"Signatures/ECDSA.swift"
	"Signatures/Ed25519.swift"
	"Signatures/MLDSA.swift"
	"Signatures/Signature.swift"
	"Util/ArraySpanHelpers.swift"
	"Util/Backports.swift"
	"Util/BoringSSL/CryptoKitErrors_boring.swift"
	"Util/BoringSSL/InlineArray+withBytes_boring.swift"
	"Util/BoringSSL/Optional+withUnsafeBytes_boring.swift"
	"Util/BoringSSL/RNG_boring.swift"
	"Util/BoringSSL/SafeCompare_boring.swift"
	"Util/BoringSSL/Zeroization_boring.swift"
	"Util/Data+ArraySpan.swift"
	"Util/PrettyBytes.swift"
	"Util/SafeCompare.swift"
	"Util/SecureBytes.swift"
	"Util/Zeroization.swift"
)

# Sources/CryptoBoringWrapper: compiled as the object module CryptoBoringWrapper (8 files)
set(SWIFT_CRYPTO_WRAPPER_FILES
	"AEAD/BoringSSLAEAD.swift"
	"CryptoKitErrors_boring.swift"
	"EC/EllipticCurve.swift"
	"EC/EllipticCurvePoint.swift"
	"Util/ArbitraryPrecisionInteger.swift"
	"Util/Data+Span.swift"
	"Util/FiniteFieldArithmeticContext.swift"
	"Util/RandomBytes.swift"
)

# Sources/CXKCP: Keccak for SHA-3 (CC0-1.0)
set(SWIFT_CRYPTO_XKCP_FILES
	"FIPS202-opt64/KeccakHash.c"
	"FIPS202-opt64/KeccakP-1600-opt64.c"
	"FIPS202-opt64/KeccakSponge.c"
	"FIPS202-opt64/SimpleFIPS202.c"
)

# Sources/CXKCPShims
set(SWIFT_CRYPTO_XKCP_SHIMS_FILES
	"shims.c"
)

# Sources/CCryptoBoringSSL: assembly that applies to the x86_64 slice and gives an empty object on arm64
set(SWIFT_CRYPTO_BORINGSSL_ASM_COMMON_FILES
	"third_party/fiat/asm/fiat_curve25519_adx_mul.S"
	"third_party/fiat/asm/fiat_curve25519_adx_square.S"
	"third_party/fiat/asm/fiat_p256_adx_mul.S"
	"third_party/fiat/asm/fiat_p256_adx_sqr.S"
)

# Sources/CCryptoBoringSSL: Mach-O x86_64 assembly generated from BoringSSL's perlasm
set(SWIFT_CRYPTO_BORINGSSL_ASM_X86_64_FILES
	"gen/bcm/aes-gcm-avx2-x86_64-apple.S"
	"gen/bcm/aes-gcm-avx512-x86_64-apple.S"
	"gen/bcm/aesni-gcm-x86_64-apple.S"
	"gen/bcm/aesni-x86_64-apple.S"
	"gen/bcm/ghash-ssse3-x86_64-apple.S"
	"gen/bcm/ghash-x86_64-apple.S"
	"gen/bcm/p256-x86_64-asm-apple.S"
	"gen/bcm/p256_beeu-x86_64-asm-apple.S"
	"gen/bcm/rdrand-x86_64-apple.S"
	"gen/bcm/rsaz-avx2-apple.S"
	"gen/bcm/sha1-x86_64-apple.S"
	"gen/bcm/sha256-x86_64-apple.S"
	"gen/bcm/sha512-x86_64-apple.S"
	"gen/bcm/vpaes-x86_64-apple.S"
	"gen/bcm/x86_64-mont-apple.S"
	"gen/bcm/x86_64-mont5-apple.S"
	"gen/crypto/aes128gcmsiv-x86_64-apple.S"
	"gen/crypto/chacha-x86_64-apple.S"
	"gen/crypto/chacha20_poly1305_x86_64-apple.S"
	"gen/crypto/md5-x86_64-apple.S"
)

# Sources/CCryptoBoringSSL: Mach-O arm64 assembly generated from BoringSSL's perlasm
set(SWIFT_CRYPTO_BORINGSSL_ASM_ARM64_FILES
	"gen/bcm/aesv8-armv8-apple.S"
	"gen/bcm/aesv8-gcm-armv8-apple.S"
	"gen/bcm/armv8-mont-apple.S"
	"gen/bcm/bn-armv8-apple.S"
	"gen/bcm/ghash-neon-armv8-apple.S"
	"gen/bcm/ghashv8-armv8-apple.S"
	"gen/bcm/p256-armv8-asm-apple.S"
	"gen/bcm/p256_beeu-armv8-asm-apple.S"
	"gen/bcm/sha1-armv8-apple.S"
	"gen/bcm/sha256-armv8-apple.S"
	"gen/bcm/sha512-armv8-apple.S"
	"gen/bcm/vpaes-armv8-apple.S"
	"gen/crypto/chacha-armv8-apple.S"
	"gen/crypto/chacha20_poly1305_armv8-apple.S"
)
