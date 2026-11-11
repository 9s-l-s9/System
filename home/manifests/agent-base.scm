;;; Shared base package set for every coding-agent container
;;; (claude/codex/pi/agy/dsh) and skill manifests.  Exported from a proper
;;; `(manifests agent-base)' module so `guix home --load-path=home' scans
;;; `home/' cleanly without load warnings; standalone manifests add `home/' to
;;; `%load-path' before importing it.
;;;
;;; Add a tool to `agent-base-specs' to hand it to ALL agents at once.
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

(define-module (manifests agent-base)
  #:export (agent-base-specs))

(define agent-base-specs
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
  ;; Node includes npm for agent installation and npx-based MCP servers.
  ;; Only DeepSeek still needs pnpm; its manifest adds that separately.
  "node@22"
  ;; File search, used generally and specifically by pi/deepseek-harness.
  "ripgrep"
  "fd"))
