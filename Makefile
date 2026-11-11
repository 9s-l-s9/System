.PHONY: qa qa-ci qa-all qa-guile-only qa-scripts qa-minde-binary qa-emacs \
	qa-home-samuel qa-home-levi qa-system-x1 qa-system-t450s \
	update pull reconfigure-system reconfigure-home minde-install minde-ensure

# Full update: pull the pinned channels, then reconfigure the system and
# the home environment (the README's installation steps, in order).
update: pull reconfigure-system reconfigure-home

# Reconfigure and QA run through time-machine so evaluation always uses the
# pinned channels, never whatever `guix pull` generation happens to be
# current (a stale or rolled-back one silently swaps package versions, and
# a plain pull profile may lack nonguix etc.).
GUIX_TM = guix time-machine -C channels.scm --

pull:
	guix pull --channels=channels.scm

# Import the pinned GitHub build on a new PC, or pin an explicitly selected
# build with `make minde-install COMMIT=<full commit>`. Never compiles Minde.
minde-install:
	guix repl -q -- scripts/minde-binary.scm install $(COMMIT)

# Import the pinned build when this store lacks it (one sudo prompt). Runs as
# the user first: root evaluation in reconfigure-system cannot download it.
minde-ensure:
	guix repl -q -- scripts/minde-binary.scm ensure

reconfigure-system: minde-ensure
	sudo $(GUIX_TM) system --load-path=systems reconfigure systems/$$HOSTNAME.scm

reconfigure-home: minde-ensure
	$(GUIX_TM) home --load-path=home reconfigure home/$$USER-home-configuration.scm

qa-ci: qa-guile-only qa-scripts

qa: qa-ci qa-minde-binary qa-emacs

qa-all: qa qa-home-samuel qa-home-levi qa-system-x1 qa-system-t450s

qa-guile-only:
	guile scripts/check-guile-only.scm

qa-scripts:
	guile scripts/check-scripts-compile.scm

qa-minde-binary:
	guix repl -q -- scripts/test-minde-binary.scm

qa-emacs:
	emacs --batch -l home/files/.config/emacs/tests/config-tests.el
	emacs --batch -l home/files/.config/emacs/tests/ui-tests.el -f ert-run-tests-batch-and-exit

qa-home-samuel:
	$(GUIX_TM) home build --dry-run --load-path=home home/samuel-home-configuration.scm

qa-home-levi:
	$(GUIX_TM) home build --dry-run --load-path=home home/levi-home-configuration.scm

qa-system-x1:
	$(GUIX_TM) system build --dry-run --load-path=systems systems/X1.scm

qa-system-t450s:
	$(GUIX_TM) system build --dry-run --load-path=systems systems/T450s.scm
