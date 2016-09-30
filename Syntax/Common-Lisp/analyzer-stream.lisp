(cl:in-package #:climacs-syntax-common-lisp)

(defclass analyzer-stream (folio-stream)
  ((%analyzer :initarg :analyzer :reader analyzer)))

;;; Make sure that the first parse result that we consider recycling
;;; starts at or beyond the current stream position.  Parse results
;;; that start before the current stream position are either no longer
;;; valid, or have been recycled already, so we remove them.  Two
;;; places are considered for recycling, namely the list of residual
;;; parse results and the suffix.
(defun pop-to-stream-position (analyzer-stream)
  (let ((analyzer (analyzer analyzer-stream)))
    (loop until (or (null (residue analyzer))
		    (> (start-line (first (residue analyzer)))
		       (current-line-number analyzer-stream))
		    (and (= (start-line (first (residue analyzer)))
			    (current-line-number analyzer-stream))
			 (>= (start-column (first (residue analyzer)))
			     (current-item-number analyzer-stream))))
	  do (pop (residue analyzer)))
    (when (null (residue analyzer))
      (loop until (or (null (suffix analyzer))
		      (> (start-line (first (suffix analyzer)))
			 (current-line-number analyzer-stream))
		      (and (= (start-line (first (suffix analyzer)))
			      (current-line-number analyzer-stream))
			   (>= (start-column (first (suffix analyzer)))
			       (current-item-number analyzer-stream))))
	    do (pop-from-suffix analyzer)))))

(defun cached-parse-result (analyzer-stream)
  (let* ((analyzer (analyzer analyzer-stream))
	 (residue (residue analyzer))
	 (suffix (suffix analyzer)))
    (cond ((not (null residue))
	   (if (and (= (start-line (first residue))
		       (current-line-number analyzer-stream))
		    (= (start-column (first residue))
		       (current-item-number analyzer-stream)))
	       (first residue)
	       nil))
	  ((not (null suffix))
	   (if (and (= (start-line (first suffix))
		       (current-line-number analyzer-stream))
		    (= (start-column (first suffix))
		       (current-item-number analyzer-stream)))
	       (first suffix)
	       nil))
	  (t nil))))

(defun advance-stream-to-beyond-parse-result (analyzer-stream parse-result)
  (setf (current-line-number analyzer-stream)
	(+ (start-line parse-result)
	   (end-line parse-result)))
  (setf (current-item-number analyzer-stream)
	(end-column parse-result))
  (read-char input-stream nil nil))

(defmethod sicl-reader:read-common
    ((input-stream analyzer-stream) eof-error-p eof-value)
  (skip-whitespace input-stream)
  (let ((parse-result (cached-parse-result input-stream)))
    (if (null parse-result)
	(prog1 (call-next-method)
	  (advance-stream-to-beyond-parse-result
	   input-stream (first (first *stack*))))
	(progn (push parse-result (first *stack*))
	       (advance-stream-to-beyond-parse-result input-stream parse-result)
	       (if (typep parse-result 'expression-parse-result)
		   (expression parse-result)
		   (sicl-reader:read-common input-stream eof-error-p eof-value))))))