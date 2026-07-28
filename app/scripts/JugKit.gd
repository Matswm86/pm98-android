class_name JugKit
extends RefCounted
## The ORIGINAL's per-club KIT RECOLOUR, ported instruction for instruction.
##
## PM98 never bakes a coloured player sprite. `JUG.PGF` stays 8-bit PALETTE INDICES and the
## engine remaps every pixel through a 256-byte LUT immediately before the blit
## (`FUN_005d34a0`, a plain per-pixel `xlat` into the scratch page `matchctx+0x1a4c`). This
## class builds that LUT. Full write-up + VAs: `docs/re/kit_palette_re.md`.
##
## Three functions own the chain:
##
## * **`FUN_005b63e0`** — per team, at match load. Reads `DatSim\paletas\P96A<key>.DAT`
##   (192 bytes; the name is `"000" + "%ld"` of the club's EQ96 key, last four characters),
##   falling back to `P96A0000.DAT`. If this is the AWAY side and its class byte equals the
##   home side's, it reads `P96B<key>.DAT` instead — the CHANGE STRIP.
##       [0..127]   the 16x8 SHIRT PATTERN grid, each cell a palette RAMP BASE index
##       [128..175] 48 LUT entries, copied over palette slots 9..56
##       [176]      the kit CLASS colour, which is also the number patch's background
##   The number INK is `0x67` when that class colour's GREEN component in the match palette
##   exceeds 100, else `0x7f`.
## * **`FUN_005a2830`** — per player. Points him at `paltab + ti*0x200`, or `+0x100` for the
##   keeper (slot 0), whose LUT is a `palpor%d` strip instead. Copies the team's pattern to
##   `player+0x2e0`, stamps his SHIRT NUMBER into its right half out of `NumCam.bmp`'s 8x8
##   glyph bank, and resolves his SKIN ramp (`DAT_006653a8`, three 8-entry ramps picked by
##   `.DBC +0x16`) and HAIR ramp (`DAT_00665380`, 4 entries picked by `.DBC +0x17`).
## * **`FUN_005a5460`** — per draw. Writes skin into LUT[1..8] and hair into LUT[0x15..0x18],
##   then walks the pattern: for every (col, row, shade) it reads
##   `JUGCAM.IND[(row + (frame.map*16 + col)*8)*6 + shade]` and, when non-zero, writes
##   `ramp(pattern[row*16 + col], shade)` into that LUT slot.
##
## `JUGCAM.IND` is the shirt-texture -> sprite-palette-index map, not a camera table: 72 maps
## x 16 cols x 8 rows x 6 shades = 55,296 bytes, which is the file's exact size. The `.PGF`
## header word the spec used to list as an open GAP (`h5`) is the map index and spans 0..71.

const BANK_PATH := "res://art/match/jug_bank.json"
const KITPAL_PATH := "res://art/match/kitpal.bin"
const JUGCAM_PATH := "res://art/match/jugcam.bin"
const SIMULPAL_PATH := "res://art/match/simulpal.bin"
const NUMCAM_PATH := "res://art/match/numcam.bin"

const RAMP_BYTES := 192
const PATTERN_BYTES := 128
const CLASS_BYTE := 176
const LUT_FIRST := 9
const LUT_COUNT := 48
const GRID_W := 16
const GRID_H := 8
const SHADES := 6
const N_MAPS := 72
const GLYPH_BYTES := 64

static var _kitpal := PackedByteArray()
static var _jugcam := PackedByteArray()
static var _simulpal := PackedByteArray()
static var _numcam := PackedByteArray()
static var _loaded := false


static func _blob(path: String) -> PackedByteArray:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("JugKit: %s missing; the match view cannot colour kits" % path)
		return PackedByteArray()
	return f.get_buffer(f.get_length())


static func load_tables() -> bool:
	if _loaded:
		return not _kitpal.is_empty()
	_loaded = true
	_kitpal = _blob(KITPAL_PATH)
	_jugcam = _blob(JUGCAM_PATH)
	_simulpal = _blob(SIMULPAL_PATH)
	_numcam = _blob(NUMCAM_PATH)
	if _jugcam.size() != N_MAPS * GRID_W * GRID_H * SHADES:
		push_warning("JugKit: jugcam.bin is %d bytes, not the 72x16x8x6 layout" % _jugcam.size())
		return false
	return not _kitpal.is_empty()


## One of the five `SIMUL<n>.PAL` pitch palettes as 256 Colors. The original picks `n` with an
## RNG draw at match load (`matchctx+0x1980`); `SIMUL0` is byte-identical to `PALETA.ACT`.
static func palette(variant := 0) -> PackedColorArray:
	load_tables()
	var out := PackedColorArray()
	if _simulpal.size() < 5 * 768:
		return out
	var base: int = clampi(variant, 0, 4) * 768
	out.resize(256)
	for i in 256:
		out[i] = Color8(_simulpal[base + i * 3], _simulpal[base + i * 3 + 1],
			_simulpal[base + i * 3 + 2])
	return out


