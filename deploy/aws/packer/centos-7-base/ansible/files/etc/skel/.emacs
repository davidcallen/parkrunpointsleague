;; ========== Prevent Emacs from making backup files ==========
(setq make-backup-files nil)

;; Set tab width
(setq tab-width 4)
(add-hook 'fundamental-mode-hook
	    (lambda ()
	          "Set tab width to 4"
		      (setq tab-width 4)))
