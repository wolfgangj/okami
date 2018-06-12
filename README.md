![okami](okami.png)

## The Threefold Conjecture

1. We need to get close down to the level of the machine to be in control of it.

2. We need to be in control of the machine to make it collaborate with us effectively.

3. We need to make the machine collaborate with us effectively to create solid high-level code.

## About `okami`

`okami` is a metamodern application development system based on a non-standard dialect of Forth.

The current implementation is written in ARM (AArch32) assembly language and runs on GNU/Linux.

Example session (slightly outdated):

![screenshot](screenshot.png)

## Vision

Sometimes, the complexity of our tools costs us about as much time as it saves us.
However, we never know when exactly things will blow up, which makes development less predictable (and often frustrating).

So is all that really necessary?
Are we really in such a mess that a comprehensible system can't be more than a toy?
With `okami`, I am exploring an alternative.

`okami` is supposed to become a fully comprehensible tool for creating real-world applications.
It shall be friendly and inviting to fellow programmers who are new to the Forth-way of thinking - not despite, but by virtue of being true to the spirit of Forth, which is simplicity.

Forth may not exactly be modern technology, but I believe it can be in a productive partnership with it (like Unix is).

Being a tool for real-world usage means that it won't be incredibly elegant.
To get stuff done, compromises are usually required.
So `okami` does not pursuit minimalism to the extreme, nor will it be entirely consistent or anything like that.
However, it needs to keep a really simple and clear core model or it would be a complete failure.

## Features

* No type inference
* No operator overloading
* No pattern matching
* No type checking (neither static nor dynamic)
* No classes and objects and interfaces and mixins
* No closures
* No local variables
* Only you and the machine having an intelligent conversation to solve problems. :-)

Oh, and we actually have some nice libraries, don't use them.
Unless you understand them and are sure they will actually make your life better.

## Requirements

- The ARM CPU it runs on needs to support the division instruction.
  This is the case e.g. on a Raspberry Pi 2, but not on a Raspberry Pi 1.
- For some features to work, the system needs to support little-endian mode.
  Most ARMs nowadays use little-endian anyway, though.
- Setting it up requires an assembler and linker.
  For convenience, `make` and `rlwrap` (for the REPL) are recommended.

No libraries are required, not even `libc`.
The interpreter is a small statically linked binary that uses Linux syscalls directly.

## Usage

Type `make` to assemble and link the interpreter.
You might have to change the name of the assembler and linker to just `as` and `ld`.

To reduce size by stripping debugging symbols, use `make tiny`.
The resulting binary size is currently about 6k.

Run tests with `./run tests` and start an interactive session with `./run repl`.
If you don't have the `rlwrap` utillity, change the `run` script.

Using the `run` script and a `Runfile` (which contains a list of files to load) is the prefered method, but alternatively, you can also just do:

    $ ./okami lib/core.ok

This will read `core.ok` and enter the REPL.
(Note that `./run repl` also loads some development support words like `backtrace`.)
Running a program can be done by adding more files to process:

    $ ./okami lib/core.ok hello.ok

To not enter the REPL afterwards, a program source can finish with `bye`.

This `run` script expects an argument, which can be either a regulary file or a directory, in which case a file called `Runfile` is looked up in this directory.

I usually list the sources I want to load during development in a file called `dev`.
So I can start a session with `./run dev` (and the file `dev` is ignored by `git` via `.gitignore`).

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

As you can see, `[]` are also treated as whitespace, i.e. they separate words.

There are no "immediate" words in `okami`.
That means that compilation directives like control structures must be placed outside of brackets so that they will be interpreted immediatelly:

    : max
      [2dup >] if [drop] else [nip] then ;

Since `okami` uses indirect threaded code, you don't *need* to use square brackets.
You could also compile a call manually by first pushing the desired code field address (CFA) onto the stack with `'` (tick) and then writing it into memory with `,` (comma):

    : sqr   ' dup , ' * , ;
    : cell+ ' lit , 4 , ' + , ;

This is sometimes useful e.g. to include constant values into compiled code:

    : colon? [lit] char : , [=?];

Note that square brackets are *not* used to create closure-like code blocks (quotations), as it is commonly done in various modern concatenative languages.
The `[]` merely denote a change of state (i.e. what the system does with the words it encounters in the source text), nothing else.

The second level of nesting brackets works similar to `postpone` in standard Forth:
It compiles code which, when executed, will compile a call to the given word.

    : if   [[0branch] mark>];
    : then [resolve>];
    : else [[branch] mark> >r resolve> r>];

The dictionary is placed at the end of the memory area and grows downwards.
It looks like this:

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
(which can be done with the word `backtrace` from `lib/dev.ok`).
So `;` compiles a call to `exit` and stores the current address in the end address of the last definition.

Unfortunatly, the builtin words are currently in a separate dictionary.
So far I failed to create a linker script for GNU ld that makes a unified dictionary work.
This should be easy to fix with our own assembler, though.
One more example of using overcomplex tools not paying off...

In addition to `dp`, there is also `hp` (the `here` pointer), which is used for compiling and by words like `,` (comma).

The content of a definition (at least if it should be possible to execute it) begins with the code field.
So the "start address of the definition" field in the dictionary actually contains the CFA (code field address).

You can use `docol,` and `dodoes,` to make a colon definition or a "does" word.
Since you can create a dictionary entry with `entry`, you could do:

    \ a working definition, although without
    \ proper end given in dictionary:
    entry: sqr docol, ' dup , ' * , ' exit ,

A "does" word needs an additional cell after the code field:
The address of the colon definition to execute.

To keep things simpler, we don't use standard `create` ... `does`.
`create` itself works as expected:

    create: buffer 256 allot
    : var: [create 0,];

However, `does` is combined with the word `with`:

    : const: with [,] does [@];
    : array: with [cells allot]
             does [swap cells +];

As you can see, there is no place anywhere to mark words as hidden.
This means a word can use itself recursively by stating its own name:

    : fact
      [0=?] if [1+] else [dup 1- fact *] then ;

A `begin` `while` `repeat` loop exists that works just like in standard Forth.
Additionally, there is a non-standard `rfor` `next` loop which pushes a terminating value on the return stack and compares the TOS with it on each iteration:

    : count rfor [dup . 1+] next ;
    5 10 count
    \ will display: 5 6 7 8 9

The `r` in `rfor` reminds you of the fact that it uses the return stack
(the upper bound will be stored there).

Not having immediate words has a few consequences.
For example, `is` works slightly differently in `okami`.
It takes two XTs from the stack:
For both the deferred word and the code that now defines it.
(The code of the deferred word is just a call and will be overwritten.)
This makes it easier to set the operation performed by the deferred word from compiled code.

You'll have to figure the rest out from the source code for now. :-)

