#!/usr/bin/python3

import sys

def get_dr(s):
    return f'R{int(s[4:8], base=2)}'
def get_sr1(s):
    return f'R{int(s[8:12], base=2)}'
def get_sr2(s):
    return f'R{int(s[12:16], base=2)}'

opcodes = {
    '0000': 'ADD',
    '0001': 'SUB',
    '0010': 'MUL',
    '0011': 'AND',
    '0100': 'OR',
    '0101': 'XOR',
    '0110': 'NOT',
    '0111': 'SH',
    '1000': 'LD',
    '1001': 'ST',
    '1010': 'LDI',
    '1011': 'B'
}

alu_ops = [
    'ADD', 'SUB', 'MUL', 'AND', 'OR', 'XOR'
]

if len(sys.argv) < 2:
    print("Not enough arguments")
    exit(1)

infile = sys.argv[1]
line_no = 0
with open(infile, 'r') as f:
    for line in f:
        line_no += 1

        instruction = ""
        line = line.strip()
        opcode = line[0:4]
        if opcode not in opcodes:
            print(f"L{line_no}: Invalid opcode {opcode}")
            exit(1)
        name = opcodes[opcode]
        instruction += name
        dr  = get_dr(line)
        sr1 = get_sr1(line)
        sr2 = get_sr2(line)
        shl = int(line[8])
        sha = int(line[9])
        shimm = int(line[11:16], base=2)
        ldiimm = int(line[8:16], base=2)
        bimm = ldiimm
        bn = int(line[4])
        bz = int(line[5])
        bc = int(line[6])
        bi = int(line[7])

        if bimm > 127:
            bimm = 127 - bimm

        if name in alu_ops:
            instruction += f' {dr}, {sr1}, {sr2}'
        elif name == 'NOT':
            instruction += f' {dr}, {sr1}'
        elif name == 'SH':
            if shl | sha:
                instruction += '.'
                if shl: instruction += 'l'
                if sha: instruction += 'a'
            instruction += f' {dr}, {shimm}'
        elif name in ('LD', 'ST'):
            instruction += f' {dr}, {sr1}'
        elif name == 'LDI':
            instruction += f' {dr}, {ldiimm}'
        elif name == 'B':
            if bn | bz | bc:
                instruction += '.'
                if bn: instruction += 'n'
                if bz: instruction += 'z'
                if bc: instruction += 'c'
            if bi:
                instruction += f' {bimm}'
            else:
                instruction += f' {sr1}'

        print(instruction)
