;; wok.scm -- statically typed concatenative language compiler.
;; Copyright (C) 2019 Wolfgang Jährling
;;
;; ISC License
;;
;; Permission to use, copy, modify, and/or distribute this software for any
;; purpose with or without fee is hereby granted, provided that the above
;; copyright notice and this permission notice appear in all copies.
;;
;; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
;; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
;; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
;; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
;; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
;; OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

(define defs '((+ (int int) (int))
               (drop (any) ())
               (= (int int) (bool))
               (foo () ((addr int)))
               (at ((addr int)) (int))
               (nil? ((ptr any)) (bool))
               (not (bool) (bool))))

(define cuts '((while (not if (break)))
               (until (if (break)))
               (test nil? (if (0 +)))))

(define (fail)
  (eval '(#f)))

(define (say . text)
  (for-each display text)
  (newline))

(define (error . text)
  (apply say text)
  (fail))

(define call/cc call-with-current-continuation)

(define expected '())
(define current '())

(define (set-current! types)
  ;(say "new:" types)
  (set! current types))

(define (current+ t)
  (set-current! (cons t current)))

(define (current- t)
  (if (null? current)
      (error "requested " t " but stack is empty")
      (if (use-as-type? t (car current))
          (set-current! (cdr current))
          (error "requested " t " but having " (car current)))))

(define (pop-current)
  (if (null? current)
      (error "expected value on stack, but it is empty")
      (let ((x (car current)))
        (set-current! (cdr current))
        x)))

(define (apply-call-effect op)
  (let ((effect (cdr (assq op defs))))
    (current-replace (car effect) (cadr effect))))

(define (def? name)
  (not (not (assq name defs))))

(define (cut? name)
  (not (not (assq name cuts))))

(define (apply-cut-effect name)
  (apply-effect (cdr (assq name cuts))))

(define (current-replace old new)
  (current-multi- old)
  (current-multi+ new))

(define (current-multi+ types)
  (for-each current+ (reverse types)))

(define (current-multi- types)
  (for-each current- types))

(define (apply-effect code)
  (call/cc
   (lambda (return)
     (for-each (lambda (element)
                 (cond ((symbol? element)
                        (cond ((def? element) (apply-call-effect element))
                              ((cut? element) (apply-cut-effect element))
                              ((eq? element 'stop)
                               (if (not (branch= current expected))
                                   (error "stop at wrong stack state "
                                          current " instead of " expected)
                                   (begin
                                     (set-current! 'stopped)
                                     (return))))
                              (else (error "symbol " element " not known"))))
                       ((number? element) (current+ 'int))
                       ((list? element) (apply-structure-effect element))))
               code))))

(define loop-starts '())
(define (loop-starts+ state)
  (set! loop-starts (cons state loop-starts)))
(define (loop-starts-)
  (let ((x (car loop-starts)))
    (set! loop-starts (cdr loop-starts))
    x))

(define loop-ends '())

(define (loop-ends-)
  (let ((x (car loop-ends)))
    (set! loop-ends (cdr loop-ends))
    x))

(define (check-loop-break state)
  (cond ((eq? (car loop-ends) 'stopped) (set-car! loop-ends state))
        ((branch= (car loop-ends) state) #t)
        (else (error "loop terminated with state " state
                     ", but should be " (car loop-ends)))))

(define (enter-loop)
  (loop-starts+ current)
  (set! loop-ends (cons 'stopped loop-ends)))

(define (end-of-loop)
  (let ((start (loop-starts-)))
    (if (branch= start current)
        (unify-branches! start current)
        (error "loop ended with state " current " instead of " start)))
  (set-current! (loop-ends-)))

(define (apply-structure-effect struct)
  (case (car struct)
    ((eif) (begin
            (current- 'bool)
            (let ((prev current))
              (apply-effect (cadr struct))
              (let ((t-branch current))
                (set-current! prev)
                (apply-effect (caddr struct))
                (if (not (branch= t-branch current))
                    (error "incompatible branches from " prev " to "
                           t-branch " vs. " current)
                    (unify-branches! t-branch current))))))
    ((if) (begin
            (current- 'bool)
            (let ((prev current))
              (apply-effect (cadr struct))
              (if (not (branch= prev current))
                  (error "then-branch left stack as " current
                         "instead of " prev)
                  (unify-branches! prev current)))))
    ((eon) (let ((top (pop-current)))
            (if (not (type= '(ptr any) top))
                (error "expected ptr on stack but got " top)
                (let ((prev current))
                  (current+ (list 'addr (cadr top)))
                  (apply-effect (cadr struct))
                  (let ((t-branch current))
                    (set-current! prev)
                    (apply-effect (caddr struct))
                    (if (not (branch= t-branch current))
                        (error "incompatible branches from " prev
                               " to " t-branch " vs. " current)
                        (unify-branches! t-branch current)))))))
    ((on) (let ((top (pop-current)))
            (if (not (type= '(ptr any) top))
                (error "expected ptr on stack but got " top)
                (let ((prev current))
                  (current+ (list 'addr (cadr top)))
                  (apply-effect (cadr struct))
                  (if (not (branch= prev current))
                      (error "on-branches left stack as " current
                             " instead of " prev)
                      (unify-branches! prev current))))))
    ((cast) (if (null? current)
                (error "cast to " (cadr struct) " on empty stack")
                (set-current! (cons (cadr struct)
                                    (cdr current)))))
    ((at) (fail))
    ((set) (fail))
    ((x) (fail))
    ((this) (fail))
    ((that) (fail))
    ((them) (fail))
    ((tuck) (fail))
    ((drop) (fail))
    ((nip) (fail))
    ((dropem) (fail))
    ((break) (begin
               (check-loop-break current)
               (set-current! 'stopped)))
    ((loop) (begin
              (enter-loop)
              (apply-effect (cadr struct))
              (end-of-loop)))))

(define (branch= variant1 variant2)
  (cond ((or (eq? variant1 'stopped)
             (eq? variant2 'stopped)) #t)
        ((null? variant1) (null? variant2))
        ((null? variant2) #f)
        ((type= (car variant1) (car variant2))
         (branch= (cdr variant1) (cdr variant2)))
        (else #f)))

(define (type= t1 t2)
  (or (eq? t1 'any)
      (eq? t2 'any)
      (eq? t1 t2)
      (and (list? t1)
           (list? t2)
           (eq? (car t1) (car t2))
           (type= (cadr t1) (cadr t2)))))

(define (use-as-type? sup sub)
  (or (eq? sup 'any)
      (eq? sub 'any)
      (eq? sub sup)
      (and (list? sup)
           (list? sub)
           (eq? (car sup) (car sub))
           (type= (cadr sup) (cadr sub)))
      (and (list? sup)
           (list? sub)
           (eq? 'ptr (car sup))
           (eq? 'addr (car sub))
           (type= (cadr sup) (cadr sub)))))

(define (unify-branches! b1 b2)
  (set-current! (cond ((eq? b1 'stopped) b2)
                      ((eq? b2 'stopped) b1)
                      (else (map unify-types b1 b2)))))

(define (all? is? . xs)
  (cond ((null? xs) #t)
        ((not (is? (car xs))) #f)
        (else (apply all? is? (cdr xs)))))

(define (unify-types t1 t2)
  (cond ((eq? t1 t2) t1)
        ((eq? t1 'any) t2)
        ((eq? t2 'any) t1)
        ((and (all? list? t1 t2)
              (eq? (car t1) (car t2))) (list (car t1)
                                             (unify-types (cadr t1)
                                                          (cadr t2))))
        ((and (all? list? t1 t2)
              (or (and (eq? (car t1) 'addr)
                       (eq? (car t2) 'ptr))
                  (and (eq? (car t1) 'ptr)
                       (eq? (car t2) 'addr)))) (cons 'ptr (car t1)))
        (else (error "incompatible types " t1 " and " t2))))

'(apply-effect '(1 (cast any)
                  1 1 1 1 = (eif (+) (drop)) (cast bool)
                  (if (drop 1))))
'(apply-effect '(1 (cast (addr int)) at))
'(apply-effect '(1 (cast (addr int)) test))
'(apply-effect '(1 (cast (ptr int))
                (eon ((cast (ptr int)))
                     (1 (cast (ptr any))))))
'(apply-effect '((on (drop))))
'(set! expected '(int))
'(apply-effect '(1 (cast bool) (eif (stop) (1))))
'(apply-effect '(1 (cast bool) (if (1 stop)) 1))

(apply-effect '(1 (loop (1 = (if (1 (cast bool) (break))) 1))))

(display current)
(newline)

;; what is nonsymmetrical about typechecks?
;; can use @foo as ^foo, but not inverse
