;; wok.scm

(define defs '((+ (int int) (int))
               (drop-int (int) ())
               (= (int int) (bool))
               (not (bool) (bool))))

(define (fail)
  (eval '(#f)))

(define (say . text)
  (for-each display text)
  (newline))

(define (error . text)
  (apply say text)
  (fail))

(define current '())

(define (set-current! types)
  ;(say "new:" types)
  (set! current types))

(define (current+ t)
  (set-current! (cons t current)))

(define (current- t)
  (if (null? current)
      (error "requested " t " but stack is empty")
      (if (type= (car current) t)
          (set-current! (cdr current))
          (error "requested " t "but having " (car current)))))

(define (apply-call-effect op)
  (let ((effect (cdr (assq op defs))))
    (current-multi- (car effect))
    (current-multi+ (cadr effect))))

(define (current-multi+ types)
  (for-each current+ (reverse types)))

(define (current-multi- types)
  (for-each current- types))

(define (apply-effect code)
  (for-each (lambda (element)
              (cond ((symbol? element) (apply-call-effect element))
                    ((number? element) (current+ 'int))
                    ((list? element) (apply-structure-effect element))))
            code))

(define (apply-structure-effect struct)
  (case (car struct)
    ((eif) (begin
            (current- 'bool)
            (let ((prev current))
              (infer (cadr struct))
              (let ((t-branch current))
                (if (not (null? (cddr struct)))
                    (begin
                      (set-current! prev)
                      (infer (caddr struct))
                      (if (not (branch= t-branch current))
                          (error "incompatible branches from " prev " to "
                                 t-branch " vs. " current))))))))
    ((loop) (fail))))

(define (branch= variant1 variant2)
  (cond ((null? variant1) (null? variant2))
        ((null? variant2) #f)
        ((type= (car variant1) (car variant2))
         (branch= (cdr variant1) (cdr variant2)))
        (else #f)))

(define (type= t1 t2)
  (eq? t1 t2)) ; for now

(apply-effect '(1 1 1 1 = (eif (+) (drop-int))))

(display current)
(newline)