static func _ramp_slot(club_id: int) -> int:
	var kit: Dictionary = JugRender.bank().get("kit", {})
	var m: Dictionary = kit.get("club_ramp", {})
	return int(m.get(str(club_id), -1))


## The 192-byte club ramp, or the 256-byte `P96A0000.DAT` fallback's first 192 bytes when the
## club has no file — `FUN_005ec1d0`'s own miss branch.
static func _ramp(club_id: int, change: bool) -> PackedByteArray:
	load_tables()
	var kit: Dictionary = JugRender.bank().get("kit", {})
	var slot := _ramp_slot(club_id)
	var clubs := int(kit.get("clubs", 0))
	if slot < 0 or _kitpal.is_empty():
		var base := int(kit.get("base_lut_off", 0))
		return _kitpal.slice(base, base + RAMP_BYTES)
	var off := ((clubs + slot) if change else slot) * RAMP_BYTES
	return _kitpal.slice(off, off + RAMP_BYTES)


## `FUN_005b63e0`'s class byte for a club, without building the rest — the away side needs it
## to decide whether it is wearing its change strip.
static func class_colour(club_id: int, change := false) -> int:
	var r := _ramp(club_id, change)
	return int(r[CLASS_BYTE]) if r.size() > CLASS_BYTE else 0


## `FUN_005b63e0` — everything a team's outfield players share.
## Returns {lut: 256 bytes, pattern: 128 bytes, cls: int, ink: int, change: bool}.
## `home_class` is the home side's class byte; pass -1 for the home side itself. The change
## strip is picked exactly as the binary does: `param_2 == 1 && matchctx+0x742 == team+0x2c6`,
## and `matchctx+0x742` IS team 0's own `+0x2d6` (`0x46c + 0x2d6 == 0x742`).
static func team_kit(club_id: int, home_class := -1, pal_variant := 0) -> Dictionary:
	load_tables()
	var kit: Dictionary = JugRender.bank().get("kit", {})
	var change := home_class >= 0 and class_colour(club_id, false) == home_class
	var ramp := _ramp(club_id, change)
	if ramp.size() < RAMP_BYTES:
		return {}
	# Both team blocks start life as P96A0000.DAT (MANAGER.EXE 0x592fa3-0x592fcf: the two
	# `rep movsd` runs into paltab+0x000 and paltab+0x200 both source the p96a0000 buffer).
	var base_off := int(kit.get("base_lut_off", 0))
	var lut := _kitpal.slice(base_off, base_off + 256)
	for i in LUT_COUNT:
		lut[LUT_FIRST + i] = ramp[PATTERN_BYTES + i]
	var cls := int(ramp[CLASS_BYTE])
	# `bVar1 = matchctx[0x1e69 + cls*4]` is the GREEN byte of the match palette's RGBQUAD for
	# that entry (the palette is `rep movsd`'d from the RIFF PAL's 0x18 in FUN_005923f0).
	var green := 0
	if _simulpal.size() >= 5 * 768:
		green = int(_simulpal[clampi(pal_variant, 0, 4) * 768 + cls * 3 + 1])
	var ink := 0x67 if green > 100 else 0x7F
	return {
		"lut": lut,
		"pattern": ramp.slice(0, PATTERN_BYTES),
		"cls": cls,
		"ink": ink,
		"change": change,
	}


## `FUN_005b63e0`'s keeper branch: the strip is `palpor<n>.DAT`, n drawn 0..7 and RE-ROLLED
## while its class (`DAT_006657b0[n]`) collides with its own outfield kit, or — for the away
## side — with either of the home side's two classes.
##
## ⛔ DECLARED DIVERGENCE: the draw comes from the DISPLAY LCG (`FUN_005ec250`, seeded by the
## whole title->match load sequence), a stream this port does not reproduce. The re-roll RULE
## is the binary's; the number fed into it is derived from the fixture instead, so a given
## fixture always dresses its keepers the same way.
static func keeper_kit(pick: int, own_class: int, home_classes: Array = []) -> Dictionary:
	load_tables()
	var kit: Dictionary = JugRender.bank().get("kit", {})
	var classes: Array = kit.get("keeper_class", [])
	var n := int(kit.get("palpor_count", 8))
	if classes.size() < n or _kitpal.is_empty():
		return {}
	var p: int = posmod(pick, n)
	for _try in n:
		var c := int(classes[p])
		var clash: bool = c == own_class or home_classes.has(c)
		if not clash:
			break
		p = (p + 1) % n
	var off := int(kit.get("palpor_off", 0)) + p * 256
	return {"lut": _kitpal.slice(off, off + 256), "cls": int(classes[p]), "pick": p}


