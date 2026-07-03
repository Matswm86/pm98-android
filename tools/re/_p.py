from pe import PE

pe=PE()
print("=== 0x5a5460 prologue (first 40 insns) ===")
for ins in pe.disasm_va(0x5a5460, 140):
    print(f"  {ins.address:#08x}: {ins.mnemonic:7} {ins.op_str}")
    if ins.address > 0x5a5460+90: break
print("\n=== vtable bytes around 0x639220 (.data) ===")
import struct

raw=pe.read_va(0x639210, 0x40)
for i in range(0,0x40,4):
    va=0x639210+i
    val=struct.unpack_from('<I',raw,i)[0]
    print(f"  [{va:#08x}] = {val:#010x}")
