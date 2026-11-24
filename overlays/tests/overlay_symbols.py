#!/usr/bin/env python3
# Copyright (C) 2026 Lubos Dolezel
#
# Licensed under the MIT license, the same as the rest of this project.
#
# Checks that every undefined symbol of the Swift SDK overlays (usr/lib/swift/libswift*.dylib and the Combine, GroupActivities and
# CryptoKit frameworks) is exported by the library its two-level namespace ordinal names (directly or through the
# libraries that one re-exports). A symbol that is not makes dyld abort at load time with "Symbol not found".
#
#   overlay_symbols.py [ROOT]     ROOT is the installed tree (default /usr/local/libexec/darling); needs llvm-nm and
#                                 llvm-objdump. Exit status 1 when a symbol is unresolved.
import glob, os, re, subprocess, sys

root = sys.argv[1] if len(sys.argv) > 1 else "/usr/local/libexec/darling"
arch = os.environ.get("ARCH", "x86_64")

def run(*args):
    return subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True).stdout

def host_path(install_name):
    if install_name.startswith("@"):
        return None
    p = root + install_name
    return p if os.path.exists(p) else None

_exports, _deps = {}, {}

def deps(path):
    """(install name, is re-export) of the libraries a dylib loads."""
    if path in _deps:
        return _deps[path]
    out, cur = [], None
    for line in run("llvm-objdump", "--macho", "--arch=" + arch, "-p", path).splitlines():
        line = line.strip()
        m = re.match(r"cmd (LC_\w+)", line)
        if m:
            cur = m.group(1)
        m = re.match(r"name (\S+)", line)
        if m and cur in ("LC_LOAD_DYLIB", "LC_LOAD_WEAK_DYLIB", "LC_REEXPORT_DYLIB", "LC_LOAD_UPWARD_DYLIB"):
            out.append((m.group(1), cur == "LC_REEXPORT_DYLIB"))
            cur = None
    _deps[path] = out
    return out

def exports(path):
    if path not in _exports:
        syms = set()
        for line in run("llvm-nm", "-m", "--arch=" + arch, path).splitlines():
            m = re.match(r"\s*(?:[0-9a-f]+ \(\S+\)|\(indirect\)) (?:weak )?(?:private )?external (\S+)", line)
            if m:
                syms.add(m.group(1))
        _exports[path] = syms
    return _exports[path]

def provides(path, symbol, seen=None):
    seen = seen or set()
    if path in seen:
        return False
    seen.add(path)
    if symbol in exports(path):
        return True
    for name, reexport in deps(path):
        if reexport:
            sub = host_path(name)
            if sub and provides(sub, symbol, seen):
                return True
    return False

targets = sorted(glob.glob(root + "/usr/lib/swift/libswift*.dylib") +
                 glob.glob(root + "/System/Library/Frameworks/*.framework/Versions/A/*"))
bad = 0
checked = 0
for lib in targets:
    if os.path.islink(lib) or not os.path.isfile(lib):
        continue
    if "Mach-O" not in run("file", "-L", lib) and not run("llvm-nm", "-m", "--arch=" + arch, lib):
        continue
    imports = {}
    for line in run("llvm-nm", "-m", "--arch=" + arch, lib).splitlines():
        m = re.match(r"\s+\(undefined\) (weak )?external (\S+) \(from (.+)\)$", line)
        if m and not m.group(1):   # an unresolved weak import is not an error
            imports.setdefault(m.group(3), []).append(m.group(2))
    if not imports:
        continue
    # only the overlays: they load a Swift runtime library
    names = [d for d, _ in deps(lib)]
    if not any("/libswiftCore.dylib" in n for n in names) and "/usr/lib/swift/" not in lib:
        continue
    checked += 1
    for leaf, symbols in imports.items():
        install = next((n for n, _ in deps(lib) if os.path.basename(n) == leaf or os.path.basename(n) == leaf + ".dylib"
                        or os.path.basename(n).startswith(leaf + ".")), None)
        path = host_path(install) if install else None
        if path is None:
            continue   # a dylib outside the tree (@rpath, a system library not installed here)
        for symbol in symbols:
            if not provides(path, symbol):
                bad += 1
                print("UNRESOLVED %s: %s (from %s, %s)" % (os.path.relpath(lib, root), symbol, leaf, install))
print("%d libraries checked, %d unresolved symbols" % (checked, bad))
sys.exit(1 if bad else 0)
