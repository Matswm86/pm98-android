from pe import PE

pe=PE()
for ins in pe.disasm_va(0x591180, 0x120):
    print(f"  {ins.address:#08x}: {ins.mnemonic:7} {ins.op_str}")
