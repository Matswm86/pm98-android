extends RefCounted
class_name PMShadow
## MANAGER.EXE's SHADOWED BITMAP BLIT, ported leaf for leaf.
##
## Reached everywhere through `FUN_004b7f60`, a thunk into
## `FUN_005cbea0(0x10, 0x21, cap, l, t, r, b, bmp, 0, 0, 0, 0x100)`. With
## `param_1 = 0x10` and `param_2 = 0x21` that call takes exactly one path:
##
##     FUN_005d66f0(scratch, bmp, 0x100)                 # silhouette
##     FUN_005d6590(scratch, scratch, 0x21, cap, 0x100)  # spread, IN PLACE
##     FUN_005d5220(dest, &rect, scratch, (0,0), bmp, (0,0))   # composite
##
## * **`FUN_005d66f0`** writes 0xff for every NON-ZERO byte of the source and 0 for
##   every zero one, over the WHOLE padded buffer (`height * stride` bytes). With
##   alpha 0x100 the scaling tail is skipped, so the scratch is a flat 0/255 mask.
## * **`FUN_005d6590`** then walks that scratch LINEARLY -- from `stride + 1` for
##   `(height - 1) * stride - 1` bytes, so it crosses row ends into the row padding --
##   and, at every byte still below 0xf0 (i.e. outside the silhouette), replaces it
##   with `((up + 2*upleft + left) >> 2) - 0x21`, clamped at `cap` and only where that
##   beats what is already there. Reading its own OUTPUT for the three neighbours is
##   what makes it an IIR spread: the shadow decays down-and-right from the sprite.
## * **`FUN_005d5220`** composites: mask 0 leaves the destination, mask 0xff copies
##   the source byte, anything between blends `dst + ((src - dst) * (mask + 1)) >> 8`
##   per channel in 16-bit wrap arithmetic and re-quantises through the two-table
##   RGB565 lookup at `DAT_00675398`, picked by an ordered-dither bit on ABSOLUTE
##   screen parity. `tools/re/build_shadow_lut.py` bakes both tables.
##
## Because the mask is only ever partial OUTSIDE the silhouette, and outside the
## silhouette the source index is 0 (= palette black), every shadow pixel is the
## destination blended toward BLACK. So a caller can draw its background, lay this
## overlay on top, then blit the sprite normally, and get the original's pixels.
##
## Full record + the evidence for the reconstructed tables: `docs/re/shadow_blit_re.md`.

