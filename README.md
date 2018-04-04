![okami](okami.png)

> If it were more difficult to compose separately developed libraries
> and knock out "glue code" and if units of source beyond a certain size
> were more difficult to manage then program design might improve.
(Thomas Lord)

## About

`okami` is a metamodern programming language / a non-standard dialect of Forth.

The current version is written in ARM (AArch32) assembly language and runs on GNU/Linux.

![screenshot](screenshot.png)

The primary goal of `okami` is to answer an important question:
Are we really in such a mess that a comprehensible system can't be more than a toy?

We'll see how it goes...

## Usage

Type `make` to assemble and link the interpreter.
You might have to change the name of the assembler and linker to just `as` and `ld`.

To reduce size by stripping debugging symbols, use `make tiny`.
Run tests with `make test` and start an interactive session with `make repl`.
The latter actually just does:

    $ ./okami core.ok

Running a program can be done by adding more files to process:

    $ ./okami core.ok hello.ok
