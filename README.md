# Calcutron-33, The Decimal RISC CPU

This is an assembler, disassembler and simulator for an imaginary CPU called Calcutron-33. The rational for this CPU was described first time in [this medium article](https://medium.com/@Jernfrost/decimal-risc-cpu-a13968922812).

It was inspired by two sources, the Little Man Computer as well as the RISC-V instruction set archtecture.

The motivation was to create a simple CPU for teaching purposes. In this regard it is worth clarifying what we are trying to teach. If teaching prospective hardware designers or compiler writers was the main goal then teaching MIPS or RISC-V would have been better.

However the goal here is not to teach anyone to be assembly progammers but to teach enough assembly programming concepts for beginners to understand better what a high level language actually does.

In particular this project developed from a desire to teach the Julia programming language. It uses a Just in Time Compiler, but that is a big topic for a complete beginner to jump into. Jumping straight into talkinga about LLVM bitcode or x86 assembly code is a too big topic for someone who is primarily trying to learn progamming for the first time.

We need an assembly language which is very easy to learn so we don't distract from actually learning Julia. 

In time we hope to add a compiler for a small subset of the Julia programming  language, which will compile Julia expressions to Calcutron-33 assembly code.

## Example

This is a simple example of the assembly language. In this example we are repeately reading two input numbers, multiplying them and writing the result to output.

    loop:
        INP x1
        INP x2
        CLR x3
    
    multiply:
        ADD x3, x1
        DEC x2
        BGT x2, multiply
        OUT x3
    
        BRA loop
    
Unlike Little Man Computer, which has only one register this has a more RISC like architecture with 9 register `x1` to `x9`. 

Branching is done similar to MIPS. One compares the contents of a register to 0. So e.g. `BGT x2, multiply` will make a jump to `multiply` if the contents of `x2` register is larger than 0.

## Status

Assemly, disassembly, running and stepping mostly works. But everything lacks polish and needs more testing.

Work on the compiler has not began at all.

Better documentation and examples are also needed.
