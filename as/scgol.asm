; stall other cores
sub r0, r0, r15
b.c -1

; load initial state
ldi r1, 80
ldi r2, 115
ldi r3, 160
sh.l r3, 1
mul r2, r2, r3
add r1, r1, r2

; glider
not r2, r0
st r1, r2
add r1, r1, r3
addi r1, r1, 1
st r1, r2
add r1, r1, r3
addi r1, r1, 1
st r1, r2
addi r1, r1, -1
st r1, r2
addi r1, r1, -1
st r1, r2

; oscillator
;st r1, r2
;addi r1, r1, 1
;st r1, r2
;addi r1, r1, 1
;st r1, r2

loop:
; calculate next state
; next state is stored in the second half of the framebuffer
; i.e. starting at x = [160, 320) instead of [0, 160)
ldi r2, 1
calc_loopy:
ldi r1, 1
calc_loopx:
; (x, y) = (r1, r2)
; neighbors:
;   (-1, -1), (+0, -1), (+1, -1)
;   (-1, +0),           (+1, +0)
;   (-1, +1), (+0, +1), (+1, +1)
mov r3, r0 ; n_neighbors

addi r4, r0, -1
loopi:
addi r5, r0, -1
loopj:
or r0, r4, r5
b.z loopj_continue ; skip the current cell

add r12, r1, r4
add r13, r2, r5
aipc r14, 1
b getpx
ldi r12, 1
and r13, r13, r12
add r3, r3, r13

loopj_continue:
addi r5, r5, 1
ldi r6, 2
sub r0, r5, r6
b.c loopj
addi r4, r4, 1
ldi r6, 2
sub r0, r4, r6
b.c loopi

; compute next state
; next = (n == 3) | (s & (n == 2))
mov r12, r1
mov r13, r2
aipc r14, 1
b getpx
; current pixel in r13
; n_neighbors in r3
ldi r4, 3
sub r0, r3, r4
b.z alive        ; n == 3
ldi r4, 1
and r13, r13, r4
add r3, r3, r13
ldi r4, 3
sub r0, r3, r4
b.z alive

; dead:
mov r3, r0
b store
alive:
not r3, r0
store:
; store pixel in right buffer
ldi r11, 160
add r11, r1, r11
mov r12, r2
mov r13, r3
aipc r14, 1
b setpx

addi r1, r1, 1
ldi r3, 159
sub r0, r1, r3
b.c calc_loopx
addi r2, r2, 1
ldi r3, 239
sub r0, r2, r3
b.c calc_loopy

; store the pixels from the right buffer into the left buffer
ldi r2, 1
buf_loopy:
ldi r1, 1
buf_loopx:

ldi r3, 160
add r12, r1, r3
mov r13, r2
aipc r14, 1
b getpx

mov r11, r1
mov r12, r2
aipc r14, 1
b setpx

addi r1, r1, 1
ldi r3, 159
sub r0, r1, r3
b.c buf_loopx
addi r2, r2, 1
ldi r3, 239
sub r0, r2, r3
b.c buf_loopy

b loop

;;;;;;;;;;;;;;;
;; FUNCTIONS ;;


; return pointer in r14
; x in r12
; y in r13
; returns pixel in r13
getpx:
	; addr = y*320 + x
	;      = (y << 6) + (y << 8) + x
	sh.l r13, 6
	add r12, r12, r13
	sh.l r13, 2
	add r12, r12, r13
	ld r13, r12

	b r14

; return pointer in r14
; x in r11
; y in r12
; px in r13
setpx:
	sh.l r12, 6
	add r11, r11, r12
	sh.l r12, 2
	add r11, r11, r12
	st r11, r13

	b r14
