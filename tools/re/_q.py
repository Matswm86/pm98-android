from pe import PE

pe=PE()
# full function ~ 0x5a5460 .. next fn. Size ~ (0x5a65a0-0x5a5460)? next known fn 0x5a65a0.
lo,hi=0x5a5460,0x5a65a0
hits=[]
for ins in pe.disasm_va(lo, hi-lo):
    ops=ins.op_str
    if '0x32c' in ops or '0x328' in ops:
        hits.append((ins.address,ins.mnemonic,ops))
print("accesses to [esp+0x32c]/0x328 (param_2 / retaddr region):")
for a,m,o in hits: print(f"  {a:#08x}: {m} {o}")
print("\naccesses mentioning 0xdc / 0xde (camera angle fields):")
for ins in pe.disasm_va(lo, hi-lo):
    if '0xdc' in ins.op_str or '0xde' in ins.op_str or '0xdd' in ins.op_str:
        print(f"  {ins.address:#08x}: {ins.mnemonic:7} {ins.op_str}")
