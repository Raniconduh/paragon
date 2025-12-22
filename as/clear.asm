ldi r1, 1
ldi r2, 240
ldi r3, 160
sh.l r3, 1
mul r2, r2, r3 ; 320*240

add r3, r0, r0
loop:
st r3, r0

add r3, r3, r1
sub r0, r3, r2
b.c loop

b.nzc -1
