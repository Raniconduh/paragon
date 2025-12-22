#include <iostream>
#include <cstdint>
#include <fstream>
#include <unistd.h>
#include <vector>
#include <string>
#include <SDL3/SDL.h>
#include <chrono>

#include "framebuffer.h"
#include "main.hpp"
#include "core.hpp"


std::vector<uint32_t> kernel;

core_t cores[N_CORES] = {};

int main(int argc, char ** argv) {
	if (argc < 2) {
		std::cout << "Usage: emu kernel.bin\n";
		return 1;
	}

	std::ifstream fp = std::ifstream(argv[1]);
	if (!fp.is_open()) {
		std::cout << "Could not open file\n";
		return 1;
	}

	std::string line;
	while (std::getline(fp, line)) {
		uint32_t i = 0;
		for (char c : line) {
			if (c != '0' && c != '1') {
				std::cout << "Invalid kernel; seen " << c << '\n';
				return 1;
			}

			uint32_t val = c - '0';
			i *= 2;
			i += val;
		}
		kernel.push_back(i);
	}
	fp.close();

	if (fb_init() < 0) {
		std::cout << "Could not initialize framebuffer\n";
		return 1;
	}

	for (int i = 0; i < N_CORES; i++) {
		cores[i].id = i;
		cores[i].halted = false;
	}

	auto last_time = std::chrono::high_resolution_clock::now();

	bool running = true;
	while (running) {
		for (int i_ = 0; i_ < 100000; i_++) {
			for (int core = 0; core < N_CORES; core++) {
				if (cores[core].halted) continue;
				step_core(cores[core], kernel);
			}
		}

		auto now_time = std::chrono::high_resolution_clock::now();
		auto passed_time = std::chrono::duration_cast<std::chrono::milliseconds>(now_time - last_time);
		if (passed_time.count() >= 15) {
			fb_refresh();
			last_time = now_time;
		}

		SDL_Event e;
		while (SDL_PollEvent(&e)) {
			if (e.type == SDL_EVENT_QUIT) running = false;
		}
	}
}
