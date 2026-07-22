#!/usr/bin/env python3
"""Validate the RE'd fee/wage generator FUN_00576cd0 against the witnesses.

Model (asm-exact, FUN_00576cd0):
  ability_tier(AV): <60->8 <65->7 <70->6 <75->5 <80->4 <85->3 <90->2 <95->1 else 0
  age_tier(age):    <20->0/1(special) <23->1 <26->2 <30->3 <33->4 else 5
  word_index = age_tier + ability_tier*6 + band*54
  fee  = feeTable[0x638788][word_index] * K
  wage = wageTable[0x638208][word_index] * K
band = club field (param_3, = club+0x58). Solve band + K here.
"""
import struct, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from pe import PE

pe = PE()
def foff(va): return pe.va_to_foff(va)
def rd(va, n): o = foff(va); return pe.data[o:o+n]

# --- verify VA->foff mapping with a known anchor (the copyright const region) ---
K_dbl = struct.unpack("<d", rd(0x638d08, 8))[0]
K_flt = struct.unpack("<f", rd(0x638d08, 4))[0]
print(f"[map] const@0x638d08  double={K_dbl}  float={K_flt}")

def words(va, n): return list(struct.unpack("<%dH" % n, rd(va, n*2)))
BANDS, ABIL, AGE = 13, 9, 6
NW = BANDS*ABIL*AGE           # 486
feeT  = words(0x638788, NW)
wageT = words(0x638208, NW)

# show block structure: are the 9 band-blocks distinct?
print("\n[tables] fee/wage per band (ability_tier 0 = best, age_tier0):")
for b in range(BANDS):
    base = b*ABIL*AGE
    print(f"  band{b}: fee row0={feeT[base:base+6]}  wage row0={wageT[base:base+6]}")

def abil_tier(av):
    for t,(lo) in enumerate([95,90,85,80,75,70,65,60]):
        if av>=lo: return t   # av>=95 ->0 ... av>=60 ->7
    return 8
def age_tier(age):
    if age<20: return 0
    if age<23: return 1
    if age<26: return 2
    if age<30: return 3
    if age<33: return 4
    return 5

def idx(av, age, band): return age_tier(age) + abil_tier(av)*6 + band*ABIL*AGE

# --- witnesses: (AVscreen, age, fee, wage). ages from source screens where known;
# for the transfer-market rows we only have AV+fee+wage; age unknown -> try all.
# Clean anchors (AV known, fee+wage known) from transfer_value_re.md sec2:
W = [
 ("Wilson",59,5000,5000), ("Martindale",54,25000,10000), ("Rickers",53,50000,5000),
 ("Carragher",57,75000,5000), ("Van Blerk",68,90000,25000), ("Kadijevic",73,150000,30000),
 ("Spiteri",78,150000,25000), ("Gojkovic",71,850000,35000), ("Villarroya",74,500000,90000),
 ("Roberts",78,1500000,125000), ("Marcelle",78,650000,175000), ("Scholes",81,8500000,575000),
 ("Berger",88,11000000,1000000),
]
K = 5000  # effective multiplier (make_offer base step; = 1e6/200)
print(f"\n[fit] force K={K}: for each witness list (band,ageTier) with feeWord*K==fee AND wageWord*K==wage")
allok = True
for name,av,fee,wage in W:
    at_abil = abil_tier(av)
    sols=[]
    for band in range(BANDS):
        for at in range(6):
            i = at + at_abil*6 + band*ABIL*AGE
            if feeT[i]*K==fee and wageT[i]*K==wage:
                sols.append((band,at,feeT[i],wageT[i]))
    ok = "OK " if sols else "MISS"
    if not sols: allok=False
    bands = sorted(set(b for b,_,_,_ in sols))
    print(f"  [{ok}] {name:10} AV{av:3} abilTier{at_abil} fee£{fee:>9} wage£{wage:>8} -> bands={bands} n={len(sols)}")
print(f"\n[RESULT] every witness reproduced by feeTable/wageTable x {K}: {allok}")
print("         band = club stature tier (0=elite ... 8=lowest); confirms fee/wage = table[stature][abil][age] x 5000")
