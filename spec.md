# `okami` language specification (preliminary version)

## Introduction

This document contains the specification of the `okami` programming language.
`okami` is a modern stack-based systems language.
It is statically typed and supports generics, tagged unions and non-nullable types.
It features memory management based on regions.
It is an intentionally small language that can be readiely learned in its entirety.

## Language Elements

### Execution Model

#### The Stacks

- The core of the execution model are several stacks, i.e. LIFO (Last In, First Out) structures.

##### Return Stack

- When calling executable words, the return address is kept on the return stack.
- There is no direct access to the return stack.
- The words `^` ("return") and `?^` ("optionally return") can cause a return from the current executable word, i.e. pop a word from the return stack into the program counter.

##### Data Stack

- The data stack is implicitly used by most operations.
- When just mentioning "the stack", this generally refers to the data stack.
- When executing the code of a block, a literal will cause the literal value to be pushed on the stack.

##### Auxilliary Stack

- The purpose of the auxilliary stack is to provide space for storing temporary values.
  This avoids complex stack operation on the data stack.
- The auxilliary stack is generally refered to as "the aux stack".
- The words `>aux` `aux>` `aux` and `-aux` give direct access to the aux stack.
  See the section "Auxilliary Stack Words" for their definition.
- There is no way to directly swap or duplicate values on the aux stack.
  The reason is that having to keep complex stack state in mind for two different stacks makes code hard to understand.
  If you have a desire to do it, choose a different solution.
- The aux stack gets cleaned automatically when returning from an executable word.

##### Scope Stack

- The scope stack is used for keeping the value of dynamically scoped variables.

###### Example

```
record: list[T] {
  hd . T
  tl . ~list[T]
}

: contains? (~list[A] (A :: bool) - bool)
    [>aux for:[this hd@  aux call ?if:[^] tl@] false keep]

scoped: needle . @str ['']

: needle? (@str :: bool)
    [needle@ x str=? ?if:[^] false keep]

: needle-in-haystack? (list[@str] @str :: bool)
    [needle in:[#:needle? contains?]]
```

### Basic Syntax Elements

#### Whitespace and Comment

Syntax of whitespace:

```
<whitespace> ::= ( space | tab | newline | <comment> )+

<comment> ::= `;`, [^\n]*, newline
```

- A comment starts with a semicolon (`;`) and ends at the end of a line.
- Whitespace is a non-empty sequence of spaces, tabs, newlines and comments.
- Whitespace is required to separate identifiers.
- It may also appear between other syntactic elements (tokens).
  It may not appear inside of identifiers, characters and numbers.

#### Identifier

```
public:

<identifier> ::= <id-char-first> <id-char>* | <dash-identifier>

<special-id> ::= [A-Z] <id-char>*

private:

<id-char> ::= ( [A-Z] | [0-9] | <id-char-first> )

<id-char-first> ::= ( [a-z] | `!` | `%` | `^` | `*` | `_` |
                      `+` | `=` | `?` | `/` | `>` | `<` )

<dash-identifier> ::= `-` ( <id-char-first> | [A-Z] )? <id-char>*
```

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

- valid <identifier>:
  `a` `x0` `abc!` `?<>` `hello-world` `if` `__N_42`  `iCanNotReadThis` `-` `--` `-nil?`

- valid <special-id>:
  `T` `Result` `KEY` `T1` `In&Out`

- invalid:
  `1+` (may not start with a number),
  `foo@` (the `@`-sign is a token of its own),
  `-10+2` (initial dash may not be followed by digit)

#### Literals (Overview)

There are several kinds of literals, each described in detail in their own section:

```
<literal> ::= <ref-exeword> | <char> | <integer> | <float> | <string>
```

#### Number

##### Syntax

```
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
```

##### Semantics

- An `<integer>` has the type `int`.
- A `<float>` has the type `float`.

##### Examples

None yet.

#### String

```
public:

<string> ::= `'` ( [^\\'] | <string-escape> )* `'`

private:

<string-escape> ::= `\n` | `\t` | `\\` | `\'`
```

#### Character

##### Syntax

```
public:

<char> ::= `#'` <char-spec> `'`

private:

