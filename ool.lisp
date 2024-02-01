;;;; -*- Mode: Lisp -*-
;;;; Buser Daniele 894514

(defparameter *classes-specs* (make-hash-table))

(defun add-class-spec (name class-spec)
  (setf (gethash name *classes-specs*) class-spec))

(defun class-spec (name)
  (gethash name *classes-specs*))

(defun remove-class (name classes-specs)
  (remhash name classes-specs))


;; Function to define a new class
(defun def-class (class-name parents &rest parts)

  ;; If the class already exists throw an error
  (when (is-class class-name)
    (error "The class already exists"))

  ;; Check that class-name is a symbol
  (unless (symbolp class-name)
    (error "The name of the class must be a symbol"))

  ;; Check if parents is a list
  (unless (and (listp parents)

	       ;; Check that every parent is a defined class
	       (every #'(lambda (parent)
			  (is-class parent))
		      parents))
    (error "The parents must be a list of defined classes"))

  ;; Check if parts is a list of fields and methods
  (unless (check-parts parts)
    (error "Parts must be a list of fields and methods"))

  ;; Save the new class as a global variable
  (add-class-spec class-name (list class-name
				   parents

				   ;; Create the fields and methods
				   ;; structure
				   (parts-structure parts)))

  ;; If you are defining a subclass check the field-type inheritance
  (check-field-type-inheritance class-name)

  ;; return the name of the class
  class-name)


;; Function to check if a class is defined
(defun is-class (class-name)
  (if (class-spec class-name) t nil))


