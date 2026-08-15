---
name: blog-bug-writeup
description: >
  Use this skill proactively right after resolving a genuinely non-trivial
  bug or investigation — one with a real story: multiple failed attempts,
  a root cause found through evidence (logs, timestamps, measurements) rather
  than a guess, or a fix that broke something else before landing. Draft a
  post in ~/Projects/CyberspaceSource (the personal blog, built with Haunt)
  using its native `sls/bug` Skribe format under skeleton/guides/, then build
  the site locally to verify it actually renders before telling the user it's
  ready. Do NOT use for trivial fixes: one-line typos, config value corrections,
  "the docs were wrong" with no investigation, or anything where the fix was
  obvious on first read. When genuinely unsure whether a bug clears the bar,
  draft it anyway (it's cheap and the file is easy to discard) but say so
  explicitly rather than silently deciding. Never commit or publish
  automatically — draft, verify it builds, hand off, stop.
license: CC0-1.0
---

# Blog bug writeup

Turns a debugging session that's actually worth reading — not just any bug
that got fixed — into a draft post in the personal blog, in the blog's own
native format, verified to actually build before handing it back.

## When to fire

Fire this **proactively**, without being asked, immediately after a bug is
resolved that has most of:

- More than one attempt, including at least one that failed or made things
  worse, with a concrete reason why (not just "tried X, didn't work").
- A root cause found via evidence — reading an actual log, diffing
  timestamps, reproducing a real failure — not theorized from memory.
- A fix that broke something else before the final one landed (a regression
  caused by the fix itself is some of the best material: it's the part a
  clean "I added a cache and it got faster" post would never mention).
- Something a future reader hitting the same class of problem could actually
  use — a specific tool's specific gotcha, not a generic lesson.

Skip it for: single-line typo fixes, config corrections with no
investigation, anything solved by reading the error message once. If it's
genuinely borderline, draft it anyway and say so — a draft costs nothing and
is easy to discard, but don't silently skip without telling the user a
judgment call was made.

## Paths

- Blog repo: `~/Projects/CyberspaceSource`
- Posts live under `skeleton/`, read by two Haunt readers registered in
  `haunt.scm`: `sls/skribe-reader` (`.skr` files, this skill's format) and
  `commonmark-reader` (`.md`, not used by this skill).
- Bug/investigation posts specifically go in `skeleton/guides/`, one file per
  post: `skeleton/guides/<kebab-case-topic>.skr`. (`skeleton/logs/` exists
  too, for informal running logs rather than a single resolved
  investigation — don't use it for this.)
- The `sls/bug` macro and its child forms are defined in
  `src/reader/skribe/bug.scm`; shared helpers (`date-line`, `tag-list`,
  `status-badge`, `refs-footer`) are in `src/reader/skribe/common.scm`. Read
  both before writing a post — this skill's summary below can drift from the
  actual macro signatures; the source is the source of truth.
- An existing post to pattern-match against:
  `skeleton/guides/wacom-tablet-orientation-guix.skr` (short, single-attempt)
  and `skeleton/guides/guix-ci-speedup.skr` (long, multi-attempt with
  regressions) if present.

## Format

```scheme
(post
 :title "Human-readable post title"
 :css "/assets/css/bug.css"

 (sls/bug
  :title "The problem, stated as it first appeared"
  :date "YYYY-MM-DD"
  :tags '(relevant symbols here)
  :status 'solved                 ; or 'partial / 'open — becomes a CSS class
  :refs '("https://...")          ; external sources actually consulted

  (bug-problem [What was actually broken, and what it looked like at first.])

  (bug-attempt :outcome 'failed
               [What was tried, what happened, and — critically — *why* it
                didn't work, if that's known. A failed attempt with no
                explained reason isn't worth including.])

  (bug-attempt :outcome 'solved
               [The attempt that actually fixed it, same level of detail.])

  (bug-win [The confirmed result: real numbers, a before/after, a log
            excerpt showing it actually worked — not "should be faster now."])

  (bug-section "Optional named section"
    (bug-note [A note that doesn't fit the problem/attempt/win shape —
               e.g. "what I deliberately didn't do and why," or a
               takeaway.])
    (bug-command [literal shell/code to run]))))
```

Notes on the format itself:
- `[...]` is Skribe's bracket-quoted prose; write plain text/backticked
  `code` inside it, not Markdown syntax.
- `bug-attempt`'s `:outcome` becomes a CSS modifier class
  (`sls-bug-attempt--failed` etc.) — use `'failed`, `'partial`, or `'solved`
  consistently with what actually happened, not just `'solved` for
  everything.
- `refs` is a flat list of URL strings, not `(label . url)` pairs — they
  render as the literal URL as link text.
- Prefer real numbers and short log excerpts over prose summaries wherever
  they're available — this blog's own existing bug posts lean on concrete
  detail (commands, exact tool output) over narrated generalities.

## Verification (required — do not skip)

A post that doesn't build isn't done. **Reuse the project's own gate,
don't re-derive it**: `tests/test-skribe-bug.scm` and
`tests/test-skribe-common.scm` already byte-exact-assert the `sls/bug`
macros' SXML and CSS-class output. Re-checking those same class names
against generated HTML with ad-hoc `grep` would be a weaker, independent
reimplementation of checks that already exist and are more rigorous —
don't do that. Run `verify.sh <topic>` from this skill directory (`<topic>`
= the `.skr` filename under `skeleton/guides/`, no extension), or by hand:

```sh
cd ~/Projects/CyberspaceSource
guix environment -l ./guix.scm -- env SLS_GUIX_ENV=1 make check   # lint + test + smoke
```

`make check`'s `test` target is exactly those macro-output tests plus
`test-skribe-index.scm`; `smoke` is a full `haunt build`; `lint` compiles
every `.scm` file with warnings-as-errors. That covers everything about
whether the *format* is right. The one thing it can't know about is
whether *this specific new post* exists in the output and is wired up —
check that, and only that, separately:

```sh
find /tmp/pages -iname '<topic>.html'                # the page exists
grep -o '<h1>[^<]*</h1>' /tmp/pages/guides/<topic>.html   # title parsed
grep -q '<topic>' /tmp/pages/guides/index.html            # linked from the index
```

## After verifying

Report what was written and that it builds; do not `git add`/commit, and
never run `make publish` (rsync + git push to a separate, public pages
repo) without the user explicitly asking for that specific action. Drafting
and verifying is this skill's job; publishing is the user's call.
