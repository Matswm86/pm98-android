import re
import struct

from pe import PE

pe=PE()
print("=== .rdata 0x6391d0..0x639250 ===")
raw=pe.read_va(0x6391d0,0x90)
for i in range(0,0x90,4):
    va=0x6391d0+i; val=struct.unpack_from('<I',raw,i)[0]
    tag=""
    if 0x401000<=val<0x623000: tag="<text>"
    print(f"  [{va:#08x}] = {val:#010x} {tag}")
# find refs to candidate vtable bases
print("\n=== .text refs to candidate vtable bases ===")
for base in (0x6391f0,0x639200,0x639210,0x6391f8,0x639208,0x639218):
    needle=base.to_bytes(4,'little')
    hits=[pe.foff_to_va(m.start()) for m in re.finditer(re.escape(needle),pe.data)
          if pe.sec_for_foff(m.start()) and pe.sec_for_foff(m.start()).name=='.text']
    if hits: print(f"  {base:#08x}: {[hex(h) for h in hits]}")
