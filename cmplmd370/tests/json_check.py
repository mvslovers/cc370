#!/usr/bin/env python3
"""Check one cmplmd370 --json result: valid, self-consistent, and complete.

usage: json_check.py RESULT.json EXIT_STATUS

The three ways a machine-readable result can quietly lie, in order of how badly
they would mislead a bulk run over thousands of pairs:

  * it does not parse at all
  * its verdict disagrees with the process exit status, which is what an
    automated caller actually branches on
  * its cluster list is SHORT -- the cluster lengths must add up to the
    diff_bytes it reports, or the consumer is reading a truncated difference
    and has no way to tell
"""
import json
import sys

d = json.load(open(sys.argv[1]))
rc = int(sys.argv[2])
# Every field a caller branches on must be present on EVERY path, error paths
# included -- a bulk run over 3,888 modules found 16 results that carried
# "error" and neither "exit" nor "identical", so the consumer read null exactly
# where it most needed an answer.
for k in ("exit", "identical", "error", "sections"):
    assert k in d, "key %r missing from the result" % k
assert d["exit"] == rc, "exit field %r != exit status %d" % (d["exit"], rc)
assert d["identical"] == (rc == 0), "identical field disagrees with exit status"
for s in d["sections"]:
    if not s.get("paired") or s.get("length_differs"):
        continue
    tot = sum(c["length"] for c in s["clusters"])
    assert tot == s["diff_bytes"], (
        "%s: clusters cover %d bytes, diff_bytes says %d"
        % (s["name"], tot, s["diff_bytes"]))
