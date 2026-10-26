.PHONY: qa qa-all qa-guile-only qa-home-samuel qa-home-levi qa-system-x1 qa-system-t450s \
	update pull reconfigure-system reconfigure-home minde-install

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

reconfigure-system:
	sudo $(GUIX_TM) system --load-path=systems reconfigure systems/$$HOSTNAME.scm

reconfigure-home:
	$(GUIX_TM) home --load-path=home reconfigure home/$$USER-home-configuration.scm

qa: qa-guile-only

qa-all: qa-guile-only qa-home-samuel qa-home-levi qa-system-x1 qa-system-t450s

qa-guile-only:
	guile scripts/check-guile-only.scm

qa-home-samuel:
	$(GUIX_TM) home build --dry-run --load-path=home home/samuel-home-configuration.scm

qa-home-levi:
	$(GUIX_TM) home build --dry-run --load-path=home home/levi-home-configuration.scm

qa-system-x1:
	$(GUIX_TM) system build --dry-run --load-path=systems systems/X1.scm

qa-system-t450s:
	$(GUIX_TM) system build --dry-run --load-path=systems systems/T450s.scm
