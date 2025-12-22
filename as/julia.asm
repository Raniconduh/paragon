loop:

ldi r2, 20
mul r2, r15, r2
loopy:
mov r1, r0
loopx:

; read c from the switches
not r3, r0
ld r3, r3
; cx is the upper 4 bits of c
; cy is the lower 4 bits
; both cx, cy are signed
mov r4, r3
sh.l r4, 20
sh r4, 18 ; extract signedness, convert to Q18.6
sh r3, 4
sh.l r3, 20
sh.a r3, 18
;; nice x: -0.8 + 0.156i
;ldi r3, 0b110011
;sub r3, r0, r3
;ldi r4, 0b001001
; (cx, cy) = (r3, r4)

; convert the coordinate into (zx, zy)
; zx = 4x / X - 2.5
; zy = 4y / Y - 2.0
mov r5, r1
sh.l r5, 8 ; 6 (conversion) + 2 (multiplication)
sh.a r5, 8  ; approximately /320
ldi r6, 2
sh.l r6, 6
ldi r7, 0b100000
or r6, r6, r7
sub r5, r5, r6 ; 4x/X - 2.5

mov r6, r2
sh.l r6, 8
sh.a r6, 8 ; approximately /240
ldi r7, 2
sh.l r7, 6
sub r6, r6, r7 ; 4y/Y - 2.0

; (x,  y)  = (r1, r2)
; (cx, cy) = (r3, r4)
; (zx, zy) = (r5, r6)
ldi r7, 255
iterloop:
; zx_next = zx*zx - zy*zy + cx
mul r8, r5, r5
mul r9, r6, r6
sub r8, r8, r9
sh.a r8, 6
add r8, r8, r3

; zy_next = 2*zx*zy + cy
mul r9, r5, r6
sh.a r9, 5 ; 2*(zx*zy >>> 6)
add r9, r9, r4

mov r5, r8
mov r6, r9

; break when zx*zx + zy*zy > 4
mul r8, r5, r5
mul r9, r6, r6
add r8, r8, r9
sh.a r8, 6
ldi r9, 4
sh.l r9, 6
sub r0, r9, r8
b.n iterloop_done

addi r7, r7, -1
sub r0, r0, r7
b.c iterloop

iterloop_done:
; diverges at time t = 255 -r7
; addr = 320*y + x
ldi r8, 160
sh.l r8, 1
mul r8, r2, r8
add r8, r8, r1

st r8, r7

addi r1, r1, 1
ldi r3, 160
sh.l r3, 1
sub r0, r1, r3
b.c loopx
addi r2, r2, 1
ldi r3, 20
addi r4, r15, 1
mul r3, r3, r4
sub r0, r2, r3
b.c loopy

b loop
