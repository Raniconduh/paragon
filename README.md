# PARAGON

Parallel Architecture for Rendering And Graphics OperatioNs: a parallel graphics
processor.

See [docs](docs) for processor documentation.

See [here](as/README.md) for a list of demo programs and what they do.

## Building

All sources are included in `hdl/`. The top level file lives at
`hdl/synth/core_top.sv`. The processor uses a VGA-HDMI converter IP provided by
RealDigital. The IP is found at `hdl/synth/hdmi_ip`. It is configured use RGB
332 (3 bits of red, 3 bits of green, and 2 bits of blue).

Aside from the VGA-HDMI IP, the processor requires instantiation of a single
Clocking Wizard. The wizard takes in the 100MHz clock from the board and outputs
the clock frequencies specified by the names of the instantiation in
`core_top.sv`.

Simulations live at `hdl/sim`.

Additionally, the graphics processor uses a MicroBlaze processor to act as a
controlling CPU. It is fairly simple and requires the following components:

* At least 16KB of on chip memory (I used 64KB)
* MicroBlaze Debug Module
* 100MHz clock input (no clocking wizard; the clock is provided by the clocking
  wizard instantiated in the top level module)
* AXI Uartlite
* AXI GPIO (ordering follows memory map; 64KB range per, 0x40000000 base)
  * `gpio_p_avail`: 1 bit output
  * `gpio_p_d_in`: 16 bit output
  * `gpio_p_lo_ack`: 1 bit input
  * `gpio_p_ready`: 1 bit input
  * `gpio_prog`: 1 bit output

The MicroBlaze processor is very minimal without expensive features like barrel
shifter and multiplier. However, inclusion of such features should not affect
operation.

The hardware can be built using the XDC file at `/top.xdc`.

## Software

The MicroBlaze processor uses the software located at `cpu/`. The demos are
already assembled and present in the file `progs.h`. The two files can be
imported into Vitis where it may be built and programmed (along with the
exported bitstream from Vivado).

## Usage

The graphics processor outputs all information to the framebuffer which is
visible through the HDMI interface.

Most of the UI happens through the MicroBlaze's UART. Connect over serial using
the configured baus rate and press enter. A list of demo programs will be
printed to the screen. Enter the number corresponding to a demo and press enter.
The kernel will be programmed onto the graphics processor and it will begin to
run.

Some demos make use of user input. For these demos, the dev board's switches (7
to 0) are passed through to the GPU.
