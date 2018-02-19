(cl:in-package #:climacs-syntax-common-lisp)

(defun indent-prog1-etc (wad client)
  (let* ((fun (lambda (wad) (compute-child-indentations wad client)))
         (arguments (rest (children wad)))
         (indentation (+ (start-column wad) 4))
         (body-wads (compute-distinguished-indentation
                     arguments indentation fun)))
    (indent-body (+ (start-column wad) 2) body-wads client)))

(defmethod compute-sub-form-indentations
    (wad (pawn (eql (intern-pawn '#:common-lisp '#:prog1))) client)
  (indent-prog1-etc wad client))

(defmethod compute-sub-form-indentations
    (wad (pawn (eql (intern-pawn '#:common-lisp '#:multiple-value-prog1))) client)
  (indent-prog1-etc wad client))

(defmethod compute-sub-form-indentations
    (wad (pawn (eql (intern-pawn '#:common-lisp '#:multiple-value-call))) client)
  (indent-prog1-etc wad client))

(defmethod compute-sub-form-indentations
    (wad (pawn (eql (intern-pawn '#:common-lisp '#:catch))) client)
  (indent-prog1-etc wad client))

(defmethod compute-sub-form-indentations
    (wad (pawn (eql (intern-pawn '#:common-lisp '#:throw))) client)
  (indent-prog1-etc wad client))

(defmethod compute-sub-form-indentations
    (wad (pawn (eql (intern-pawn '#:common-lisp '#:unwind-protect))) client)
  (indent-prog1-etc wad client))

(defmethod compute-sub-form-indentations
    (wad (pawn (eql (intern-pawn '#:common-lisp '#:when))) client)
  (indent-prog1-etc wad client))

(defmethod compute-sub-form-indentations
    (wad (pawn (eql (intern-pawn '#:common-lisp '#:unless))) client)
  (indent-prog1-etc wad client))
