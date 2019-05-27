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

;; general helpers

(define (bool x) (not (not x)))

(define (exist? name alist)
  (bool (assq name alist)))

(define (fail)
  (eval '(#f)))

(define (say . text)
  (for-each display text)
  (newline))

(define (error . text)
  (apply say text)
  (fail))

(define (note x)
  (say "NOTE:" x)
  x)

(define call/cc call-with-current-continuation)

(define (car* x)
  (if (pair? x)
      (car x)
      x))

(define (cdr* x)
  (if (pair? x)
      (cdr x)
      x))

;; application logic starts here

(define defs '((+ (int int) (int))
               (drop (any) ())
               (= (int int) (bool))
               (foo () ((addr int)))
               (at ((addr int)) (int))
               (nil? ((ptr any)) (bool))
               (not (bool) (bool))))

(define cuts '((while (not (if ((break)))))
               (until ((if ((break)))))))

(define recs '((point (x int) (y int))
               (triangle (p1 point) (p2 point) (p3 point))))

(define thes '((pos point 1)
               (n int 1)))

(define types '(int bool byte size))

(define (def? name) (exist? name defs))
(define (cut? name) (exist? name cuts))
(define (rec? name) (exist? name recs))
(define (the? name) (exist? name thes))
(define (type? name) (bool (memq name types)))

(define (definable-call name)
  (if (or (def? name)
          (cut? name)
          (the? name))
      (error name " defined twice")
      name))

(define (definable-datatype name)
  (if (or (type? name)
          (rec? name))
      (error "type " name " defined twice")
      name))

(define (type+ t)
  (set! types (cons (definable-datatype t) types)))

(define (the+ name type amount)
  (set! thes (cons (list (definable-call name) type amount)
                   thes)))

(define (cut+ name block)
  (set! cuts (cons (list (definable-call name) block)
                   cuts)))

(define expected '())
(define current '())

(define (set-current! types)
  ;(say "new:" types)
  (set! current types))

(define (current+ t)
  (if (and (symbol? t) (rec? t))
      (error "cannot push rec " t " directly"))
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
  (for-each (lambda (element)
              (cond ((symbol? element)
                     (cond ((def? element) (apply-call-effect element))
                           ((cut? element) (apply-cut-effect element))
                           ((the? element) (let ((type (cadr (assq element thes))))
                                             (current+ (list 'addr type))))
                           (else (error "symbol " element " not known"))))
                    ((number? element) (current+ 'int))
                    ((string? element) (current+ '(addr byte)))
                    ((list? element) (apply-structure-effect element))))
            code))

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

(define (referenced-type t)
  (if (eq? t 'any) t (cadr t)))

(define (apply-structure-effect struct)
  (call/cc
   (lambda (return)
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
       ((ehas) (let ((top (pop-current)))
                 (if (not (type= '(ptr any) top))
                     (error "expected ptr on stack but got " top)
                     (let ((prev current))
                       (current+ (list 'addr (referenced-type top)))
                       (apply-effect (cadr struct))
                       (let ((t-branch current))
                         (set-current! prev)
                         (apply-effect (caddr struct))
                         (if (not (branch= t-branch current))
                             (error "incompatible branches from " prev
                                    " to " t-branch " vs. " current)
                             (unify-branches! t-branch current)))))))
       ((has) (let ((top (pop-current)))
                (if (not (type= '(ptr any) top))
                    (error "expected ptr on stack but got " top)
                    (let ((prev current))
                      (current+ (list 'addr (referenced-type top)))
                      (apply-effect (cadr struct))
                      (if (not (branch= prev current))
                          (error "on-branches left stack as " current
                                 " instead of " prev)
                          (unify-branches! prev current))))))
       ((cast) (if (null? current)
                   (error "cast to " (cadr struct) " on empty stack")
                   (set-current! (cons (cadr struct)
                                       (cdr current)))))
       ((at) (let ((type (pop-current)))
               (if (not (type= '(addr any) type))
                   (error "tos was " type " when @ was called")
                   (current+ (referenced-type type)))))
       ((set) (let* ((addr (pop-current))
                     (val (pop-current)))
                (if (or (not (type= '(addr any) addr))
                        (not (type= val (referenced-type addr))))
                    (error "setting " addr " with " val
                           " via ! operation"))))
       ((field) (let ((field-name (cadr struct))
                      (tos-type (pop-current)))
                  (if (or (not (type= tos-type '(addr any)))
                          (not (rec? (referenced-type tos-type))))
                      (error "tos was " tos-type
                             " instead of address of a record"
                             " when requesting field " field-name))
                  (let* ((rec-name (cadr tos-type))
                         (rec-fields (cdr (assq rec-name recs)))
                         (field-type (car* (cdr* (assq field-name
                                                       rec-fields)))))
                    (if field-type
                        (current+ (list 'addr field-type))
                        (error "field " field-name " is not in " rec-name)))))
       ((x) (let* ((tos (pop-current))
                   (nos (pop-current)))
              (current+ tos)
              (current+ nos)))
       ((this) (let* ((tos (pop-current)))
                 (current+ tos)
                 (current+ tos)))
       ((that) (let* ((tos (pop-current))
                      (nos (pop-current)))
                 (current+ nos)
                 (current+ tos)
                 (current+ nos)))
       ((them) (let* ((tos (pop-current))
                      (nos (pop-current)))
                 (current+ nos)
                 (current+ tos)
                 (current+ nos)
                 (current+ tos)))
       ((tuck) (let* ((tos (pop-current))
                      (nos (pop-current)))
                 (current+ tos)
                 (current+ nos)
                 (current+ tos)))
       ((drop) (pop-current))
       ((nip) (let* ((tos (pop-current))
                     (nos (pop-current)))
                (current+ tos)))
       ((dropem) (pop-current) (pop-current))
       ((stop) (if (not (branch= current expected))
                   (error "stop at wrong stack state "
                          current " instead of " expected)
                   (begin
                     (set-current! 'stopped)
                     (return))))
       ((break) (begin
                  (check-loop-break current)
                  (set-current! 'stopped)))
       ((loop) (begin
                 (enter-loop)
                 (apply-effect (cadr struct))
                 (end-of-loop)))))))

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

;; lexer

(define ahead #f)

(define (token-ahead)
  (if (not ahead)
      (set! ahead (token)))
  ahead)

(define (token)
  (if ahead
      (let ((result ahead))
        (set! ahead #f)
        result)
      (begin
        (skip-to-token)
        (token-here))))

(define (identifier? token)
  (eq? 'identifier (car token)))

(define (keyword? token)
  (eq? 'keyword (car token)))

(define (any-cast?)
  (case (peek-char)
    ((#\space #\newline #\! #\@ #\; #\] #\#) #t)
    (else #f)))

(define (token-here)
  (let ((c (read-char)))
    (case c
      ((#\@) '(special at))
      ((#\^) '(special circumflex))
      ((#\:) (if (eq? (read-char) #\:)
                 '(special double-colon)
                 (error "syntax error: colon followed by invalid character")))
      ((#\!) '(special bang))
      ((#\() '(special open-paren))
      ((#\)) '(special close-paren))
      ((#\[) '(special open-bracket))
      ((#\]) '(special close-bracket))
      ((#\.) (let ((next (token-here)))
               (if (identifier? next)
                   (list 'field (cadr next))
                   (error "dot not followed by identifier"))))
      ((#\") (list 'string (read-string)))
      ((#\#) (if (any-cast?)
                 '(special standalone-hash)
                 '(special hash)))
      ((#\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9)
       (list 'int (read-int (char->digit c))))
      (else
       (if (eof-object? c)
           '(eof)
           (let ((next (peek-char)))
             (if (and (eq? c #\-)
                      (digit? next))
                 (list 'int (- (read-int (char->digit (read-char)))))
                 (let ((id (rest-of-identifier (list c) next)))
                   (if (eq? (peek-char) #\:)
                       (begin (read-char)
                              (list 'keyword id))
                       (list 'identifier id))))))))))

(define (skip-to-token)
  (case (peek-char)
    ((#\space #\newline) (read-char) (skip-to-token))
    ((#\;) (let loop ((c (read-char)))
             (if (or (eq? c #\newline)
                     (eof-object? c))
                 (skip-to-token)
                 (loop (read-char)))))))

(define (read-string)
  (let loop ((chars '())
             (next (read-char)))
    (cond ((eof-object? next) (error "eof in string"))
          ((eq? next #\") (list->string (reverse chars)))
          (else (loop (cons next chars)
                      (read-char))))))

(define (rest-of-identifier before next)
  (cond ((eof-object? next) (rest-of-identifier before #\newline))
        ((identifier-char? next)
         (let ((next (read-char))) ; due to undefined evaluation order
           (rest-of-identifier (cons next before)
                               (peek-char))))
        (else
         (list->string (reverse before)))))

(define (identifier-char? c)
  (case c
    ((#\` #\~ #\! #\@ #\# #\% #\^ #\& #\( #\) #\\
      #\| #\[ #\] #\{ #\} #\; #\: #\' #\" #\. #\,
      #\space #\newline)
     #f)
    (else #t)))

(define (digit? c)
  (case c
    ((#\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9) #t)
    (else #f)))

(define (char->digit c)
  (- (char->integer c) (char->integer #\0)))

(define (read-int before)
  (let ((c (peek-char)))
    (case c
      ((#\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9)
       (read-int (+ (char->digit (read-char))
                    (* 10 before))))
      (else before))))

;; parser

(define (parse-type)
  (let ((next (token)))
    (case (car next)
      ((special)
       (case (cadr next)
         ((at) (list 'addr (parse-type)))
         ((circumflex) (list 'ptr (parse-type)))
         ((open-paren) (fail)) ; TODO
         (else (error "expected type"))))
      ((identifier) (string->symbol (cadr next)))
      (else (error "expected type")))))

(define (parse-toplevel)
  (let ((next (token)))
    (case (car next)
      ((eof) next)
      ((identifier)
       (case (string->symbol (cadr next))
         ((def) (fail))
         ((rec) (fail))
         ((cut) (let ((name (token)))
                  (cond ((not (identifier? name))
                         (error "expected identifier"))
                        ((not (open-bracket? (token)))
                         (error "parse error: expected opening bracket"))
                        (else (cut+ (definable-call (string->symbol (cadr name)))
                                    (parse-block))))))
         ((the) (let ((next (token))
                      (amount 1))
                  (if (equal? next '(special open-bracket))
                      (begin
                        (set! next (token))
                        (if (not (eq? 'int (car next)))
                            (error "expected int"))
                        (set! amount (cadr next))
                        (if (not (equal? (token)
                                         '(special close-bracket)))
                            (error "expected closing bracket"))
                        (set! next (token))))
                  (if (not (keyword? next))
                      (error "expected name of variable and colon"))
                  (let ((type (parse-type)))
                    (the+ (string->symbol (cadr next))
                          type
                          amount))))
         ((type) (let ((name-token (token)))
                   (if (identifier? (car name-token))
                       (type+ (string->symbol (cadr name-token)))
                       (error "expected identifier, got " name-token))))
         ((dec) (fail))
         (else (error "unknown keyword " (cadr next)))))
      (else (error "parse error at toplevel, token " next)))))

(define (open-bracket? x)
  (equal? x '(special open-bracket)))

(define (with-else keyword)
  (case keyword
    ((if) 'eif)
    ((has) 'ehas)
    (else (error "internal error"))))

;; open-bracket has been found, parse rest of block
(define (parse-block)
  (let loop ((next (token)))
    (cond ((equal? next '(special close-bracket)) '())
          ((eq? (car next) 'keyword)
           (let ((keyword (string->symbol (cadr next))))
             (case keyword
               ((if has)
                (if (not (open-bracket? (token)))
                    (error "parse error: expected opening bracket")
                    (let ((block (parse-block)))
                      (if (equal? (token-ahead) '(keyword "else"))
                          (let* ((else-token (token))
                                 (bracket-token (token)))
                            (if (not (open-bracket? bracket-token))
                                (error "parse error: "
                                       "expected opening bracket")
                                (let ((else-block (parse-block)))
                                  (cons (list (with-else keyword)
                                              block else-block)
                                        (loop (token))))))
                          (cons (list keyword block)
                                (loop (token)))))))
               ((loop)
                (if (not (open-bracket? (token)))
                    (error "parse error after `loop:`")
                    (let ((block (parse-block)))
                      (cons (list 'loop block)
                            (loop (token))))))
               (else (error "unexpected keyword " next)))))
          ((eq? (car next) 'identifier)
           ;; TODO: detect stop, break, this, + etc.
           (cons (string->symbol (cadr next))
                 (loop (token))))
          ((or (eq? (car next) 'int)
               (eq? (car next) 'string))
           (cons (cadr next)
                 (loop (token))))
          ((eq? (car next) 'field)
           (cons (list 'field (string->symbol (cadr next)))
                 (loop (token))))
          (else (error "invalid token in block" next)))))
