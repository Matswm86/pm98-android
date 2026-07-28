class_name JugRender
extends RefCounted
## The ORIGINAL's JUG.PGF sprite-index model, ported instruction for instruction.
## Resolves AUDIT A7 ("`_facing()`'s uniform-45 compass and the `[3 phase x 8 dir]` bake are
## BOTH inventions") by replacing both with the engine's own arithmetic.
##
## Source: `MANAGER.EXE` player draw `FUN_005a5460` (the 2D billboard branch, i.e. everything
## after the `sim+0x5fac` 3D-model early-out) and the per-tick animation advance
## `FUN_005a50c0`. Tables come out of `.data` via `tools/re/export_jug_bank.py` and land in
## `app/art/match/jug_bank.json`; `tools/re/dump_jug_kind_tables.py` prints the same numbers
## straight from the binary. Full write-up: `docs/re/jug_render_spec.md`.
##
## What the engine actually does, per player, per tick:
##   kind  = player+0x40                       (74 kinds, NOT 16 — the app already keeps this
##                                              field; `Pm98Movement.set_position_code` is
##                                              `FUN_005a5430`, whose LUT IS the next-state
##                                              table `DAT_00665208`)
##   phase = player+0x2c, clamped to fpd[kind]-1
##   dir   = how many of the EIGHT NON-UNIFORM thresholds `DAT_006653e0` the camera-relative
##           facing exceeds, then `+2 & 7`; mirrored per `mode[kind]` (§3 of the spec)
##   frame = base[kind] + fpd[kind]*dir + phase
## and it draws TWO billboards from that (`uVar36`/`uVar37`) — the second uses the facing
## measured against the ball-yaw word `matchctx+0x181e` rather than the camera.

const BANK_PATH := "res://art/match/jug_bank.json"
const INDEX_PATH := "res://art/match/jug_index.bin"

## Composited sprites are cached by (frame, LUT). A running player cycles 14 phases per
## direction, so the working set is small and steady-state redraws are pure cache hits; the cap
## exists so a long match cannot grow it without bound.
const CACHE_CAP := 1536

## `FUN_005a5460`'s direction term is `facing - cameraYaw + 0x4000`. The camera yaw is 0x4000
## (a quarter turn), which is DERIVED, not assumed, from two things that agree:
##   1. The draw builds the billboard along the axis `(cos, sin)` of `sVar23 = cameraYaw -
##      0x4000` (`:337-369`). A billboard must face the camera, and a real WATCH capture shows
##      the camera looking along world +Y (the ad hoardings are the FAR touchline, the halfway
##      line recedes) — so the quad must lie along X, i.e. `sVar23 = 0`, i.e. yaw = 0x4000.
##   2. That makes the term collapse to plain `facing`, and then a player running AWAY from
##      the camera (facing +Y = 0x4000) lands on dir 4 while one running TOWARD it (0xc000)
##      lands on dir 0 — front-facing frame first, which is what the bank actually holds.
## ⛔ This contradicts `jug_render_spec.md` §5's "yaw is a constant 0 -> the view matrix is
## pure translation". The game's own rendered frame is the authority and it is not a
## translation-only view; see `Pm98Camera` for the same correction stated in full.
const CAMERA_YAW := 0x4000

static var _bank: Dictionary = {}
static var _index := PackedByteArray()
static var _index_tried := false
static var _cache: Dictionary = {}
static var _cache_order: Array = []


