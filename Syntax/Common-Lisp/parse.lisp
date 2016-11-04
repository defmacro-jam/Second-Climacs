(cl:in-package #:climacs-syntax-common-lisp)

(defun parse (analyzer-stream)
  (let ((*stack* (list '())))
    (sicl-reader:read analyzer-stream)
    (first (first *stack*))))

(defun parse-and-cache (analyzer-stream)
  (push (parse analyzer-stream)
	(prefix (folio analyzer-stream))))

(defun parse-buffer (analyzer-stream)
  (loop with analyzer = (folio analyzer-stream)
	until (progn
		(skip-whitespace analyzer-stream)
		(or (eof-p analyzer-stream)
		    (and (not (null (suffix analyzer)))
			 (let* ((pr (first (suffix analyzer)))
				(l (start-line pr))
				(c (start-column pr)))
			   (and (= l (current-line-number analyzer-stream))
				(= c (current-item-number analyzer-stream)))))))
	do (parse-and-cache analyzer-stream)
	   (pop-to-stream-position analyzer-stream)))
