#!/bin/sh
# install.sh against a local stand-in for the GitHub API (api.py) and file://
# releases of a fake cc370 9.9.9, libc370 2.0.0 / 1.0.0 (#879) and maclib370
# 1.0.0.  The point
# is that each way the API can fail is reported as what it is -- never as
# "no libc370 release fits", which is reserved for a list that was read.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
INST=$HERE/../install.sh
W=$(mktemp -d "${TMPDIR:-/tmp}/cc370inst.XXXXXX") || exit 2
pid=""
trap '[ -n "$pid" ] && kill $pid 2>/dev/null; rm -rf "$W"' 0
fail=0
ok()  { echo "install: OK   $*"; return 0; }
bad() { echo "install: FAIL $*"; fail=1; return 0; }

case $(uname -s) in Linux) os=linux ;; Darwin) os=darwin ;; *) echo "install: SKIP unsupported OS"; exit 0 ;; esac
case $(uname -m) in x86_64|amd64) arch=amd64 ;; aarch64|arm64) arch=arm64 ;; *) echo "install: SKIP unsupported machine"; exit 0 ;; esac
if command -v sha256sum >/dev/null; then sums() { sha256sum "$@"; return $?; }; else sums() { shasum -a 256 "$@"; return $?; }; fi

# the fake releases
R=$W/rel
n=cc370-9.9.9-$os-$arch
mkdir -p "$W/b/$n/bin" "$R/cc370/v9.9.9"
printf '#!/bin/sh\necho "cc370 9.9.9 (fake)"\n' > "$W/b/$n/bin/cc370"
chmod +x "$W/b/$n/bin/cc370"
tar -C "$W/b" -czf "$R/cc370/v9.9.9/$n.tar.gz" "$n"
(cd "$R/cc370/v9.9.9" && sums "$n.tar.gz" > SHA256SUMS)
for lv in 2.0.0 1.0.0; do
    d=$R/libc370/v$lv; s=libc370-$lv-sysroot
    mkdir -p "$d" "$W/l$lv/$s/include" "$W/l$lv/$s/lib"
    echo "/* libc370 $lv */" > "$W/l$lv/$s/include/fake$lv.h"
    mkdir -p "$W/l$lv/$s/macros" && echo '         MACRO' > "$W/l$lv/$s/macros/libmac.macro"
    if [ $lv = 2.0.0 ]; then
        mkdir -p "$W/l$lv/$s/share/libc370"
        printf '# removed in 2.0.0\nGETMAIN.macro\r\n\nWTO.macro\n../escape.macro\nsub/x.macro\nlibmac.macro\n' \
            > "$W/l$lv/$s/share/libc370/sysmac-removed.txt"
    fi
    : > "$W/l$lv/$s/lib/libc.a"
    tar -C "$W/l$lv" -czf "$d/$s.tar.gz" "$s"
    (cd "$d" && sums "$s.tar.gz" > SHA256SUMS)
done
echo '{"requires": {"cc370": ">=9.0.0 <10"}}' > "$R/libc370/v2.0.0/libc370-2.0.0-metadata.json"
echo '{"requires": {"cc370": ">=1.0.0 <2"}}'  > "$R/libc370/v1.0.0/libc370-1.0.0-metadata.json"
# maclib370: no top directory, macros/ at the root, as the real tarball
d=$R/maclib370/v1.0.0
mkdir -p "$d" "$W/m/macros"
echo '         MACRO' > "$W/m/macros/FAKE.macro"
tar -C "$W/m" -czf "$d/maclib370-1.0.0.tar.gz" macros
(cd "$d" && sums maclib370-1.0.0.tar.gz > SHA256SUMS)

python3 "$HERE/api.py" > "$W/port" &
pid=$!
i=0; while [ ! -s "$W/port" ] && [ $i -lt 50 ]; do sleep 0.1; i=$((i+1)); done
port=$(cat "$W/port")
[ -n "$port" ] || { echo "install: cannot start api.py"; exit 2; }

