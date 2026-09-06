;;; Shared base package set for every coding-agent container
;;; (claude/codex/pi). The per-agent manifests pull this in via
;;; `primitive-load' on an absolute path -- the same pattern
;;; home/services/minde.scm uses for minde-package.scm -- so we avoid putting
;;; home/ on the Guile %load-path just to cross-reference a module.
;;;
;;; This file's value is its last expression: a plain list of Guix package
;;; specifications. Add a tool here to hand it to ALL agents at once.
;;;
;;; Notes on the Python tooling:
;;;   uv         -- Astral's package/venv manager. Works inside the
;;;                 `guix shell --container --emulate-fhs --network' the
;;;                 launchers build: --network reaches PyPI, and --emulate-fhs
;;;                 lets uv's downloaded standalone CPython binaries (they need
;;;                 /lib64/ld-linux) actually run.
;;;   nss-certs  -- REQUIRED for uv/pip HTTPS to PyPI; guix shell exports
;;;                 SSL_CERT_FILE/SSL_CERT_DIR from it. Without it every TLS
;;;                 fetch fails. (Set UV_PYTHON_PREFERENCE=system if you would
;;;                 rather uv reuse the `python' below than download its own.)
;;;   python     -- a stable interpreter on PATH so uv/pipx have a system one.
;;;   ruff       -- single-binary linter/formatter, natural uv companion.
'("bash"
  "coreutils"
  "grep"
  "sed"
  "gawk"
  "git"
  "curl"
  "podman"
  "github-cli"   ; provides the `gh` binary
  "openssh"
  "guix"
  "guile"
  "make"
  "findutils"
  "d2"
  ;; Wayland screenshots so an agent can capture the real screen for UI/debug
  ;; work; the launchers expose WAYLAND_DISPLAY/XDG_RUNTIME_DIR into the
  ;; container. slurp adds interactive region selection.
  "grim"
  "slurp"
  ;; Python tooling for agents:
  "uv"
  "python"
  "nss-certs"
  "ruff"
  ;; Node/pnpm runtime: every agent CLI (claude/codex/pi/deepseek-harness)
  ;; needs at least node; pnpm was duplicated in three of the four.
  "node@22"
  "pnpm@9"
  ;; File search, used generally and specifically by pi/deepseek-harness.
  "ripgrep"
  "fd")
