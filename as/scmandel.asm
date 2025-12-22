; mandelbrot set demo but single core
; all cores other than zero will loop
sub r0, r0, r15
b.c -1

; 18.6 fixed point format
; 18.6 * 18.6 = 36.12 => 12.12
ldi r1, 1

; draw to [coreid*60, (coreid+1)*60]
;ldi r3, 20
;mul r3, r15, r3
ldi r3, 0
loopy:

; cy = y*3/240 - 1.5
mov r5, r3
sh.l r5, 6     ; r5 = fixed_point(y)
ldi r6, 3
sh.l r6, 6     ; r6 = 3.0
ldi r7, 0b000000
or r6, r6, r7
mul r5, r5, r6
sh.a r5, 14
ldi r6, 1
sh.l r6, 6
ldi r7, 0b100000
or r6, r6, r7  ; r7 = 1.5
sub r5, r5, r6

mov r2, r0
loopx:
; (x, y)   = (r2, r3)
; (cx, cy) = (r4, r5)

; cx = x*3.5/320 - 2.5
mov r4, r2
sh.l r4, 6     ; r4 = fixed_point(x)
ldi r6, 3
sh.l r6, 6
ldi r7, 0b100000
or r6, r6, r7  ; r6 = 3.5
mul r4, r4, r6
sh.a r4, 14
ldi r6, 2
sh.l r6, 6
ldi r7, 0b100000
or r6, r6, r7  ; r6 = 2.5
sub r4, r4, r6


mov r6, r0
mov r7, r0

; (cx, cy) = (r4, r5)
; (xz, zy) = (r6, r7)
mov r8, r0
iterloop:
; zx_next = zx*zx - zy*zy + cx
mul r9, r6, r6
sh.a r9, 6
mul r10, r7, r7
sh.a r10, 6
sub r9, r9, r10
add r9, r9, r4
; zy_next = 2*zx*zy + cy
mul r10, r6, r7
sh.a r10, 5
add r10, r10, r5

mov r6, r9
mov r7, r10

; break when zx*zx + zy*zy > 4
mul r9, r6, r6
sh.a r9, 6
mul r10, r7, r7
sh.a r10, 6
add r9, r9, r10
ldi r10, 4
sh.l r10, 6
sub r0, r10, r9
b.c iterloop_done

addi r8, r8, 1
ldi r9, 255
sh.l r9, 2
sub r0, r8, r9
b.n iterloop

iterloop_done:
; diverged at time t = r8
ldi r9, 255
sh.l r9, 2
sub r9, r9, r8
; addr = y*320 + x
ldi r10, 160
sh.l r10, 1
mul r10, r3, r10
add r10, r10, r2
st r10, r9

addi r2, r2, 1
ldi r9, 160
sh.l r9, 1
sub r0, r2, r9
b.n loopx

addi r3, r3, 1
;ldi r10, 20
;add r9, r15, r1
;mul r9, r9, r10
ldi r9, 240
sub r0, r3, r9
b.n loopy

b -1
