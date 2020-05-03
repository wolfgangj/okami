![Wok](logo.png)

> The Joy of Systems Programming

# Welcome to `wok`: Wolfgang's Open Kompiler

One day, this will be a compiler for a programming language with these properties:

- concatenative / stack-based
- statically typed (with non-nullables)
- low-level (no GC etc., runtime <2K)
- object-based (i.e. classes, but no inheritance)

It will initially run on x86-64 and OpenBSD, but will be easiely portable.

## Status

There is a prototype for an earlier design written in Scheme, that has a mostly working typechecker.
The runtime is complete.
I'm going to write the compiler in Ruby now, then port it to Wok itself.