;; Function to create a new istance of a class
(defun make (class-name &rest parts)

  ;; Check if the class is defined
  (unless (is-class class-name)
    (error "The ~a class has not been defined" class-name))

  ;; To create the instance scroll the parts
  (labels ((process-parts (parts instance)
	     (if (null parts)

		 ;; If parts is null return instance
		 instance

		 (let ((field-name (intern (string (first parts))))
		       (field-value (second parts)))

		   ;; Check if field-name is a symbol
		   (unless (symbolp field-name)
		     (error "The name of the field must be a symbol"))

		   ;; Check if the field has been defined for the
		   ;; class or for its superclasses
		   (let* ((field-spec
			   (extract-field class-name field-name)))

		     ;;If extract-field return a field then check
		     ;;field-value and field-type compatibility
		     (if field-spec
			 (unless (check-field-type-compatibility
				  (third field-spec) field-value)
			   (error "Value ~a for field ~a is not of
type ~a" field-value field-name (third field-spec))))

		     ;; Add the name and the value of the field to the
		     ;; instance
		     (process-parts
		      (cddr parts) (list (first instance)
					 (second instance)
					 (append
					  (third instance)
					  (list (list
						 (intern (string
							  field-name))
						 field-value))))))))))
    (process-parts parts (list 'oolinst class-name nil))))


;; Function to check if the value is an instance
(defun is-instance (value &optional (class-name 'T))

  ;; Check if value is a list and if its first element is 'oolinst
  (cond ((not (and (listp value)
		   (eq (first value) 'oolinst)))
	 (error "The input value is not an instance"))

	;; If I have 'T instead of class-name return true
	((eq class-name 'T) 'T)

	;; If class-name is not 'T check if value is an instance of
	;; class-name or of its superclasses
	((or (eq (second value) class-name)
	     (member class-name (extract-superclasses (second
						       value))))
	 'T)
	(t (error "The value is not an instance of ~a or of its
superclasses" class-name))))


;; Function to extract the value of a field given an instance of a
;; class
(defun field (instance field-name)

  ;; Keywords handling
  (let ((field-name
	 (if (keywordp field-name)
	     (intern (string-upcase (string field-name)))
	     field-name)))

    ;; Check if instance is an instance
    (is-instance instance)

    ;; Check if field-name is a symbol
    (unless (symbolp field-name)
      (error "The field name must be a symbol"))

    ;; Scroll (field-name field-value)* list and check if field-name
    ;; is defined in the instance, in the class or in its superclasses
    (let ((field-value (assoc field-name (third instance))))
      (if field-value

	  ;; If you find field-value in the instance return it's value
	  (second field-value)

	  ;; Otherwise check the inheritance
	  (let ((field-spec (extract-field (second instance)
					   field-name)))
	    (if field-spec

		;; If you find field-spec in the superclasses return
		;; its value
		(second field-spec)
		(error "The field ~a was not found in the instance or
in its superclasses" field-name)))))))


;; Function to extract the value associated to the last element of
;; fields-names
(defun field* (instance &rest fields-names)
  (if fields-names
      instance
      (field* (field instance (first fields-names))
	      (rest fields-names))))



;; USEFUL FUNCTIONS

;; Function to check if parts is only composed by fields and methods
(defun check-parts (parts)
  (every #'(lambda (part)
	     (or (eq (first part) 'fields)
		 (eq (first part) 'methods)))
	 parts))


;; Function to extract the parts of a class
(defun extract-parts (class-name)
  (third (class-spec class-name)))


;; Function to create the class structure processing fields and
;; methods
(defun parts-structure (parts)

  ;; If my class has no parts return nil
  (when (null parts)
    (return-from parts-structure nil))

  ;; Otherwise scroll parts and process fields and methods
  (mapcar (lambda (part)
	    (cond ((eq (first part) 'fields)
		   (cons 'fields (fields-part (cdr part))))
		  ((eq (first part) 'methods)
		   (cons 'methods (methods-part (cdr part))))))
	  parts))


;; Function to process fields
(defun fields-part (fields)

  ;; Scroll all the fields and create the structure for each one
  (mapcar (lambda (field)
	    (let* ((field-name (first field))
		   (field-value (second field))

		   ;; If there is not third field set to default type
		   ;; 'T
		   (field-type (or (third field) 'T)))

	      ;; Check that field-name is a symbol
	      (unless (symbolp field-name)
		(error "The name of the field must be a symbol"))

	      ;; Check if field-value is a self evaluating expression
	      (unless (constantp field-value)
		(error "The value of the field must be a
	      self-evaluating expression"))

	      ;; Check if the field-type is valid type. It can be a
	      ;; defined class a numeric value or the default value 'T
	      (unless (or (eq field-type 'T)
			  (class-spec field-type)
			  (typep field-value field-type))
		(error "The type of the field must be a valid type"))

	      (list field-name field-value field-type)))
	  fields))


;; Function to process methods
(defun methods-part (methods)

  ;; Scroll all the methods and create the structure for each one
  (mapcar (lambda (method)
	    (let* ((method-name (first method))
		   (method-spec (rest method)))

	      ;; Check that method-name is a symbol
	      (unless (symbolp method-name)
		(error "The name of the method must be a symbol"))

	      ;; Check that method-spec is a list
	      (unless (listp method-spec)
		(error "The spec of the method must be a list"))

	      (cons method-name (process-method method-name
						method-spec))))
	  methods))	


;; Function to process each method
(defun process-method (method-name method-spec)

  ;; Define the trampoline function
  (let ((trampoline (lambda (this &rest args)
		      (let ((method (extract-method this
						    method-name)))
			(apply method this args)))))
    (setf (fdefinition method-name) trampoline)
    (eval (rewrite-method-code method-spec))))


;; Function to rewrite the method code
(defun rewrite-method-code (method-spec)
  (let ((arglist (first method-spec))
	(form (rest method-spec)))
    (let ((rewritten-method
	   (cons 'lambda (cons (cons 'this arglist) form))))
      rewritten-method)))


;; Function to extract a method given an instance
(defun extract-method (instance method-name)
  (let ((class-name (second instance)))
    
    ;; Filter the methods from the parts of the class
    (let ((methods (filter-methods (extract-parts class-name))))
      
      ;; Search if there is the method in the instance class
      (let ((method (cdr (assoc method-name methods))))
	(if method
	    ;; If there is the method return it
	    method
	    
	    ;; Otherwise search in the class superclasses
	    (let ((superclasses (extract-superclasses class-name)))
	      (or (when superclasses
		    (some (lambda (superclass)
			    (let* ((superclass-parts (extract-parts
						      superclass))
				   
				   ;; Filter methods from the parts of
				   ;; the superclass
				   (superclass-methods
				    (filter-methods
				     superclass-parts)))			      
			      
			      ;; Search if there is the method in the
			      ;; instance superclass
			      (let ((method
				     (cdr (assoc method-name
						 superclass-methods))))				
				(if method
				    ;; If there is the method return it
				    method))))
			  superclasses))
		  (error "The method ~a was not found" method-name
			 class-name))))))))



;; Function to extract a field given a class-name
(defun extract-field (class-name field-name)

  ;; Extract the parts of the class
  (let ((parts (extract-parts class-name)))

    ;; Scoll each part
    (let ((field (some (lambda (part)
			 (when (eq (first part) 'fields)

			   ;; Scroll each field
			   (some (lambda (field)

				   ;; If you find a field with
				   ;; field-name return field
				   (when (eq (first field) field-name)
				     field))
				 (cdr part))))
		       parts)))
      (if field
	  field
	  
	  ;; Otherwise search in the superclasses
	  (let ((superclasses (extract-superclasses class-name)))
	    (when superclasses
	      
	      ;; Scroll each superclass
	      (let ((field (some (lambda (superclass)
				   (extract-field superclass
						  field-name))
				 superclasses)))
		
		(if field
		    field
		    
		    ;; Otherwise throw an error
		    (error "The field ~a was not found in the class ~a
		    or in its superclasses" field-name
		    class-name)))))))))


;; Function to extract the superclasses of a class given its name
(defun extract-superclasses (class-name)
  
  ;; Check if class exists
  (if (is-class class-name)
      (let* ((class-spec (class-spec class-name))
	     
	     ;; The directs superclasses are the parents of the class
	     (direct-superclasses (second class-spec))
	     
	     ;; The indirects superclasses are the parents of the
	     ;; parents ... of the class
	     (indirect-superclasses (mapcan #'extract-superclasses
					    direct-superclasses)))
	
	;; Merge into a list the directs and indirects superclasses
	(append direct-superclasses indirect-superclasses))
      
      ;; Otherwise throw an error
      (error "The ~a class has not been defined" class-name)))


;; Function to filter fields from the parts of a class
(defun filter-fields (parts)
  (mapcan #'rest
	  (remove-if-not #'(lambda (part)
			     (eq (first part) 'fields))
			 parts)))


;; Function to filter methods from the parts of a class
(defun filter-methods (parts)
  (mapcan #'rest
	  (remove-if-not #'(lambda (part)
			     (eq (first part) 'methods))
			 parts)))


;; Function to check the compatibility of two field-type
(defun check-field-type-compatibility (field-type field-value)
  (cond
    
    ;; If field-type is a defined class field-value should be an
    ;; instance of field-type
    ((is-class field-type)(is-instance field-value field-type))
    
    ;; If field-type is t field-value can be any type
    ((eq field-type t) t)
    
    ;; Otherwise check that field-value is of the type specified by
    ;; field-type
    (t (typep field-value field-type))))


;; Function to check the field-type inheritance when defining a new
;; subclass
(defun check-field-type-inheritance (subclass)
  
  ;; Extract the superclasses of the subclass
  (let ((superclasses (extract-superclasses subclass)))
    
    ;; If subclass has no parents return true
    (if (null superclasses)
	t
	
	;; Otherwise check
	(every #'identity
	       (mapcar
		(lambda (superclass)
		  (let* ((superclass-parts (extract-parts superclass))
			 (subclass-parts (extract-parts subclass))
			 
			 (superclass-fields (filter-fields
					     superclass-parts))
			 (subclass-fields (filter-fields
					   subclass-parts)))
		    
		    (every (lambda (field)
			     (let* ((field-name (first field))
				    (superclass-field
				     (assoc field-name
					    superclass-fields)))
			       
			       (if superclass-field
				   (let ((superclass-type
					  (third
					   superclass-field))
					 (subclass-type (third
							 field)))
				     
				     ;; Check the "width" of the
				     ;; type
				     (or (subtypep subclass-type
						   superclass-type)
					 (progn
					   
					   ;; Remove the class
					   ;; from classes-specs
					   (remove-class
					    subclass *classes-specs*)
					   (error "Value ~a for
field ~a is not of type ~a" (second field) field-name
superclass-type))))
				   t)))
			   subclass-fields)))
		superclasses)))))



;;;;
