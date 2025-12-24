BIN=	emu
SRC=	src/core.cpp \
		src/framebuffer.c \
		src/main.cpp \
		src/vram.cpp

CXX?=	c++
CFLAGS+=	-Iinclude -Wall -Wextra -Ofast
LDFLAGS+=	-lSDL3

all: ${SRC} include/*.h include/*.hpp
	${CXX} ${CFLAGS} ${LDFLAGS} -o ${BIN} ${SRC}

clean:
	rm ${BIN}

.PHONY: all clean
