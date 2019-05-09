;; wok.scm

(define defs '((+ (int int) (int))
               (drop-int (int) ())
               (= (int int) (bool))
               (not (bool) (bool))))

(define (error . text)
  (for-each display text)
  (newline)
  (#f))

(define initial '())

(define (initial+ t)
  (set! initial (cons t initial)))

(define current '(int))

(define (current+ t)
  (set! current (cons t current)))

(define (current- t)
  (if (null? current)
      (initial+ t)
      (if (eq? (car current) t)
          (set! current (cdr current))
          (error "requested " t "but having " (car current)))))

(define (apply-effect-of op)
  (let ((effect (cdr (assq op defs))))
    (current-multi- (car effect))
    (current-multi+ (cadr effect))))

(define (current-multi+ types)
  (for-each current+ (reverse types)))

(define (current-multi- types)
  (for-each current- types))

(apply-effect-of '=)


(display initial)
(display current)
(newline)