## ⚠ NOT universal, and now MEASURED at every site — s87 corrected the note, s88 closed it.
## `tools/re/probe_shadow_sites.py` byte-scans `.text` for `E8 rel32` targeting the thunk
## `0x4b7f60` or the core `0x5cbea0` (74 sites), then decodes each caller forwards with
## capstone and reads the three leading pushes. **65 of the 74 push all three as immediates,
## and they form SEVENTEEN distinct (flags, thr, cap) triples**, not one:
##
##     (0x10, 0x40, 0xff) x23   (0x10, 0x00, 0x00) x11   (0x20, 0x21, 0x5a) x9
##     (0x20, 0x21, 0x63) x4    (0x10, 0x30, 0xff) x4    (0x10, 0x32, 0x64) x4
##     (0x10, 0x20, 0xff) x2    (0x10, 0x50, 0xff) x2    (0x20, 0x40, 0x80) x1
##     (0x20, 0x30, 0xff) x1    (0x10, 0x21, 0x63) x1    (0x10, 0x21, 0x84) x1
##     (0x10, 0x40, 0x80) x1    (0x20, 0x00, 0x00) x1    + 9 sites pushing non-immediates
##
## So `THR` below is the value of the TWO sites this leaf was reversed from and of no other:
## `0x50f9e3` (markers, cap 0x63) and `0x50fba1` (the 48x64 kit, cap 0x84). Any caller that
## is not one of those two must pass its OWN site's thr and cap.
##
## ⚠ AND SIXTEEN SITES ARE A DIFFERENT PASS ENTIRELY. `flags = 0x20` takes the other arm of
## `FUN_005cbea0` — `FUN_005d66f0(src, 0x100)` then **`FUN_005d60a0`**, an EDGE pass that
## rewrites each mask byte as `table[code] * 2 + 1` — where `flags = 0x10` takes the
## `FUN_005d6590` SPREAD this leaf models. Nothing here implements the 0x20 arm yet, and it
## is the standing candidate for the un-reversed 1-px on-sprite kit edge: `0x5c0688`, the
## RIDIESC picture widget's own blit, is a 0x20 site (its flags word is `FUN_005c0d50`'s
## `param_4 = 0x20`, stored at record `+0x90` and reloaded at `0x5c0607`).
##
## s89 corrects two numbers and removes the blocker. The code is **13 bits and the table is
## 8,192 entries**, not 12 and 4,096: the leaf makes twelve comparisons and then `stc; rcl`,
## so bit 0 is hardwired to 1. `DAT_006b5890` is `.bss`, built by the graphics-init at
## 0x5c9762 from `letras.bmp` — which ships in NEITHER source — so it was read out of the
## RUNNING original instead (`tools/re/refs/aliasing-2026-08-02/`, dumped by
## `m5_rsp_capture.py`). It is provably the generator's own output: rotation-invariant at
## 0 violations in 8,192, and monotone in popcount up to **253 for a fully-enclosed pixel**
## — a 2/256 nudge toward the destination on every interior pixel, which is where s84
## measured 415 of 449 residual px to be. Determinism across boots is CONFIRMED on THREE
## independent boots (one a fully isolated instance): all dump the same 8,192 bytes, same sha256. What still gates shipping
## the pass is the render-diff, not the table. See docs/re/shadow_blit_re.md, "The 0x20 arm,
## RUN".
const THR := 0x21          ## FUN_005cbea0 param_2 at 0x50f9e3 / 0x50fba1 ONLY
const CAP_MARKER := 0x63   ## FUN_0050f970 -- the MAN-TO-MAN marking-line markers
const CAP_KIT := 0x84      ## FUN_0050fae0 -- the 48x64 opponent kit
## The measured flag words. 0x10 = the spread this leaf models; 0x20 = the edge pass it does
## not. Callers should say which one their site is rather than assume.
const FLAGS_SPREAD := 0x10
const FLAGS_EDGE := 0x20

const LUT_PATH := "res://data/shadow_lut.bin"

static var _pal: PackedByteArray = PackedByteArray()
static var _t0: PackedByteArray = PackedByteArray()
static var _t1: PackedByteArray = PackedByteArray()
static var _cache: Dictionary = {}


static func _load() -> bool:
	if not _t0.is_empty():
		return true
	var f := FileAccess.open(LUT_PATH, FileAccess.READ)
	if f == null:
		push_warning("PMShadow: %s missing; shadowed blits fall back to none" % LUT_PATH)
		return false
	var raw := f.get_buffer(768 + 2 * 65536)
	f.close()
	if raw.size() < 768 + 2 * 65536:
		push_warning("PMShadow: %s is short (%d bytes)" % [LUT_PATH, raw.size()])
		return false
	_pal = raw.slice(0, 768)
	_t0 = raw.slice(768, 768 + 65536)
	_t1 = raw.slice(768 + 65536, 768 + 2 * 65536)
	return true


## `FUN_005d66f0` + `FUN_005d6590`: the spread mask of a sprite, as `height` rows of
## `stride` bytes. `alpha` is one byte per sprite pixel, non-zero where the sprite
## has a non-zero palette index (which is what the exported PNGs carry as alpha).
static func spread_mask(alpha: PackedByteArray, w: int, h: int, cap: int) -> PackedByteArray:
	var stride := ((w * 8 + 31) / 32) * 4
	var buf := PackedByteArray()
	buf.resize(stride * h)
	for y in h:
		var ro := y * stride
		var ao := y * w
		for x in w:
			buf[ro + x] = 255 if alpha[ao + x] != 0 else 0
	# The linear walk. Row padding is zero here: a loaded surface's pad bytes are
	# not part of the picture, and file-pad vs zero-pad were measured identical on
	# both marker sprites (docs/re/shadow_blit_re.md §"The padding question").
	var i := stride + 1
	var last := i + (h - 1) * stride - 1
	while i < last:
		var s := buf[i]
		if s < 0xF0:
			var avg := (buf[i - stride] + 2 * buf[i - stride - 1] + buf[i - 1]) >> 2
			if avg >= THR:
				var d := avg - THR
				if d != 0 and s < d:
					buf[i] = cap if cap < d else d
		i += 1
	return buf


