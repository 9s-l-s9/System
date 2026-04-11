.PHONY: qa qa-all qa-guile-only qa-tests qa-home-samuel qa-home-levi qa-system-x1 qa-system-t450s

qa: qa-guile-only qa-tests

qa-all: qa-guile-only qa-tests qa-home-samuel qa-home-levi qa-system-x1 qa-system-t450s

qa-guile-only:
	guile scripts/check-guile-only.scm

qa-tests:
	GUILE_AUTO_COMPILE=0 guile tests/helix-home-services.scm

qa-home-samuel:
	guix home build --dry-run --load-path=home home/samuel-home-configuration.scm

qa-home-levi:
	guix home build --dry-run --load-path=home home/levi-home-configuration.scm

qa-system-x1:
	guix system build --dry-run --load-path=systems systems/X1.scm

qa-system-t450s:
	guix system build --dry-run --load-path=systems systems/T450s.scm