# run MODE [env...]: install into a fresh prefix; rc in $rc, stdout+stderr in $W/out
run() {
    m=$1; shift
    P=$W/p.$m; rm -rf "$P"
    env PREFIX="$P" CC370_API_URL="http://127.0.0.1:$port/$m" \
        CC370_BASE_URL="file://$R/cc370" LIBC370_BASE_URL="file://$R/libc370" \
        MACLIB370_BASE_URL="file://$R/maclib370" MACLIB370_VERSION=1.0.0 NO_MACLIB370= \
        GITHUB_TOKEN= CC370_VERSION= LIBC370_VERSION= LIBC370_RELEASES= NO_LIBC370= \
        "$@" ${RUNSH:-sh} "$INST" > "$W/out" 2>&1
    rc=$?
    return 0
}
has() { pat=$1; grep -q "$pat" "$W/out"; return $?; }
show() { tr '\n' '|' < "$W/out"; return 0; }

run ok
[ $rc = 0 ] && has 'cc370 9.9.9 for' && [ -f "$P/cc370/include/fake2.0.0.h" ] \
    && ok "latest cc370 from the API, newest fitting libc370 (2.0.0) installed" \
    || bad "ok: rc=$rc $(show)"

if command -v zsh >/dev/null; then
    RUNSH=zsh; run ok; RUNSH=sh
    [ $rc = 0 ] && [ -f "$P/cc370/include/fake2.0.0.h" ] \
        && ok "run by zsh: libc370 found as well" || bad "zsh: rc=$rc $(show)"
fi

run nofit
[ $rc = 0 ] && has 'no libc370 release declares a range that fits cc370 9.9.9' && [ -x "$P/bin/cc370" ] \
    && ok "a list without a fitting release: cc370 only, rc 0" \
    || bad "nofit: rc=$rc $(show)"

run limit CC370_VERSION=9.9.9
[ $rc = 1 ] && has 'libc370 is NOT' && has 'rate limit' && has 'resets in 10 min' \
    && has 'GITHUB_TOKEN' && ! has 'no libc370 release declares' && [ -x "$P/bin/cc370" ] \
    && ok "rate limit on the libc370 list: named, rc 1, cc370 installed" \
    || bad "limit (libc370): rc=$rc $(show)"

run limit
[ $rc = 1 ] && has 'cannot determine the latest cc370 release: the GitHub API rate limit' \
    && has 'CC370_VERSION=' && [ ! -e "$P/bin/cc370" ] \
    && ok "rate limit on the cc370 lookup: named, rc 1" \
    || bad "limit (cc370): rc=$rc $(show)"

run e500 CC370_VERSION=9.9.9
[ $rc = 1 ] && has 'answered HTTP 500' && ! has 'no libc370 release declares' \
    && ok "HTTP 500 named as such" || bad "e500: rc=$rc $(show)"

run token CC370_VERSION=9.9.9
[ $rc = 1 ] && has 'answered HTTP 401' && ok "no token: the 401 is named" || bad "token (none): rc=$rc $(show)"
run token GITHUB_TOKEN=tok
[ $rc = 0 ] && [ -f "$P/cc370/include/fake2.0.0.h" ] \
    && ok "GITHUB_TOKEN is sent to the API" || bad "token: rc=$rc $(show)"

# maclib370 -- the cases above name its version, so they test libc370's path
M=cc370/maclib370/macros/FAKE.macro
run ok MACLIB370_VERSION=
[ $rc = 0 ] && has 'maclib370 1.0.0' && [ -f "$P/$M" ] && [ -f "$P/cc370/include/fake2.0.0.h" ] \
    && ok "latest maclib370 from the API, beside libc370" || bad "maclib370: rc=$rc $(show)"

run limit CC370_VERSION=9.9.9 MACLIB370_VERSION=
[ $rc = 1 ] && has 'maclib370 is NOT' && has 'rate limit' && [ -x "$P/bin/cc370" ] && [ ! -e "$P/$M" ] \
    && ok "rate limit on the maclib370 lookup: named, rc 1, cc370 installed" \
    || bad "limit (maclib370): rc=$rc $(show)"

run ok NO_MACLIB370=1
[ $rc = 0 ] && has 'maclib370 skipped' && [ ! -e "$P/cc370/maclib370" ] && [ -f "$P/cc370/include/fake2.0.0.h" ] \
    && ok "NO_MACLIB370=1 leaves it out, libc370 still installed" || bad "NO_MACLIB370: rc=$rc $(show)"

