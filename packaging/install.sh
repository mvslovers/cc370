#!/bin/sh
# Install cc370 and a libc370 that fits it (#523):
#
#   curl -fsSL https://github.com/mvslovers/cc370/releases/latest/download/install.sh | sh
#
# into $PREFIX (default ~/.local), the layout `make install' gives: the
# binaries in $PREFIX/bin, everything else in $PREFIX/cc370, $PREFIX/libexec
# and $PREFIX/lib.  The libc370 sysroot (headers, libc.a, crt*.o, macros) goes
# into $PREFIX/cc370, where cc370 searches.
#
# Which libc370: the newest release whose libc370-<v>-metadata.json accepts
# this cc370 (`requires.cc370', e.g. ">=1.1.0 <2"; libc370#326).  A libc370
# without that file is not considered.
#
# Settings (environment):
#   PREFIX            install root                      ~/.local
#   CC370_VERSION     cc370 release to install           the latest
#   LIBC370_VERSION   libc370 release, skipping the match  the newest that fits
#   NO_LIBC370=1      install cc370 only
#   LIBC370_RELEASES  the libc370 versions to consider, newest first (default
#                     the GitHub release list; for a mirror or a test)
#   CC370_BASE_URL / LIBC370_BASE_URL   where release assets are fetched
#                     (default the GitHub releases; a file:// URL works)
#   GITHUB_TOKEN      sent to the GitHub API if set: 5000 requests an hour
#                     instead of 60 per address
#   CC370_API_URL     the GitHub API root (default https://api.github.com;
#                     for a test)
set -eu

PREFIX=${PREFIX:-$HOME/.local}
GH=https://github.com/mvslovers
API=${CC370_API_URL:-https://api.github.com}/repos/mvslovers
CC370_BASE_URL=${CC370_BASE_URL:-$GH/cc370/releases/download}
LIBC370_BASE_URL=${LIBC370_BASE_URL:-$GH/libc370/releases/download}

say() { echo "install.sh: $*"; }
die() { echo "install.sh: $*" >&2; exit 1; }

command -v curl >/dev/null || die "curl is required"
fetch() { curl -fsSL "$1" -o "$2" || die "cannot fetch $1"; }

if command -v sha256sum >/dev/null; then sha() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum >/dev/null; then sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
else die "sha256sum or shasum is required"; fi

# verify FILE against the SHA256SUMS beside it in the same release
verify() {
    want=$(grep "  $(basename "$1")\$" "$2" | cut -d' ' -f1)
    [ -n "$want" ] || die "$(basename "$1") is not listed in SHA256SUMS"
    [ "$(sha "$1")" = "$want" ] || die "checksum mismatch: $(basename "$1")"
}

case $(uname -s) in Linux) os=linux ;; Darwin) os=darwin ;; *) die "unsupported OS $(uname -s)" ;; esac
case $(uname -m) in x86_64|amd64) arch=amd64 ;; aarch64|arm64) arch=arm64 ;; *) die "unsupported machine $(uname -m)" ;; esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# GET $API/$1 into $tmp/api.json.  On anything but 200, set $apierr to the
# status and its cause and return 1 -- an empty answer must not pass for an
# empty list (#879).
api() {
    rm -f "$tmp/api.hdr" "$tmp/api.json"
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        code=$(curl -sSL -H "Authorization: Bearer $GITHUB_TOKEN" -D "$tmp/api.hdr" \
            -o "$tmp/api.json" -w '%{http_code}' "$API/$1" 2>"$tmp/api.err") || code=000
    else
        code=$(curl -sSL -D "$tmp/api.hdr" -o "$tmp/api.json" -w '%{http_code}' \
            "$API/$1" 2>"$tmp/api.err") || code=000
    fi
    [ "$code" = 200 ] && return 0
    if [ "$code" = 000 ]; then
        apierr="cannot reach $API ($(head -1 "$tmp/api.err"))"
    elif tr -d '\r' < "$tmp/api.hdr" | grep -qi '^x-ratelimit-remaining: *0$'; then
        reset=$(tr -d '\r' < "$tmp/api.hdr" | sed -n 's/^[Xx]-[Rr]ate[Ll]imit-[Rr]eset: *\([0-9]*\).*/\1/p' | head -1)
        wait=""
        [ -n "$reset" ] && wait=", resets in $(( (reset - $(date +%s) + 59) / 60 )) min"
        apierr="the GitHub API rate limit for this address is used up (HTTP $code$wait); retry later or set GITHUB_TOKEN"
    else
        apierr="the GitHub API answered HTTP $code for $API/$1"
    fi
    return 1
}
# every tag_name in the answer, in order -- one per line or all on one
tags() { tr ',{}' '\n\n\n' < "$tmp/api.json" | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p'; }

# --- cc370 -------------------------------------------------------------------
if [ -n "${CC370_VERSION:-}" ]; then
    v=$CC370_VERSION
else
    api cc370/releases/latest || die "cannot determine the latest cc370 release: $apierr (or name one with CC370_VERSION=)"
    v=$(tags | head -1)
    [ -n "$v" ] || die "cannot determine the latest cc370 release: no tag_name in the answer"
fi
tb=cc370-$v-$os-$arch.tar.gz
say "cc370 $v for $os-$arch"
fetch "$CC370_BASE_URL/v$v/$tb" "$tmp/$tb"
fetch "$CC370_BASE_URL/v$v/SHA256SUMS" "$tmp/cc370.sums"
verify "$tmp/$tb" "$tmp/cc370.sums"
mkdir -p "$tmp/cc370" "$PREFIX"
tar -C "$tmp/cc370" -xzf "$tmp/$tb"
cp -R "$tmp/cc370/cc370-$v-$os-$arch/." "$PREFIX/"
got=$("$PREFIX/bin/cc370" --version | head -1)
say "installed: $got"

[ "${NO_LIBC370:-}" = 1 ] && { say "libc370 skipped (NO_LIBC370=1)"; exit 0; }

# --- libc370 -----------------------------------------------------------------
# a.b.c -> comparable integer; a pre-release suffix is dropped
num() { echo "${1%%-*}" | awk -F. '{ printf "%d", $1 * 1000000 + $2 * 1000 + $3 }'; }
# does version $1 satisfy the space-separated range $2 (">=1.1.0 <2")?
fits() {
    n=$(num "$1")
    for c in $2; do
        op=$(echo "$c" | sed 's/[0-9].*//'); w=$(echo "$c" | sed 's/^[^0-9]*//')
        case $w in *.*.*) ;; *.*) w=$w.0 ;; *) w=$w.0.0 ;; esac
        m=$(num "$w")
        case $op in
            '>=') [ "$n" -ge "$m" ] || return 1 ;;
            '>')  [ "$n" -gt "$m" ] || return 1 ;;
            '<=') [ "$n" -le "$m" ] || return 1 ;;
            '<')  [ "$n" -lt "$m" ] || return 1 ;;
            '='|'') [ "$n" -eq "$m" ] || return 1 ;;
            *) return 1 ;;
        esac
    done
}
# the requires.cc370 range of a metadata.json
range_of() { tr -d '\n' < "$1" | sed -n 's/.*"requires"[^}]*"cc370"[ ]*:[ ]*"\([^"]*\)".*/\1/p'; }