## The overlay `FUN_005d5220` paints OUTSIDE the silhouette: an RGBA image the size
## of the sprite, opaque only on shadow pixels, to be drawn between the background
## and the sprite itself.
##
## `dest` is the sprite's position in the 640x480 SCREEN space -- the dither parity
## is a checkerboard on absolute screen coordinates, so it may not be passed in some
## panel-local frame. `bg` holds the destination as it stands before the blit and
## `bg_origin` is where its own (0,0) sits on that screen.
static func overlay(bg: Image, bg_origin: Vector2i, alpha: PackedByteArray,
		w: int, h: int, dest: Vector2i, cap: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	if not _load():
		return img
	var mask := spread_mask(alpha, w, h, cap)
	var stride := ((w * 8 + 31) / 32) * 4
	var bw := bg.get_width()
	var bh := bg.get_height()
	for y in h:
		var sy := dest.y + y
		var by := sy - bg_origin.y
		if by < 0 or by >= bh:
			continue
		for x in w:
			var a: int = mask[y * stride + x]
			if a == 0 or a == 255:
				continue
			var sx := dest.x + x
			var bx := sx - bg_origin.x
			if bx < 0 or bx >= bw:
				continue
			var c := bg.get_pixel(bx, by)
			var wt := a + 1
			var r := _blend(int(round(c.r * 255.0)), wt)
			var g := _blend(int(round(c.g * 255.0)), wt)
			var b := _blend(int(round(c.b * 255.0)), wt)
			var k := ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | ((b & 0xF8) >> 3)
			var idx: int = (_t1 if ((sx + sy + 1) & 1) != 0 else _t0)[k]
			img.set_pixel(x, y, Color8(_pal[idx * 3], _pal[idx * 3 + 1], _pal[idx * 3 + 2]))
	return img


## One channel of `dst + ((0 - dst) * wt) >> 8` in the original's own arithmetic
## (the source is always palette black outside the silhouette).
##
## Two wraps matter and NEITHER may be replaced by a clamp:
##   * the product is taken modulo 16 bits before the `>> 8`, so a large `wt`
##     folds the difference around (this is what makes the capped 0x84 stamp come
##     out DARKER than a linear blend would);
##   * the sum lands in a byte, so `255 + 123` is 122, not a saturated 255.
## Clamping either one costs 124 px on the MAN-TO-MAN 48x64 kit alone.
static func _blend(dst: int, wt: int) -> int:
	var t := (-dst * wt) & 0xFFFF
	var b := (t >> 8) & 0xFF
	return (dst + (b - 256 if b >= 128 else b)) & 0xFF


## Cached texture form. `key` must identify the sprite AND the destination pixels
## under it; screens whose background is static chrome can key on the sprite alone.
static func texture(key: String, bg: Image, bg_origin: Vector2i, alpha: PackedByteArray,
		w: int, h: int, dest: Vector2i, cap: int) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var t := ImageTexture.create_from_image(overlay(bg, bg_origin, alpha, w, h, dest, cap))
	_cache[key] = t
	return t


## Convenience: the overlay for a sprite TEXTURE over a background TEXTURE, cached.
static func for_sprite(key: String, bg: Texture2D, bg_origin: Vector2i,
		sprite: Texture2D, dest: Vector2i, cap: int) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	if bg == null or sprite == null:
		return null
	var si := sprite.get_image()
	var t := ImageTexture.create_from_image(overlay(bg.get_image(), bg_origin,
		alpha_of(si), si.get_width(), si.get_height(), dest, cap))
	_cache[key] = t
	return t


## The sprite's per-pixel "is this a non-zero palette index" bytes, from its alpha.
static func alpha_of(img: Image) -> PackedByteArray:
	var w := img.get_width()
	var h := img.get_height()
	var out := PackedByteArray()
	out.resize(w * h)
	for y in h:
		for x in w:
			out[y * w + x] = 255 if img.get_pixel(x, y).a > 0.0 else 0
	return out


## ---------------------------------------------------------------------------------------
## The `0x20` arm — `FUN_005d60a0`, the EDGE pass, and the composite that carries it.
##
## `FUN_005cbea0` with `flags & 0x20` takes the other branch: silhouette at alpha 0x100,
## then `FUN_005d60a0`, then — `thr` permitting — the SAME `FUN_005d6590` spread the 0x10
## arm uses, then the composite. So a 0x20 site paints BOTH: an on-sprite edge and the
## down-and-right drop shadow. That is why the group draw's kits carry a dithered shadow
## outside the silhouette AND a darkened rim inside it.
##
## `FUN_005d60a0` rewrites every NON-ZERO mask byte as `EDGE_TABLE[code] * 2 + 1`, where
## `code` is a 13-bit neighbourhood built from twelve `cmp ch, [edi+off]` tests plus a
## hardwired low bit (`stc; rcl`). `ch` is the loop counter's own high byte, which for a
## 0/255 mask is only ever 0..2 — kept as measured, not tidied into a constant.
##
## The table is `DAT_006b5890`, built at startup from `letras.bmp`, which ships in NEITHER
## `pm98.iso` NOR `Premier_Manager_98.rar`. It was read out of the RUNNING original over the
## RSP stub instead and is deterministic across three independent boots (one of them a fully
## isolated wineprefix): `tools/re/refs/aliasing-2026-08-02/aliasing.bin`, sha256 401e3411…
##
## RENDER-DIFF, the gate s89 left open — `tools/re/probe_groupdraw_edge_render.py`, scored
## against the port's own `cupdraw_groups.png` and the frame
## `manutd_s1_eurocup_groups_1_8_final.png`:
##
##     port render, no pass                      345 wrong px over the four kit cells
##     edge only                                 256   (on-sprite 131 -> 42)
##     edge + spread(thr 0x40, cap 0x80)         178
##     edge + spread(thr 0x20, cap 0x80)           0   <- all four kits, 884 sprite px
##                                                        and 476 background px each
##
## `thr` / `cap` are pushed as REGISTERS at this site (`0x5c0688`, the RIDIESC picture
## widget's own blit), so unlike the 65 immediate-pushing sites they cannot be read off the
## call. They are not fitted: the sweep is over the byte values the other sites attest
## (`thr` 0x20 at two 0x10 sites, `cap` 0x80 at `(0x20, 0x40, 0x80)`), and the frame picks
## between them — 0 px against 10 for the nearest neighbour and 250+ two steps away.
const EDGE_TABLE_PATH := "res://data/aliasing.bin"

static var _edge_table: PackedByteArray = PackedByteArray()


static func _load_edge_table() -> bool:
	if not _edge_table.is_empty():
		return true
	var f := FileAccess.open(EDGE_TABLE_PATH, FileAccess.READ)
	if f == null:
		push_warning("PMShadow: %s missing; the 0x20 edge pass falls back to none"
			% EDGE_TABLE_PATH)
		return false
	_edge_table = f.get_buffer(0x2000)
	f.close()
	if _edge_table.size() != 0x2000:
		push_warning("PMShadow: %s is %d bytes, want 8192" % [EDGE_TABLE_PATH, _edge_table.size()])
		_edge_table = PackedByteArray()
		return false
	return true


## `FUN_005d66f0(0x100)` + `FUN_005d60a0` + (thr permitting) `FUN_005d6590`: the whole
## 0x20 mask, as `h` rows of `stride` bytes. Pass `thr = 0` for the edge alone.
static func edge_mask(alpha: PackedByteArray, w: int, h: int, thr: int, cap: int) -> PackedByteArray:
	var stride := ((w * 8 + 31) / 32) * 4
	var buf := PackedByteArray()
	buf.resize(stride * h)
	for y in h:
		for x in w:
			buf[y * stride + x] = 255 if alpha[y * w + x] != 0 else 0
	if _load_edge_table():
		# The offsets, MSB first: 2W, W, W+1, 2, 1, 1-W, -2W, -W, -1-W, -2, -1, W-1.
		var offs := [2 * stride, stride, stride + 1, 2, 1, 1 - stride,
			-2 * stride, -stride, -1 - stride, -2, -1, stride - 1]
		var start := 2 * (stride + 1)
		var count := (h - 4) * stride - 4
		var src := buf.duplicate()          # the pass reads the SILHOUETTE, writes beside it
		for k in count:
			var i: int = start + k
			if src[i] == 0:
				continue
			var ch := ((count - k) >> 8) & 0xFF
			var code := 0
			for off in offs:
				var j: int = i + int(off)
				var bit := 1 if (j >= 0 and j < src.size() and src[j] > ch) else 0
				code = (code << 1) | bit
			buf[i] = (_edge_table[(code << 1) | 1] * 2 + 1) & 0xFF
	if thr != 0:
		var i2 := stride + 1
		var last := i2 + (h - 1) * stride - 1
		while i2 < last:
			var s: int = buf[i2]
			if s < 0xF0:
				var avg: int = (buf[i2 - stride] + 2 * buf[i2 - stride - 1] + buf[i2 - 1]) >> 2
				if avg >= thr:
					var d := avg - thr
					if d != 0 and s < d:
						buf[i2] = cap if cap < d else d
			i2 += 1
	return buf


## `FUN_005d5220` for the 0x20 arm: mask 0 keeps the destination, 0xff copies the source,
## anything between blends and re-quantises. Unlike `overlay` this covers the ON-sprite
## pixels too — the edge pass puts partial mask INSIDE the silhouette, where the source is
## the sprite's own colour rather than palette black — so it returns the finished cell and
## the caller draws THAT instead of the sprite.
##
## `bg` is the destination as it stands before the blit (the same size as the sprite) and
## `dest` is where the sprite lands in 640x480 SCREEN space, because the dither parity is a
## checkerboard on absolute screen coordinates.
static func edge_blit(bg: Image, sprite: Image, dest: Vector2i, thr: int, cap: int) -> Image:
	var w := sprite.get_width()
	var h := sprite.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	if not _load():
		return out
	var mask := edge_mask(alpha_of(sprite), w, h, thr, cap)
	var stride := ((w * 8 + 31) / 32) * 4
	for y in h:
		for x in w:
			var d := bg.get_pixel(x, y)
			var a: int = mask[y * stride + x]
			var opaque := sprite.get_pixel(x, y).a > 0.0
			var s := sprite.get_pixel(x, y) if opaque else Color8(0, 0, 0)
			if a == 0:
				out.set_pixel(x, y, d)
				continue
			if a == 0xFF:
				out.set_pixel(x, y, s)
				continue
			var wt := a + 1
			var r := _blend_src(int(round(d.r * 255.0)), int(round(s.r * 255.0)), wt)
			var g := _blend_src(int(round(d.g * 255.0)), int(round(s.g * 255.0)), wt)
			var b := _blend_src(int(round(d.b * 255.0)), int(round(s.b * 255.0)), wt)
			var k := ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | ((b & 0xF8) >> 3)
			var sx := dest.x + x
			var sy := dest.y + y
			var idx: int = (_t1 if ((sx + sy + 1) & 1) != 0 else _t0)[k]
			out.set_pixel(x, y, Color8(_pal[idx * 3], _pal[idx * 3 + 1], _pal[idx * 3 + 2]))
	return out


## `dst + ((src - dst) * wt) >> 8` in the original's own wrap arithmetic. `_blend` above is
## this with `src` pinned to 0; the edge arm needs the general form because its partial mask
## lands on pixels whose source is the sprite, not palette black. Both wraps are load
## bearing — see `_blend`.
static func _blend_src(dst: int, src: int, wt: int) -> int:
	var t := ((src - dst) * wt) & 0xFFFF
	var b := (t >> 8) & 0xFF
	return (dst + (b - 256 if b >= 128 else b)) & 0xFF


## Cached form of `edge_blit`. `key` must identify the sprite, the destination pixels under
## it AND its screen position (the dither is on absolute coordinates).
static func edge_texture(key: String, bg: Image, sprite: Image, dest: Vector2i,
		thr: int, cap: int) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var t := ImageTexture.create_from_image(edge_blit(bg, sprite, dest, thr, cap))
	_cache[key] = t
	return t


static func clear_cache() -> void:
	_cache.clear()
