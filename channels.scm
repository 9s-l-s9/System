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
       (name 'radix)
       (url "https://codeberg.org/anemofilia/radix.git")
       (branch "main")
       (commit "0669b69d8cdfd7cc3ceda31fee1de603adf2d30d")
       (introduction
	(make-channel-introduction
	 "f9130e11e35d2c147c6764ef85542dc58dc09c4f"
	 (openpgp-fingerprint
          "F164 709E 5FC7 B32B AEC7  9F37 1F2E 76AC E3F5 31C8"))))


      (channel
       (name 'rosenthal)
       (url "https://codeberg.org/hako/rosenthal.git")
       (branch "trunk")
       (commit "3a0838e5e0ac96c5935a5e5e44b73bdfb1b68450")
       (introduction
	(make-channel-introduction
	 "7677db76330121a901604dfbad19077893865f35"
	 (openpgp-fingerprint
	  "13E7 6CD6 E649 C28C 3385  4DF5 5E5A A665 6149 17F7"))))


      (channel
       (name 'guix-science)
       (url "https://codeberg.org/guix-science/guix-science.git")
       (branch "master")
       (commit "8b23b5c024aaff671ab4008ad8d253480788a1cc")
       (introduction
	(make-channel-introduction
	 "b1fe5aaff3ab48e798a4cce02f0212bc91f423dc"
	 (openpgp-fingerprint
	  "CA4F 8CF4 37D7 478F DA05  5FD4 4213 7701 1A37 8446"))))

      (channel
       (name 'saayix)
       (branch "entropy")
       (commit "26bb1d0d253d3288a80effc9ea2784fdf0fff662")
       (url "https://codeberg.org/look/saayix")
       (introduction
	(make-channel-introduction
	 "12540f593092e9a177eb8a974a57bb4892327752"
	 (openpgp-fingerprint
          "3FFA 7335 973E 0A49 47FC  0A8C 38D5 96BE 07D3 34AB"))))

      (channel
       (name 'rde)
       (url "https://git.sr.ht/~abcdw/rde")
       (branch "master")
       (commit "6ccd368e0a0484e724205f9d608d2eb1ab706ac3")
       (introduction
	(make-channel-introduction
	 "257cebd587b66e4d865b3537a9a88cccd7107c95"
	 (openpgp-fingerprint
	  "2841 9AC6 5038 7440 C7E9  2FFA 2208 D209 58C1 DEB0"))))

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
