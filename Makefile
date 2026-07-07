.PHONY: qa qa-all qa-guile-only qa-home-samuel qa-home-levi qa-system-x1 qa-system-t450s

qa: qa-guile-only

qa-all: qa-guile-only qa-home-samuel qa-home-levi qa-system-x1 qa-system-t450s

qa-guile-only:
	guile scripts/check-guile-only.scm

# QA runs through time-machine so evaluation uses the channels the system
# is actually built from (a plain `guix pull` profile may lack nonguix etc.).
GUIX_TM = guix time-machine -C channels.scm --

qa-home-samuel:
	$(GUIX_TM) home build --dry-run --load-path=home home/samuel-home-configuration.scm

qa-home-levi:
	$(GUIX_TM) home build --dry-run --load-path=home home/levi-home-configuration.scm

qa-system-x1:
	$(GUIX_TM) system build --dry-run --load-path=systems systems/X1.scm

qa-system-t450s:
	$(GUIX_TM) system build --dry-run --load-path=systems systems/T450s.scm
