![okami](okami.png)

## What?

Okami is an application development platform. It consists of several components:

- At the core is the okami engine, a tiny but flexible virtual machine.
  It is written in Assembly language for each supported instruction set architecture (ISA).
- It is accompanied by PropulsionScript, a low-level scripting language intended not for application development, but for extending the capabilities of the okami engine.
   High-level languages can use PropulsionScript as a convenient compilation target.
   (But they don't have to - they may as well target the format understood by the okami engine directly.)
- Wok is a statically typed, object-based concatenative language with automatic memory management.
  It compiles to PropulsionScript.

You can roughly compare this to the Java technology stack:
The okami engine is like the JVM (but several thousand times smaller).
PropulsionScript is like Java bytecode (but far more powerful).
Wok is like Java - the default language for application development.
Additional languages will be welcome.

Software often has some limited need for doing low-level technicalities,
but is otherwise better off being constructed at a higher level.
The architecture of Okami allows you to write your business logic in a high-level language,
while descending down to PropulsionScript where desired.

## Status

2022-08-31: The x86-64 version of the okami engine is mostly done and seems to work well so far.
I am mostly concentrating on implementing PropulsionScript now.

2022-07-15: I have documented my new vision for the `okami` platform above.

2022-07-07: I have picked up working on `okami` again and I am porting it to x86-64.

## Who?

You can contact me via `wolfgang at okami dash systems dot org`
