#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "xil_printf.h"

#include "progs.h"

volatile uint32_t * p_avail_data  = (uint32_t*)0x40000000;
volatile uint32_t * p_d_in_data   = (uint32_t*)0x40010000;
volatile uint32_t * p_lo_ack_data = (uint32_t*)0x40020000;
volatile uint32_t * p_ready_data  = (uint32_t*)0x40030000;
volatile uint32_t * prog_data     = (uint32_t*)0x40040000;

#define P_AVAIL    (*(p_avail_data))
#define P_D_IN     (*(p_d_in_data))
#define P_LO_ACK   (*(p_lo_ack_data))
#define P_READY    (*(p_ready_data))
#define PROG       (*(prog_data))

#define ARRLEN(A) (sizeof(A) / sizeof*(A))
#define PROG_ENTRY(prog, name) {prog, ARRLEN(prog), name}

typedef struct {
	uint16_t * rom;
	uint32_t size;
	char name[16];
} prog_t;

prog_t progs[] = {
	PROG_ENTRY(prog_clear, "Display Clear"),
	PROG_ENTRY(prog_halt, "Halt"),
	PROG_ENTRY(prog_gradient, "Gradient"),
	PROG_ENTRY(prog_scmandel, "SC Mandelbrot"),
	PROG_ENTRY(prog_mandel, "Mandelbrot Set"),
	PROG_ENTRY(prog_ship, "Burning Ship"),
	PROG_ENTRY(prog_julia, "Julia Set"),
	PROG_ENTRY(prog_blur, "Box Blur"),
	PROG_ENTRY(prog_r30, "Rule 30"),
	PROG_ENTRY(prog_scgol, "SC GoL"),
	PROG_ENTRY(prog_gol, "Game of Life"),
	PROG_ENTRY(prog_checker, "Checkerboard"),
	PROG_ENTRY(prog_cube, "Cube"),
};

static inline void do_program(int id) {
	xil_printf("Programming: %s\n", progs[id].name);
	P_AVAIL = 0;
	PROG = 1;
	for (uint32_t i = 0; i < progs[id].size; i++) {
		P_D_IN = progs[id].rom[i];
		P_AVAIL = 1;
		while (!P_READY)
			;
		P_AVAIL = 0;
		while (!P_LO_ACK)
			;
	}
	PROG = 0;
	xil_printf("Programming Finished\n");
}

static inline void print_selector(void) {
	for (int i = 0; i < ARRLEN(progs); i++) {
		xil_printf("%d. ", i);
		xil_printf("%s\n", progs[i].name);
	}
	xil_printf("\n");
}

static inline int readint(void) {
	int i = 0;
	char seen = 0;
	char c;
	while ((c = inbyte()) != '\r' && c != '\n') {
		if (c < '0' || c > '9') return -1;
		i *= 10;
		i += c - '0';
		seen = 1;
	}
	if (!seen) return -2;
	return i;
}

int main()
{
    init_platform();

	for (;;) {
		print_selector();

		int i = readint();
		if (i == -2) continue;
		if (i < 0 || i >= ARRLEN(progs)) xil_printf("Invalid ID: %d\n", i);
		else do_program(i);
	}

    cleanup_platform();
    return 0;
}
