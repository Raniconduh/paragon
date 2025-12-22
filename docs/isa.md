# ISA

```
ADD   0000 _dr_ _sr_ _sr_      dr <- sr1 + sr2
SUB   0001 _dr_ _sr_ _sr_      dr <- sr1 - sr2
MUL   0010 _dr_ _sr_ _sr_      dr <- sr1 * sr2

AND   0011 _dr_ _sr_ _sr_      dr <- sr1 & sr2
OR    0100 _dr_ _sr_ _sr_      dr <- sr1 | sr2
XOR   0101 _dr_ _sr_ _sr_      dr <- sr1 ^ sr2
NOT   0110 _dr_ _sr_ 0000      dr <- ~sr1

SH    0111 _dr_ l a 0 -----    dr <- (dr << imm) when l else
                                     (dr >>> imm) when a else
                                     (dr >> imm)

LD    1000 _dr_ _sr_ 0000      dr <- [sr]
ST    1001 _dr_ _sr_ 0000      [dr] <- sr
LDI   1010 _dr_ ---- ----      dr <- ZEXT(imm)

B     1011 n z c i _sr_ ----   if (CC) PC <- sr when ~i else
                                             PC + SEXT(imm)

ADDI  1100 _dr_ _sr_ ----      dr <- sr + SEXT(imm)
AIPC  1101 _dr_ ---- ----      dr <- PC + SEXT(imm)
```

# Special Cases

The `B` instruction checks the condition codes before branching. The branch
condition is `(n & CC.n) | (z & CC.z) | (c & CC.c) | (n & z & c)`.

When `i` is specified for the `B` instruction, the `sr` field and remaining
four bits make up the eight bit immediate

# Registers

16 register, 24 bits wide

0x0 is zero register: sinks all writes, sources 0

0xF is core ID

# Memory

Harvard style ISA: instruction ROM is read-only and is only accessed by fetch.
Video memory (VRAM) is accessed using `LD` and `ST` instructions and is byte
addressed. Each byte is one pixel (RRRGGGBB). VRAM corresponds to a 320x240
display, so `SCREEN[x][y]` = `VRAM[y * 320 + x]`.
