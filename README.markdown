# clq

This repository was moved to [Codeberg](https://codeberg.org/sebastianardelean/clq) and the development will continue there.

## Usage

**clq** is a package that allows the definition and development of quantum circuits in Common Lisp and to export them to **OpenQASM v2.0**.

The following code presents an example that initializes a quantum circuit made of one 2-qubits quantum register and one 2-bits classical register.
We apply on the circuit Hadamard, Pauli-X, Pauli-Y, Pauli-Z and CNOT gates.

```
 (defvar qreg (make-qregister 2 "q"))
  (defvar creg (make-cregister 2 "c"))
  (defvar qc (make-qcircuit (list qreg) (list creg)))
  (hgate qc qreg 0)
  (xgate qc qreg 1)
  (ygate qc qreg 0)
  (zgate qc qreg 1)
  (cxgate qc qreg 0 qreg 1)
  (measure qc qreg 0 creg 1)

```

To generate the **OpenQASM v2.0** is enough to call the function `(generate-openqasm qc "")`, thus generating the string:

```
OPENQASM 2.0;
include "qelib1.inc";
qreg q[2];
 creg c[2];
h q[0];
x q[1];
y q[0];
z q[1];
cx q[0], q[1];
measure q[0] -> c[1]
```

To save the generated code in a file, the function `(defun save-openqasm-to-file (qc file-path)` must be called.

### Example of Deutsch-Jozsa's algorithm implementation:

```
;; Deutsch-Jozaa Algrithm Implementation

;; Oracle f(x) = 0
(defun oracle-f1 ()
  )

;; Oracle f(x) = 1

(defun oracle-f2 (qc qr)
  (clq:xgate qc qr 1))

;; Oracle f(x) = x
(defun oracle-f3 (qc cqr tqr)
  (clq:cnotgate qc cqr 0 tqr 1))

;; Oracle f(x) = 1 - x

(defun oracle-f4 (qc cqr tqr)
  (progn
    (clq:cnotgate qc cqr 0 tqr 1)
    (clq:xgate qc cqr 1)))


(defconstant  +QREG+ (clq:make-qregister 2 "q"))
(defconstant  +CREG+ (clq:make-cregister 1 "c"))

(defun run ()
  (let ((qc   (clq:make-qcircuit (list +QREG+) (list +CREG+))))
    (progn
      (clq:xgate qc +QREG+ 1)
      (clq:hgate qc +QREG+ 0)
      (clq:hgate qc +QREG+ 1)
      (oracle-f2 qc +QREG+)
      (clq:hgate qc +QREG+ 0)
      (clq:measure qc +QREG+ 0 +CREG+ 0)
      (clq:generate-openqasm qc ""))))
```

## Installation

In your new project add the package as a dependency or in REPL run `(ql:quickload "clq")`.

## Author

* Sebastian Ardelean

## Copyright

MIT License

Copyright (c) 2024 Sebastian Ardelean

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

