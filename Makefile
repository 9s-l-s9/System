.PHONY: qa qa-ci qa-all qa-guile-only qa-scripts qa-minde-binary qa-git-hooks qa-privileged-scripts qa-mail qa-emacs \
	qa-home-samuel qa-home-samuel-wsl2 qa-system-x1 qa-system-t450s \
	reconfigure pull reconfigure-system reconfigure-home minde-install minde-ensure minde-update minde-commit-lock sudo-warm

# The whole run: one sudo prompt up front, pull the pinned channels (the pins
# in channels.scm are bumped by hand, never here), move the Minde pin to the
# newest successful GitHub build when there is one (MINDE_UPDATE=0 disables
# that), then reconfigure the system and the home environment. The lock file
# is committed (alone) after a successful run, see minde-commit-lock.
# Recipe order, not prerequisites, so the steps run sequentially under -j.
reconfigure:
	$(MAKE) sudo-warm
	$(MAKE) pull
	$(MAKE) sudo-warm minde-update
	$(MAKE) reconfigure-system
	$(MAKE) reconfigure-home
	$(MAKE) minde-commit-lock

# Commit only the changed lock (never other pending files); push unless the
# branch is behind its upstream. No change: nothing happens.
minde-commit-lock:
	@if git diff --quiet -- minde-binary.lock.scm; then :; else \
	  sha=$$(guix repl -q -- scripts/minde-binary.scm commit | tail -n1); \
	  git commit -q -m "minde: Binary auf $$(echo $$sha | cut -c1-8) aktualisieren" -- minde-binary.lock.scm && \
	  echo "Committed minde-binary.lock.scm ($$sha)."; \
	  git fetch -q 2>/dev/null; \
	  if [ "$$(git rev-list --count HEAD..@{u} 2>/dev/null || echo x)" = 0 ]; then \
	    git push -q && echo "Pushed." || echo "WARNING: push failed; lock committed locally."; \
	  else echo "WARNING: branch is behind or has no upstream; lock committed locally, not pushed."; fi; \
	fi

# Refresh the sudo timestamp (also after a long pull, where it may expire).
sudo-warm:
	sudo -v

# Newest successful guix-binary run on main, imported when ahead of the lock.
minde-update:
	MINDE_UPDATE=$(MINDE_UPDATE) guix repl -q -- scripts/minde-binary.scm update

# Reconfigure and QA run through time-machine so evaluation always uses the
# pinned channels, never whatever `guix pull` generation happens to be
# current (a stale or rolled-back one silently swaps package versions, and
# a plain pull profile may lack nonguix etc.).
MINDE_UPDATE ?= 1

GUIX_TM = guix time-machine -C channels.scm --

# Download options for the commands that fetch many substitutes.  The
# daemon fetches each item from the first server that has it and counts
# downloads as jobs (default: one at a time); nonguix also mirrors plain
# Guix packages but is the slowest server.  systems/base-system.scm sets the
# same for the daemon; passing them here also covers a daemon that still
# runs an older configuration (first reconfigure, a fresh install).
SUBSTITUTE_URLS = https://bordeaux.guix.gnu.org https://ci.guix.gnu.org https://substitutes.nonguix.org
GUIX_FETCH = --max-jobs=4 --substitute-urls="$(SUBSTITUTE_URLS)"

pull:
	guix pull --channels=channels.scm $(GUIX_FETCH)

# Import the pinned GitHub build on a new PC, or pin an explicitly selected
# build with `make minde-install COMMIT=<full commit>`. Never compiles Minde.
minde-install:
	guix repl -q -- scripts/minde-binary.scm install $(COMMIT)

# Import the pinned build when this store lacks it (one sudo prompt). Runs as
# the user first: root evaluation in reconfigure-system cannot download it.
minde-ensure:
	guix repl -q -- scripts/minde-binary.scm ensure

reconfigure-system: minde-ensure
	sudo $(GUIX_TM) system --load-path=systems reconfigure $(GUIX_FETCH) systems/$$HOSTNAME.scm

reconfigure-home: minde-ensure
	$(GUIX_TM) home --load-path=home reconfigure $(GUIX_FETCH) home/$$USER-home-configuration.scm

qa-ci: qa-guile-only qa-scripts

qa: qa-ci qa-minde-binary qa-git-hooks qa-privileged-scripts qa-mail qa-emacs

qa-all: qa qa-home-samuel qa-home-samuel-wsl2 qa-system-x1 qa-system-t450s

qa-guile-only:
	guile scripts/check-guile-only.scm

qa-scripts:
	guile scripts/check-scripts-compile.scm

qa-minde-binary:
	guix repl -q -- scripts/test-minde-binary.scm

qa-git-hooks:
	$(GUIX_TM) repl -q -- scripts/test-git-hooks.scm

qa-privileged-scripts:
	$(GUIX_TM) repl -q -- scripts/test-privileged-scripts.scm

qa-mail:
	guile --no-auto-compile scripts/test-mail-workflows.scm

qa-emacs:
	emacs --batch -l home/files/.config/emacs/tests/config-tests.el
	emacs --batch -l home/files/.config/emacs/tests/ui-tests.el -f ert-run-tests-batch-and-exit

qa-home-samuel:
	$(GUIX_TM) home build --dry-run --load-path=home home/samuel-home-configuration.scm

qa-home-samuel-wsl2:
	$(GUIX_TM) home build --dry-run --load-path=home home/samuel-wsl2-home-configuration.scm

qa-system-x1:
	$(GUIX_TM) system build --dry-run --load-path=systems systems/X1.scm

qa-system-t450s:
	$(GUIX_TM) system build --dry-run --load-path=systems systems/T450s.scm
