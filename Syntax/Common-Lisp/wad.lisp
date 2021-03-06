(cl:in-package #:climacs-syntax-common-lisp)

(defclass basic-wad ()
  (;; This slot contains information about the start line of the parse
   ;; result.  Simple applications might always store the absolute
   ;; line number of the first line of the parse result in this slot.
   ;; Other applications might store a line number relative to some
   ;; other parse result.
   (%start-line :initarg :start-line :accessor start-line)
   ;; This slot contains the difference between the start line and the
   ;; end line.  A value of 0 indicates that the parse result starts
   ;; and ends in the same line.
   (%height :initarg :height :reader height)
   ;; This slot contains the absolute column of the first character in
   ;; this parse result.  A value of 0 indicates that this parse
   ;; result starts in the leftmost position in the source code.
   (%start-column :initarg :start-column :accessor start-column)
   ;; This slot contains the absolute column of the last character of
   ;; the parse result.  The value of this slot can never be 0.  If
   ;; the last character of the parse result is the leftmost character
   ;; in a line, then this slot contains the value 1.
   (%end-column :initarg :end-column :accessor end-column)
   ;; This slot contains the absolute column that the first character
   ;; of this parse result should be positioned in, as computed by the
   ;; rules of indentation.  If this parse result is not the first one
   ;; on the line, then this slot contains NIL.
   (%indentation :initform nil :initarg :indentation :accessor indentation)))

(defclass wad (basic-wad)
  (;; This slot contains the column number of the leftmost known
   ;; non-whitespace character of the parse result.  It may not be
   ;; entirely correct if a reader macro reads character by character
   ;; and such characters happen to be outside the part that is
   ;; returned by a call to READ.  But we only use this information
   ;; for highlighting, and selection.  Not for drawing.
   (%min-column-number :initarg :min-column-number :reader min-column-number)
   ;; This slot contains the column number of the leftmost known
   ;; non-whitespace character of the parse result.  It may not be
   ;; entirely correct for the same reason as the preceding slot.
   (%max-column-number :initarg :max-column-number :reader max-column-number)
   ;; This slot contains the maximum line width of any line that is
   ;; part of the parse result.
   (%max-line-width :initarg :max-line-width :reader max-line-width)
   ;; This slot contains TRUE if and only if the START-LINE slot is
   ;; relative to some other line.
   (%relative-p :initarg :relative-p :accessor relative-p)
   (%children :initarg :children :accessor children)))

(defmethod initialize-instance :after ((object wad) &key)
  (let ((min-column-number (min (start-column object)
                                (end-column object)
                                (reduce #'min (children object)
                                        :initial-value 0
                                        :key #'min-column-number)))
        (max-column-number (max (start-column object)
                                (end-column object)
                                (reduce #'max (children object)
                                        :initial-value 0
                                        :key #'max-column-number))))
    (reinitialize-instance object
                           :min-column-number min-column-number
                           :max-column-number max-column-number)))

(defmethod print-object ((object wad) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "(~d,~d -> ~d,~d) rel: ~s"
            (start-line object)
            (start-column object)
            (if (relative-p object)
                (height object)
                (end-line object))
            (end-column object)
            (relative-p object))))

;;; Define an indirection for MAKE-INSTANCE for creating parse
;;; results.  The main purpose is so that the creation of parse
;;; results can be traced.
(defun make-wad (class &rest initargs)
  (apply #'make-instance class initargs))

(defclass expression-wad (wad)
  ((%expression :initarg :expression :accessor expression)))

(defclass no-expression-wad (wad)
  ())

;;; This class is the base class of all comment wads.
(defclass comment-wad (no-expression-wad)
  ())

;;; This class is used for a block comment introduced by #|.
(defclass block-comment-wad (comment-wad)
  ())

;;; This class is used for a comment introduced by one or more
;;; semicolons.
(defclass semicolon-comment-wad (comment-wad)
  (;; This slot contains the number of consecutive initial semicolons
   ;; of the comment.
   (%semicolon-count :initarg :semicolon-count :reader semicolon-count)))

(defclass error-wad (wad)
  ())

(defclass eof-wad (wad)
  ())

(defgeneric relative-to-absolute (wad offset)
  (:method ((p wad) offset)
    (assert (relative-p p))
    (incf (start-line p) offset)
    (setf (relative-p p) nil)))

(defgeneric absolute-to-relative (wad offset)
  (:method ((p wad) offset)
    (assert (not (relative-p p)))
    (decf (start-line p) offset)
    (setf (relative-p p) t)))

;;; RELATIVE-WADS is a list of parse results where the start line of
;;; the first element is relative to OFFSET, and the start line of
;;; each of the other elements is relative to the start line of the
;;; preceding element.  Modify the parse results in the list so that
;;; they are absolute.  Return the original list, now containing the
;;; modified parse results.
(defun make-absolute (relative-wads offset)
  (loop with base = offset
        for wad in relative-wads
        do (relative-to-absolute wad base)
           (setf base (start-line wad)))
  relative-wads)

;;; ABSOLUTE-WADS is a list of absolute parse results.  Modify the
;;; parse results in the list so that the start line of the first
;;; element is absolute to OFFSET, and the start line of each of the
;;; other elements is relative to the start line of the preceding
;;; element.  Return the original list, now containing the modified
;;; parse results.
(defun make-relative (absolute-wads offset)
  (loop with base = offset
        for wad in absolute-wads
        for start-line = (start-line wad)
        do (absolute-to-relative wad base)
           (setf base start-line))
  absolute-wads)

(defgeneric end-line (wad)
  (:method ((p wad))
    (assert (not (relative-p p)))
    (+ (start-line p) (height p))))
