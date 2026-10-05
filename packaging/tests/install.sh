#!/bin/sh
# install.sh against a local stand-in for the GitHub API (api.py) and file://
# releases of a fake cc370 9.9.9 and libc370 2.0.0 / 1.0.0 (#879).  The point
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
    : > "$W/l$lv/$s/lib/libc.a"
    tar -C "$W/l$lv" -czf "$d/$s.tar.gz" "$s"
    (cd "$d" && sums "$s.tar.gz" > SHA256SUMS)
done
echo '{"requires": {"cc370": ">=9.0.0 <10"}}' > "$R/libc370/v2.0.0/libc370-2.0.0-metadata.json"
echo '{"requires": {"cc370": ">=1.0.0 <2"}}'  > "$R/libc370/v1.0.0/libc370-1.0.0-metadata.json"

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
        GITHUB_TOKEN= CC370_VERSION= LIBC370_VERSION= LIBC370_RELEASES= NO_LIBC370= \
        "$@" sh "$INST" > "$W/out" 2>&1
    rc=$?
    return 0
}
has() { pat=$1; grep -q "$pat" "$W/out"; return $?; }
show() { tr '\n' '|' < "$W/out"; return 0; }

run ok
[ $rc = 0 ] && has 'cc370 9.9.9 for' && [ -f "$P/cc370/include/fake2.0.0.h" ] \
    && ok "latest cc370 from the API, newest fitting libc370 (2.0.0) installed" \
    || bad "ok: rc=$rc $(show)"

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

# a port nothing listens on: the stand-in's, after it is stopped
kill $pid 2>/dev/null; wait $pid 2>/dev/null; pid=""
run ok CC370_VERSION=9.9.9
[ $rc = 1 ] && has 'cannot reach' && ! has 'no libc370 release declares' \
    && ok "no connection named as such" || bad "unreachable: rc=$rc $(show)"

run ok CC370_VERSION=9.9.9 LIBC370_RELEASES="2.0.0 1.0.0"
[ $rc = 0 ] && [ -f "$P/cc370/include/fake2.0.0.h" ] \
    && ok "LIBC370_RELEASES needs no API" || bad "LIBC370_RELEASES: rc=$rc $(show)"

exit $fail
