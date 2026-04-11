# QA Roadmap

This repository needs QA in layers.
The order matters because later checks are only useful once the baseline evaluation path is stable.

## Issue 1: Baseline Evaluation Cleanup

Status: in progress

Goal:

- make `guix home build --dry-run --load-path=home ...` a reliable baseline check
- make `guix system build --dry-run --load-path=systems ...` the system-side equivalent

Current blockers found while testing:

- several files under `home/packages/` have module names that do not match their file paths
- some package modules have load-time issues and warnings during `guix home` evaluation
- `home/manifests/` still needs naming cleanup beyond the minimal module declarations
- profile-specific files should not introduce broken package references that poison unrelated evaluations

## Issue 2: Standardize QA Entry Points

Status: added

Files:

- `Makefile`
- `scripts/check-guile-only.scm`

Current targets:

- `make qa`
  Runs the fast repo-policy check.
- `make qa-guile-only`
  Enforces the hard rule that files in `scripts/` are Guile or documentation, not shell.
- `make qa-home-samuel`
- `make qa-home-levi`
- `make qa-system-x1`
- `make qa-system-t450s`

These targets are intentionally thin wrappers around the real Guix commands so the checks stay transparent.

## Issue 3: Normalize Module Naming

Status: todo

Goal:

- make file paths and module names agree everywhere under `home/` and `systems/`

Primary targets:

- `home/packages/*.scm`
- `home/manifests/*.scm`
- any profile entrypoint whose `(define-module ...)` does not match the filename

This should reduce noisy warnings and make load-path behavior predictable.

## Issue 4: Add Pure Guile Smoke Tests

Status: todo

Goal:

- test repo-local logic that does not need a full system or home build

Best starting point:

- Helix TOML serialization in `home/services/helix-home-services.scm`
- repo policy checks like the Guile-only scripts rule

Suggested shape:

- a small `tests/` directory
- SRFI-64 tests
- one target that runs the pure tests without requiring a full reconfigure

## Issue 5: Document The Pre-Commit Flow

Status: todo

Goal:

- define the smallest useful QA sequence before committing

Recommended eventual flow:

1. `make qa`
2. `make qa-home-samuel`
3. run the relevant profile or system target if the change touches that area
4. only run full reconfigure when the dry-run/build path is clean
