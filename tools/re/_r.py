from pe import PE

pe=PE()
text=next(s for s in pe.sections if s.name=='.text')
data=pe.data[text.foff:text.foff+text.size]
base=text.vma
needle=(0x639220).to_bytes(4,'little')
import re

print("immediate 0x639220 refs in .text:")
for m in re.finditer(re.escape(needle), data):
    va=base+m.start()
    # disasm a few insns starting a bit before to show the instruction using it
    # find instruction boundary by disassembling from va-16
    seq=list(pe.disasm_va(va-16, 32))
    host=None
    for ins in seq:
        if ins.address <= va < ins.address+ins.size:
            host=ins; break
    if host:
        print(f"  {host.address:#08x}: {host.mnemonic:7} {host.op_str}")
    else:
        print(f"  raw @ {va:#08x} (not aligned to an insn in window)")
