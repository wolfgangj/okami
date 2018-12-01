# `okami` language specification (preliminary version)

## Introduction

This document contains the specification of the `okami` programming language.
`okami` is a modern stack-based systems language. 
It is statically typed and supports generics, tagged unions and non-nullable types.
It features memory management based on regions.
It is an intentionally small language that can be readiely learned in its entirety.

## Language Elements

### Basic Syntax Overview

#### Whitespace and Comment

Syntax of whitespace:

    <whitespace> ::= ( space | tab | newline | <comment> )+
    
    <comment> ::= `;`, [^\n]*, newline

- A comment starts with a colon (`;`) and ends at the end of a line.
- Whitespace is a non-empty sequence of spaces, tabs, newlines and comments.
- Whitespace is required to separate identifiers.
- It may also appear between other syntactic elements (tokens).
  It may not appear inside of identifiers, characters and numbers.

#### Identifier

    public:
    
    <identifier> ::= <id-char-first> <id-char>* | <dash-identifier>
    
    <special-id> ::= [A-Z] <id-char>*

    private:
    
    <id-char> ::= ( [A-Z] | [0-9] | <id-char-first> )
    
    <id-char-first> ::= ( [a-z] | `!` | `%` | `^` | `*` | `_`
                          | `+` | `=` | `?` | `/` | `>` | `<` )
    
    <dash-identifier> ::= `-` ( <id-char-first> | [A-Z] )? <id-char>*
    
- A `<special-id>` is used for constants and formal arguments of generics.
- By convention, constants should have names longer that a single character,
  use all-uppercase and possibly underscores as separator (e.g. `SIZE`, `DATA_ID`).
  Formal arguments of generics may be a single character long; if they are longer,
  they should use lowercase and separate words with dashes (e.g. `T`, `HTML-Element`).
- The rule for `<dash-identifier>` exists to avoid ambiguities with nubers.

##### Keywords

- There are no reserved words, everything that follows the rules for valid identifiers can be used.
- However, certain words have special meaning in various contexts:
  - `private` `protected` `public` - see section "Module and Scope"
  - `record` `union` - see section "Definition of Data Structures"
  - `if` `else` `while` `do` `until` `for` `has` `in` `is` - see section "Control Structures"

##### Examples

    ;; valid <identifier>:
    a
    x0
    abc!
    ?<>
    hello-world
    if
    __N_42
    iCanNotReadThis
    -
    --
    -nil?
    
    ;; valid <special-id>:
    T
    Result
    KEY
    T1
    In&Out
    
    ;; invalid:
    1+     ; may not start with a number
    foo@   ; the @-sign is a token of its own
    -10+2  ; initial dash may not be followed by digit

#### Number

##### Syntax

    public:

    <integer> ::= <decimal-int> | <hex-int> | <oct-int> | <bin-int>
    
    <float> ::= <normal-float> | <scientific-float> | <special-float>
    
    private:

    <decimal-int> ::= `-`? [0-9]+
    
    <hex-int> ::= `#x` [0-9a-fA-F]+
    
    <oct-int> ::= `#o` [0-7]+
    
    <bin-int> ::= `#b` [01]+
    
    <special-float> ::= `#\NaN` | `#\Inf` | `#\-Inf`
    
    <normal-float> ::= `-`? [0-9]+ `.` [0-9]+
    
    <scientific-float> ::= `-`? [0-9] `.` [0-9]+ [eE] `-`? [0-9]+ 

##### Semantics
##### Examples

None yet.

#### String
#### Character

