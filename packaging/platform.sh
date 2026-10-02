#!/bin/sh
# The release platform name of this host: linux-amd64, linux-arm64,
# darwin-arm64, darwin-amd64 (#523).  PLATFORM= overrides it in make.
case $(uname -s) in
    Linux)  os=linux ;;
    Darwin) os=darwin ;;
    *)      echo "platform.sh: unsupported OS $(uname -s)" >&2; exit 1 ;;
esac
case $(uname -m) in
    x86_64|amd64)  arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *)             echo "platform.sh: unsupported machine $(uname -m)" >&2; exit 1 ;;
esac
echo "$os-$arch"
