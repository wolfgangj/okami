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

(define initial '())

(define (initial+ t)
  (say "init:" t)
  (set! initial (cons t initial)))

(define current '(int))

(define (set-current! types)
  (say "new:" types)
  (set! current types))

(define (current+ t)
  (set-current! (cons t current)))

(define (current- t)
  (if (null? current)
      (initial+ t)
      (if (eq? (car current) t)
          (set-current! (cdr current))
          (error "requested " t "but having " (car current)))))

(define (apply-effect-of op)
  (let ((effect (cdr (assq op defs))))
    (current-multi- (car effect))
    (current-multi+ (cadr effect))))

(define (current-multi+ types)
  (for-each current+ (reverse types)))

(define (current-multi- types)
  (for-each current- types))

(define (infer code)
  (for-each (lambda (element)
              (if (symbol? element)
                  (apply-effect-of element)
                  (apply-structure-effect element)))
            code))

(define (apply-structure-effect struct)
  (case (car struct)
    ((if) (begin
            (current- 'bool)
            (let ((prev current))
              (infer (cadr struct))
              (let ((t-branch current))
                (if (not (null? (cddr struct)))
                    (begin
                      (set-current! prev)
                      (infer (caddr struct))
                      (if (compatible-branches? t-branch current)
                          (possibly-extend-to t-branch)
                          (error "incompatible branches from " prev " to "
                                 t-branch " vs. " current))))))))
    ((loop) (fail))))

(define (compatible-branches? variant1 variant2)
  (or (includes? variant1 variant2)
      (includes? variant2 variant1)))

(define (possibly-extend-to result)
  (if (includes? result current)
      (set-current! result)))

(define (includes? large small)
  (prefix? (reverse small) (reverse large)))

(define (prefix? prefix xs)
  (cond ((null? prefix) #t)
        ((null? xs) #f)
        ((not (type= (car prefix) (car xs))) #f)
        (else (prefix? (cdr prefix) (cdr xs)))))

(define (type= t1 t2)
  (eq? t1 t2)) ; for now

(infer '(= (if (+) (+))))
;(infer '(= (if (+) (drop-int))))


(display initial)
(display current)
(newline)
