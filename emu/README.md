# PARAGON Emulator

This emulator runs a single kernel at a time and displays the framebuffer in an
SDL3 window. The number of emulated cores is specified at compile time in
`include/main.hpp`.

## Building

The emulator requires a C++ compiler and the SDL3 development library. Run
`make` to build.

## Running

The emulator reads a single kernel which is specified in ASCII binary format.
That is, each instruction is a single line and each line contains only the bits
(as ASCII characters) that make up the instruction.

To run, `emu kernel.bin` where `kernel.bin` contains the kernel to run. Quit the
emulator with `^C`.
