import re

from pe import PE

pe=PE()
for name,val in [("0x5a5460",0x5a5460),("0x639220",0x639220),("0x5a5430",0x5a5430)]:
    needle=val.to_bytes(4,'little')
    print(f"\n=== occurrences of {name} in whole image ===")
    for m in re.finditer(re.escape(needle), pe.data):
        foff=m.start()
        try:
            va=pe.foff_to_va(foff); sec=pe.sec_for_foff(foff).name
            print(f"  foff {foff:#08x} -> VA {va:#08x} [{sec}]")
        except Exception as e:
            print(f"  foff {foff:#08x} (no VA: {e})")
