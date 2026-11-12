# QA Roadmap

This repository needs QA in layers.
The order matters because later checks are only useful once the baseline evaluation path is stable.

## Issue 1: Baseline Evaluation Cleanup

Status: done

Goal:

- make `guix time-machine -C channels.scm -- home build --dry-run --load-path=home ...` a reliable baseline check
- make `guix time-machine -C channels.scm -- system build --dry-run --load-path=systems ...` the system-side equivalent

Resolution:

- `Makefile` wraps all Guix build/reconfigure targets in `guix time-machine -C channels.scm --`, decoupling evaluation from the active `guix pull` generation
- package, service, manifest, home, and system modules under `home/` and `systems/` align their `(define-module ...)` headers with their file paths
- `(base-system)` and `(X1)` declare `#:duplicates (merge-generics replace last)` (matching Guix's `(gnu)` convention for `modify-services`'s `delete` clause) so compilation emits no core-binding override warnings

## Issue 2: Standardize QA Entry Points

Status: done

Files:

- `Makefile`
- `scripts/check-guile-only.scm`
- `scripts/check-scripts-compile.scm`
- `scripts/test-minde-binary.scm`
- `scripts/test-git-hooks.scm`
- `scripts/test-privileged-scripts.scm`
- `scripts/test-mail-workflows.scm`
- `home/files/.config/emacs/tests/config-tests.el`
- `home/files/.config/emacs/tests/ui-tests.el`
- `.github/workflows/ci.yml`

Current targets:

- `make qa-ci`
  Runs `qa-guile-only` and `qa-scripts` (enforces the Guile-only `scripts/` policy and compiles scripts with `-Wunbound-variable -Warity-mismatch -Wformat`, failing on warnings; runs in GitHub Actions without Guix).
- `make qa`
  Runs `qa-ci`, `qa-minde-binary` (Minde binary verification & trust tests), `qa-git-hooks` (installed Git dispatchers in temporary repositories), `qa-privileged-scripts` (immutable helpers and sudoers), `qa-mail` (isolated Maildirs with fake SMTP/IMAP programs), and `qa-emacs` (Emacs configuration and UI ERT suites).
- `make qa-guile-only`
  Enforces the hard rule that files in `scripts/` are Guile (`.scm`) or documentation (`.org`), never shell/Python.
- `make qa-scripts`
  Compiles `scripts/` and treats compiler warnings as errors. Guix-dependent scripts use `guix repl` so the compiler matches Guix's module bytecode; other scripts use `guild compile`.
- `make qa-minde-binary`
  Runs `scripts/test-minde-binary.scm` via `guix repl`.
- `make qa-emacs`
  Runs both batch ERT suites (`config-tests.el` and `ui-tests.el`).
- `make qa-git-hooks`
  Builds the Git hook dispatchers with pinned Guix and checks hook arguments, exit status, stdin, attribution checks, linked worktrees, and clean/dirty `updateInstead` pushes using temporary local repositories.
- `make qa-privileged-scripts`
  Builds the power/keyboard helpers, checks store ownership and argument rejection, and validates both sudoers files with the system's `visudo`. Never performs a power or keyboard operation.
- `make qa-mail`
  Exercises draft filenames, successful-send cleanup failures, isolated export failures and retries. Requires notmuch, w3m and guile-json; never contacts a mail server.
- `make qa-home-samuel`
- `make qa-home-samuel-wsl2`
- `make qa-system-x1`
- `make qa-system-t450s`
- `make qa-all`
  Runs `make qa` plus all four `guix time-machine` home and system dry-run builds.

These targets are intentionally thin wrappers around the real commands so the checks stay transparent.

## Issue 3: Normalize Module Naming

Status: done

Goal:

- make file paths and module names agree everywhere under `home/` and `systems/`

Resolution:

- every module under `home/` (`packages/`, `services/`, `manifests/`, `lib/`, and `*-home-configuration.scm`) and `systems/` (`base-system.scm`, `X1.scm`, `T450s.scm`) declares a `(define-module ...)` matching its load-path-relative filename
- intentional exception: `minde-package.scm` at the repository root is evaluated via `primitive-load` for its final package value rather than imported from `home/` or `systems/`, so it does not declare `(define-module ...)`

## Issue 4: Document The Pre-Commit Flow

Status: done

Pre-commit QA sequence:

1. `make qa` — local checks: Guile-only script policy, strict compilation across `scripts/`, Minde binary security tests, Git hook integration tests, and Emacs batch ERT tests (`config-tests.el` + `ui-tests.el`). The first Git hook test run builds small Guix programs.
2. Run the dry-run build target(s) matching the area touched (evaluated reproducibly against `channels.scm` via `guix time-machine`):
   - `make qa-home-samuel` / `make qa-home-samuel-wsl2` when changing `home/` or `minde-package.scm`
   - `make qa-system-x1` / `make qa-system-t450s` when changing `systems/` or `minde-package.scm`
   - `make qa-all` when changing shared foundations (`channels.scm`, `minde-package.scm`, `home/packages/base-packages.scm`, `systems/base-system.scm`)
3. Only run `make reconfigure-home` / `make reconfigure-system` once the dry-run build is clean.

## Note: Always Check Channel News After `guix pull`

Rule: run `guix pull --news` after every pull, before reconfiguring.

Incident (2026-07): after a channel update, the new system generation had
wifi but "no internet". Cause: guix commit `86776ccd30b` updated openresolv
to 3.17.4, which refuses to manage `/etc/resolv.conf` unless the file starts
with the exact line `# Generated by resolvconf`. Result: stale resolv.conf,
dead DNS, everything except wifi association appeared broken. The breaking
change was announced in channel news (Jun 21) and easy to miss.

Offline fix, as root:

    rm /etc/resolv.conf
    herd restart NetworkManager

Debugging takeaway: `/etc/resolv.conf` is mutable state outside the system
generation, so rollbacks do not necessarily reproduce or fix such issues.