# an older level's member does not survive a reinstall
P=$W/p.re; rm -rf "$P"; mkdir -p "$P/cc370/maclib370/macros"; : > "$P/cc370/maclib370/macros/OLD.macro"
env PREFIX="$P" CC370_API_URL="http://127.0.0.1:$port/ok" CC370_BASE_URL="file://$R/cc370" \
    LIBC370_BASE_URL="file://$R/libc370" MACLIB370_BASE_URL="file://$R/maclib370" \
    MACLIB370_VERSION=1.0.0 NO_MACLIB370= NO_LIBC370=1 GITHUB_TOKEN= CC370_VERSION=9.9.9 \
    sh "$INST" > "$W/out" 2>&1; rc=$?
[ $rc = 0 ] && [ -f "$P/$M" ] && [ ! -e "$P/cc370/maclib370/macros/OLD.macro" ] \
    && ok "reinstall replaces maclib370 whole" || bad "reinstall: rc=$rc $(show)"

# #933: an upgrade drops the IBM copies libc370 no longer ships, nothing else
P=$W/p.up; rm -rf "$P"; mkdir -p "$P/cc370/macros" "$P/cc370/sub"
for f in GETMAIN.macro WTO.macro OWN.macro; do echo old > "$P/cc370/macros/$f"; done
echo keep > "$P/cc370/escape.macro"; echo keep > "$P/cc370/sub/x.macro"
env PREFIX="$P" CC370_API_URL="http://127.0.0.1:$port/ok" CC370_BASE_URL="file://$R/cc370" \
    LIBC370_BASE_URL="file://$R/libc370" MACLIB370_BASE_URL="file://$R/maclib370" \
    MACLIB370_VERSION=1.0.0 NO_MACLIB370= NO_LIBC370= LIBC370_VERSION=2.0.0 GITHUB_TOKEN= CC370_VERSION=9.9.9 \
    sh "$INST" > "$W/out" 2>&1; rc=$?
M=$P/cc370/macros
[ $rc = 0 ] && [ ! -e "$M/GETMAIN.macro" ] && [ ! -e "$M/WTO.macro" ] && [ -f "$M/OWN.macro" ] \
    && [ -f "$M/libmac.macro" ] && [ -f "$P/cc370/escape.macro" ] && [ -f "$P/cc370/sub/x.macro" ] \
    && has 'removed 2 macro files libc370 2.0.0 no longer ships' \
    && ok "upgrade removes the listed IBM copies; own files, re-shipped names and paths kept" \
    || bad "stale macros: rc=$rc $(show) | $(ls "$M" | tr '\n' ' ')"

# a libc370 without the list removes nothing
P=$W/p.nolist; rm -rf "$P"; mkdir -p "$P/cc370/macros"; echo old > "$P/cc370/macros/GETMAIN.macro"
env PREFIX="$P" CC370_API_URL="http://127.0.0.1:$port/ok" CC370_BASE_URL="file://$R/cc370" \
    LIBC370_BASE_URL="file://$R/libc370" MACLIB370_BASE_URL="file://$R/maclib370" \
    MACLIB370_VERSION=1.0.0 NO_MACLIB370= NO_LIBC370= LIBC370_VERSION=1.0.0 GITHUB_TOKEN= CC370_VERSION=9.9.9 \
    sh "$INST" > "$W/out" 2>&1; rc=$?
[ $rc = 0 ] && [ -f "$P/cc370/macros/GETMAIN.macro" ] && ! has 'removed' \
    && ok "no sysmac-removed.txt: nothing removed" || bad "nolist: rc=$rc $(show)"

# a port nothing listens on: the stand-in's, after it is stopped
kill $pid 2>/dev/null; wait $pid 2>/dev/null; pid=""
run ok CC370_VERSION=9.9.9
[ $rc = 1 ] && has 'cannot reach' && ! has 'no libc370 release declares' \
    && ok "no connection named as such" || bad "unreachable: rc=$rc $(show)"

run ok CC370_VERSION=9.9.9 LIBC370_RELEASES="2.0.0 1.0.0"
[ $rc = 0 ] && [ -f "$P/cc370/include/fake2.0.0.h" ] \
    && ok "LIBC370_RELEASES needs no API" || bad "LIBC370_RELEASES: rc=$rc $(show)"

exit $fail
