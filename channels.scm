(list (channel
        (name 'guix)
        (url "https://git.savannah.gnu.org/git/guix.git")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
              "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
      (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix")
        (introduction
          (make-channel-introduction
            "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
            (openpgp-fingerprint
             "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
      (channel
       (name 'binary-guix)
       (url "https://codeberg.org/s-l-s/BinaryGuix")
       (branch "main"))
      
      (channel
       (name 'radix)
       (url "https://codeberg.org/anemofilia/radix.git")
       (branch "main")
       (introduction
	(make-channel-introduction
	 "f9130e11e35d2c147c6764ef85542dc58dc09c4f"
	 (openpgp-fingerprint
          "F164 709E 5FC7 B32B AEC7  9F37 1F2E 76AC E3F5 31C8"))))


      (channel
       (name 'rosenthal)
       (url "https://codeberg.org/hako/rosenthal.git")
       (branch "trunk")
       (introduction
	(make-channel-introduction
	 "7677db76330121a901604dfbad19077893865f35"
	 (openpgp-fingerprint
	  "13E7 6CD6 E649 C28C 3385  4DF5 5E5A A665 6149 17F7"))))


      (channel
       (name 'guix-science)
       (url "https://codeberg.org/guix-science/guix-science.git")
       (introduction
	(make-channel-introduction
	 "b1fe5aaff3ab48e798a4cce02f0212bc91f423dc"
	 (openpgp-fingerprint
	  "CA4F 8CF4 37D7 478F DA05  5FD4 4213 7701 1A37 8446"))))

      (channel
       (name 'saayix)
       (branch "entropy")
       (url "https://codeberg.org/look/saayix")
       (introduction
	(make-channel-introduction
	 "12540f593092e9a177eb8a974a57bb4892327752"
	 (openpgp-fingerprint
          "3FFA 7335 973E 0A49 47FC  0A8C 38D5 96BE 07D3 34AB"))))

      (channel
       (name 'rde)
       (url "https://git.sr.ht/~abcdw/rde")
       (introduction
	(make-channel-introduction
	 "257cebd587b66e4d865b3537a9a88cccd7107c95"
	 (openpgp-fingerprint
	  "2841 9AC6 5038 7440 C7E9  2FFA 2208 D209 58C1 DEB0"))))

      (channel 
        (name 'pantherx)
        (url "https://codeberg.org/gofranz/panther.git")
        ;; Enable signature verification
        (introduction
         (make-channel-introduction
          "54b4056ac571611892c743b65f4c47dc298c49da"
          (openpgp-fingerprint
           "A36A D41E ECC7 A871 1003  5D24 524F EB1A 9D33 C9CB"))))
      )
