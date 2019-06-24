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

(define (filter keep? xs)
  (cond ((null? xs) '())
        ((keep? (car xs)) (cons (car xs) (filter keep? (cdr xs))))
        (else (filter keep? (cdr xs)))))

;; application logic starts here

(define defs '())

(define cuts '((while ((not) (if ((break)))))
               (until ((if ((break)))))))

(define recs '())

(define thes '())

(define decs '()) ; declared but not yet defined

(define types '(any int bool byte size))

(define (def? name) (exist? name defs))
(define (dec? name) (exist? name decs))
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

(define (rec+ name fields)
  (set! recs (cons (list (definable-datatype name) fields)
                   recs))
  (validate-fields fields))

(define (the+ name type amount)
  (validate-vartype type)
  (set! thes (cons (list (definable-call name) type amount)
                   thes)))

(define (cut+ name block)
  (set! cuts (cons (list (definable-call name) block)
                   cuts)))

(define (def+ name effect block)
  (set! defs (cons (list (definable-call name) effect block)
                   defs))
  (validate-effect effect)
  (set! expected (cadr effect))
  (validate-code effect block))

(define (dec+ name effect)
  (set! decs (cons (list (definable-call name) effect)
                   decs)))

;; remove if it exists, error if exists and effect does not match
(define (dec- name effect)
  (let ((dec-effect (car* (cdr* (assq name decs)))))
    (if dec-effect
        (if (not (equal? dec-effect effect))
            (error "declared stack effect does not match definition")
            (set! decs (filter (lambda (x)
                                 (not (eq? (car x) name)))
                               decs))))))

(define (fields-of-rec recname)
  (cadr (assq recname recs)))

(define (validate-fields fields)
  (for-each (lambda (field)
              (validate-type (cadr field)))
            fields))

(define (validate-type type)
  (cond ((list? type) (validate-type (cadr type)))
        ((symbol? type)
         (if (not (or (rec? type)
                      (type? type)))
             (error "type does not exist: " type)))
        (else (error "internal error"))))

(define (validate-effect effect)
  (validate-stack-types (car effect))
  (validate-stack-types (cadr effect)))

(define (validate-stack-types types)
  (for-each (lambda (t)
              (if (not (valid-type-on-stack? t))
                  (error "type " t " cannot be pushed on stack")))
            types))

(define (valid-type-on-stack? type)
  (cond ((list? type) (validate-type (cadr type)) #t)
        ((type? type) #t)
        ((rec? type) #f)
        (else (error "type does not exist: " type))))

(define (validate-vartype type)
  (cond ((addr? type)
         (error type " in variable, but addr would start invalid"))
        ((rec? type)
         (for-each validate-vartype
                   (map (lambda (field) (cadr field))
                        (fields-of-rec type))))))

(define (validate-code effect code)
  (set-current! (car effect))
  (apply-effect code)
  ;; TODO: this handles 'stopped' wrong.
  (if (not (branch= (cadr effect) current))
      (error "declared effect " (cadr effect)
             " does not match actual effect " current)))

(define (addr? t)
  (and (list? t)
       (eq? (car t) 'addr)))

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

(define (effect-of name)
  (or (car* (cdr* (assq name defs)))
      (car* (cdr* (assq name decs)))
      (error name " not defined or declared")))

(define (apply-call-effect op)
  (let ((effect (effect-of op)))
    (current-replace (car effect) (cadr effect))))

(define (apply-cut-effect name)
  (apply-effect (cadr (assq name cuts))))

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
                           ((dec? element) (apply-call-effect element))
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
                         (rec-fields (fields-of-rec rec-name))
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
       ((= <>) (let* ((tos (pop-current))
                      (nos (pop-current)))
                 (if (not (type= tos nos))
                     (error "types " tos " and " nos " do not match"))
                 (current+ 'bool)))
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
                 (end-of-loop)))
       (else (error "internal error: unknown builtin"))))))

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
         ((def) (let ((name-token (token)))
                  (cond ((not (identifier? name-token))
                         (error "expected identifier"))
                        ((not (open-paren? (token)))
                         (error "parse error: expected opening paren"))
                        (else
                         (let ((effect (parse-effect)))
                           (if (not (open-bracket? (token)))
                               (error "expected block"))
                           (let ((name (string->symbol (cadr name-token))))
                             (dec- name effect)
                             (def+ name effect (parse-block))))))))
         ((rec) (let ((name (token)))
                  (cond ((not (identifier? name))
                         (error "expected identifier"))
                        ((not (open-paren? (token)))
                         (error "parse error: expected opening paren"))
                        (else
                         (rec+ (string->symbol (cadr name))
                               (parse-fields))))))
         ((cut) (let ((name (token)))
                  (cond ((not (identifier? name))
                         (error "expected identifier"))
                        ((not (open-bracket? (token)))
                         (error "parse error: expected opening bracket"))
                        (else
                         (cut+ (definable-call (string->symbol (cadr name)))
                               (parse-block))))))
         ((the) (apply the+ (parse-data)))
         ((type) (let ((name-token (token)))
                   (if (identifier? (car name-token))
                       (type+ (string->symbol (cadr name-token)))
                       (error "expected identifier, got " name-token))))
         ((dec) (let ((name-token (token)))
                   (cond ((not (identifier? name-token))
                          (error "expected identifier, got " name-token))
                         ((not (open-paren? (token)))
                          (error "parse error: expected openening  paren"))
                         (else
                          (dec+ (string->symbol (cadr name-token))
                                (parse-effect))))))
         (else (error "unknown keyword " (cadr next)))))
      (else (error "parse error at toplevel, token " next)))))

(define (open-bracket? x)
  (equal? x '(special open-bracket)))
(define (open-paren? x)
  (equal? x '(special open-paren)))

(define (with-else keyword)
  (case keyword
    ((if) 'eif)
    ((has) 'ehas)
    (else (error "internal error"))))

;; for `the` and `rec` fields.
(define (parse-data)
  (let ((next (token))
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
      (list (string->symbol (cadr next))
            type
            amount))))

;; open-bracket has been found, parse rest of block
(define (parse-block)
  (let loop ((next (token)))
    (cond ((equal? next '(special close-bracket)) '())
          ((or (equal? next '(special at))
               (equal? next '(special bang)))
           (cons (list (cadr next))
                 (loop (token))))
          ((equal? next '(special standalone-hash))
           (cons '(cast any) (loop (token))))
          ((equal? next '(special hash))
           (let ((type (parse-type)))
             (cons (list 'cast type) (loop (token)))))
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
           (cons (symbol->block-element (string->symbol (cadr next)))
                 (loop (token))))
          ((or (eq? (car next) 'int)
               (eq? (car next) 'string))
           (cons (cadr next)
                 (loop (token))))
          ((eq? (car next) 'field)
           (cons (list 'field (string->symbol (cadr next)))
                 (loop (token))))
          (else (error "invalid token in block" next)))))

(define (symbol->block-element sym)
  (case sym
    ((x this that them tuck drop nip dropem stop break
        = <> > < >= <= << >> + - * / fetch store)
     (list sym))
     (else sym)))

;; open-paren was read, parse until close-paren
(define (parse-effect)
  (let* ((remove (let loop ()
                   (if (equal? (token-ahead) '(special double-colon))
                       (begin (token) '())
                       (let ((type (parse-type)))
                         (cons type (loop))))))
         (add (let loop ()
                   (if (equal? (token-ahead) '(special close-paren))
                       (begin (token) '())
                       (let ((type (parse-type)))
                         (cons type (loop)))))))
    (list remove add)))
    
;; fields of a record, open-paren was read before.
(define (parse-fields)
  (let loop ()
    (if (equal? (token-ahead) '(special close-paren))
        (begin (token)
               '())
        (let ((field (parse-data)))
          (cons field (loop))))))

;;; code generator

(define emit say)

(define last-label 0)

(define (genlabel)
  (set! last-label (+ last-label 1))
  last-label)

(define (compile-if then-branch)
  (let ((end (genlabel)))
    (emit "cmp r0, #0")
    (emit "pop r0")
    (emit "be .L" end)
    (compile-block then-branch)
    (emit ".L" end ":")))

(define (compile-eif then-branch else-branch)
  (let* ((middle (genlabel))
         (end (genlabel)))
    (emit "cmp r0, #0")
    (emit "pop r0")
    (emit "be .L" middle)
    (compile-block then-branch)
    (emit "b .L" end)
    (emit ".L" middle ":")
    (compile-block else-branch)
    (emit ".L" end ":")))

(define (compile-has then-branch)
  (let ((end (genlabel)))
    (emit "cmp r0, #0")
    (emit "pope r0")
    (emit "be .L" end)
    (compile-block then-branch)
    (emit ".L" end ":")))

(define (compile-ehas then-branch else-branch)
  (let* ((middle (genlabel))
         (end (genlabel)))
    (emit "cmp r0, #0")
    (emit "be .L" middle)
    (compile-block then-branch)
    (emit "b .L" end)
    (emit ".L" middle ":")
    (emit "pop r0")
    (compile-block else-branch)
    (emit ".L" end ":")))

(define (compile-loop body)
  (let ((start (genlabel)))
    (push-loop (genlabel))
    (emit ".L" start ":")
    (compile-block body)
    (emit "b .L" start)
    (emit ".L" (pop-loop) ":")))

(define open-loops '())

(define (top-loop)
  (if (null? open-loops)
      (error "no open loop"))
  (car open-loops))

(define (push-loop label)
  (set! open-loops (cons label open-loops)))

(define (pop-loop)
  (let ((res (top-loop)))
    (set! open-loops (cdr open-loops))
    res))

(define (compile-break)
  (emit "b .L" (top-loop)))

(define (compile-block code)
  (for-each compile-element code))

(define (compile-stop)
  (emit "ldr pc, r12 + #4")) ;; as above

(define (compile-element el)
  (cond ((list? el)
         (case (car el)
           ((if) (compile-if (cadr el)))
           ((eif) (compile-eif (cadr el) (caddr el)))
           ((loop) (compile-loop (cadr el)))
           ((break) (compile-break))
           ((stop) (compile-stop))
           ((cast) #f) ; noop
           ((at) (emit "ldr r0, r0"))
           ((set) (emit "pop r1") (emit "str r0, r1") (emit "pop r0"))
           ((this) (emit "push r0"))
           ((that) (emit "ldr r1, sp") (emit "push r1"))
           ((them) (emit "ldr r1, sp") (emit "push r0") (emit "push r1"))
           ((drop) (emit "pop r0"))
           ((dropem) (emit "TODO")) ; TODO: can do in 1 instruction?
           ((nip) (emit "add sp, #4"))
           ((x) (emit "ldr r1, sp") (emit "str r0, sp") (emit "mov r0, r1"))
           ((tuck) (emit "ldr r1, sp") (emit "str sp, r0") (emit "push r1"))
           ((+) (emit "pop r1") (emit "add r0, r0, r1"))
           ((-) (emit "pop r1") (emit "sub r0, r1, r0"))
           ((*) (emit "pop r1") (emit "mul r0, r0, r1"))
           ((/) (emit "pop r1") (emit "idiv r0, r1, r0"))
           ((=)
            (emit "pop r1") (emit "cmp r0, r1")
            (emit "mov r0, #0") (emit "move r0, #-1"))
           ((<>)
            (emit "pop r1") (emit "cmp r0, r1")
            (emit "mov r0, #-1") (emit "move r0, #0"))
           ((not) (emit "not r0, r0"))
           ((and) (emit "pop r1") (emit "and r0, r0, r1"))
           ((or) (emit "pop r1") (emit "orr r0, r0, r1"))
           ((xor) (emit "pop r1") (emit "eor r0, r0, r1"))
           (else (error "internal error: unknown builtin " el))))
        ((symbol? el)
         (cond ((def? el) (emit "bl " el))
               ((cut? el) (compile-block (cadr (assq el cuts))))
               ((the? el) (error "TODO: not implemented"))))
        ((number? el)
         (emit "push r0")
         (emit "moveval r0, #" el))
        (else (error "internal error: don't know how to compile " el))))

(define (compile-def def)
  (emit (obj-symbol (car def)) ":")
  (emit "str lr, r12, #-4") ;; TODO: this is probably not correct yet
  (compile-block (caddr def))
  (compile-stop))

(define (obj-symbol identifier)
  identifier) ; TODO: convert +-*/%=><?

(define (compile)
  (emit ".data")
  ;(for-each compile-the thes)
  (emit ".text")
  (for-each compile-def defs))
