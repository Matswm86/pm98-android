# Oracle self-test: emulate the RNG FUN_005ec250 with state seeded to srand(1).
# Ground truth (canonical MSVC rand after srand(1)): 41 18467 6334 26500 19169.
# If the emulator reproduces these, the harness is proven AND the RNG bytes are confirmed.
entry   0x5ec250
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
mem     0x006d3184 4 0x00000001
calls   5
read_reg EAX
read_mem 0x006d3184 4
maxsteps 100000
