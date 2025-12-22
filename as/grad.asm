ldi r1, 1
ldi r2, 160
sh.l r2, 1
ldi r3, 240

add r4, r0, r0
loopy:

add r5, r0, r0
loopx:

; r = x >> 4
; g = y >> 4
; b = (x + y) >> 5
; pixel = (r << 5) | (g << 2) | b

add r6, r0, r5
sh r6, 4
add r7, r0, r4
sh r7, 4
add r8, r6, r7
sh r8, 5

sh.l r6, 5
sh.l r7, 2
or r6, r6, r7
or r6, r5, r8

; addr = y * 320 + x = (y << 8) + (y << 6) + x
add r7, r0, r4
sh.l r7, 8
add r8, r0, r4
sh.l r8, 6
add r7, r7, r8
add r7, r7, r5
st r7, r6

add r5, r5, r1
sub r0, r5, r2
b.n loopx

add r4, r4, r1
sub r0, r4, r3
b.n loopy

b.nzc -1
