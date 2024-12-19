(require 'gptel)
;; (gptel-make-ollama
;;  "Ollama"                               ;Any name of your choosing
;;  :host "localhost:11434"                ;Where it's running
;;  :models '("llama2:latest")            ;Installed models
;;  :stream t)                             ;Stream responses


;; OPTIONAL configuration
(setq-default gptel-model "orca2:13b" ;Pick your default model
              gptel-backend
	      (gptel-make-ollama
	       "Ollama"                               ;Any name of your choosing
	       :host "localhost:11434"                ;Where it's running
	       :stream t)                             ;Stream responses
	      )
(provide 'gptel-config)