<char-spec> := [a-zA-Z0-9~`!@#$%^&*()_-=+{}|;:"<>,.?/ ] |
               `\\` | `\'` | `\n` | `\t` | `[` | `]` | `U+` [0-9a-zA-Z]{4}
```

##### Examples

- `#'a'`
- `#'\n'`
- `#'?'`
- `#'U+03F8'`

#### Referencing executable words

```
<ref-execword> ::= `#:` <identifier>
```

#### Other characters with special meaning

`~@#()[]{}:.`

### Toplevel

#### Syntax

```
public:

<toplevel> ::= ( <definition> | <declaration> | <scope> )*

private:

<scope> ::= ( `private` | `protected` | `public` ) `:`

<definition> ::= ( <executable> | <global> | <scoped> | <constant> |
                   <type-def> | <enum> | <record> | <union> )
```

#### Semantics

- The `<toplevel>` is the entry point of parsing a file.

### Declaration

#### Syntax

```
public:

<declaration> ::= `declare` ( <exec-header> | <decl-data> )

private:

<decl-data> ::= ( `record` | `union` ) `:` <identifier>
```

#### Semantics
#### Examples

### Definition of Executable Words

#### Syntax

```
public:

<exec-header> ::= `:` <identifier> <prototype>

<executable> ::= <exec-header> <block>

<prototype> ::= `(` <type>* `::` <type> `)`
```

#### Semantics

#### Examples

None yet.

### Definition of Constants

#### Syntax

```
public:

<constant> ::= `const` `:` <special-id> `.` <type> <block>
```

#### Semantics

- Defines a constant value that can be used in blocks by using its name.
- The block may only use built-in operations (see section "Built-In Operations"), other constants and literals.
- The block must have the type `(:: <type>)`.

#### Examples

```
const: PI . float [3.1415926535897932]
const: NEWLINE . char [#'\n']

const: HALF_ANSWER . int 21
: answer (:: int)
[HALF_ANSWER 2 *]
```

### Definition of Global Variables

#### Syntax

```
<global> ::= `var` `:` <identifier> <block>
```

#### Semantics

- The block may only contain literals and built-in operations of type 1 as described in section "Built-In Operations".

#### Examples

```
var: count . int [0]
: 0count (::)
[0 count !]
: count+ (::)
[count@ 1 + count !]
```

### Definition of Scoped Variables

#### Syntax

```
public:

<scoped> ::= `scoped` `:` <identifier> `.` <type> <block>
```

###### Semantics


### Definition of Simple Types

#### Type Name

A new type without any semantics attached can be created as:

```
<type-def> ::= `type` `:` <identifier>
```

#### Enum

```
<enum> ::= `enum` `:` <identifier> `{` <identifier>+ `}`
```

### Definition of Data Structures

There are two types of data structures:
Records (sometimes called "structures" or "structs") and unions.
They both consist of elements, which are syntactically specified as:

```
<element> ::= <identifier> `.` <type>
```

#### Record

```
<record> ::= `record` `:` <identifier> <generic-formal>? `{` <element>+ `}`
```

##### Syntax
##### Semantics
##### Examples

None yet.

#### Union

##### Syntax

```
<union> ::= `union` `:` <identifier> <generic-formal>? `{` <element>+ `}`
```

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

```
<block> ::= `[` <instruction>* `]`
```

- The square brackets `[ ]` are also used for type arguments of generics.
  - However, there is no amiguity since there is no contexts in which both could appear.

#### Semantics

The instructions in the block will be executed from left to right.

#### Examples

None yet.

### Instructions

```
<instruction> ::= <control> | <special-structure> | <literal> | <identifier>
```

### Built-In Operations

The following operations are built-in:

Type 1:

- `+` `-` `*` `/` `mod` `>` `<` `=` `<>` `>=` <=`
- `and` `or` `not` `xor` `shift<` `shift>`
- `this` `that` `them` `-this` `-that` `-them` `x` `tuck`
- `>aux` `aux>` `aux` `-aux`

Type 2:

- `@` `!` `+!` `-!` `on` `off`
- `^` `?^` `call` `keep`

- Type 1 Built-Ins can be used to define constants.
- Type 1 and 2 Built-Ins can be used without linking code with the `okami` runtime library.
- The semantics of these operations is defined in the section "Library"

### Control Structures

- Control structures can be used without linking code to the `okami` runtime library.

```
public:

<control> ::= <if> | <while> | <until> | <has> | <for>
```

#### if else
#### while do
#### until
#### has else
#### for

### Other Special Code Structures

```
<special-structure> ::= <special-in>
```

#### Setting Scoped Variables

##### Syntax

```
<special-in> ::= `as` `:` <identifier> `in` `:` <block>
```

The given `<identifier>` must refer to a scoped variable.

##### Semantics

- Set a scoped variable to a value for the dynamic extend of a block.
- Using it requires element on the top of the stack with the correct type for the given variable.
- The scoped variable will be set to the value on top of the stack before entering the block.
- When leaving the block (by reaching its end or e.g. with `^`), the original value will be restored.

##### Examples

```
scoped: user . @str ['']

: login-msg (::)
    ['login for: ' say   user@ say newline]

: session-for (@str ::)
    [as:user in:[login-msg do-stuff]]
```

### Creation of Data Structures

#### Syntax

#### Semantics

#### Examples

```
record: point {
  x . int
  y . int
}

: point0 (-- @point)
    [0 as:x 0 as:y new:point]
```

### call

#### Syntax

```
<call> ::= `call`
```

#### Semantics

- `call` calls an executable word.
  Therefore, `call` has the stack effect of the executable word on the top of the stack.

#### Examples

```
: add7 (int :: int)
    [7 +]

: twice (int (int :: int) :: int)
    [tuck call x call]

: add14 (int :: int)
    [#:add7 twice]
```

### Type

#### Syntax

```
public:

<type> ::= ( <identifier> | <special-id> | <address> | <nullable> | <prototype> |
             <type> <generic-actual> )

private:

<address> ::= `@` <type>

<nullable> ::= `~` <type>
```

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

```
public:

<generic-actual> ::= `[` ( <type> | <generic-arg> )+ `]`

<generic-formal> ::= `[` <special-id>+ `]`
```

#### Semantics
#### Examples

None yet.

### Module and Scope

## Library

Built-In words

### Data Stack Words

```
: this (A :: A A)
```

- Push the value on top of the stack.
- Was traditionally called `dup` in most concatenative languages.

```
: that (A B :: A B A)
```

- Push the second element on top of the stack (without removing the original one).
- Was traditionally called `over` in most concatenative languages.

```
: them (A B :: A B A B)
```

- Pushes the top two elements of the stack.
- Was traditionally called `2dup` in most concatenative languages.

```
: -this (A ::)
```

- Removes the top element from the stack.
- Was traditionally called `drop` in most concatenative languages.

```
: -that (A B :: B)
```

- Removes the second element from the stack.
- Was traditionally called `nip` in most concatenative languages.

```
: -them (A B ::)
```

- Removes the top two elements from the stack.
- Was traditionally called `2drop` in most concatenative languages.

```
: x (A B :: B A)
```

- Swaps the top two elements on the stack.
- Was traditionally called `swap` in most concatenative languages.

```
: tuck (A B :: B A B)
```

- "Tucks" the top element below under the second element of the stack (without removing the original).

### Auxilliary Stack Words

The point of these operations is to work with the aux stack.
Therefore, the stack effects they have on the aux stack is given below as a comment after the normal data stack effect.

```
: >aux (A ::)  ; aux:(:: A)
```

- Pop an element from the data stack and push it to the aux stack.

```
: aux> (:: A)  ; aux:(A ::)
```

- Pop an element from the aux stack and push it to the data stack.

```
: aux (:: A)  ; aux:(A :: A)
```

- Move an element from the data stack to the auxilliary stack.

```
: -aux (::)  : aux:(A ::)
```

- Remove an element from the aux stack, not storing it anywhere.
- This does to the aux stack what `-this` does to the data stack.

## Appendix A: Syntax Reference

### Notation

### Specification

## Appendix B: IL2 Reference

An `okami` compiler should be able to output compiled code in the IL2 format described in this section.
IL2 is a simple assembly language that can easiely converted to machine specific assembly languages.
This makes it simple to port `okami` to new instruction set architectures.

### General principles

### IL2 Syntax

Ther are ten registers, with names `r0` to `r9`:

```
<reg> ::= `r`[0-9]
```

### Instruction Reference

#### ALU Instructions

```
add.i <reg> <int>
add.r <reg> <reg>
```

- `add.i`: Add the value of the register and the given integer literal.
- `add.r`: Add the value of the registers.
- Store the result in the register given as first argument.

### Branch instructions

```
b <label>
```

- Branch to the given `<label>`, unconditionally.

```
b.<condition>.i <label> <reg> <int>
b.<condition>.r <label> <reg> <reg>
```

- Branch to the given `<label>` if the given condition is met regarding the other arguments.
- The label must be defined in the same file.
- All conditions compare the value in the first register (value 1) with either
  the literal value (for `.i`) or
  the value in the register (for `.r`)
  given as last argument (value 2).
- The available conditions are:
  - `eq` - equal (values 1 and 2 are identical)
  - `ne` - not equal (values 1 and 2 are different)
  - `lt` - lesser than (value 1 is smaller than value 2)
  - `gt` - greater than (value 1 is larger than value 2)
  - `le` - lesser or equal (value 1 is smaller than value 2 or they are identical)
  - `ge` - greater or equal (value 1 is larger than value 2 or they are identical)
