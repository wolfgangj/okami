![okami](okami.png)

> Making systems programming a better place!

## Status Update

2022-07-07: Guess what, I have picked up working on `okami` again and I am porting it to x86-64.

## What?

`okami` is a metamodern application development platform that attempts to reduce technological wastefulness and complexity.
It is based on a non-standard dialect of Forth.

The current implementation is written in ARM (AArch32) assembly language and runs on GNU/Linux.
You can use it on a Raspberry Pi 2/3 and similar computers.

Forth may not exactly be modern technology, but I believe it can be in a productive partnership with it (like Unix is).
One unique advantage of Forth in todays world is that it allows for a system to be fully comprehensible, yet practical.

But `okami` is not a programming language (although it contains one).
It is intended to be an integrated platform for application development.

Example session:

![screenshot](screenshot.png)

## Features

* No type inference
* No operator overloading
* No pattern matching
* No type checking (neither static nor dynamic)
* No classes and objects and interfaces and mixins
* No closures
* No local variables
* Only you and the machine having an intelligent conversation to solve problems. :-)

Oh, and we actually have some nice libraries, but don't use them.
Unless you understand them deeply and are sure they will actually make your life better.
Keep in mind that any library you use is a part of your codebase.
(Also, note that the same should be considered true for the interpreter.)

## Requirements

- The ARM CPU it runs on needs to support the division instruction.
  This is the case e.g. on a Raspberry Pi 2, but not on a Raspberry Pi 1.
- For some features to work, the system needs to support little-endian mode.
  Most ARMs nowadays use little-endian anyway, though.
- Setting it up requires an assembler and linker (usually in package `binutils`).
  If you're on a 64-bit system (like me), you'll need the cross-assembler/linker toolchain.
  (That would be something like `binutils-arm-linux-gnueabihf`.)
- For convenience, `rlwrap` (for the REPL) is recommended.
  If it exists on the system, it will be used.

No external libraries are required, not even `libc`.
The interpreter is a small statically linked binary that uses Linux syscalls directly.

## Usage

Programs can be started with the `run` script or its `dev` symlink.
The first time you do this, the `okami` binary will be assembled/linked.
Using `dev` will always reassemble the binary and also load debugging support words like `backtrace`.

The `run`/`dev` script expects an argument, which can be either a file or a directory, in which case a file called `Runfile` is looked up in this directory.
In any case, the file will be read as a list of source files to load.

Run tests with `./run tests` and start an interactive session with debugging support by using just `./dev`.

Using the `run` script and a `Runfile` is the prefered method, but alternatively, you can also directly do:

    $ ./okami lib/core.ok

This will read `lib/core.ok` and enter the REPL.
Running a program can be done by adding more files to process:

    $ ./okami lib/core.ok hello.ok

To not enter the REPL afterwards, a program source can finish with `bye`.

To reduce the size of the binary by stripping debugging symbols, use `strip okami`.
The resulting binary size is currently about 6k.

## Tutorial

Basic knowledge of Forth is required for this section.

`okami` is a Three-State-Forth:
It can be in interpret mode, compile mode or postpone mode.

You cannot set this state by executing a word or accessing a `state` variable.
Rather, the state is always explicit in the source code:
Square brackets `[]` are used to switch between the three states:

* In interpret mode, `[` will switch to compile mode.
* In compile mode, `[` will switch to postpone mode.
* In postpone mode, `]` will switch back to compile mode.
* In compile mode, `]` will switch back to interpret mode.
* Other uses of `[]` are invalid, i.e. don't use `]` in interpret mode or `[` in postpone mode.

Since code will be compiled if it is enclosed in square brackets, a basic definition looks like this:

    : 2dup [over over];

As you can see, `[]` also separate words, like whitespace does.

There are no "immediate" words in `okami`.
That means that compilation directives like control structures must be placed outside of brackets so that they will be interpreted immediatelly:

    : max
      [2dup >] if [drop] else [nip] then ;

This makes it obvious that `if` `then` `else` are words that compile code, so a beginner is less likely to get confused and ask "Why will these only work in colon definitions?"
It might be less pretty (and sometimes less flexible), but makes it more obvious what actually happens, i.e. it results in a slightly less twisted mental model.

It also has the advantage of looking weird if you use multiple control structures in a single definition.
A definition should preferably contain no more than one control structure, so this helps to factor properly.

