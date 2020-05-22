![Wok](logo.png)

> The Joy of Systems Programming

# Welcome to `wok`: Wolfgang's Open Kompiler

What is Wok?

- Wok is a rather primitive, statically-typed, concatenative (stack-based) systems programming language.
- Wok provides more safety than C (e.g. safe access to nullable pointers and bounds-checked array access) and yet an easier way to do unsafe things via the `any` type.
- Wok acknowledges that stack-shuffling is confusing and tries hard to reduce its impact (without giving up on concatenativity). In other words: Wok wants to make concatenative programming more accessible without watering it down.
- Wok tries to provide a simple, yet pleasantly readable syntax with visual cues.
- Wok is independent of C - it has its own tiny runtime (<2K)
- Wok is designed so that one can keep the full language in ones head.
- Wok generates straightforward code, i.e. no nasal-demon-defined behaviour, although at the cost of performance.
- Wok is inspired by Ruby, Go, Forth and Joy. Currently, it works only on OpenBSD/x86-64, but is easy to port.

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

Nullable references are called pointers.
You need `has` to convert nullables to non-nullables.
Without it, you can not access their values.
`has` works similar to `if`.

```
; deref pointer or use default value
def val-or-0 (^int :: int)
    [has:[@] else:[0]]
```

You can define macros with `for`.
The tokens of the body will be inserted whenever the name is encountered.

```
for while {not if:[break]}
for until {    if:[break]}

def downto0 (int)
    [loop:[this 0= until 1 -],]
```

## Requirements

- `nasm` as assembler (`pkg_add nasm`)
- a linker (GNU ld / ld.bfd, part of OpenBSD base)
- the current compiler is written in Ruby, this will be replaced eventually

## Questions?

You can discuss it on [/r/concatenative](https://old.reddit.com/r/concatenative) for now.
Hint: Use i.redit.com on mobile to get a decent experience.
