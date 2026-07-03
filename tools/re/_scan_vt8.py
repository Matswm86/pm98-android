"""Scan .text for indirect `call dword [reg+8]` sites and show context.
For each, disasm a 24-insn window before to spot vtable-load + arg push."""
from capstone import CS_ARCH_X86, CS_MODE_32, Cs
from pe import PE

pe = PE()
text = next(s for s in pe.sections if s.name==".text")
data = pe.data[text.foff:text.foff+text.size]
base = text.vma
md = Cs(CS_ARCH_X86, CS_MODE_32); md.detail=True

# call dword ptr [reg+8]: FF /2 with disp8 = 08
# modrm: mod=01 (disp8), reg=010 (/2), rm=reg. byte = 0x50|rm ; rm 0..7 except 4(SIB),5=disp only
sites=[]
i=0
n=len(data)
while i < n-2:
    if data[i]==0xFF:
        modrm=data[i+1]
        mod=(modrm>>6)&3; reg=(modrm>>3)&7; rm=modrm&7
        if reg==2 and mod==1 and rm!=4 and data[i+2]==0x08:  # call [reg+8], disp8=8
            sites.append(base+i)
    i+=1
print(f"indirect call [reg+8] sites: {len(sites)}")
for s in sites:
    print(hex(s))
