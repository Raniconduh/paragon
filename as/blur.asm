ldi r2, 20
mul r2, r15, r2
loopy:
ldi r1, 0
loopx:

mov r3, r0 ; R
mov r4, r0 ; G
mov r5, r0 ; B

addi r6, r0, -1
loopi:
addi r7, r0, -1
loopj:

; (x', y') = (x + i, y + j)
add r8, r1, r6
add r9, r2, r7
; load pixel @ (y' * 320) + x'
ldi r10, 160
sh.l r10, 1
mul r9, r9, r10
add r8, r8, r9
ld r9, r8
mov r8, r9

; px = r8
; r' += (px >> 5) & 0b111
; g' += (px >> 2) & 0b111
; b' += (px >> 0) & 0b011
ldi r9, 0b011
and r9, r8, r9
add r5, r5, r9
ldi r10, 0b111
sh r8, 2
and r9, r8, r10
add r4, r4, r9
sh r8, 3
and r9, r8, r10
add r3, r3, r9

addi r7, r7, 1
ldi r8, 2
sub r0, r7, r8
b.n loopj
addi r6, r6, 1
sub r0, r6, r8
b.n loopi

; (r, g, b) = 1/9 * (r', g', b')
sh r3, 3
sh r4, 3
sh r5, 3
ldi r6, 0b011
and r5, r5, r6
ldi r6, 0b111
and r4, r4, r6
and r3, r3, r6
; px = (r << 5) | (g << 2) | (b << 0)
sh.l r3, 5
sh.l r4, 2
or r3, r3, r4
or r3, r3, r5

; addr' = (y * 320) + x + 160
ldi r4, 160
sh.l r4, 1
mul r4, r2, r4
add r4, r4, r1
;ldi r5, 160
;add r4, r4, r5

st r4, r3

addi r1, r1, 1
ldi r3, 160
sh.l r3, 1
sub r0, r1, r3
b.c loopx
addi r2, r2, 1
addi r3, r15, 1
ldi r4, 20
mul r3, r3, r4
sub r0, r2, r3
b.c loopy

b.nzc -1
