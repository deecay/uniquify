;;  uniquify.l - uniquify.el for xyzzy
#|
  by Deecay

 ●説明

 emacs用のuniquify.elをDeecayがxyzzy用に移植したものです。

 emacs lisp 移植キットを使わせてもらいました。ありがとうございます。
 http://members.at.infoseek.co.jp/osuneko/xyzzy/xyzzy.html


 xyzzyは同じファイル名のついたファイルを開くと、ファイル名の後に<2>, <3>
 のような番号をつけることで一意なバッファ名を生成します。このuniquifyは
 このような動作を置き換え、ファイル名の一部を使って一意なバッファ名を
 生成するようにします。
 たとえば、/u/mernst/tmp/Makefile と /usr/projects/zaphod/Makefile を
 開いているバッファの名前は、Makefile|tmp と Makefile|zaphod のようになります。
 これ以外にもいくつかの生成方式が選べます。各種設定を見てください。
 一部の機能はファイル内の英語documentationと違うかもしれません。



 ●インストール

 uniquify.lをsite-lispフォルダにコピー。emacs 移植キットがインストールされて
 いないならemacs.lとelisp.lもコピー。必要に応じてバイトコンパイル。



 ●初期設定

 .xyzzyかsiteinit.lに

 (require "elisp")
 (require "uniquify")
 (setq elisp::uniquify-buffer-name-style 'elisp::post-forward)

 を追加。



 ●各種設定

 elisp::uniquify-buffer-name-style
   /foo/bar/mumble/name と /baz/quux/mumble/name の二つのファイルを開くと
     elisp::forward         bar/mumble/name  quux/mumble/name
     elisp::reverse         name\\mumble\\bar  name\\mumble\\quux
     elisp::post-forward    name|bar/mumble  name|quux/mumble
     elisp::post-forward-angle-brackets   name<bar/mumble>  name<quux/mumble>
     nil                    name name<2>
   のように表示方法を選ぶことができます。

 elisp::uniquify-after-kill-buffer-p t
  t ならバッファがkillされた後に重複バッファ名がないかチェックをします。
  つまり必要がなくなったバッファ名変更は解除されます。

 elisp::uniquify-ignore-buffers-re "^\\*\\(un\\)?sent "
  バッファ名が重複していたとしても無視するバッファを指定する正規表現。

 elisp::uniquify-min-dir-content 0
  後ろ向きにたどるフォルダ名の最小の個数。
  たとえば 1 にすると必ずバッファ名にフォルダ名が一つつきます。

 elisp::uniquify-separator nil
  post-forward形式のセパレーター文字。何も指定しなければ "|" になる。



 ●お約束の表示
 このソフトはフリーウェアであり、法的な意味でその正常な動作を保証しません。
 ユーザが被るかもしれない損害を、法的な意味も含めて作者は補償しません。


 ●ライセンス
   GNU GPLです。(たぶん)


 ●コンタクト
   http://megahurtz.bblog.jp/
|#


;;; uniquify.el --- unique buffer names dependent on file name

;; Copyright (c) 1989, 1995, 1996, 1997, 2001 Free Software Foundation, Inc.

;; Author: Dick King <king@reasoning.com>
;; Maintainer: FSF
;; Keywords: files
;; Created: 15 May 86

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Emacs's standard method for making buffer names unique adds <2>, <3>,
;; etc. to the end of (all but one of) the buffers.  This file replaces
;; that behavior, for buffers visiting files and dired buffers, with a
;; uniquification that adds parts of the file name until the buffer names
;; are unique.  For instance, buffers visiting /u/mernst/tmp/Makefile and
;; /usr/projects/zaphod/Makefile would be named Makefile|tmp and
;; Makefile|zaphod, respectively (instead of Makefile and Makefile<2>).
;; Other buffer name styles are also available.

;; To use this file, do (require 'uniquify)
;; and set uniquify-buffer-name-style to one of its non-nil alternative values.

;; For other options, see "User-visible variables", below.

;; A version of uniquify.el that works under Emacs 18, Emacs 19, XEmacs,
;; and InfoDock is available from the maintainer.

;;; Change Log:

;; Originally by Dick King <king@reasoning.com> 15 May 86
;; Converted for Emacs 18 by Stephen Gildea <gildea@stop.mail-abuse.org>
;; Make uniquify-min-dir-content 0 truly non-invasive.  gildea 23 May 89
;; Some cleanup.  uniquify-min-dir-content default 0.  gildea 01 Jun 89
;; Don't rename to "".  Michael Ernst <mernst@theory.lcs.mit.edu> 15 Jun 94
;; Add kill-buffer-hook.  Kenneth Manheimer <ken.manheimer@nist.gov> 09 May 95
;; Add advice for rename-buffer and create-file-buffer, handle dired buffers,
;;  kill-buffer-rationalize-buffer-names-p, documentation.  mernst 24 May 95
;; Remove free variables, fix typos.  mernst 5 Jun 95
;; Efficiently support Emacs 19.27 & earlier.  ken.manheimer, mernst 10 Jun 95
;; Rename user options to "uniquify-...", add uniquify-reverse-dir-content-p,
;;  add uniquify-ask-about-buffer-names-p.  king, mernst 13 Jun 95
;; Prefix functions by "uniquify-..."; rename mnemonic-buffer-names to
;;  uniquify-buffer-name-style; add 'forward and 'post-forward-angle-brackets
;;  styles; remove uniquify-reverse-dir-content-p; add
;;  uniquify-trailing-separator-p.  mernst 4 Aug 95
;; Don't call expand-file-name on nil.  mernst 7 Jan 96
;; Check whether list-buffers-directory is bound.  mernst 11 Oct 96
;; Ignore non-file non-dired buffers. Colin Rafferty <craffert@ml.com> 3 Mar 97
;; Use last component, not "", for file name of directories.  mernst 27 Jun 97
;; Use directory-file-name; code cleanup.  mernst 6 Sep 97
;; Add uniquify-ignore-buffers-re.
;;  Andre Srinivasan <andre@visigenic.com> 9 Sep 97
;; Add uniquify-list-buffers-directory-modes
;;   Stefan Monnier <monnier@cs.yale.edu> 17 Nov 2000
;; Algorithm and data structure changed to reduce consing with lots of buffers
;;   Francesco Potorti <pot@gnu.org> (ideas by rms and monnier) 2001-07-18

;; Valuable feedback was provided by
;; Paul Smith <psmith@baynetworks.com>,
;; Alastair Burt <burt@dfki.uni-kl.de>,
;; Bob Weiner <weiner@footloose.sps.mot.com>,
;; Albert L. Ting <alt@vlibs.com>,
;; gyro@reasoning.com,
;; Bryan O'Sullivan <bos@eng.sun.com>.


;;; Code:

(in-package "elisp")
(require "emacs")

;;; User-visible variables

(defcustom uniquify-buffer-name-style nil
  "*If non-nil, buffer names are uniquified with parts of directory name.
The value determines the buffer name style and is one of `forward',
`reverse', `post-forward', or `post-forward-angle-brackets'.
For example, files `/foo/bar/mumble/name' and `/baz/quux/mumble/name'
would have the following buffer names in the various styles:
  forward        bar/mumble/name  quux/mumble/name
  reverse        name\\mumble\\bar  name\\mumble\\quux
  post-forward   name|bar/mumble  name|quux/mumble
  post-forward-angle-brackets   name<bar/mumble>  name<quux/mumble>
  nil            name  name<2>"
  :type '(radio (const forward)
		(const reverse)
		(const post-forward)
		(const post-forward-angle-brackets)
		(const :tag "standard Emacs behavior (nil)" nil))
  :require 'uniquify)

(defcustom uniquify-after-kill-buffer-p t
  "*If non-nil, rerationalize buffer names after a buffer has been killed.
This can be dangerous if Emacs Lisp code is keeping track of buffers by their
names (rather than keeping pointers to the buffers themselves)."
  :type 'boolean)

(defcustom uniquify-ask-about-buffer-names-p nil
  "*If non-nil, permit user to choose names for buffers with same base file.
If the user chooses to name a buffer, uniquification is preempted and no
other buffer names are changed."
  :type 'boolean)

;; The default value matches certain Gnus buffers.
(defcustom uniquify-ignore-buffers-re "^\\*\\(un\\)?sent "
  "*Regular expression matching buffer names that should not be uniquified.
For instance, set this to \"^draft-[0-9]+$\" to avoid having uniquify rename
draft buffers even if `uniquify-after-kill-buffer-p' is non-nil and the
visited file name isn't the same as that of the buffer."
  :type '(choice (const :tag "Uniquify all buffers" nil) regexp))

(defcustom uniquify-min-dir-content 0
  "*Minimum number of directory name components included in buffer name."
  :type 'integer)

(defcustom uniquify-separator nil
  "*String separator for buffer name components.
When `uniquify-buffer-name-style' is `post-forward', separates
base file name from directory part in buffer names (default \"|\").
When `uniquify-buffer-name-style' is `reverse', separates all
file name components (default \"\\\")."
  :type '(choice (const nil) string))

(defcustom uniquify-trailing-separator-p nil
  "*If non-nil, add a file name separator to dired buffer names.
If `uniquify-buffer-name-style' is `forward', add the separator at the end;
if it is `reverse', add the separator at the beginning; otherwise, this
variable is ignored."
  :type 'boolean)

(defvar uniquify-list-buffers-directory-modes '(dired-mode cvs-mode)
  "List of modes for which uniquify should obey `list-buffers-directory'.
That means that when `buffer-file-name' is set to nil, `list-buffers-directory'
contains the name of the directory which the buffer is visiting.")

;;; Utilities

;; uniquify-fix-list data structure
(defstruct (uniquify-item
	    (:constructor nil) (:copier nil)
	    (:constructor uniquify-make-item (base filename buffer proposed)))
  base filename buffer proposed)

;; Internal variables used free
(defvar uniquify-possibly-resolvable nil)

;;; Main entry point.

(defmacro assert (test-form &rest rest)
  "Macro for it is not defined in xyzzy nor in emacs.l.
Comments are welcomed."
	(let ((places (first rest))
		   (msg    (second rest))
		   (args   (cddr rest)))
		(declare (ignore places))
		(if (null msg)
		   `(unless ,test-form (error "Assertion failed: ~A" ',test-form))
		  `(unless ,test-form (error ,msg ,@args)))))

(defun directory-file-name (filename)
  "Defined for it is not defined in xyzzy nor in emacs.l.
Comments are more than welcomed."
  (remove-trail-slash filename))

(defmacro with-current-buffer (buffer &rest body)
  "Defined for it is not defined in xyzzy nor in emacs.l.
Comments are truely welcomed."
  `(save-window-excursion
     (ignore-errors
	 (progn
       (set-buffer ,buffer)
	   ,@body))))

(defun uniquify-rationalize-file-buffer-names (&optional newbuffile newbuf)
  "Make file buffer names unique by adding segments from file name.
If `uniquify-min-dir-content' > 0, always pulls that many
file name elements.
Arguments NEWBUFFILE and NEWBUF cause only a subset of buffers to be renamed."
  (interactive)
  (when newbuffile
    (setq newbuffile (expand-file-name (directory-file-name newbuffile))))
  (let ((fix-list nil)
	(base (and newbuffile (file-name-nondirectory newbuffile))))
    (dolist (buffer (buffer-list))
      (let ((bufname (buffer-name buffer))
	    bfn rawname)
	(when (and (not (and uniquify-ignore-buffers-re
			     (string-match uniquify-ignore-buffers-re
					   bufname)))
		   (setq bfn (if (eq buffer newbuf) newbuffile
			       (uniquify-buffer-file-name buffer)))
		   (setq rawname (file-name-nondirectory bfn))
		   (or (null base) (equal rawname base)))
	  (when (setq bfn (file-name-directory bfn)) ;Strip off the `base'.
	    (setq bfn (directory-file-name bfn)))    ;Strip trailing slash.
	  (push (uniquify-make-item rawname bfn buffer
				    (uniquify-get-proposed-name rawname bfn))
		fix-list))))
    ;; selects buffers whose names may need changing, and others that
    ;; may conflict, then bring conflicting names together
    (uniquify-rationalize-a-list fix-list)))

;; uniquify's version of buffer-file-name; result never contains trailing slash
(defun uniquify-buffer-file-name (buffer)
  "Return name of file BUFFER is visiting, or nil if none.
Works on ordinary file-visiting buffers and buffers whose mode is mentioned
in `uniquify-list-buffers-directory-modes', otherwise returns nil."
  (or (buffer-file-name buffer)
      (with-current-buffer buffer
	(and
	 (memq major-mode uniquify-list-buffers-directory-modes)
	 (if (boundp 'list-buffers-directory) ; XEmacs mightn't define this
	     (and list-buffers-directory
		  (directory-file-name list-buffers-directory))
	   ;; don't use default-directory if dired-directory is nil
	   (and dired-directory
		(expand-file-name
		 (directory-file-name
		  (if (consp dired-directory)
		      (car dired-directory)
		    dired-directory)))))))))

(defun uniquify-item-greaterp (item1 item2)
  (string-lessp (uniquify-item-proposed item2)
		(uniquify-item-proposed item1)))

(defun uniquify-rationalize-a-list (fix-list &optional depth)
  (unless depth (setq depth uniquify-min-dir-content))
  (let (conflicting-sublist	; all elements have the same proposed name
	(old-proposed "")
	proposed)
    ;; Divide fix-list into items with same proposed names and pass them
    ;; to uniquify-rationalize-conflicting-sublist.
    (dolist (item (sort fix-list 'uniquify-item-greaterp))
      (setq proposed (uniquify-item-proposed item))
      (unless (equal proposed old-proposed)
	(uniquify-rationalize-conflicting-sublist conflicting-sublist
						  old-proposed depth)
	(setq conflicting-sublist nil))
      (push item conflicting-sublist)
      (setq old-proposed proposed))
    (uniquify-rationalize-conflicting-sublist conflicting-sublist
					      old-proposed depth)))

(defun uniquify-get-proposed-name (base filename &optional depth)
  (unless depth (setq depth uniquify-min-dir-content))
  (assert (equal (directory-file-name filename) filename))  ;No trailing slash.

  ;; Distinguish directories by adding extra separator.
  (if (and uniquify-trailing-separator-p
	   (file-directory-p (expand-file-name base filename))
	   (not (string-equal base "")))
      (cond ((eq uniquify-buffer-name-style 'forward)
	     (setq base (file-name-as-directory base)))
	    ;; (setq base (concat base "/")))
	    ((eq uniquify-buffer-name-style 'reverse)
	     (setq base (concat (or uniquify-separator "\\") base)))))

  (let ((extra-string nil)
	(n depth))
    (while (and (> n 0) filename)
      (let ((file (file-name-nondirectory filename)))
	(when (setq filename (file-name-directory filename))
	  (setq filename (directory-file-name filename)))
	(setq n (1- n))
	(push (if (zerop (length file)) ;nil or "".
		  (prog1 "" (setq filename nil)) ;Could be `filename' iso "".
		file)
	      extra-string)))
    (when (zerop n)
      (if (and filename extra-string
	       (equal filename (file-name-directory filename)))
	  ;; We're just before the root.  Let's add the leading / already.
	  ;; With "/a/b"+"/c/d/b" this leads to "/a/b" and "d/b" but with
	  ;; "/a/b"+"/c/a/b" this leads to "/a/b" and "a/b".
	  (push "" extra-string))
      (setq uniquify-possibly-resolvable t))

    (cond
     ((null extra-string) base)
     ((string-equal base "") ;Happens for dired buffers on the root directory.
      (mapconcat 'identity extra-string "/"))
     ((eq uniquify-buffer-name-style 'reverse)
      (mapconcat 'identity
		 (cons base (nreverse extra-string))
		 (or uniquify-separator "\\")))
     ((eq uniquify-buffer-name-style 'forward)
      (mapconcat 'identity (nconc extra-string (list base))
		 "/"))
     ((eq uniquify-buffer-name-style 'post-forward)
      (concat base (or uniquify-separator "|")
	      (mapconcat 'identity extra-string "/")))
     ((eq uniquify-buffer-name-style 'post-forward-angle-brackets)
      (concat base "<" (mapconcat 'identity extra-string "/")
	      ">"))
     (t (error "Bad value for uniquify-buffer-name-style: ~A"
	       uniquify-buffer-name-style)))))


;; Deal with conflicting-sublist, all of whose elements have identical
;; "base" components.
(defun uniquify-rationalize-conflicting-sublist (conf-list old-name depth)
  (when conf-list
    (if (or (cdr conf-list)
	    ;; Check that the proposed name doesn't conflict with some
	    ;; existing buffer.
	    (let ((buf (get-buffer old-name)))
	      (and buf (not (eq buf (uniquify-item-buffer (car conf-list)))))))
	(when uniquify-possibly-resolvable
	  (setq uniquify-possibly-resolvable nil
		depth (1+ depth))
	  (dolist (item conf-list)
	    (setf (uniquify-item-proposed item)
		  (uniquify-get-proposed-name
		   (uniquify-item-base item)
		   (uniquify-item-filename item)
		   depth)))
	  (uniquify-rationalize-a-list conf-list depth))
      (unless (string= old-name "")
	(uniquify-rename-buffer (car conf-list) old-name)))))


(defun uniquify-rename-buffer (item newname)
  (let ((buffer (uniquify-item-buffer item)))
    (unless (equal newname (buffer-name buffer))
      (with-current-buffer buffer
	(let ((uniquify-buffer-name-style nil))	;Avoid hooks on rename-buffer.
	  ;; Pass the `unique' arg, just in case.
	  (rename-buffer newname t))))))

;;; Hooks from the rest of Emacs

;; The logical place to put all this code is in generate-new-buffer-name.
;; It's written in C, so we would add a generate-new-buffer-name-function
;; which, if non-nil, would be called instead of the C.  One problem with
;; that is that generate-new-buffer-name takes a potential buffer name as
;; its argument -- not other information, such as what file the buffer will
;; visit.

;; The below solution works because generate-new-buffer-name is called
;; only by rename-buffer (which, as of 19.29, is never called from C) and
;; generate-new-buffer, which is called only by Lisp functions
;; create-file-buffer and rename-uniquely.  Rename-uniquely generally
;; isn't used for buffers visiting files, so it's sufficient to hook
;; rename-buffer and create-file-buffer.  (Setting find-file-hook isn't
;; sufficient.)

(add-hook '*find-file-hooks* 'uniquify-rationalize-file-buffer-names)

; (defadvice rename-buffer (after rename-buffer-uniquify activate)
;   "Uniquify buffer names with parts of directory name."
;   (if (and uniquify-buffer-name-style
; 	   ;; UNIQUE argument
; 	   (ad-get-arg 1))
;       (progn
; 	(if uniquify-after-kill-buffer-p
; 	    ;; call with no argument; rationalize vs. old name as well as new
; 	    (uniquify-rationalize-file-buffer-names)
; 	  ;; call with argument: rationalize vs. new name only
; 	  (uniquify-rationalize-file-buffer-names
; 	   (uniquify-buffer-file-name (current-buffer)) (current-buffer)))
; 	(setq ad-return-value (buffer-name (current-buffer))))))
; 
; (defadvice create-file-buffer (after create-file-buffer-uniquify activate)
;   "Uniquify buffer names with parts of directory name."
;   (if uniquify-buffer-name-style
;       (uniquify-rationalize-file-buffer-names (ad-get-arg 0) ad-return-value)))

;; Buffer deletion
;; Rerationalize after a buffer is killed, to reduce coinciding buffer names.
;; This mechanism uses `kill-buffer-hook', which runs *before* deletion.
;; That means that the kill-buffer-hook function cannot just delete the
;; buffer -- it has to set something to do the rationalization *later*.
;; It actually puts another function on `post-command-hook'.  This other
;; function runs the rationalization and then removes itself from the hook.
;; Is there a better way to accomplish this?
;; (This ought to set some global variables so the work is done only for
;; buffers with names similar to the deleted buffer.  -MDE)

(defun uniquify-delay-rationalize-file-buffer-names ()
  "Add `delayed-uniquify-rationalize-file-buffer-names' to `post-command-hook'.
For use on, eg, `kill-buffer-hook', to rationalize *after* buffer deletion."
  (if (and uniquify-buffer-name-style
	   uniquify-after-kill-buffer-p
	   ;; Rationalizing is costly, so don't do it for temp buffers.
	   (uniquify-buffer-file-name (current-buffer)))
      (add-hook '*post-command-hook*
		'uniquify-delayed-rationalize-file-buffer-names t))
  t)

(defun uniquify-delayed-rationalize-file-buffer-names ()
  "Rerationalize buffer names and remove self from `post-command-hook'.
See also `delay-rationalize-file-buffer-names' for hook setter."
  (uniquify-rationalize-file-buffer-names)
  (delete-hook '*post-command-hook*
	       'uniquify-delayed-rationalize-file-buffer-names))

;; Ideally we'd like to add it buffer-locally, but that doesn't work
;; because kill-buffer-hook is not permanent-local :-(
(add-hook '*query-kill-buffer-hook* 'uniquify-delay-rationalize-file-buffer-names)

(provide 'uniquify)
;;; uniquify.el ends here
