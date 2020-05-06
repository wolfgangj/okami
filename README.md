![Wok](logo.png)

> The Joy of Systems Programming

# Welcome to `wok`: Wolfgang's Open Kompiler

This is a (work-in-progress) compiler for a programming language with these properties:

- concatenative / stack-based
- statically typed (with non-nullables)
- low-level (no GC etc., runtime <2K)
- object-based (i.e. classes, but no inheritance)

It will initially run on x86-64 and OpenBSD, but will be easiely portable.
