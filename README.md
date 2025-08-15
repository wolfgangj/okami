![okami](okami.png)

## What?

Okami is a low-level scripting language that runs on top of Unix kernels. While it supports functional and class/object-based programming styles, it's primary paradigm can be called "dictionary-oriented" and goes along with a concatenative style.

It emphasizes a modern, lightweight, consistent syntax with simple straightforward semantics. Its meta-programming facility is a natural extension of its normal interpretation and compilation mechanism. It draws heavy influence from modern non-standard dialects of the Forth language.

At its core is the okami engine, a tiny but flexible virtual machine which is written in Assembly language for each supported instruction set architecture (ISA).

## Status

2024-07-14: I recently re-evaluated the project goals and dropped the high-level Wok language for now that was supposed to accompany the low-level language.
Progress is slow as usual.

## FAQ

Q: What is the logo showing?

A: A robotic baby wolf.

Q: Is the okami language a Forth dialect?

A: If you like, you can consider it to be a non-standard Forth, similar to some other systems like ColorForth.

Q: You are calling it a scripting language, but what does it script?

A: First, the okami engine. Later, the application one is writing in it.

Q: You are calling it "dictionary-oriented", but why not call it a stack-based language? It is one, isn't it?

A: Technically, it is, but the term is suggesting a very wrong way of thinking about the language and its use. Here is how I explained it once regarding Forth, which has exactly this problem:

> The common misunderstanding of Forth works like this:
>
> "Let's see which features Forth offers... You can define things like variables, procedures etc., you have control structures... Oh, and there's the stack! The other ones I knew from other languages. But the stack is what makes Forth special. Yeah, Forth is called a stack-based language. So I should concentrate on working with the stack, put my data there, shuffle it around depending on which order I need it in."
>
> How to fix it:
>
> Understand that you should focus on something that gets easily overlooked because other languages SEEM to have it as well: The ability to define words. Think of Forth as a dictionary-based language rather than a stack-based language. Factor your code into small definitions. There is no need for indentation in Forth. Indenting code like in applicative languages is an anti-pattern (I never even bother TRYING to understand code like that). If you want to write long definitions that use many values, you will always be better off using other languages, as they make it easy to do such complicated things. Forth makes this hard, as you have to use horrible things like ROT to make it work at all. And even if you do, it will always be far harder to understand than reading the same thing in Python. This is the advantage of Forth: It forces you to avoid complexity. Because complexity always results in more complexity (on all layers). Forth starts with simplifying the problem. The customer wants to have a program that displays the text "Hello world"? Nah, he actually just wants to be able to see the text whenever he desires. No program needed, just write it in a file. Or even on a piece of paper. Because technology can be part of a solution, but should never be part of the problem statement. This is "Hello world" in Forth: Simplifying the problem.

Okami exists in exactly this spirit of Forth".
