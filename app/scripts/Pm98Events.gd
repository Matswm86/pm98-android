class_name Pm98Events
extends RefCounted
## EXACT port of MANAGER.EXE's match-event-queue layer (docs/re/EXACT_PORT_PLAN.md,
## Stage 3 task 2 -- the event enqueue the keeper-save predicate deferred). Two fns:
##   * enqueue      = FUN_00594470 (__thiscall, this=match) -- append a 16-byte event
##                    [code, player+0x2b8, player+0x2c0, 0x168] to the match event
##                    array (match+0x1a24), bump the count (match+0x1a28), and keep
##                    the 0x1a30 timer / 0x1a2c "max-flag" bookkeeping. No-op when
##                    DAT_006d31c4!=0 (replay, never in-sim) or match+0x1a38!=0
##                    (queue frozen). The Win32 GlobalReAlloc growth (FUN_005bbf10)
##                    is implicit in Array.append.
##   * keeper_event = FUN_005909f0 (__thiscall, this=ball) -- on a keeper save, bump
##                    the keeper save stat (*(keeper+0x3b8)+0x80, or +0x7c when
##                    save_flag!=0) and, when the match+0x462 height-band bits warrant
##                    (&0x40 -> 0x16, else &0xa0 -> 0x15), enqueue a commentary event
##                    for the keeper. This is the call FUN_0058f140 (keeper_save)
##                    makes at 58f30b with save_flag=0, just before it zeroes
##                    ball+0x50 at 58f314; Pm98Predicates.keeper_save returns the
##                    `save` boolean that gates it (the deferred wire, now closeable).
##
## Structs are offset->Variant Dictionaries mutated in place, like Pm98Predicates.
## The event array (match+0x1a24) is an Array of 4-int records [code, x, y, delay];
## match+0x1a28 holds its length. Nested struct pointers (ball+0x50 -> keeper,
## ball+0x1d4 -> match, keeper+0x3b8 -> stat, match+0x468 -> team) are modelled as
## nested Dictionaries; a missing / non-Dictionary slot == a null pointer.
##
## Oracle-validated bit-for-bit: tools/re/run_event_oracle.sh -> specs/event_oracle.txt,
## locked by test_events.gd. enqueue + keeper_event are driven through the REAL
## binary under the PCode emulator (FUN_005bbf10 realloc stubbed, queue buffer
## pre-allocated); test_events.gd reproduces every banked field.

const EVENT_DELAY := 0x168    # piVar1[3] -- the fixed delay/ttl stamped on every event
const SAVE_TIMER := 0x12c     # match+0x1a30 := 300 when an event arrives with flag==1


static func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))


## A nested struct pointer: the Dictionary at `d[off]`, or {} when the slot is unset
## or not a Dictionary (== a null pointer in the binary).
static func _ref(d: Dictionary, off: int) -> Dictionary:
	var v: Variant = d.get(off, null)
	return v if v is Dictionary else {}


## FUN_005943d0 || FUN_005943b0: true when the match phase (match+0x468 -> +0xfa0)
## is 4 (FUN_005943d0) or 0 (FUN_005943b0). Gates the match+0x1a2c "max-flag" update.
static func _phase_0_or_4(m: Dictionary) -> bool:
	var phase := _g(_ref(m, 0x468), 0xfa0)
	return phase == 4 or phase == 0


## FUN_00594470 (__thiscall, this=match). Append event `code` for `player` (an
## offset->int Dictionary; pass {} for param_3==0 = "no player") with priority `flag`
## (param_4). Record = [code, player+0x2b8, player+0x2c0, 0x168]; no player -> 0,0.
## DAT_006d31c4 is always 0 in-sim (not modelled); match+0x1a38!=0 freezes the queue.
static func enqueue(m: Dictionary, code: int, player: Dictionary, flag: int) -> void:
	if _g(m, 0x1a38) != 0:
		return
	var px := 0
	var py := 0
	if not player.is_empty():
		px = _g(player, 0x2b8)
		py = _g(player, 0x2c0)
	var queue: Array = m.get(0x1a24, [])
	queue.append([code, px, py, EVENT_DELAY])
	m[0x1a24] = queue
	m[0x1a28] = queue.size()                 # iVar5 = count+1, then stored at +0x1a28
	if flag == 1:
		m[0x1a30] = SAVE_TIMER
	# match+0x1a2c := max(0x1a2c, flag), unless phase in {0,4} AND code==1 AND flag==1.
	if (not _phase_0_or_4(m)) or (code != 1 and flag != 1):
		var cur := _g(m, 0x1a2c)
		m[0x1a2c] = flag if cur <= flag else cur


## FUN_005909f0 (__thiscall, this=ball). On a keeper save: bump the keeper save stat
## (save_flag==0 -> *(keeper+0x3b8)+0x80, the save counter; else +0x7c), then enqueue
## a 0x15/0x16 commentary event for the keeper when the match+0x462 band bits warrant.
## No-op when ball+0x4c!=0 or ball+0x50 (the keeper) is null. ball+0x1d4 -> match.
static func keeper_event(b: Dictionary, save_flag: int) -> void:
	if _g(b, 0x4c) != 0:
		return
	var keeper := _ref(b, 0x50)
	if keeper.is_empty():
		return
	var stat := _ref(keeper, 0x3b8)
	if save_flag == 0:
		stat[0x80] = _g(stat, 0x80) + 1
	else:
		stat[0x7c] = _g(stat, 0x7c) + 1
	var m := _ref(b, 0x1d4)
	var bits := _g(m, 0x462) & 0xff
	var bit40 := bits & 0x40
	if bit40 != 0 or (bits & 0xa0) != 0:
		enqueue(m, 0x15 + (1 if bit40 != 0 else 0), keeper, 0)
