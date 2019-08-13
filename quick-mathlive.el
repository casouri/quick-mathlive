;;; quick-mathlive.el --- WYSIWYG math editing      -*- lexical-binding: t; -*-

;; Author: Yuan Fu <casouri@gmail.com>

;;; This file is NOT part of GNU Emacs

;;; Commentary:
;;

;; `quick-mathlive--tex-math-preview-bounds-of-tex-math' is copied from tex-math-preview.el
;; without change, with license information as follow:

;; Copyright 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2015, 2016 Kevin Ryde

;; Author: Kevin Ryde <user42_kevin@yahoo.com.au>
;; Version: 17
;; Keywords: tex, maths
;; URL: http://user42.tuxfamily.org/tex-math-preview/index.html
;; EmacsWiki: TexMathPreview
;; Compatibility: Emacs 21, Emacs 22
;; Incompatibility: XEmacs 21

;; tex-math-preview.el is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; tex-math-preview.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You can get a copy of the GNU General Public License online at
;; <http://www.gnu.org/licenses/>.

;;; Code:
;;


(defvar quick-mathlive--server-buffer "*quick-mathlive*"
  "Buffer that quick-mathlive server process is attached to.")

(defun quick-mathlive ()
  (interactive)
  (unless (get-buffer-process quick-mathlive--server-buffer)
    (quick-mathlive--start-server)
    ;; wait for server to sartup
    (sleep-for 0.5))
  (let* ((ret (quick-mathlive--tex-math-preview-bounds-of-tex-math))
         (beg (car ret))
         (end (cdr ret))
         (old-math-str (buffer-substring-no-properties beg end))
         (new-math-str
          (with-temp-buffer
            (if (eq 0 (call-process "quick-mathlive"
                                    nil (current-buffer)
                                    nil "edit" old-math-str))
                (buffer-string)
              (let ((output (buffer-string)))
                (with-current-buffer (get-buffer-create "*quick-mathlive-error*")
                  (erase-buffer)
                  (insert output)))))))
    (if new-math-str
        (progn (goto-char beg)
               (delete-region beg end)
               (insert new-math-str))
      (message "Error calling mathlive, see *quick-mathlive-error* for error message"))))

(defun quick-mathlive--start-server ()
  "Start background server."
  (let ((process (start-process "quick-mathlive-server"
                                (get-buffer-create quick-mathlive--server-buffer)
                                "quick-mathlive" "start")))
    (set-process-query-on-exit-flag process nil)))

(defun quick-mathlive-quit-server ()
  "Quit background server."
  (interactive)
  (interrupt-process quick-mathlive--server-buffer))

(defun quick-mathlive--tex-math-preview-bounds-of-tex-math ()
  "A `bounds-of-thing-at-point' function for a TeX math expression.
See `tex-math-preview' for what's matched.
The return is a pair of buffer positions (START . END), or nil if
no recognised expression at or surrounding point."

  ;; TeX style $...$ could easily match some huge chunk of the buffer, and
  ;; even @math{...} or <math>...</math> could occur in comments or some
  ;; unrelated context.  So it's not reliable just to take the first of
  ;; these which match, instead the strategy is to check for all forms
  ;; around point and take the one that's the smallest.
  ;;
  ;; Only the start position of the match is considered for "smallest", the
  ;; one that's the shortest distance before point (but covering point of
  ;; course) in the buffer is taken.

  (let (case-fold-search beg end)

    ;; $...$ and $$...$$
    ;; thing-at-point-looking-at doesn't work on "$...$".  The way the start
    ;; and end are the same (ie. "$") breaks the straightforward
    ;; implementation of that function; so the idea here is to search back
    ;; for the starting "$", and one not "\$" escaped, then check the $...$
    ;; extent covers point
    (save-excursion
      (while (and (search-backward "$" nil t) ;; $ not preceded by \
                  (eq ?\\ (char-before))))
      (when (looking-at "\\$+\\(\\(?:\\\\\\$\\|[^$]\\)+?\\)\\$")
        (setq beg (match-beginning 1) end (match-end 1))))

    (dolist (elem
             '(;; <math>...</math>
               (1 . "<math>\\(\\(.\\|\n\\)*?\\)</math>")

               ;; @math{...}
               (1 . "@math{\\(\\(.\\|\n\\)*?\\)}")

               ;; <alt role="tex">$...$</alt>
               ;; <alt role="tex">\[...\]</alt>
               ;; the contents $..$ or \[..\] of the alt can be recognised
               ;; on their own, but with this pattern we can work with point
               ;; in the <alt> part as well as in the expression
               (1 . "<alt\\s-+role=\"tex\">\\$*\\(\\(.\\|\n\\)+?\\)\\$*</alt>")

               ;; \[...\]
               (0 . "\\\\\\[\\(.\\|\n\\)*?\\\\]")

               ;; \(...\)
               (0 . "\\\\(\\(.\\|\n\\)*?\\\\)")

               ;; [;...;]
               (0 . "\\[;\\(.\\|\n\\)*?;]")

               ;; \begin{math}...\end{math}
               ;; \begin{displaymath}...\end{displaymath}
               (0 . "\\\\begin{\\(\\(display\\)?math\\|equation\\|align\\*?\\)}\\(\\(.\\|\n\\)*?\\)\\\\end{\\1}")))

      (when (thing-at-point-looking-at (cdr elem))
        ;; if no other match, or this match is later, then override
        (if (or (not beg)
                (> (match-beginning (car elem)) beg))
            (setq beg (match-beginning (car elem)) end (match-end (car elem))))))

    (and beg
         (cons beg end))))

(provide 'quick-mathlive)

;;; quick-mathlive.el ends here
