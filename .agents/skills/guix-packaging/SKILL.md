---
name: guix-packaging
description: Write, test, and debug GNU Guix package definitions for software that is missing from Guix — fonts, Python/Rust/Node/Go/Perl libraries, and standalone programs. Use when a needed package is not in Guix (e.g. `guix show NAME` fails), when asked to package a font (such as Space Mono), to import a package from PyPI/crates.io/npm/CRAN/Hackage, to compute a source hash, to write a standalone `.scm` package file, or to debug a failing `guix build`. Supports host Guix shells and explicitly selected container sessions.
---

# Guix Packaging

Use this skill to add software that Guix does not yet provide. The deliverable is
usually a **standalone package file** that builds with `guix build -f file.scm`,
which can then be installed (`guix install -f`), entered (`guix shell -f`), or
folded into this repo's package modules / a personal channel.

## Check the execution environment

`claude-guix` defaults to a host Guix shell. Only `--full` and `--sandbox`
select `guix shell --container --nesting`. Check the launch mode before using
container workarounds; `GUIX_ENVIRONMENT` alone is set in both modes. If the
launch command is unknown, inspect `/proc/self/mountinfo` and `/sys` rather
than assuming that a Guix shell is a container.

Check `command -v guix`, `guix --version`, `guix describe`, and access to
`/var/guix/daemon-socket/socket`. If Guix is absent, add this skill's manifest
while preserving the chosen mode, e.g.:

```sh
claude-guix --sandbox -m .agents/skills/guix-packaging/manifest.scm
```

Container notes below apply only inside a container and only when the described
failure occurs. Do not change certificate variables or avoid working host
commands preemptively. Both container modes expose the network and daemon;
initial builds may spend time fetching substitutes.

## Step 1 — Confirm it is actually missing

Never package something that already exists.

```sh
guix show NAME            # exact package
guix search REGEX         # fuzzy; e.g. guix search 'space mono'
```

For fonts, the Guix naming convention is `font-<foundry-or-family>`
(e.g. `font-space-grotesk`), so search both the bare name and the `font-` prefix.

## Step 2 — Prefer an importer over hand-writing

`guix import` generates a definition (and recursively its dependencies with
`-r`). Always start here for ecosystem packages:

```sh
guix import pypi   NAME            # Python (PyPI)
guix import crate  NAME            # Rust (crates.io)
guix import npm-binary NAME        # Node (npm)
guix import gem    NAME            # Ruby
guix import cran   NAME            # R (CRAN)
guix import hackage NAME           # Haskell
guix import go     IMPORT-PATH     # Go
guix import elpa   NAME            # Emacs (ELPA/MELPA: -a melpa)
guix import texlive NAME           # TeX Live

guix import pypi -r NAME           # also emit missing dependencies
```

Pipe the output into a file, then clean it up (fix synopsis/description,
license, drop dependencies already in Guix). Importers get you ~80% there;
review every field. Fonts, plain release tarballs, and bespoke programs have no
importer — hand-write them (Step 3).

## Step 3 — Hand-write a package definition

Copy the closest template from `references/templates.scm` and edit it. Three
common shapes are provided: **font** (release archive), **url-fetch program**
(GNU/CMake tarball), and **git-fetch** (tagged source checkout).

A standalone file must (a) import the modules it uses and (b) **evaluate to a
package object as its final expression** so `guix build -f` can pick it up:

```scheme
(use-modules (guix packages)
             (guix download)            ; url-fetch
             (guix build-system font)
             ((guix licenses) #:prefix license:))

(package
  (name "font-space-mono")
  (version "1.000")
  (source (origin
            (method url-fetch)
            (uri "https://example.com/SpaceMono-1.000.zip")
            (sha256 (base32 "0000000000000000000000000000000000000000000000000000"))))
  (build-system font-build-system)
  (home-page "https://fonts.google.com/specimen/Space+Mono")
  (synopsis "Fixed-width display typeface")
  (description "Space Mono is a monospaced display typeface...")
  (license license:silofl1.1))
```

Notes:
- The trailing object is the build target. Do **not** wrap it in
  `define-public` in a `guix build -f` file (a `define` returns no value).
  When moving the package into a module later, add `define-public`.
- Fonts use `font-build-system` (installs `.ttf`/`.otf`/`.woff` into the
  profile, no compilation) and almost always `license:silofl1.1`.
- Common licenses: `license:expat` (MIT), `license:asl2.0`, `license:gpl3+`,
  `license:bsd-3`, `license:silofl1.1`. Browse with
  `guix repl -- -c '(use-modules (guix licenses))'` or grep
  `~/.config/guix/current/.../licenses.scm`.

## Step 4 — Get the source hash

A package needs the exact `sha256`. Compute it for real input; never invent it.

**Release archive / tarball (`url-fetch`):** `guix download` fetches and prints
the base32 hash:

```sh
guix download https://example.com/SpaceMono-1.000.zip
# => /gnu/store/...-SpaceMono-1.000.zip
#    0abc...    <- paste this into (base32 "...")
```

**Git checkout (`git-fetch`):** hash the tree content recursively:

```sh
git clone --depth 1 -b TAG https://example.com/repo /tmp/src
guix hash -rx /tmp/src        # -r recursive, -x respect .gitignore/skip .git
```

(For older guix: `guix hash -rx` may be `guix hash -S nar -x`; check
`guix hash --help`.)

If you don't yet have the hash, put 52 zeros as a placeholder and let the first
`guix build` fail — it prints the expected hash, which you paste back in. This
is the standard "fail to learn the hash" trick.

## Step 5 — Build and test

```sh
guix build -f file.scm                 # build the derivation
guix build -f file.scm --keep-failed   # keep /tmp build tree on failure
guix shell -f file.scm -- COMMAND      # try it in an ephemeral environment
guix install -f file.scm               # install into the default profile (fonts: log out/in or `fc-cache -f`)
guix lint -f file.scm                  # style/metadata/synopsis checks
```

Iterate: edit → `guix build -f` → read the error → fix. `--keep-failed` plus the
printed build directory is the main debugging lever for compile failures.

## Step 6 — Place it (optional, repo-specific)

This repo (`~/Projects/System`) keeps package modules under
`home/packages/`. To make a package permanent rather than a loose `.scm`:

1. Add `define-public` and move it into the appropriate `(define-module ...)`
   file (or create one), with the right `#:use-module` imports.
2. Reference it from the relevant manifest / home configuration.
3. For a package you want available everywhere without editing Guix itself,
   prefer a **personal channel** (`~/.config/guix/channels.scm` +
   `guix pull`) over patching the store.

See `references/templates.scm` for ready-to-edit definitions and
`references/cheatsheet.md` for a condensed command reference.

## Failure handling

- `guix build` fails with a hash mismatch → paste the "actual" hash into the
  `(base32 ...)` field. That is normal on the first build.
- "unbound variable: some-package" → add the `#:use-module`/`(use-modules ...)`
  that defines it, or it isn't in Guix and must be packaged too.
- Network/substitute timeouts → retry; the daemon resumes partial downloads.
- `guix` not found at all → the active environment lacks the binary; relaunch with
  `-m .agents/skills/guix-packaging/manifest.scm` (see preflight).
