;; Every channel is pinned to a commit (taken from the running system's
;; provenance, i.e. a combination that is known to build and boot). Pinning
;; matters for speed as much as reproducibility: `guix time-machine` (the
;; Makefile QA targets) caches its profile keyed on the channel set, and a
;; floating branch invalidates that cache on every upstream push -- each QA
;; run then re-fetches and rebuilds channel derivations. With pins, QA
;; reuses the cache and starts in seconds.
;;
;; To update: bump the commit(s), run `make qa-all`, reconfigure, and only
;; then commit the new pins. `guix time-machine -C channels.scm -- describe
;; -f channels` prints the resolved set in this exact format.
(list (channel
        (name 'guix)
        (url "https://git.savannah.gnu.org/git/guix.git")
        (branch "master")
        (commit "0802546301e0a9fab4d43b872ddac96c753a2430")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
              "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
      (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix")
        (branch "master")
        (commit "66ab7fff7a4ee0592c708651556ef3805c85068f")
        (introduction
          (make-channel-introduction
            "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
            (openpgp-fingerprint
             "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
      (channel
       (name 'binary-guix)
       (url "https://codeberg.org/s-l-s/BinaryGuix")
       (branch "main")
       (commit "503b1033a69f1fc493734d49ffcf2b873f0ad898"))

      (channel
        (name 'pantherx)
        (url "https://codeberg.org/gofranz/panther.git")
        (branch "master")
        (commit "7ce17d5c86602ad297bff5355f1d0b3aac6c52fa")
        ;; Enable signature verification
        (introduction
         (make-channel-introduction
          "54b4056ac571611892c743b65f4c47dc298c49da"
          (openpgp-fingerprint
           "A36A D41E ECC7 A871 1003  5D24 524F EB1A 9D33 C9CB"))))
      )