##### Syntax

    public:
    
    <char> ::= `#'` <char-spec> `'`

    private:
    
    <char-spec> := [a-zA-Z0-9~`!@#$%^&*()_-=+{}|;:"<>,.?/ ] |
                   `\\` | `\n` | `\t` | `[` | `]` | `U+` [0-9a-zA-Z]{4}

##### Examples

    #'a'
    #'\n'
    #'?'
    #'U+03F8'

#### Other characters with special meaning

~@#()[]{}:.

### Toplevel

#### Syntax

    public:
    
    <toplevel> ::= ( <definition> | <declaration> | <scope> )*
    
    private:
    
    <scope> ::= ( `private` | `protected` | `public` ) `:`
    
    <definition> ::= ( <executable> | <global> | <scoped> | <constant>
                       <type-def> | <enum> | <record> | <union> )
    
    <declaration> ::= `declare` ( <exec-header> | <decl-data> )
    
    <decl-data> ::= ( `record` | `union` ) `:` <identifier>

#### Semantics

- The `<toplevel>` is the entry point of parsing a file.

### Definition of Executable Words

#### Syntax

    public:
    
    <exec-header> ::= `:` <identifier> <prototype>
    
    <executable> ::= <exec-header> <block>
    
    <prototype> ::= `(` <type>* `::` <type> `)`

#### Semantics

#### Examples

None yet.

### Definition of Constants

#### Syntax

    public:
    
    <constant> ::= `const` `:` <special-id> `.` <type> <block>

#### Semantics

- Defines a constant value that can be used in blocks by using its name.
- The block may only use built-in operations (see section "Built-In Operations"), other constants and literals.
- The block must have the type `(:: <type>)`.

#### Examples

    const: PI . float [3.1415926535897932]
    const: NEWLINE . char [#'\n']
    
    const: HALF_ANSWER . int 21
    : answer (:: int)
        [HALF_ANSWER 2 *]

### Definition of Global Variables
### Definition of Scoped Variables
### Definition of Simple Types

#### Type Name

A new type without any semantics attached can be created as:

    <type-def> ::= `type` `:` <identifier>

#### Enum

    <enum> ::= `enum` `:` <identifier> `{` <identifier>+ `}`

### Definition of Data Structures

There are two types of data structures:
Records (sometimes called "structures" or "structs") and unions.
They both consist of elements, which are syntactically specified as:

    <element> ::= <identifier> `.` <type>

#### Record

    <record> ::= `record` `:` <identifier> <generic-formal>? `{` <element>+ `}`

##### Syntax
##### Semantics
##### Examples

None yet.

#### Union

##### Syntax

    <union> ::= `union` `:` <identifier> <generic-formal>? `{` <element>+ `}`

##### Semantics
##### Examples

None yet.

### Instruction

#### Syntax

#### Semantics
#### Examples

None yet.

### Block

#### Syntax

    <block> ::= `[` <instruction>* `]`

- The square brackets `[ ]` are also used for type arguments of generics.
  - However, there is no amiguity since there is no contexts in which both could appear.

#### Semantics

The instructions in the block will be executed from left to right.

#### Examples

None yet.

### Instructions

### Built-In Operations

The following operations are built-in:

Type 1:

- `+` `-` `*` `/` `mod` `>` `<` `=` `<>` `>=` <=`
- `and` `or` `not` `xor` `shift<` `shift>`
- `this` `that` `them` `-this` `-that` `-them` `x` `tuck`
- `>aux` `aux>` `aux` `-aux`
- `cell` `cell+` `cells`

Type 2:

- `@` `!` `+!` `-!` `on` `off`
- `^` `?^`

- Type 1 Built-Ins can be used to define constants.
- Type 1 and 2 Built-Ins can be used without linking code with the `okami` runtime library.
- The semantics of these operations is defined in the section "Library"

### Control Structures

- Control structures can be used without linking code to the `okami` runtime library.

    <control> ::= <if> | <while> | <until> | <has> | <for> | <is>

#### if else
#### while do
#### until
#### has else
#### for
#### is do

### Creation of Data Structures

#### Syntax

#### Semantics

#### Examples

    record: point {
      x . int
      y . int
    }
    
    : point0 (-- @point)
        [0 as:x 0 as:y new:point]

### call


#### Syntax

    <call> ::= `call`

#### Semantics

- `call` calls an executable word.
  Therefore, `call` has the stack effect of the executable word on the top of the stack.

#### Examples

    : add7 (int :: int)
        [7 +]
    
    : twice (int (int :: int) :: int)
        [tuck call x call]
    
    : add14 (int :: int)
        [#:add7 twice]

### Type

#### Syntax

    public:
    
    <type> ::= ( <identifier> | <special-id> | <address> | <nullable> | <prototype> |
                 <type> <generic-actual> )
    
    private:
    
    <address> ::= `@` <type>
    
    <nullable> ::= `~` <type>

#### Semantics
#### Examples

None yet.

### Built-In Types

The following types are built-in, i.e. they are always available:

- `int` (integer literals do have this type)
- `char` (character literals do have this type)
- `str` (string literals have type `@str`)
- `bool` (an `enum` of two values `true` and `false` for boolean logic)
- `any` (can be used as anything without type casts; use with care)

### Generics

#### Syntax

    public:
    
    <generic-actual> ::= `[` ( <type> | <generic-arg> )+ `]`
    
    <generic-formal> ::= `[` <special-id>+ `]`

#### Semantics
#### Examples

None yet.

### Module and Scope

## Library

## Syntax Reference

### Notation

### Specification
