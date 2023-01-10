# PropulsionScript

> propulsion (noun) - the action of driving forth

## What?

PropulsionScript is a low-level scripting language.
It allows to extend the capabilities of the okami engine, the virtual machine on which it is built.
It is not intended for application development.

Technically, it is a stack-based, untyped programming language.
It has a lot in common with Forth, and can be considered a Forth dialect, although it also differs in many ways.

## Differences from conventional Forth

Aside from superficial differences like using other naming conventions, the most unique thing about it is the lack of immediate words.

In Forth, by default words are interpreted, i.e. executed directly.
Some words (like `:`) will enter compile mode so all subsequent words are compiled.
To stop compiling at all, it must be possible to interpret a word despite being in compile mode.
This is what Forth uses immediate words for.
Control structure words (like `else`) must be immediate words, for example.

This adds a mechanism behind the scenes and can be confusing, as there is no general visible difference between the different kinds of words and when they are interpreted or compiled.
This way of operation is closely linked to Forth's lack of complex syntax.
Forth just differentiates between whitespace (that separates words) and non-whitespace (that words consist of).

A simple Forth word definition can switch between interpret and compile mode several times:

```
: max 2dup > if drop else nip then ;
```

This is why Forth sometimes receives the same criticism as Lisp:
It lacks visual cues.
This creates confusion in practice.
For example, a common beginners question in Forth is: "Why does `if` not work outside of colon definitions?"

PropulsionScript introduces a third class of character:
The characters `[` and `]` do not belong to words, they switch between interpret and compile mode.
This results in code with visual cues and an explicitness about compile vs. interpret mode:

```
: max [they >] if [drop] else [nip];
```

This also has the advantage of looking somewhat weird if you use multiple control structures in a single definition.
A definition should preferably contain no more than one control structure, so this helps to factor properly.

Note: The square brackets are *not* used to create closure-like code blocks, as it is commonly done in various modern concatenative languages.
The `[]` merely denote a change of state (i.e. what the system does with the words it encounters in the source text), nothing else.

Since the okami engine (and therefore PropulsionScript as well) uses indirect threaded code, you don't *need* to use square brackets.
You can also compile a call manually by first pushing the desired code field address (CFA) onto the stack with `'` (tick) and then writing it into memory with `,` (comma):

    : sqr   ' dup , ' * , ;

This is sometimes useful e.g. to include constant values into compiled code:

    : colon? [lit] char : , [=?];

The square brackets extend naturally to postponing, i.e. the second level of nesting them works similar to `postpone` in standard Forth:
It compiles code which, when executed, will compile a call to the given word (and accordingly for constants).

    : {char} [[lit] char ,];
    : colon? {char} : [=?];

A second important point is that the general philosophy of PropulsionScript is about avoiding stack juggling complexity.
Forth provides words that perform actions three (or even arbitrary) stack items deep.
PropulsionScript only ever accesses the first two stack items, i.e. it does not have `rot`, `-rot` or even `pick` and `roll`.

Additionally, even when using stack shuffling words, we don't want programmers to think about what they are doing too much in terms of manipulating a stack.
That's why we use different names, like `this` and `that` instead of `dup` and `over`.

