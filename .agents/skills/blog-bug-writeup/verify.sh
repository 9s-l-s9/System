#!/bin/sh
# Run the blog's own verification gate (make check: lint + test + smoke —
# tests/test-skribe-bug.scm and tests/test-skribe-common.scm already
# byte-exact-assert the sls/bug macros' SXML/class output; smoke = a full
# haunt build), then confirm the one thing that gate can't know about: that
# THIS specific new post file exists in the build output and is linked from
# its index. Deliberately does not re-derive class-name/structure checks
# `make check` already covers more rigorously — see this skill's SKILL.md.
#
# Usage: verify.sh <topic>
#   where <topic> is the .skr filename under skeleton/guides/ without
#   the extension, e.g.:
#     verify.sh guix-ci-speedup
#   for skeleton/guides/guix-ci-speedup.skr
set -eu

topic=${1:?"usage: verify.sh <topic>  (skeleton/guides/<topic>.skr, no extension)"}
repo=~/Projects/CyberspaceSource
page="/tmp/pages/guides/$topic.html"

cd "$repo"
[ -f "skeleton/guides/$topic.skr" ] || {
    echo "error: skeleton/guides/$topic.skr does not exist" >&2
    exit 1
}

echo "== make check (lint + test + smoke) =="
guix environment -l ./guix.scm -- env SLS_GUIX_ENV=1 make check

echo "== checking $page exists and is wired up =="
[ -f "$page" ] || { echo "error: $page was not generated" >&2; exit 1; }

echo "-- title --"
grep -o '<h1>[^<]*</h1>' "$page" || { echo "error: no <h1> found" >&2; exit 1; }

echo "-- linked from guides index --"
grep -q "$topic" /tmp/pages/guides/index.html && echo "yes" || {
    echo "error: $topic not linked from guides/index.html" >&2
    exit 1
}

echo "verify.sh: $topic.skr passes make check and is wired into the site"
