sub r0, r0, r15
b.c -1

; load cube corners
ldi r1, 160
sh.l r1, 1
ldi r2, 240
mul r10, r1, r2
; r10 + 0: (x1: 8b, y1: 8b, z1: 8b)
; r10 + 3: (x2: 8b, y2: 8b, z2: 8b)
; ...
; ( 1,  1,  1) 0
; ( 1,  1, -1) 1
; ( 1, -1,  1) 2
; ( 1, -1, -1) 3
; (-1,  1,  1) 4
; (-1,  1, -1) 5 
; (-1, -1,  1) 6
; (-1. -1, -1) 7
mov r11, r10

ldi r1, 1
sh.l r1, 6
sub r2, r0, r1

; 0
st r11, r1
addi r11, r11, 1
st r11, r1
addi r11, r11, 1
st r11, r1
; 1
addi r11, r11, 1
st r11, r1
addi r11, r11, 1
st r11, r1
addi r11, r11, 1
st r11, r2
; 2
addi r11, r11, 1
st r11, r1
addi r11, r11, 1
st r11, r2
addi r11, r11, 1
st r11, r1
; 3
addi r11, r11, 1
st r11, r1
addi r11, r11, 1
st r11, r2
addi r11, r11, 1
st r11, r2
; 4
addi r11, r11, 1
st r11, r2
addi r11, r11, 1
st r11, r1
addi r11, r11, 1
st r11, r1
; 5
addi r11, r11, 1
st r11, r2
addi r11, r11, 1
st r11, r1
addi r11, r11, 1
st r11, r2
; 6
addi r11, r11, 1
st r11, r2
addi r11, r11, 1
st r11, r2
addi r11, r11, 1
st r11, r1
; 7
addi r11, r11, 1
st r11, r2
addi r11, r11, 1
st r11, r2
addi r11, r11, 1
st r11, r2
; cube is stored at r10

loop:
ldi r1, 160
sh.l r1, 1
ldi r2, 240
mul r1, r1, r2
clear:
st r1, r0
addi r1, r1, -1
ldi r2, 160
sub r0, r2, r1
b.c clear

; draw cube
mov r1, r10
loop_cube:

ld r2, r1
sh.l r2, 16
sh.a r2, 16
addi r1, r1, 1
ld r3, r1
sh.l r3, 16
sh.a r3, 16
addi r1, r1, 1
ld r4, r1
sh.l r4, 16
sh.a r4, 16
addi r1, r1, 1

; (x, y, z) = (r2, r3, r4)
; fbx = 160 + int(x*16)
; fby = 120 + int(y*16)
mov r5, r2
sh.a r5, 1
mov r6, r3
sh.a r6, 1
ldi r7, 160
add r5, r5, r7
ldi r7, 120
add r6, r6, r7
; addr = (fby * 320) + fbx
ldi r7, 160
sh.l r7, 1
mul r6, r6, r7
add r5, r5, r6
; store white pixel
not r6, r0
st r5, r6

; rotate cube
;     /  cos(t)  -sin(t)  0 \ / 1    0        0    \
; R = |  sin(t)   cos(t)  0 | | 0  cos(t)  -sin(t) |
;     \    0        0     1 / \ 0  sin(t)   cos(t) /
;
;     / cos(t)  -sin(t)cos(t)     sin(t)^2   \
;   = | sin(t)    cos(t)^2     -sin(t)cos(t) |
;     \   0        sin(t)          cos(t)    /
;
; x' = xcos(t) - ysin(t)cos(t) + zsin(t)^2
; y' = xsin(t) + ycos(t)^2 - zsin(t)cos(t)
; z' = ysin(t) + zcos(t)
;
; (x, y, z) = (r2, r3, r4)
ldi r5, 0b00111111 ; cos
ldi r6, 0b00001011 ; sin
ldi r7, 0b00001010 ; sin*cos
ldi r8, 0b00111110 ; cos^2
ldi r9, 0b00000001 ; sin^2

;addi r5, r5, 1
;addi r6, r6, 1
;addi r7, r7, 1
;addi r8, r8, 1
;addi r9, r9, 1

; x' = xcos(t) - ysin(t)cos(t) + zsin(t)^2
mul r11, r2, r5
mul r12, r3, r7
mul r13, r4, r9
add r11, r11, r13
sub r11, r11, r12
sh.a r11, 6
addi r12, r1, -3
st r12, r11
; y' = xsin(t) + ycos(t)^2 - zsin(t)cos(t)
mul r11, r2, r6
mul r12, r3, r8
mul r13, r4, r7
add r11, r11, r12
sub r11, r11, r13
sh.a r11, 6
addi r12, r1, -2
st r12, r11
; z' = ysin(t) + zcos(t)
mul r11, r3, r6
mul r12, r4, r5
add r11, r11, r12
sh.a r11, 6
addi r12, r1, -1
st r12, r11

ldi r5, 24     ; 3 * 8
add r5, r5, r10
sub r0, r1, r5
b.c loop_cube

ldi r1, 255
sh.l r1, 11
busy:
addi r1, r1, -1
sub r0, r0, r1
b.c busy

b loop


b -1
