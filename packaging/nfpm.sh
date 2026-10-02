#!/bin/sh
# Build the .deb and .rpm from an unpacked release tree (#523):
#   nfpm.sh TREE ARCH OUTDIR        ARCH = amd64 | arm64
#
# The tree is what `make dist' installs -- relocatable, so it goes to
# /usr/lib/cc370 unchanged, and /usr/bin gets a symlink per binary.  The
# driver resolves that symlink to find its own pieces (measured, #523), so no
# wrapper is needed.  Man pages are linked into /usr/share/man/man1.
#
# The dependencies are the ones decided on #523 (2026-10-03).  The two
# packages depend on each other -- cc370 cannot build an ordinary program
# without libc370's crt0.o, libc.a and headers, libc370 needs a cc370 in its
# range -- which apt and dnf resolve in one transaction.  cc370 1.1.0 takes
# over the three prologue macro files libc370 2.0 still owns (#688), hence
# the Breaks/Replaces and Conflicts: a libc370 before 2.1.0 cannot sit
# beside it.
#
# nfpm comes from https://github.com/goreleaser/nfpm; CI installs it.
set -eu
tree=$1; arch=$2; out=$3
here=$(cd "$(dirname "$0")" && pwd)
ver=$(tr -d ' \t\r\n' < "$here/../VERSION")
LIBC_MIN=2.1.0                      # cc370 1.1.0's own minimum (#523)
case $arch in
    amd64) rpmarch=x86_64 ;;
    arm64) rpmarch=aarch64 ;;
    *) echo "nfpm.sh: unknown arch $arch" >&2; exit 2 ;;
esac
tree=$(cd "$tree" && pwd)
mkdir -p "$out"
cfg="$out/nfpm-$arch.yaml"

{
cat <<EOF
name: cc370
arch: $arch
platform: linux
version: $ver
version_schema: semver
maintainer: mvslovers <https://github.com/mvslovers>
description: |
  Host-native cross-toolchain for MVS 3.8j: the cc370 C compiler (a GCC
  3.4.6 fork), the as370 assembler, the ld370 linker and their tools.
homepage: https://github.com/mvslovers/cc370
license: GPL-2.0-or-later
contents:
  - src: $tree/
    dst: /usr/lib/cc370
    type: tree
EOF
for b in "$tree"/bin/*; do
    n=$(basename "$b")
    printf '  - src: /usr/lib/cc370/bin/%s\n    dst: /usr/bin/%s\n    type: symlink\n' "$n" "$n"
done
for m in "$tree"/share/man/man1/*.1; do
    [ -f "$m" ] || continue
    n=$(basename "$m")
    printf '  - src: /usr/lib/cc370/share/man/man1/%s\n    dst: /usr/share/man/man1/%s\n    type: symlink\n' "$n" "$n"
done
cat <<EOF
overrides:
  deb:
    depends:
      - libc370-dev (>= $LIBC_MIN)
    replaces:
      - libc370-dev (<< $LIBC_MIN)
  rpm:
    depends:
      - libc370-devel >= $LIBC_MIN
    conflicts:
      - libc370-devel < $LIBC_MIN
deb:
  breaks:
    - libc370-dev (<< $LIBC_MIN)
EOF
} > "$cfg"

nfpm package -f "$cfg" -p deb -t "$out/cc370_${ver}_${arch}.deb"
nfpm package -f "$cfg" -p rpm -t "$out/cc370-${ver}.${rpmarch}.rpm"
rm -f "$cfg"
