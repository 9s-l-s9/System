# guix-packaging — maintainer notes & field tricks

This file records the non-obvious tricks discovered while building this skill, so
future agents don't have to rediscover them. `SKILL.md` is the agent-facing
instruction set; this is the "why it works / gotchas" companion.

## Proven end to end

The skill was validated by packaging **Space Mono** from scratch with zero human
input. The verified result lives in:

- `references/example-font-space-mono.scm` — standalone, `guix build -f`-able.
- `../../../home/packages/font-space-mono.scm` — the same package as a repo
  module with `define-public`.

Both build to an identical store path containing all four styles as `.ttf`/`.otf`.

## Trick 1 — Let the daemon do the network fetch, not local tools

Inside the `claude-guix` sandbox, **local `git`/`curl` often fail TLS** with
`server certificate verification failed (CAfile: none)`. But the **guix build
daemon has its own CA bundle**, so anything fetched *through* guix works:
`guix download URL`, `guix build` (git-fetch/url-fetch), `guix import`.

Practical consequence: don't `git clone` to compute a hash if local TLS is
broken. Instead use **Trick 2** and let the daemon fetch + report the hash.

## Trick 2 — "Fail to learn the hash"

You rarely know a source's `sha256` up front. Put a 52-zero placeholder:

```scheme
(sha256 (base32 "0000000000000000000000000000000000000000000000000000"))
```

Run `guix build -f file.scm`. The daemon fetches the source, the hash check
fails, and the error prints:

```
  expected hash: 0000...   (your placeholder)
  actual hash:   1mklddqxd77pv8jgz2hd6k6zfg863xaafng60l61yckp8gvsm1x8
```

Paste the **actual hash** back in and rebuild. This is faster and more reliable
than `guix download`/`guix hash` when local networking is restricted.

Filter the noise: the first build also prints a wall of `bordeaux`/`ci.guix`
substitute 404s and Software Heritage fallback lines — ignore them and grep for
`actual hash`:

```sh
guix build -f file.scm 2>&1 | grep -iE 'actual hash|expected hash'
```

## Trick 3 — Don't trust a "version" tag name; pin a commit

GitHub repos lie about tags. `googlefonts/spacemono` has **no usable `v1.0`
tag** — its only tag is literally named after a commit hash (`f5ebc1e1c0`), so
`(commit "v1.0")` fails with `couldn't find remote ref v1.0`. When a project has
no clean release archive or tag, **pin an explicit 40-char commit** from
`https://api.github.com/repos/OWNER/REPO/commits/BRANCH` and use a
`git-version`-style version string like `1.0.0-1.329858c`.

## Trick 4 — Standalone file must END in a bare package object

`guix build -f file.scm` evaluates the file and uses its **last value**. A file
whose last form is `(define-public foo …)` returns *no value* and fails. Either:

- end the file with a bare `(package …)`, or
- keep `define-public foo` and add a trailing line `foo` (what the repo module
  does, so the same file works both as a module and via `guix build -f`).

## Trick 5 — `font-build-system` is zero-config

For fonts you almost never need build phases: `font-build-system` recursively
finds `.ttf`/`.otf`/`.woff` in the source and installs them under
`share/fonts/...`. No `inputs`, no compilation. License is nearly always
`license:silofl1.1`. This makes fonts the easiest possible packaging target.

## Sandbox setup (one-time)

`claude-guix` runs in `guix shell --container --nesting`. Nesting exposes the
daemon socket (`/var/guix/daemon-socket/socket`) and the store, **but the `guix`
binary is frequently absent** (`could not add current Guix to the profile`).
Relaunch with this skill's manifest to get it:

```sh
claude-guix -m .agents/skills/guix-packaging/manifest.scm
```

No change to `claude-guix.scm` itself is required — `--nesting` + `--network`
(both already passed by the launcher) plus this manifest are sufficient.

## Files in this skill

| File | Purpose |
|---|---|
| `SKILL.md` | Agent-facing workflow (discover → import → write → hash → build). |
| `README.md` | This file: tricks and rationale. |
| `manifest.scm` | Layered `-m` manifest adding `guix`/`git`/`nss-certs`. |
| `references/templates.scm` | Copy-paste package skeletons (font / tarball / git). |
| `references/cheatsheet.md` | Condensed command tables. |
| `references/example-font-space-mono.scm` | Verified, buildable worked example. |
