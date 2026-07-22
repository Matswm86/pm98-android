#!/usr/bin/env python3
"""Extract the byte-exact fee/wage lookup tables from MANAGER.EXE.

Source: FUN_00576cd0 (the market fee/wage generator, RE'd 2026-07-22).
  fee  = feeTable [stature*54 + abilTier(AV)*6 + ageTier(age)] * 5000
  wage = wageTable[stature*54 + abilTier(AV)*6 + ageTier(age)] * 5000
Tables: fee @VA 0x638788, wage @VA 0x638208; 9 stature bands x 9 ability tiers x
6 age tiers = 486 uint16 each. Emits docs/re/value_tables.json (data-only; the
values are the game's own bytes, never hand-authored -> ship-real-content rule).
"""
import json, struct, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from pe import PE

BANDS, ABIL, AGE = 13, 9, 6
N = BANDS * ABIL * AGE  # 486

def main():
    pe = PE()
    def words(va):
        o = pe.va_to_foff(va)
        return list(struct.unpack("<%dH" % N, pe.data[o:o + N * 2]))
    fee = words(0x638788)
    wage = words(0x638208)
    out = {
        "_source": "MANAGER.EXE FUN_00576cd0; fee@0x638788 wage@0x638208; x5000",
        "multiplier": 5000,
        "dims": {"stature": BANDS, "ability_tier": ABIL, "age_tier": AGE},
        "ability_tier_from_AV": "AV>=95:0 >=90:1 >=85:2 >=80:3 >=75:4 >=70:5 >=65:6 >=60:7 else:8",
        "age_tier_from_age": "age<20:0 <23:1 <26:2 <30:3 <33:4 else:5",
        "AV": "(VE+RE+AG+CA)>>2",
        "index": "stature*54 + ability_tier*6 + age_tier",
        "fee_table": fee,
        "wage_table": wage,
    }
    dst = Path(__file__).resolve().parents[2] / "docs" / "re" / "value_tables.json"
    dst.write_text(json.dumps(out, indent=1))
    print(f"wrote {dst} ({N} fee + {N} wage uint16, x{out['multiplier']})")
    # sanity print: band0 (elite) vs band8 (lowest), best-ability row
    for b in (0, 3, 8):
        base = b * ABIL * AGE
        print(f"  stature{b} bestAbil fee={fee[base:base+6]} wage={wage[base:base+6]}")

if __name__ == "__main__":
    main()
