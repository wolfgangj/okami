![Wok](logo.png)

> The Joy of Systems Programming

# Welcome to `wok`: Wolfgang's Open Kompiler

This is a (work-in-progress) compiler for a programming language with these properties:

- concatenative / stack-based
- statically typed (with non-nullables)
- low-level (no GC etc., runtime <2K)
- object-based (i.e. classes, but no inheritance)

It will initially run on x86-64 and OpenBSD, but will be easiely portable.

## Quick Intro

You can define variables

```
the answer: int
```

And executable words

```
; multiplies a number with itself
def square (int :: int)
    [this *]

def ask ()
    [7 square 7 - answer !] 
```

The names of stack shuffling words are slightly different from most concatenative languages.

Wok    | Forth
-------|-------
this   | dup
that   | over
them   | 2dup
alt    | swap
,      | drop
dropem | 2drop
nip    | nip
tuck   | tuck

Use `if` as a control structure

```
; remove the minus sign if it has one
def abs (int :: int)
    [this 0 < if:[0 alt -]]

def max (int int :: int)
    [them > if:[,] else:[nip]]
```

Non-nullable references are called addresses.

```
def zero! (@int)
    [0 alt !]

def inc! (@int :: @int)
    [this @ 1 + that !]
```

Nullable references are called pointers (but are not supported yet).
You need `has` to convert nullables to non-nullables.
Without it, you can not access their values.
`has` works similar to `if`.

```
; deref pointer or use default value
def val-or-0 (^int :: int)
    [has:[@] else:[0]]
```

## Requirements

- `nasm` as assembler (`pkg_add nasm`)
- a linker (GNU ld / ld.bfd, part of OpenBSD base)
- the current compiler is written in Ruby, this will be replaced eventually

## Questions?

You can discuss it on [/r/concatenative](https://old.reddit.com/r/concatenative) for now.
Hint: Use i.redit.com on mobile to get a decent experience.