## Load (once) the tables baked out of MANAGER.EXE. Returns {} if the bake is missing, which
## every caller must treat as "cannot draw", never as a reason to substitute a guess.
static func bank() -> Dictionary:
	if not _bank.is_empty():
		return _bank
	if not ResourceLoader.exists(BANK_PATH) and not FileAccess.file_exists(BANK_PATH):
		return {}
	var f := FileAccess.open(BANK_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_bank = parsed
	return _bank


## The 8-bit PALETTE INDICES of every frame, packed contiguously at each frame's own visible
## width. This is what the original keeps in memory too — it never stores a coloured player.
static func index_bank() -> PackedByteArray:
	if _index_tried:
		return _index
	_index_tried = true
	var f := FileAccess.open(INDEX_PATH, FileAccess.READ)
	if f == null:
		push_warning("JugRender: %s missing; players cannot be drawn" % INDEX_PATH)
		return _index
	_index = f.get_buffer(f.get_length())
	var want := int(bank().get("index_bytes", 0))
	if want > 0 and _index.size() != want:
		push_warning("JugRender: %s is %d bytes, bank says %d" % [INDEX_PATH, _index.size(), want])
	return _index


## One frame's sprite, coloured through `lut` and `pal` — `FUN_005d34a0`'s per-pixel remap,
## then the palette. Cached on (frame, LUT), so a repeating run cycle costs nothing after the
## first pass. Returns null when the bank is missing; callers must not substitute a guess.
static func composite(frame: int, lut: PackedByteArray, pal: PackedColorArray) -> Texture2D:
	var frames: Array = bank().get("frames", [])
	if frame < 0 or frame >= frames.size() or lut.size() < 256 or pal.size() < 256:
		return null
	var key := "%d:%d" % [frame, hash(lut)]
	var hit: Variant = _cache.get(key)
	if hit != null:
		return hit as Texture2D
	var src := index_bank()
	if src.is_empty():
		return null
	var fr: Dictionary = frames[frame]
	var w := int(fr["w"])
	var h := int(fr["h"])
	var off := int(fr["off"])
	if w <= 0 or h <= 0 or off + w * h > src.size():
		return null
	var rgba := PackedByteArray()
	rgba.resize(w * h * 4)
	# Precompute the 256 mapped RGBA quads once; the inner loop is then a straight copy.
	var r8 := PackedByteArray(); r8.resize(256)
	var g8 := PackedByteArray(); g8.resize(256)
	var b8 := PackedByteArray(); b8.resize(256)
	for i in 256:
		var c: Color = pal[lut[i]]
		r8[i] = int(c.r8)
		g8[i] = int(c.g8)
		b8[i] = int(c.b8)
	var o := 0
	for i in w * h:
		var v := int(src[off + i])
		if v == 0:
			o += 4
			continue
		rgba[o] = r8[v]
		rgba[o + 1] = g8[v]
		rgba[o + 2] = b8[v]
		rgba[o + 3] = 255
		o += 4
	var tex := ImageTexture.create_from_image(Image.create_from_data(w, h, false,
		Image.FORMAT_RGBA8, rgba))
	if _cache_order.size() >= CACHE_CAP:
		var oldest: String = _cache_order.pop_front()
		_cache.erase(oldest)
	_cache[key] = tex
	_cache_order.append(key)
	return tex


## Drop every composited sprite — called when a match ends so one fixture's kits do not keep
## another's memory alive.
static func clear_cache() -> void:
	_cache.clear()
	_cache_order.clear()


static func kind_count() -> int:
	var b := bank()
	return (b.get("kinds", []) as Array).size()


static func kind_row(kind: int) -> Dictionary:
	var kinds: Array = bank().get("kinds", [])
	if kind < 0 or kind >= kinds.size():
		return {}
	return kinds[kind]


## `FUN_005a5460:207-237` — bucket a 16-bit facing on the EIGHT NON-UNIFORM thresholds
## `DAT_006653e0 = [3584,13312,19456,29184,36352,46080,52224,61952]`, then `dir + 2 & 7`.
## Non-uniform is the whole point: it is a camera-relative 3/4-perspective quantisation, so a
## uniform 45-degree `atan2` (what the app used to do) is a different function, not a rounding.
static func octant(facing: int) -> int:
	var thr: Array = bank().get("thresholds8", [])
	if thr.is_empty():
		return 0
	var rel := (facing - CAMERA_YAW + 0x4000) & 0xFFFF
	var n := 0
	for t in thr:
		if int(t) < rel:
			n += 1
	return (n & 7)


## `FUN_005a5460:239-282` — turn a raw octant into (bank direction, horizontal flip) using
## the kind's own `mode`, which is the literal count of directions STORED for that kind:
##   |mode| == 8  -> all 8 stored, no mirror
##   |mode| == 5  -> dirs 0..4 stored; 5,6,7 are 3,2,1 drawn flipped
##   |mode| == 1  -> one stored direction, facing ignored
##   mode  <  0   -> a mirror twin: it shares its positive twin's `base` and draws flipped,
##                   with `dir = (|mode| - dir) % |mode|`
## Returns {dir, flip}.
static func direction(kind: int, facing: int) -> Dictionary:
	var row := kind_row(kind)
	if row.is_empty():
		return {"dir": 0, "flip": false}
	var mode := int(row["mode"])
	var m: int = absi(mode)
	var d := (octant(facing) + 2) & 7
	var flip := false
	if mode < 0:
		flip = true
		if m > 0:
			d = (m - d) % m
	# `bVar7` (:189) gates the mirror OFF for the 8/12-direction kinds — they store every
	# direction, so nothing is flipped for them.
	var mirror_runs := not (m == 8 or m == 12)
	if mirror_runs:
		if m == 1:
			d = 0
		elif d > 4:
			d = 8 - d
			flip = not flip
	return {"dir": d, "flip": flip}


## `FUN_005a5460:333-343` — the frame index itself.
## `frame = base[kind] + fpd[kind]*dir + min(phase, fpd[kind]-1)`.
static func frame_index(kind: int, dir: int, phase: int) -> int:
	var row := kind_row(kind)
	if row.is_empty():
		return 0
	var fpd := int(row["fpd"])
	if fpd <= 0:
		return int(row["base"])
	return int(row["base"]) + fpd * dir + clampi(phase, 0, fpd - 1)


## `FUN_005a5460:263-270` — a mirrored 14-phase self-looping kind is drawn HALF A CYCLE ON,
## so a flipped run cycle does not put both legs in the same place as its unflipped twin.
static func mirror_phase(kind: int, phase: int) -> int:
	var row := kind_row(kind)
	if row.is_empty():
		return phase
	if int(row["next"]) == kind and int(row["fpd"]) == 0xE:
		return (phase + 7) % 0xE
	return phase


## `FUN_005a50c0` — the per-tick animation advance: step the phase, and when it wraps hand the
## player to `next[kind]`. `reverse` is the binary's `player+0x68 < 0` branch, which plays
## kinds 0..3 backwards. Returns the new {kind, phase}.
static func advance(kind: int, phase: int, reverse := false) -> Dictionary:
	var row := kind_row(kind)
	if row.is_empty():
		return {"kind": kind, "phase": phase}
	var fpd := int(row["fpd"])
	if fpd <= 0:
		return {"kind": int(row["next"]), "phase": 0}
	if reverse and kind <= 3:
		var p := phase - 1
		if p < 0:
			return {"kind": int(row["next"]), "phase": fpd - 1}
		return {"kind": kind, "phase": p}
	var np := phase + 1
	if np >= fpd:
		return {"kind": int(row["next"]), "phase": 0}
	return {"kind": kind, "phase": np}


## Resolve everything a view needs for one player in one call.
## Returns {frame, flip, rect:Rect2, ax, ay} — `rect` is the atlas source rect and `ax`/`ay`
## the frame's OWN anchor from the `.PGF` header, which is what the billboard is built around.
static func resolve(kind: int, facing: int, phase: int) -> Dictionary:
	var b := bank()
	if b.is_empty():
		return {}
	var dd := direction(kind, facing)
	var ph: int = phase
	if bool(dd["flip"]):
		ph = mirror_phase(kind, ph)
	var idx := frame_index(kind, int(dd["dir"]), ph)
	var frames: Array = b.get("frames", [])
	if idx < 0 or idx >= frames.size():
		return {}
	var fr: Dictionary = frames[idx]
	return {
		"frame": idx,
		"flip": bool(dd["flip"]),
		"rect": Rect2(0, 0, int(fr["w"]), int(fr["h"])),
		"ax": int(fr["ax"]),
		"ay": int(fr["ay"]),
		# `.PGF` header `h5` -> frame slot `+0x10`: the JUGCAM.IND shirt-map this frame wears.
		"map": int(fr["map"]),
	}


## World height of one sprite pixel, in metres, straight off the draw: the billboard's z span
## is `(ay - H .. ay) * 0x1b333 / 0x30` in 16.16. A 45-px frame with ay=46 comes out 1.63 m
## tall, which is what pins this as the real scale rather than an art-directed guess.
static func metres_per_pixel_z() -> float:
	var b := bank()
	if b.is_empty():
		return 0.0
	return float(int(b["z_num"])) / float(int(b["z_den"])) / 65536.0


## Same, horizontally: the x half-widths are `-ax` / `(W - ax)` scaled by `0x10000` and then
## divided by `0x1a` on the way into world coords, so one pixel is `1/0x1a` of a world unit.
static func metres_per_pixel_x() -> float:
	var b := bank()
	if b.is_empty():
		return 0.0
	return 1.0 / float(int(b["x_den"]))


## Animation ticks per second on the TIMELINE path. A live match does not use this — it takes
## `phase` straight off the engine, which advances it once per outer frame. The engine runs
## ~63.6 outer frames a second on this desktop (measured, `test_live_match.gd`), and the gait
## kinds are 14-phase, so 12 Hz is the app's own readable stand-in and is declared as such.
const ANIM_HZ := 12.0
