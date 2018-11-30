# `okami` language specification (preliminary version)

## Introduction

This document contains the specification of the `okami` language.
`okami` is a statically typed stack-based low-level language with support for generics.
It features memory management based on regions.
It is an intentionally small language that can be readiely learned in its entirety.
It was mostly influenced by Forth, Go, Lisp and ML.

## Language Elements

### Basic Syntax Overview

#### Whitespace and Comment

- A comment starts with a colon (`;`) and ends at the end of a line.
- Whitespace is a non-empty sequence of spaces, tabs, newlines and comments.
- Whitespace is required to separate identifiers.
- It may also appear between other syntactic elements (tokens)

#### Keywords

- There are no reserved words.
- However, certain words have special meaning in various contexts:
  - `private protected public` - see section "Module and Scope"
  - `record union` - see section "Definition of Data Structures"
  - `if else while do until for` - see section "Control Structures"

#### Identifier

    <identifier> ::= <id-char-first> <id-char>*
    
    <id-char> ::= ( [A-Z] | [0-9] | <id-char-first> )
    
    <id-char-first> ::= ( [a-z] | `!` | `%` | `^` | `*` | `-` | `_`
                          | `+` | `=` | `?` | `/` | `>` | `<` )
    
    <special-id> ::= [A-Z] <id-char>*

- A `<special-id>` is used for constants and formal arguments of generics.
- By convention, constants should have names longer that a single character,
  use all-uppercase and possibly underscores as separator (e.g. `SIZE`, `DATA_ID`).
  Formal arguments of generics may be a single character long; if they are longer,
  they should use lowercase and separate words with dashes (e.g. `T`, `HTML-Element`).

##### Examples

    ;; valid <identifier>:
    a
    x0
    abc!
    ?<>
    hello-world
    __N_42
    iCanNotReadThis
    
    ;; valid <special-id>:
    T
    Result
    KEY
    T1
    In&Out
    
    ;; invalid:
    1+     ; may not start with a number
    foo@   ; the @-sign is a token of its own

#### Number
#### String
#### Character
#### Other characters with special meaning

~@#()[]{}:.

### Toplevel

#### Syntax

    <toplevel> ::= ( <definition> | <scope> )*
    
    <scope> ::= ( `private` | `protected` | `public` )
    
    <definition> ::= ( <executable> | <global> | <scoped> |
                       <record> | <union> | <constant> )

### Definition of Executable Words

#### Syntax

    <executable> ::= `:` <identifier> <prototype> <block>
    
    <prototype> ::= `(` <type>* `::` <type> `)`

#### Semantics

#### Examples

### Definition of Constants
### Definition of Global Variables
### Definition of Scoped Variables
### Definition of Data Structures

There are two types of data structures:
Records (sometimes called "structures" or "structs") and unions.
They both consist of elements, which are syntactically specified as:

    <element> ::= <identifier> `.` <type>

#### Record

    <record> ::= `record` <identifier> <generic-formal>? `{` <element>+ `}`

##### Syntax
##### Semantics
##### Examples

#### Union

##### Syntax

    <union> ::= `union` <identifier> <generic-formal>? `{` <element>+ `}`

##### Semantics
##### Examples

### Instruction

#### Syntax

#### Semantics
#### Examples

### Block

#### Syntax

    <block> ::= `[` <instruction>* `]`

- The square brackets `[ ]` are also used for type arguments of generics.
  - However, there is no amiguity since there is no contexts in which both could appear.

#### Semantics

The instructions in the block will be executed from left to right.

#### Examples

### Instructions

### Control Structures

### Type

#### Syntax

    <type> ::= ( <identifier> | <special-id> | `@` <type> | `~` <type> | <prototype> |
                 <type> <generic-actual> )

#### Semantics
#### Examples

### Generics

#### Syntax

    <generic-actual> ::= `[` ( <type> | <generic-arg> )+ `]`
    
    <generic-formal> ::= `[` <special-id>+ `]`

#### Semantics
#### Examples

### Module and Scope

## Syntax Reference
