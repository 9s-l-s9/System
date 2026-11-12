#!/bin/sh
# Run the blog's own make check, then verify this post's generated title
# and its link from the guides index. The current theme need not emit an h1.
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
guix shell -D -f guix.scm -- env SLS_GUIX_ENV=1 make check

echo "== checking $page exists and is wired up =="
[ -f "$page" ] || { echo "error: $page was not generated" >&2; exit 1; }

echo "-- title --"
grep -o '<title>[^<]*</title>' "$page" || { echo "error: no page title found" >&2; exit 1; }

echo "-- linked from guides index --"
grep -q "$topic" /tmp/pages/guides/index.html && echo "yes" || {
    echo "error: $topic not linked from guides/index.html" >&2
    exit 1
}

echo "verify.sh: $topic.skr passes make check and is wired into the site"
