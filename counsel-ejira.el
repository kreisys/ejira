;;; counsel-ejira.el --- Ivy-completion for ejira.el -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2019 Henrik Nyman

;; Author: Shay Bergmann <henrikjohannesnyman@gmail.com>
;; URL: https://github.com/nyyManni/ejira
;; Keywords: jira, org, ivy, counsel
;; Version: 1.0
;; Package-Requires: ((ejira "1.0") (org "8.3") (ivy-rich "20191209.1200") (counsel "0.8.0") (dash "1.0"))

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Ivy-integration to ejira.el.

;;; Code:

(require 'ivy)

(defun org-fancy-priority-get-value-with-face (priority)
  (let ((fancy-str (alist-get priority org-fancy-priorities-list))
        (face (alist-get priority org-priority-faces)))
    (propertize fancy-str 'face face)))

(defun counsel-ejira--issue-matcher (regexp candidates)
  "Return REGEXP matching CANDIDATES.
Match issue summaries as well"
  (ivy--re-filter regexp candidates (lambda (re-str)
                                      (lambda (key)
                                        (string-match-p
                                         re-str
                                         (format "%s %s"
                                                 key
                                                 (ejira--get-property key "ITEM")))))))

(defun counsel-ejira--sort-by-priority (l r)
  (let ((lp (string-to-char (ejira--get-property l "PRIORITY")))
        (rp (string-to-char (ejira--get-property r "PRIORITY"))))
    (< lp rp)))

(defun counsel-ejira-jql (jql)
  (interactive)
  (counsel-ejira--init)
  (let ((ivy-sort-functions-alist '((counsel-ejira-jql . counsel-ejira--sort-by-priority))))
    (ivy-read "Pick: " (ejira--jql jql)
              :sort t
              :matcher #'counsel-ejira--issue-matcher
              :caller 'counsel-ejira-jql)))

(defun counsel-ejira--key-transformer (key) (format " [%s]" key))
(defun counsel-ejira--summary-transformer (key) (ejira--get-property key "ITEM"))
(defun counsel-ejira--status-transformer (key) (ejira--get-property key "STATUS"))
(defun counsel-ejira--priority-transformer (key) (-> (ejira--get-property key "PRIORITY")
                                                     string-to-char
                                                     org-fancy-priority-get-value-with-face))
(defun counsel-ejira--type-transformer (key) (ejira--get-property key "Issuetype"))

(defun counsel-ejira--init ()
  (setq ivy-rich-display-transformers-list
        (plist-put ivy-rich-display-transformers-list
                   'counsel-ejira-jql
                   '(:columns
                     ((counsel-ejira--key-transformer (:width 10)) ; the original transformer
                      (counsel-ejira--priority-transformer (:width 3))
                      (counsel-ejira--type-transformer (:width 15 :face font-lock-doc-face))
                      (counsel-ejira--status-transformer (:width 15 :face font-lock-doc-face))
                      (counsel-ejira--summary-transformer (:face font-lock-doc-face))))))

  (ivy-rich-mode -1)
  (ivy-rich-mode +1))

(provide 'counsel-ejira)