if [ -n "${LIBC370_VERSION:-}" ]; then
    lv=$LIBC370_VERSION
else
    lv=""
    if [ -n "${LIBC370_RELEASES:-}" ]; then
        rels=$LIBC370_RELEASES
    else
        api "libc370/releases?per_page=50" \
            || die "cc370 $v is installed, libc370 is NOT: $apierr (or name one with LIBC370_VERSION=)"
        rels=$(tags)
    fi
    for t in $rels; do
        curl -fsSL "$LIBC370_BASE_URL/v$t/libc370-$t-metadata.json" -o "$tmp/meta.json" 2>/dev/null || continue
        r=$(range_of "$tmp/meta.json")
        if [ -n "$r" ] && fits "$v" "$r"; then lv=$t; break; fi
    done
    [ -n "$lv" ] || { say "no libc370 release declares a range that fits cc370 $v -- installed cc370 only"; exit 0; }
fi
say "libc370 $lv"
st=libc370-$lv-sysroot.tar.gz
fetch "$LIBC370_BASE_URL/v$lv/$st" "$tmp/$st"
fetch "$LIBC370_BASE_URL/v$lv/SHA256SUMS" "$tmp/libc370.sums"
verify "$tmp/$st" "$tmp/libc370.sums"
mkdir -p "$tmp/libc370"
tar -C "$tmp/libc370" -xzf "$tmp/$st"
src=$tmp/libc370
[ -d "$src/include" ] || src=$(find "$tmp/libc370" -mindepth 1 -maxdepth 1 -type d | head -1)
[ -d "$src/include" ] && [ -d "$src/lib" ] || die "$st has no include/ and lib/"
mkdir -p "$PREFIX/cc370"
cp -R "$src/." "$PREFIX/cc370/"
say "installed libc370 $lv into $PREFIX/cc370"
case ":$PATH:" in *":$PREFIX/bin:"*) ;; *) say "add $PREFIX/bin to PATH" ;; esac
