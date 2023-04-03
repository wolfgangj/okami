# The Wok programming language

Work in progress, here's a brain dump of the current idea for how it will look like:

```
class foo {
  x: int     ; attributes are class-private by default
  new (int)  ; constructor
    [@x]     ; with @ we set attributes
  bar (int)  ; methods are public by default
    [x + @x] ; like x = x + arg
private
  switch-x (int :: int)
    [x alt @x]     ; set x and return old value
  get-x (: int)    ; single colon is enough
    [x]
shared             ; class-private (visible to other method blocks for this class)
  pick (bool :: int)
    [if:[x] else:[0]]
  ; only kind of loop, can leave it with while, until or break:
  double-times (int :: int)
    [x loop:[that 0 = until, 2 *, alt 1 - alt] nip]  ; comma is whitespace
}

ops {              ; global
  lala [blub blub] ; no args, no output, so empty stack effect is optional
private            ; only visible in this ops block
  blub [something]
}

ops foo {      ; add methods to foo
  lele [lala]
}

trait greet {
  hello (str)
  hi  ; has no stack effect
}

ops hello: foo {  ; implement trait for class
  hello (str)
    ["hello " say say]
  hi
    ["hi" say]
}

class bar {
  x: int [0]        ; default value code will be implicitly added to constructor
  ops foo {         ; add methods to foo which can access bar
    combine (: int) ; these are always private to this block
      [x \x +]      ; \x refers to the x from bar
  }
}

class (T)list { ; generic
  first: T
  rest: ((T)list)maybe
}

class (T:greet)greetgroup {  ; generic with arg type that must implement trait
  first: T
  rest: ((T)greetgroup)maybe
  greet-all
    [first hi, rest Just:[greet-all] else:[]]
}

choice toggle { On Off }

choice (T)maybe {
  Just: T
  None
}

ops (T)maybe {
  or-else (T :: T)
    [self Just:[nip] None:[]]
}

choice xmlnode {
  Tag: tag
  Cdata: cdata
  Comment: comment
}

ops xmlnode {
  ; picking choices must always be exhaustive, but you can discard with 'else':
  clean (: xmlnode)
    [self Comment:["" new:cdata] else:[self]]
}

; unused characters: $%^&|'
```
