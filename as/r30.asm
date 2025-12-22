; draw the single center pixel in the top row
ldi r1, 160
not r2, r0
st r1, r2

; compute the next line
; lines are computed forever and wrap around to the top
ldi r2, 1
loopy:
ldi r1, 0
loopx:

; current address is (y * 320) + x
; address of previous line is (y - 1) * 360 + x
;  (x-1) = p, (x+0) = q, (x+1) = r
ldi r3, 160
sh.l r3, 1
mul r4, r2, r3
add r4, r4, r1 ; current address = r4

addi r5, r2, -1
mul r5, r5, r3
add r5, r5, r1

addi r5, r5, -1 ; top left    = p
ld r6, r5
addi r5, r5, 1  ; right above = q
ld r7, r5
addi r5, r5, 1  ; top right    = r
ld r8, r5

; next state = p XOR (q OR r)
or r7, r7, r8
xor r6, r6, r7

st r4, r6

; wait a bit
ldi r3, 255
sh.l r3, 1
loop_busy:
addi r3, r3, -1
sub r0, r0, r3
b.c loop_busy


addi r1, r1, 1
ldi r3, 160
sh.l r3, 1
sub r0, r1, r3
b.c loopx
addi r2, r2, 1
b loopy
