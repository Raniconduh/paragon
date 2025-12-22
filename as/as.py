#!/usr/bin/python3

import sys
import re

class Operand:
    REGISTER = "register"
    UIMMEDIATE8 = "unsigned immediate8"
    SIMMEDIATE8 = "signed immediate8"
    SIMMEDIATE4 = "signed immediate4"
    IMMEDIATE5 = "immediate5"
    LABEL = "label"

    def __init__(self, op, optype):
        self.op = op
        self.optype = optype
        self.conv = None

    def __str__(self):
        return self.op

    def __repr__(self):
        return str(self)

    def type(self):
        return self.optype

    def valid(self):
        if not self.op: return False

        if self.type() == Operand.REGISTER:
            if len(self.op) < 2: return False
            if self.op[0].upper() != 'R': return False
            i = None
            try:
                i = int(self.op[1:])
            except ValueError:
                return False
            if i < 0 or i > 15:
                return False
            self.conv = f'{i:04b}'
            return True
        elif self.type() == Operand.UIMMEDIATE8:
            base = 10
            if self.op.startswith('-'): return False
            if self.op.startswith('0x'): base = 16
            elif self.op.startswith('0b'): base = 2
            elif self.op.startswith('0'): base = 8
            i = None
            try:
                i = int(self.op, base=base)
            except ValueError:
                return False
            if i > 255 or i < 0: return False
            self.conv = f'{i:08b}'
            return True
        elif self.type() == Operand.SIMMEDIATE8:
            base = 10
            sint = self.op
            if self.op.startswith('-'): sint = self.op[1:]
            if sint.startswith('0x'): base = 16
            elif sint.startswith('0b'): base = 2
            elif sint.startswith('0'): base = 8
            i = None
            try:
                i = int(self.op, base=base)
            except ValueError:
                return False
            if i < -128 or i > 127: return False
            if i < 0: i = (1 << 8) + i
            self.conv = f'{i:08b}'
            return True
        elif self.type() == Operand.SIMMEDIATE4:
            base = 10
            sint = self.op
            if self.op.startswith('-'): sint = self.op[1:]
            if sint.startswith('0x'): base = 16
            elif sint.startswith('0b'): base = 2
            elif sint.startswith('0'): base = 8
            i = None
            try:
                i = int(self.op, base=base)
            except ValueError:
                return False
            if i < -8 or i > 7: return False
            if i < 0: i = (1 << 4) + i
            self.conv = f'{i:04b}'
            return True
        elif self.type() == Operand.IMMEDIATE5:
            if not self.op: return False
            base = 10
            if self.op.startswith('0x'): base = 16
            elif self.op.startswith('0b'): base = 2
            elif self.op.startswith('0'): base = 8
            i = None
            try:
                i = int(self.op, base=base)
            except ValueError:
                return False
            if i >= (1<<5) or i < 0: return False
            self.conv = f'{i:05b}'
            return True
        elif self.type() == Operand.LABEL:
            label_re = r'[_a-zA-Z][_a-zA-Z0-9]*'
            if re.match(label_re, self.op) is None: return False
            self.conv = self.op
            return True

class Instruction:
    def __init__(self, opcode, n_args, argtypes, flags, formatter):
        self.opcode = opcode
        self.n_args = n_args
        self.argtypes = argtypes
        self.flags = flags
        self.formatter = lambda *args: opcode + formatter(*args)

class Format:
    def join(l):
        s = ''
        for i in l:
            s += i.conv
        return s

    def ALU(args, _):
        return Format.join(args)

    def NOT(args, _):
        return Format.join(args) + '0000'

    def SH(args, flags):
        l = '1' if 'L' in flags else '0'
        a = '1' if 'A' in flags else '0'
        return args[0].conv + l + a + '0' + args[1].conv

    def LD_ST(args, _):
        return Format.join(args) + '0000'

    def LDI(args, _):
        return Format.join(args)

    def B(args, flags):
        n = '1' if 'N' in flags else '0'
        z = '1' if 'Z' in flags else '0'
        c = '1' if 'C' in flags else '0'
        if n == '0' and z == '0' and c == '0':
            n = '1'
            z = '1'
            c = '1'
        fmt = n + z + c
        if args[0].type() is Operand.REGISTER:
            fmt += '0' + args[0].conv + '0000'
        else:
            fmt += '1' + args[0].conv
        return fmt

    def ADDI(args, _):
        return Format.join(args)

    def AIPC(args, _):
        return Format.ADDI(args, _)

    # pseudo ops
    def MOV(args, _):
        return Format.join(args) + '0000'

