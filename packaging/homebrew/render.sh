#!/bin/sh
# Render the Homebrew formula for one cc370 release (#699):
#   render.sh VERSION SHA256SUMS > cc370.rb
# SHA256SUMS is the release's own file; every tarball the formula names must
# be listed in it, or this fails rather than writing an empty checksum.
set -eu
v=$1; sums=$2
here=$(cd "$(dirname "$0")" && pwd)
sum() {
    s=$(grep "  cc370-$v-$1.tar.gz\$" "$sums" | cut -d' ' -f1)
    [ -n "$s" ] || { echo "render.sh: cc370-$v-$1.tar.gz not in $sums" >&2; exit 1; }
    echo "$s"
}
sed -e "s/@VERSION@/$v/g" \
    -e "s/@SHA_DARWIN_ARM64@/$(sum darwin-arm64)/" \
    -e "s/@SHA_DARWIN_AMD64@/$(sum darwin-amd64)/" \
    -e "s/@SHA_LINUX_ARM64@/$(sum linux-arm64)/" \
    -e "s/@SHA_LINUX_AMD64@/$(sum linux-amd64)/" \
    "$here/cc370.rb.in"
