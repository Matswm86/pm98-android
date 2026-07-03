from pe import PE

pe=PE()
def win(site, back=48, fwd=6):
    start=site-back
    print(f"\n==== site {site:#x} (window {start:#x}..) ====")
    for ins in pe.disasm_va(start, back+fwd):
        mark=" <==" if ins.address==site else ""
        print(f"  {ins.address:#08x}: {ins.mnemonic:7} {ins.op_str}{mark}")
for s in [0x598b53,0x598b64,0x598b73,0x598b82,0x5b8c02]:
    win(s)