class Instructions:
    class Type:
        Label = "label"
        Instruction = "instruction"

    class InsPair:
        def __init__(self, instype, name, address):
            self.instype = instype
            self.name = name
            self.address = address

        def __repr__(self):
            if self.instype == Instructions.Type.Label:
                return f'{self.name}: 0x{self.address:x}'
            else:
                return str(self.instype) + str(self.name)


    instructions = {
        'ADD' : Instruction('0000', 3, [[Operand.REGISTER]*3], None, Format.ALU),
        'SUB' : Instruction('0001', 3, [[Operand.REGISTER]*3], None, Format.ALU),
        'MUL' : Instruction('0010', 3, [[Operand.REGISTER]*3], None, Format.ALU),
        'AND' : Instruction('0011', 3, [[Operand.REGISTER]*3], None, Format.ALU),
        'OR'  : Instruction('0100', 3, [[Operand.REGISTER]*3], None, Format.ALU),
        'XOR' : Instruction('0101', 3, [[Operand.REGISTER]*3], None, Format.ALU),
        'NOT' : Instruction('0110', 2, [[Operand.REGISTER]*2], None, Format.NOT),
        'SH'  : Instruction('0111', 2, [[Operand.REGISTER, Operand.IMMEDIATE5]], ['L', 'A'], Format.SH),
        'LD'  : Instruction('1000', 2, [[Operand.REGISTER]*2], None, Format.LD_ST),
        'ST'  : Instruction('1001', 2, [[Operand.REGISTER]*2], None, Format.LD_ST),
        'LDI' : Instruction('1010', 2, [[Operand.REGISTER, Operand.UIMMEDIATE8]], None, Format.LDI),
        'B'   : Instruction('1011', 1, [[Operand.REGISTER], [Operand.SIMMEDIATE8], [Operand.LABEL]], ['N', 'Z', 'C'], Format.B),
        'ADDI': Instruction('1100', 3, [[Operand.REGISTER, Operand.REGISTER, Operand.SIMMEDIATE4]], None, Format.ADDI),
        'AIPC': Instruction('1101', 2, [[Operand.REGISTER, Operand.SIMMEDIATE8]], None, Format.AIPC),

        # pseudo ops
        'MOV' : Instruction('0000', 2, [[Operand.REGISTER]*2], None, Format.MOV),
    }

    def get(name):
        return Instructions.instructions.get(name.upper(), None)


if len(sys.argv) < 3:
    print("Command format: `as <infile> <outfile>`")
    exit(1)

infile = sys.argv[1]
outfile = sys.argv[2]

assembled = []
labels = {}

# lexing and some parsing
line_no = 0
address = 0
with open(infile, 'r') as f:
    for line in f:
        line_no += 1
        # remove comments
        for i in range(len(line)):
            if line[i] == ';':
                line = line[:i]
                break
        line = [s.strip() for s in line.strip().split(' ')]
        line = [s for s in line if s] # remove empty elements
        if not line: continue

        if line[0].endswith(':'):
            if len(line) != 1:
                print(f'L{line_no}: Garbage past label declaration')
                exit(1)
            label = line[0][:-1]
            labels[label] = address
        else:
            opc = line[0].partition('.')
            flags = [f.upper() for f in opc[2]]
            opcode = Instructions.get(opc[0])
            if opcode is None:
                print(f'L{line_no}: Unknown opcode {opc[0]}')
                exit(1)

            for flag in flags:
                if flag not in opcode.flags:
                    print(f'L{line_no}: Invalid flag "{flag}"')
                    exit(1)

            args = []
            for arg in line[1:]:
                if arg.endswith(','):
                    arg = arg[:-1]

                args.append(arg)
            if len(args) != opcode.n_args:
                print(f'L{line_no}: Instruction expects {opcode.n_args} arguments, {len(args)} given')
                exit(1)
            for i in range(len(args)):
                for argtype in opcode.argtypes:
                    arg = Operand(args[i], argtype[i])
                    if arg.valid():
                        args[i] = arg
                        break
                else:
                    print(f'L{line_no}: Invalid argument "{args[i]}", expected {opcode.argtypes}')
                    exit(1)


            assembled.append(Instructions.InsPair(Instructions.Type.Instruction, [opc[0], flags, args], address))
            address += 1

# label offsets
for word in assembled:
    for i in range(len(word.name[2])):
        arg = word.name[2][i]
        if arg.type() == Operand.LABEL:
            # PC is addr+1 for each instruction
            # so branches have to account for it
            label_addr = labels.get(arg.op, None)
            if label_addr is None:
                print(f'Invalid label: {arg.op}')
                exit(1)
            word_addr = word.address
            offset = label_addr - word_addr - 1

            if offset < -128 or offset > 127:
                print(f'{word} Branch offset is too large; fix manually')
                exit(1)
            operand = Operand(str(offset), Operand.SIMMEDIATE8)
            if not operand.valid():
                print('Uhh, I made an offset error!')
                exit(1)
            word.name[2][i] = operand

# output
#with open(outfile, 'w') as f:
#    for word in assembled:
#        instruction = Instructions.get(word.name[0])
#        word = instruction.formatter(word.name[2], word.name[1])
#        f.write(f'{word}\n')

print(f"uint16_t prog_{outfile}[] = {{")
for word in assembled:
    instruction = Instructions.get(word.name[0])
    word = instruction.formatter(word.name[2], word.name[1])
    print(f'\t0b{word},')
print("};")
