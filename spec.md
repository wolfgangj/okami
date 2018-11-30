# `okami` language specification (preliminary version)

## Introduction

This document contains the specification of the `okami` language.
`okami` is a statically typed stack-based low-level language with support for generics.
It features memory management based on regions.
It is an intentionally small language that can be readiely learned in its entirety.
It was mostly influenced by Forth, Go and Kitten.

## Language Elements

### Basic Syntax Overview

#### Whitespace and Comment

Syntax of whitespace:

    <whitespace> ::= ( space | tab | newline | <comment> )+
    
    <comment> ::= `;`, [^\n]*, newline

- A comment starts with a colon (`;`) and ends at the end of a line.
- Whitespace is a non-empty sequence of spaces, tabs, newlines and comments.
- Whitespace is required to separate identifiers.
- It may also appear between other syntactic elements (tokens)
  It may not appear inside of identifiers and numbers

#### Keywords

- There are no reserved words.
- However, certain words have special meaning in various contexts:
  - `private protected public` - see section "Module and Scope"
  - `record union` - see section "Definition of Data Structures"
  - `if else while do until for has in is` - see section "Control Structures"

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

##### Examples

    ;; valid <identifier>:
    a
    x0
    abc!
    ?<>
    hello-world
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

    public:

    <integer> ::= <decimal-int> | <hex-int> | <oct-int> | <bin-int>
    
    <float> ::= <normal-float> | <scientific-float> | <special-float>
    
    private:

    <decimal-int> ::= `-`? [0-9]+
    
    <hex-int> ::= `#x` [0-9a-fA-F]+
    
    <oct-int> ::= `#o` [0-7]+
    
    <bin-int> ::= `#b` [01]+
    
    <special-float> ::= `#\NaN` | `#\` `-`? `Inf`
    
    <normal-float> ::= `-`? [0-9]+ `.` [0-9]+
    
    <scientific-float> ::= [0-9] `.` [0-9]+ [eE] `-`? [0-9]+ 

#### String
#### Character
#### Other characters with special meaning

~@#()[]{}:.

### Toplevel

#### Syntax

    public:
    
    <toplevel> ::= ( <definition> | <declaration> | <scope> )*
    
    private:
    
    <scope> ::= ( `private` | `protected` | `public` ) `:`
    
    <definition> ::= ( <executable> | <global> | <scoped> |
                       <record> | <union> | <constant> )
    
    <declaration> ::= `declare` ( <exec-header> | <decl-data> )
    
    <decl-data> ::= ( `record` | `union` ) `:` <identifier>

### Definition of Executable Words

#### Syntax

    public:
    
    <exec-header> ::= `:` <identifier> <prototype>
    
    <executable> ::= <exec-header> <block>
    
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

    <record> ::= `record` `:` <identifier> <generic-formal>? `{` <element>+ `}`

##### Syntax
##### Semantics
##### Examples

#### Union

##### Syntax

    <union> ::= `union` `:` <identifier> <generic-formal>? `{` <element>+ `}`

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
