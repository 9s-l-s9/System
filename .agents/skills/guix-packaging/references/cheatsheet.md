# Guix packaging cheatsheet

## Discover
| Goal | Command |
|---|---|
| Show a package | `guix show NAME` |
| Search | `guix search REGEX` |
| Where is it defined | `guix edit NAME` |
| Current guix/channels | `guix describe` |

## Import (generate a definition)
| Ecosystem | Command |
|---|---|
| PyPI | `guix import pypi NAME` |
| crates.io | `guix import crate NAME` |
| npm | `guix import npm-binary NAME` |
| RubyGems | `guix import gem NAME` |
| CRAN (R) | `guix import cran NAME` |
| Hackage | `guix import hackage NAME` |
| Go | `guix import go IMPORT/PATH` |
| Emacs | `guix import elpa NAME` (`-a melpa`) |
| + dependencies | add `-r` |

## Hash a source
| Source | Command |
|---|---|
| Tarball/zip URL (url-fetch) | `guix download URL` |
| Git checkout (git-fetch) | `guix hash -rx /path/to/checkout` |
| Learn hash by failing | put 52 zeros, run `guix build -f`, copy "expected" |

The base32 sha256 placeholder is 52 chars:
`0000000000000000000000000000000000000000000000000000`

## Build / test / install (standalone file)
| Goal | Command |
|---|---|
| Build | `guix build -f file.scm` |
| Keep failed build tree | `guix build -f file.scm --keep-failed` |
| Try in shell | `guix shell -f file.scm -- COMMAND` |
| Install | `guix install -f file.scm` |
| Lint | `guix lint -f file.scm` |
| Refresh font cache | `fc-cache -f` (or log out/in) |

## Build systems (common)
| Kind | Module | build-system |
|---|---|---|
| Fonts | `(guix build-system font)` | `font-build-system` |
| Autotools | `(guix build-system gnu)` | `gnu-build-system` |
| CMake | `(guix build-system cmake)` | `cmake-build-system` |
| Meson | `(guix build-system meson)` | `meson-build-system` |
| Python | `(guix build-system pyproject)` | `pyproject-build-system` |
| Rust | `(guix build-system cargo)` | `cargo-build-system` |
| Node | `(guix build-system node)` | `node-build-system` |
| Trivial copy | `(guix build-system copy)` | `copy-build-system` |

## Licenses (prefix `license:` after `((guix licenses) #:prefix license:)`)
`expat` (MIT) · `asl2.0` · `gpl3+` · `gpl2+` · `lgpl3+` · `bsd-3` ·
`silofl1.1` (fonts) · `cc-by-sa4.0` · `public-domain`

## Inputs
- `native-inputs` — build-time only (compilers, pkg-config, generators).
- `inputs` — runtime libraries linked/used by the package.
- `propagated-inputs` — must appear in the user profile too (e.g. Python deps).

## Sandbox notes (claude-guix)
- Relaunch with packaging tools:
  `claude-guix -m .agents/skills/guix-packaging/manifest.scm`
- Daemon socket: `/var/guix/daemon-socket/socket` (exposed by `--nesting`).
- Everything needs `--network`; the launcher already passes it.