## `FUN_005a2830`'s number stamp: the background patch in the kit's CLASS colour, then the
## digits in the contrast INK, both written into the player's own copy of the 16x8 pattern.
## `NumCam.bmp` is 8x480 8-bit — sixty 8x8 glyphs, `pixels + (number-1)*0x40`.
static func stamp_number(pattern: PackedByteArray, number: int, cls: int, ink: int) -> PackedByteArray:
	load_tables()
	var out := pattern.duplicate()
	var n: int = clampi(number, 1, maxi(1, _numcam.size() / GLYPH_BYTES))
	var g := (n - 1) * GLYPH_BYTES
	if _numcam.size() < g + GLYPH_BYTES:
		return out
	# Pass 1 (L165-186): the inner 6x6 of the glyph, stamped at pattern offset 0x1a with the
	# three companion offsets -2 / -0x11 / +0xf — the patch that clears the stripes behind the
	# number. Written in the kit's own class colour.
	for col in 6:
		for row in 6:
			if _numcam[g + 9 + col + row * 8] == 0:
				continue
			var at := 0x1A + col + row * GRID_W
			for d: int in [-2, 0, -0x11, 0xF]:
				var i: int = at + d
				if i >= 0 and i < PATTERN_BYTES:
					out[i] = cls
	# Pass 2 (L200-215): the full 8x8 glyph in the contrast ink, at pattern offset 8 — the
	# right half of the grid, i.e. the back of the shirt.
	for col in 8:
		for row in 8:
			if _numcam[g + col + row * 8] == 0:
				continue
			var i := 8 + col + row * GRID_W
			if i >= 0 and i < PATTERN_BYTES:
				out[i] = ink
	return out


## `FUN_005a2830`'s skin/hair resolve. `b16`/`b17` are the .DBC bytes the career carries
## verbatim; the engine reads value-1. Hair index 1 is BALD and redirects to `skin + 6`, which
## is why the hair table has three extra rows that repeat the three skin ramps.
static func skin_hair(b16: int, b17: int) -> Dictionary:
	var b := JugRender.bank()
	var skin_tbl: Array = b.get("skin_ramp", [])
	var hair_tbl: Array = b.get("hair_ramp", [])
	if skin_tbl.size() < 24 or hair_tbl.size() < 40:
		return {"skin": PackedByteArray(), "hair": PackedByteArray()}
	var dc: int = clampi(b16 - 1, 0, 2)
	var skin := PackedByteArray()
	skin.resize(8)
	for i in 8:
		skin[i] = int(skin_tbl[dc * 8 + i])
	var db := b17 - 1
	if db == 1:
		# `actor+0x367 = actor+0x366 = actor+0x365`, then `db = dc + 6`.
		skin[7] = skin[5]
		skin[6] = skin[5]
		db = dc + 6
	db = clampi(db, 0, hair_tbl.size() / 4 - 1)
	var hair := PackedByteArray()
	hair.resize(4)
	for i in 4:
		hair[i] = int(hair_tbl[db * 4 + i])
	return {"skin": skin, "hair": hair}


## `FUN_005a5460:519-556` — the per-draw LUT. Takes the team LUT, overwrites skin and hair,
## then paints the shirt pattern through `JUGCAM.IND` for THIS frame's map.
## `mirrored` is the draw's own negative horizontal scale: the JUGCAM column mirrors within
## each half (`((col & 8) - (col & 7)) + 7`) while the pattern cell does not.
static func draw_lut(team_lut: PackedByteArray, pattern: PackedByteArray, skin: PackedByteArray,
		hair: PackedByteArray, map_id: int, mirrored: bool, with_pattern := true) -> PackedByteArray:
	load_tables()
	var lut := team_lut.duplicate()
	if lut.size() < 256:
		return lut
	if skin.size() == 8:
		for i in 8:
			lut[1 + i] = skin[i]
	if hair.size() == 4:
		for i in 4:
			lut[0x15 + i] = hair[i]
	if not with_pattern or pattern.size() < PATTERN_BYTES or _jugcam.is_empty():
		return lut
	var b := JugRender.bank()
	var white: Array = b.get("ramp_white", [])
	var grey: Array = b.get("ramp_grey", [])
	var m: int = clampi(map_id, 0, N_MAPS - 1)
	for col in GRID_W:
		var cm := ((col & 8) - (col & 7)) + 7 if mirrored else col
		var jc_col := (m * GRID_W + cm) * GRID_H
		for row in GRID_H:
			var cell := int(pattern[row * GRID_W + col])
			var jc := (row + jc_col) * SHADES
			for sh in SHADES:
				var idx := int(_jugcam[jc + sh])
				if idx == 0:
					continue
				if cell == 0x7F:
					lut[idx] = int(white[sh]) if white.size() == SHADES else 0x7F
				elif cell == 0x67:
					lut[idx] = int(grey[sh]) if grey.size() == SHADES else 0x67
				else:
					lut[idx] = (cell - sh + 5) & 0xFF
	return lut
