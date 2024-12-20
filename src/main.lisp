;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; c) 2024, Sebastian Ardelean (sebastian.ardelean@cs.upt.ro)
;; version 1.0.0 (major minor patch)
;; version history below

#|
DESCRIPTION

CLQ (Common Lisp Quantum) is a package, written in
Common Lisp, that allows a user to define a quantum circuit
in terms of quantum register, quantum gates, and classical register
and to export it to OpenQASM. Thus, the circuit defined in Common Lisp
can be simulated or run on IBMQ quantum processors.

CLQ was developed to ease the development of quantum algorithms
following the circuit model, while having an easy to use but complex API.
The driving motivation for implementing this package was the need of
having a small library--that can be extended as needed--to define quantum
circuits.

The reason behind chosing Common Lisp was represented by the wish of using
a functional programming language that doesn't have lot of dependencies and
can be ported to different Operating Systems and microprocessor
architectures.

VERSION HISTORY

* Dec 12, 2023 (sebastian ardelean): Finished the implementation on quantum circuits and H, X, Y, Z, and CNOT gate.

* Dec 13, 2023 (sebastian ardelean): Finished the implementation of functions that generate the OpenQASM code; Added documentation.
* Dec 21, 2023 (sebastian ardelean): Refactored gate methods and added S,St,T,Tt gates. Removed gate IDs and modified the methods to validate and create a quantum gate.
* Jul 17, 2024 (sebastian ardelean): Refactored QCircuit's method to use lists of quantum and classical registers.
* Nov 21, 2024 (sebastian ardelean): Reimplemented gate methods and added CCX gate. Modified gate class to store only the OpenQASM instruction.
|#
(defpackage clq
  (:use :cl)
  (:export #:qregister
           #:make-qregister
           #:print-object
           #:size
           #:cregister
           #:make-cregister
           #:print-object
           #:size
           #:qgate
           #:make-qgate
           #:print-object
           #:qcircuit
           #:make-qcircuit
           #:print-object
           #:qregs
           #:cregs
           #:hgate
           #:xgate
           #:ygate
           #:zgate
           #:igate
           #:sgate
           #:sdggate
           #:tgate
           #:tdggate
           #:cxgate
           #:ccxgate
           #:czgate
           #:cygate
           #:chgate
           #:qbarrier
           #:measure
           #:generate-openqasm
           #:save-openqasm-to-file))

(in-package :clq)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Class definition for the Quantum Register

(defclass qregister ()
  (;; the number of qubits in the register
   (size :accessor size :initarg :size
         :documentation "Quantum Register size.")
   ;; the name of the quantum register
   (name :accessor name :initarg :name
         :documentation "Quantum Register name.")))

(defun make-qregister (size name)
  "Constructor for the Quantum Register.

  Parameters:
  - sizes: the number of qubits in the quantum register.
  - name: quantum register's name.
  "
  (make-instance 'qregister :size size :name name))

(defmethod print-object ((obj qregister) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "size ~a, name: ~a" (size obj) (name obj))))



(defmethod qregister-equal ((a qregister) (b qregister))
  (and (equal (size a) (size b))
       (equal (name a) (name b))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Class definition for the Classical Registers

(defclass cregister ()
  (;; the number of bits in the register
   (size :accessor size :initarg :size
         :documentation "Classical Register size.")
   ;; the name of the classical register
   (name :accessor name :initarg :name
         :documentation "Classical Register name.")))

(defun make-cregister (size name)
  "Constructor for the Classical Register.

  Parameters:
  - size: the number of bits in the classical register.
  - name: classical register's name.
  "
  (make-instance 'cregister :size size :name name))

(defmethod cregister-equal ((a cregister) (b cregister))
  (and (equal (size a) (size b))
       (equal (name a) (name b))))

(defmethod print-object ((obj cregister) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "size ~a, name: ~a" (size obj) (name obj))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Class definition for Quantum Gate

(defclass qgate()
  (;; Quantum gate's name
   (name :accessor name :initarg :name
         :documentation "Quantum gate's name.")
   ;; Format of the generated OpenQASM v2.0 code
   (fmt :accessor fmt :initarg :fmt
        :documentation "Format of the generated OpenQASM v2.0 code.")))

(defun make-qgate (name fmt)
  "Constructor for the Quantum Gate.

  Parameters:
  - ctrlreg: control register.
  - ctrlbit: index of the control qubit.
  - targreg: target register.
  - targbit: index of the target qubit.
  - name   : quantum gate's name.
  - fmt    : format of the generate OpenQASM v2.0 code
  - mop    : true if the operator is for measurement
  "
  (make-instance 'qgate :name name
                        :fmt fmt
                        ))

(defmethod print-object ((obj qgate) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "Gate name: ~a, Gate format: ~a"
             (name obj) (fmt obj) )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Class definition for Quantum Circuit

(defclass qcircuit ()
  (;; List of quantum registers.
   (qregs :accessor qregs :initarg :qregs
          :documentation "Quantum Registers.")
   ;; List of classical registers.
   (cregs :accessor cregs :initarg :cregs
          :documentation "Classical Registers.")
   ;; List of quantum gates.
   (gates :accessor gates :initarg :gates
          :documentation "List of applied quantum gates.")))

(defun make-qcircuit (qregs cregs)
  "Constructor for the Quantum Circuit.

  Parameters:
  - qregs: list of quantum register.
  - cregs: list of classical register.
  "
  (make-instance 'qcircuit :qregs qregs
                           :cregs cregs
                           :gates '()))

(defmethod print-object ((obj qcircuit) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "qreg: ~a, creg: ~a, gates: ~a" (qregs obj) (cregs obj) (gates obj))))

(defmethod add-gate ((qc qcircuit) (qg qgate))
  (let ((gate-list (gates qc)))
    (setf (gates qc) (push qg gate-list))))

(defmethod validate-qregister ((qc qcircuit) (reg qregister))
  (let ((qcregs (qregs qc)))
    (if qcregs
        (let ((qreg (find-if (lambda (x) (qregister-equal reg x)) qcregs)))
          (if qreg
              T
              (format t "Register not found in the quantum circuit")))
        (format t "Quantum circuit does not have any quantum registers"))))

(defmethod validate-cregister ((qc qcircuit) (reg cregister))
  (let ((qcregs (cregs qc)))
    (if qcregs
        (let ((creg (find-if (lambda (x) (cregister-equal reg x)) qcregs)))
          (if creg
              T
              (format t "Register not found in the quantum circuit")))
        (format t "Quantum circuit does not have any quantum registers"))))



(defmethod hgate ((qc qcircuit) (reg qregister) position)
  " Create and apply a Hadamard gate.

  Parameters:
  - qc      : quantum circuit
  - reg     : quantum register.
  - position: the qubit's index in the quantum register on which the gate is applied.
  "
  (if (and (> (size reg) position) (validate-qregister qc reg))
      (let ((qg (make-qgate  "Hadamard" (format nil "h ~a[~a];~%" (name reg) position) )))
        (add-gate qc qg))
      (format t "Qubit position or the register is not valid")))

(defmethod xgate ((qc qcircuit) (reg qregister) position)
  " Create and apply a Pauli-X gate.

  Parameters:
  - qc      : quantum circuit
  - reg     : quantum register.
  - position: the qubit's index in the quantum register on which the gate is applied.
  "
  (if (and (> (size reg) position) (validate-qregister qc reg))
      (let ((qg (make-qgate "Pauli-X" (format nil "x ~a[~a];~%" (name reg) position) )))
        (add-gate qc qg))
      (format t "Qubit position or the register is not valid")))

(defmethod ygate ((qc qcircuit) (reg qregister) position)
  " Create and apply a Pauli-Y gate.

  Parameters:
  - qc      : quantum circuit
  - reg     : quantum register.
  - position: the qubit's index in the quantum register on which the gate is applied.
  "  
  (if (and (> (size reg) position) (validate-qregister qc reg))
      (let ((qg (make-qgate "Pauli-Y" (format nil "y ~a[~a];~%" (name reg) position) )))
        (add-gate qc qg))
      (format t "Qubit position or the register is not valid")))

(defmethod zgate ((qc qcircuit) (reg qregister) position)
  " Create and apply a Pauli-Z gate.

  Parameters:
  - qc      : quantum circuit
  - reg     : quantum register.
  - position: the qubit's index in the quantum register on which the gate is applied.
  "  
  (if (and (> (size reg) position) (validate-qregister qc reg))
      (let ((qg (make-qgate "Pauli-Z" (format nil "z ~a[~a];~%" (name reg) position) )))
        (add-gate qc qg))
      (format t "Qubit position or the register is not valid")))


(defmethod igate ((qc qcircuit) (reg qregister) position)
  " Create and apply an Identity gate.

  Parameters:
  - qc      : quantum circuit
  - reg     : quantum register.
  - position: the qubit's index in the quantum register on which the gate is applied.
  "  
  (if (and (> (size reg) position) (validate-qregister qc reg))
      (let ((qg (make-qgate "Identity" (format nil "i ~a[~a];~%" (name reg) position) )))
        (add-gate qc qg))
      (format t "Qubit position or the register is not valid")))


(defmethod sgate ((qc qcircuit) (reg qregister) position)
  " Create and apply a SQRT(Z) gate.

  Parameters:
  - qc      : quantum circuit
  - reg     : quantum register.
  - position: the qubit's index in the quantum register on which the gate is applied.
  "  
  (if (and (> (size reg) position) (validate-qregister qc reg))
      (let ((qg (make-qgate  "SQRT(Z)" (format nil "s ~a[~a];~%" (name reg) position))))
        (add-gate qc qg))
      (format t "Qubit position or the register is not valid")))

(defmethod sdggate ((qc qcircuit) (reg qregister) position)
  " Create and apply a Conjugate SQRT(Z) gate.

  Parameters:
  - qc      : quantum circuit
  - reg     : quantum register.
  - position: the qubit's index in the quantum register on which the gate is applied.
  "  
  (if (and (> (size reg) position) (validate-qregister qc reg))
      (let ((qg (make-qgate  "Conjugate SQRT(Z)" (format nil "sdg ~a[~a];~%" (name reg) position) )))
        (add-gate qc qg))
      (format t "Qubit position or the register is not valid")))


(defmethod tgate ((qc qcircuit) (reg qregister) position)
  " Create and apply a SQRT(S) gate.

  Parameters:
  - qc      : quantum circuit
  - reg     : quantum register.
  - position: the qubit's index in the quantum register on which the gate is applied.
  "  
  (if (and (> (size reg) position) (validate-qregister qc reg))
      (let ((qg (make-qgate "SQRT(S)" (format nil "t ~a[~a];~%" (name reg) position) )))
        (add-gate qc qg))
      (format t "Qubit position or the register is not valid")))

(defmethod tdggate ((qc qcircuit) (reg qregister) position)
  " Create and apply a Conjugate SQRT(Z) gate.

  Parameters:
  - qc      : quantum circuit
  - reg     : quantum register.
  - position: the qubit's index in the quantum register on which the gate is applied.
  "  
  (if (and (> (size reg) position) (validate-qregister qc reg))
      (let ((qg (make-qgate "Conjugate SQRT(S)" (format nil "tdg ~a[~a];~%" (name reg) position) )))
        (add-gate qc qg))
      (format t "Qubit position or the register is not valid")))





(defmethod cxgate ((qc qcircuit) (ctrl qregister) ctrlp (targ qregister) targp)
  " Create and apply a Controlled-X gate.

  Parameters:
  - qc      : quantum circuit.
  - ctrl    : control quantum register.
  - ctrlp   : the qubit's index in the control quantum register.
  - targ    : target quantum register.
  - targp   : the qubit's index in the target quantum register.
  "
  (if (and (> (size ctrl) ctrlp) (validate-qregister qc ctrl))
      (if (and (> (size targ) targp) (validate-qregister qc targ))
          (let ((qg (make-qgate "CNOT" (format nil "cx ~a[~a], ~a[~a];~%" (name ctrl) ctrlp (name targ) targp) )))
            (add-gate qc qg))
           (format t "Qubit position or the target register is not valid!"))
      (format t "Qubit position or the control register is not valid!")))




(defmethod cygate ((qc qcircuit) (ctrl qregister) ctrlp (targ qregister) targp)
  " Create and apply a Controlled-Y gate.

  Parameters:
  - qc      : quantum circuit.
  - ctrl    : control quantum register.
  - ctrlp   : the qubit's index in the control quantum register.
  - targ    : target quantum register.
  - targp   : the qubit's index in the target quantum register.
  "
  (if (and (> (size ctrl) ctrlp) (validate-qregister qc ctrl))
      (if (and (> (size targ) targp) (validate-qregister qc targ))
          (let ((qg (make-qgate "CY" (format nil "cy ~a[~a], ~a[~a];~%" (name ctrl) ctrlp (name targ) targp) )))
            (add-gate qc qg))
          (format t "Qubit position or the target register is not valid!"))
      (format t "Qubit position or the control register is not valid!")))



(defmethod czgate ((qc qcircuit) (ctrl qregister) ctrlp (targ qregister) targp)
  " Create and apply a Controlled-Z gate.

  Parameters:
  - qc      : quantum circuit.
  - ctrl    : control quantum register.
  - ctrlp   : the qubit's index in the control quantum register.
  - targ    : target quantum register.
  - targp   : the qubit's index in the target quantum register.
  "
  (if (and (> (size ctrl) ctrlp) (validate-qregister qc ctrl))
      (if (and (> (size targ) targp) (validate-qregister qc targ))
          (let ((qg (make-qgate "CZ" (format nil "cz ~a[~a], ~a[~a];~%" (name ctrl) ctrlp (name targ) targp) )))
            (add-gate qc qg))
          (format t "Qubit position or the target register is not valid!"))
      (format t "Qubit position or the control register is not valid!")))

(defmethod chgate ((qc qcircuit) (ctrl qregister) ctrlp (targ qregister) targp)
  " Create and apply a Controlled-H gate.

  Parameters:
  - qc      : quantum circuit.
  - ctrl    : control quantum register.
  - ctrlp   : the qubit's index in the control quantum register.
  - targ    : target quantum register.
  - targp   : the qubit's index in the target quantum register.
  "
  (if (and (> (size ctrl) ctrlp) (validate-qregister qc ctrl))
      (if (and (> (size targ) targp) (validate-qregister qc targ))
          (let ((qg (make-qgate "CH" (format nil "ch ~a[~a], ~a[~a];~%" (name ctrl) ctrlp (name targ) targp) )))
            (add-gate qc qg))
          (format t "Qubit position or the target register is not valid!"))
      (format t "Qubit position or the control register is not valid!")))


(defmethod ccxgate ((qc qcircuit) (ctrl0 qregister) ctrlp0 (ctrl1 qregister) ctrlp1 (targ qregister) targp)
  " Create and apply a Controlled-X gate.

  Parameters:
  - qc      : quantum circuit.
  - ctrl0    : control quantum register.
  - ctrlp0   : the qubit's index in the control quantum register.
  - ctrl1    : control quantum register.
  - ctrlp1   : the qubit's index in the control quantum register.
  - targ    : target quantum register.
  - targp   : the qubit's index in the target quantum register.
  "
  (if (and (> (size ctrl0) ctrlp0) (validate-qregister qc ctrl0))
      (if (and (> (size ctrl1) ctrlp1) (validate-qregister qc ctrl1))
          (if (and (> (size targ) targp) (validate-qregister qc targ))
              (let ((qg (make-qgate "CNOT" (format nil "ccx ~a[~a], ~a[~a] ,~a[~a];~%" (name ctrl0) ctrlp0 (name ctrl1) ctrlp1 (name targ) targp) )))
                (add-gate qc qg))
              (format t "Qubit position or the target register is not valid!"))
          (format t "Qubit position or the control register is not valid!"))
      (format t "Qubit position or the control register is not valid!")))



(defmethod measure ((qc qcircuit) (ctrl qregister) ctrlp (targ cregister) targp)
  " Create and apply a Measurement operator.

  Parameters:
  - qc      : quantum circuit.
  - ctrl    : control quantum register.
  - ctrlp   : the qubit's index in the quantum register.
  - targ    : classical register.
  - targp   : the qubit's index in the classical register.
  "
  (if (and (> (size ctrl) ctrlp) (validate-qregister qc ctrl))
      (if (and (> (size targ) targp) (validate-cregister qc targ))
          (let ((qg (make-qgate "Measurement" (format nil "measure ~a[~a] -> ~a[~a];~%" (name ctrl) ctrlp (name targ) targp) )))
            (add-gate qc qg))
          (format t "Qubit position or the classical register is not valid!"))
      (format t "Qubit position or the quantum register is not valid!")))


(defmethod qbarrier ((qc qcircuit))
  (let ((qg (make-qgate "barrier" (format nil "barrier ~{~A~^,~};~%" (mapcar #'name (qregs qc))))))
    (add-gate qc qg)))

(defun get-gate (gate)
  (fmt gate))

            

(defun get-operators (xs &optional result-str)
  (if xs
      (let ((el (car xs)))
        (get-operators (cdr xs) (concatenate 'string
                                             result-str
                                             (get-gate el))))
      result-str))





(defun get-qregisters (xs &optional result-str)
  (if xs
      (let ((el (car xs)))
        (get-qregisters (cdr xs) (concatenate 'string
                                              result-str
                                              (format nil "qreg ~a[~a];~%" (name el) (size el))))) result-str))

(defun get-cregisters (xs &optional result-str)
  (if xs
      (let ((el (car xs)))
        (get-cregisters (cdr xs) (concatenate 'string
                                              result-str
                                              (format nil "creg ~a[~a];~%" (name el) (size el))))) result-str))




(defun generate-openqasm (qc &optional result-str)
  " Converts the Quantum Circuit into OpenQASM v2.0 code.

  Parameters:
  - qc: the quantum circuit object.
  - result-str: the string that will contain the OpenQASM v2.0 code. By default is empty.
  "
  (let (
        (header (format nil "OPENQASM 2.0;~%include \"qelib1.inc\";~%"))
        (qregs (get-qregisters (qregs qc) ""))
        (cregs (get-cregisters (cregs qc) ""))
        (operators (get-operators (reverse (gates qc)) "")))
    (concatenate 'string result-str header qregs cregs operators)))


(defun save-openqasm-to-file (qc file-path)
  " Converts the Quantum Circuit into OpenQASM v2.0 code and writes it into a file.

  Parameters:
  - qc: the quantum circuit object.
  - file-path: the file path that will be created.
  "
  (with-open-file (stream file-path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (format stream (generate-openqasm qc ""))))

;; FOR DEBUG only
;;(defvar qr (make-qregister 2 "qr"))
;;(defvar cr (make-cregister 2 "cr"))
;;(defvar qc (make-qcircuit (list qr) (list cr)))
;;(hgate qc qr 0)
;;(xgate qc qr 1)
;;(cxgate qc qr 0 qr 1)
;;(measure qc qr 0 cr 0)
;;(generate-openqasm qc "")
