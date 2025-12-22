#include <SDL3/SDL.h>

#include "framebuffer.h"

uint8_t framebuffer[FB_HEIGHT*FB_WIDTH] = {};

static SDL_Window * window = NULL;
static SDL_Renderer * renderer = NULL;
static SDL_Texture * fb_texture = NULL;


int fb_init(void) {
	int ret;
	if (!SDL_Init(SDL_INIT_VIDEO)) return -1;

	ret = SDL_CreateWindowAndRenderer(
		"PARAGON",
		FB_WIDTH,
		FB_HEIGHT,
		SDL_WINDOW_RESIZABLE,
		&window,
		&renderer
	);
	if (!ret) return -1;

	SDL_SetRenderLogicalPresentation(
		renderer,
		FB_WIDTH,
		FB_HEIGHT,
		SDL_LOGICAL_PRESENTATION_INTEGER_SCALE
	);

	fb_texture = SDL_CreateTexture(
		renderer,
		SDL_PIXELFORMAT_RGB332,
		SDL_TEXTUREACCESS_STREAMING,
		FB_WIDTH,
		FB_HEIGHT
	);

	SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
	SDL_RenderClear(renderer);
	return 0;
}


//void fb_setpx(uint32_t addr, uint8_t px) {
//	int x, y;
//	x = addr % FB_WIDTH;
//	y = addr / FB_WIDTH;
//
//	uint8_t r, g, b;
//	r = (px >> 5) & 0b111;
//	g = (px >> 2) & 0b111;
//	b = (px >> 0) & 0b011;
//
//	r = (0xFF * (uint16_t)r) / 0b111;
//	g = (0xFF * (uint16_t)g) / 0b111;
//	b = (0xFF * (uint16_t)b) / 0b011;
//
//	SDL_SetRenderDrawColor(renderer, r, g, b, SDL_ALPHA_OPAQUE);
//	SDL_RenderPoint(renderer, x, y);
//}


void fb_refresh(void) {
	SDL_UpdateTexture(fb_texture, NULL, framebuffer, FB_WIDTH);
	SDL_RenderClear(renderer);
	SDL_RenderTexture(renderer, fb_texture, NULL, NULL);
	SDL_RenderPresent(renderer);
}
