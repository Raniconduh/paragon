# Tools

[as](as.py) is the assembler. Takes in an assembly file and outputs a C array of
unsigned 16 bit integers comprising the assembled instructions.

[deas](deas.py) is the disassembler. Takes in an ASCII instruction dump and
outputs the corresponding disassembly.

# Demos

* [Clear](clear.asm): Zeros out the framebuffer (sets to black).
* [Gradient](grad.asm): Displays a gradient.
* [SC Mandelbrot](scmandel.asm): Draws the Mandelbrot set on a single compute core.
  Note that all other cores are stalled as to not slow the drawer.
* [Mandelbrot](mandel.asm): Multicore Mandelbrot set rendering.
* [Ship](ship.asm): Burning ship fractal rendering.
* [Julia](julia.asm): Interactive Julia set demo. It takes an outside input and
  uses it to calculate the requested Julia set.
* [Blur](blur.asm): Multicore box blur kernel. Blurs whatever is in the
  framebuffer.
* [Rule 30](r30.asm): Rule 30 elementary cellular automaton simulation. Either runs
  the default simulation or uses the top row of the framebuffer as the initial
  state.
* [SC GoL](scgol.asm): Single core Conway's Game of Life simulation. Draws the
  current state in the left half of the framebuffer and the next state in the
  right half.
* [GoL](gol.asm): Simulates Conway's Game of Life in parallel.
* [Cube](cube.asm): Renders a 3D rotating cube.
