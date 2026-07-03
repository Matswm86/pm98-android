from pe import PE

pe=PE()
text=next(s for s in pe.sections if s.name==".text")
data=pe.data[text.foff:text.foff+text.size]; base=text.vma
LO,HI=0x58e000,0x5c0000   # sim region
# decode /2 indirect calls with mod 0/1/2, capture disp
out=[]
i=0; n=len(data)
while i<n-6:
    if data[i]==0xFF:
        modrm=data[i+1]; mod=(modrm>>6)&3; reg=(modrm>>3)&7; rm=modrm&7
        if reg==2 and mod!=3 and rm!=4 and not(mod==0 and rm==5):
            va=base+i
            if LO<=va<HI:
                if mod==0: disp=0; ln=2
                elif mod==1: disp=int.from_bytes(data[i+2:i+3],'little',signed=True); ln=3
                else: disp=int.from_bytes(data[i+2:i+6],'little',signed=True); ln=6
                out.append((va,rm,disp))
    i+=1
# for each, disasm preceding window, find pushes
for va,rm,disp in out:
    seq=list(pe.disasm_va(va-64,72))
    pre=[x for x in seq if x.address<va][-7:]
    pushes=[f"{x.mnemonic} {x.op_str}" for x in pre if x.mnemonic=='push']
    ctx=" ; ".join(f"{x.mnemonic} {x.op_str}" for x in pre[-4:])
    print(f"{va:#08x} slot+{disp:#x} pushes={pushes}\n     ctx: {ctx}")