While such code looks syntactically similar to the increasingly popular Joy-style quotations, there is no semantic relation.
To make this very clear:
The square brackets are *not* used to create closure-like code blocks, as it is commonly done in various modern concatenative languages.
The `[]` merely denote a change of state (i.e. what the system does with the words it encounters in the source text), nothing else.

Since `okami` uses indirect threaded code, you don't *need* to use square brackets.
You can also compile a call manually by first pushing the desired code field address (CFA) onto the stack with `'` (tick) and then writing it into memory with `,` (comma):

    : sqr   ' dup , ' * , ;
    : cell+ ' lit , 4 , ' + , ;

This is sometimes useful e.g. to include constant values into compiled code:

    : colon? [lit] char : , [=?];

The square brackets extend naturally to postponing, i.e. the second level of nesting them works like `postpone` in standard Forth:
It compiles code which, when executed, will compile a call to the given word (and accordingly for constants).

    : {char} [[lit] char ,];
    : colon? {char} : [=?];

I tried to make most obvious optimizations in the interpreter.
For example, the dictionary is placed at the end of the memory area, so it doesn't interfere with cache utilization during long-running operations where no dictionary lookups are done anyway.
The dictionary grows downwards (i.e. we search forward) and looks like this:

    Diagram of the dictionary structure
    ===================================
    dp @ points to most recent entry:
    [       2 ] len of name (in cells)
    [   "allo"] entry name, cell 1
    ["t\0\0\0"] cell 2, padded with 0s
    [   ...   ] start addr of definition
    [   ...   ] end addr of definition
    next entry follows immediately:
    [       2 ]
    [   "2dup"] at least one \0 after..
    ["\0\0\0\0"] ..name, plus padding
    [   ...   ]
    [   ...   ]

We store the end of a definition so that we can easiely display a backtrace
(with the word `backtrace` (or `bt`) from `lib/dev/debug.ok`).
So `;` compiles a call to `exit` and stores the current address in the end address of the last definition.

As you can see above, there is no place anywhere to mark words as hidden.
This means a word can use itself recursively by stating its own name:

    : fact
      [0=?] if [1+] else [dup 1- fact *] then ;

Unfortunatly, the builtin words are currently in a separate dictionary.
So far I failed to create a linker script for GNU ld that makes a unified dictionary work.
This should be easy to fix with our own assembler, though.
One more example of using overcomplex tools not paying off...

One additional detail of the dictionary structure is that we can have sections of private definitions, which will be skipped when looking up names.
Those entries have the length of the name set to zero.
This zero value is followed up by the address of the next non-private dictionary entry.
This facillity is utilized by the `private{` ... `}in{` words.
You'll find plenty of examples in the library code.

In addition to `dp`, there is also `hp` (the `here` pointer), which is used for compiling and by words like `,` (comma).

The content of a definition (at least if it should be possible to execute it) begins with the code field.
So the "start address of the definition" field in the dictionary actually contains the CFA (code field address).

You can use `docol,` and `dodoes,` to make a colon definition or a "does" word.
Since you can create a dictionary entry with `entry:`, you could do:

    \ a working definition, although without
    \ proper end given in dictionary:
    entry: sqr docol, ' dup , ' * , ' exit ,

A "does" word needs an additional cell after the code field:
The address of the colon definition to execute.

To keep things simpler, we don't use standard "create does".
`create:` itself works as expected:

    create: buffer 256 allot
    : var: [create: 0,];

However, `does` is combined with the word `with` instead:

    : const: with [,] does [@];
    : array: with [cells allot]
             does [swap cells +];

A `begin` `while` `repeat` loop exists that works just like in standard Forth.
Additionally, there is a non-standard `for` `next` loop which pushes a terminating value on the auxiliary stack (see below) and compares the TOS with it on each iteration:

    : count for [dup . 1+] next ;
    5 10 count
    \ will display: 5 6 7 8 9

The upper bound will be stored on the auxiliary stack.
This is an additional stack we use for storing temporary values.
Traditional Forth uses the return stack for this purpose.
However, refactoring is sometimes easier when keeping return addresses and values separate.
Of course, you can still acccess the return stack in `okami` as usual.

Not having immediate words has a few consequences.
For example, `is` works slightly differently in `okami`.
It takes two XTs from the stack:
For both the deferred word and the code that now defines it.
(The code of the deferred word is just a call and will be overwritten.)
This makes it easier to set the operation performed by the deferred word from compiled code.

## Who?

You can contact me via `wolfgang at okami dash systems dot org`
