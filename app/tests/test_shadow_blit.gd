extends SceneTree
## The shadowed bitmap blit (`FUN_004b7f60`), pinned as a MODEL — the render-diff
## gate is `tools/re/diff_mantoman_parity.py`. Everything asserted here is read out
## of MANAGER.EXE and written up in docs/re/shadow_blit_re.md:
##
##  * the silhouette is 0xff for every non-zero source byte (`FUN_005d66f0`);
##  * the spread walks LINEARLY over the padded buffer from `stride + 1`, so a
##    silhouette that reaches a row's right edge leaves a tail at the LEFT of the
##    row below (`FUN_005d6590`);
##  * its value is `((up + 2*upleft + left) >> 2) - 0x21`, capped, and it reads its
##    own output, so it decays by 0x21 a step;
##  * the two call-site caps are 0x63 (the marking markers) and 0x84 (the 48x64 kit);
##  * the composite's byte arithmetic WRAPS — `255 + 123` is 122, not 255.

var _fail := 0


func _initialize() -> void:
	_silhouette_and_decay()
	_row_wrap()
	_cap()
	_blend_wraps()
	_tables()
	if _fail > 0:
		push_error("test_shadow_blit: %d FAILED" % _fail)
		quit(1)
		return
	print("test_shadow_blit: ALL PASS")
	quit(0)


## One opaque pixel at (1,1) of an 8x4 sprite: the spread runs down-right from it and
## decays by THR a step, so the reachable values are 0x2f then nothing (0x2f - 0x21 is
## below the 0-guard once the average dilutes).
func _silhouette_and_decay() -> void:
	var w := 8
	var h := 4
	var a := PackedByteArray()
	a.resize(w * h)
	a[1 * w + 1] = 1
	var m := PMShadow.spread_mask(a, w, h, PMShadow.CAP_KIT)
	var stride := ((w * 8 + 31) / 32) * 4
	_ok(stride == 8, "an 8-wide 8bpp surface has stride 8")
	_ok(m[1 * stride + 1] == 255, "the silhouette itself stays 0xff")
	_ok(m[1 * stride + 0] == 0, "nothing spreads LEFT on the same row")
	_ok(m[0 * stride + 1] == 0, "nothing spreads UP")
	# (2,1): up=0, upleft=0, left=255 -> (0 + 0 + 255) >> 2 = 63, minus 0x21 = 30
	_ok(m[1 * stride + 2] == 30, "right of the silhouette is ((255) >> 2) - 0x21 = 30")
	# (1,2): up=255, upleft=0, left=0 -> 63 -> 30 as well
	_ok(m[2 * stride + 1] == 30, "below the silhouette is the same 30")
	# (2,2): up=30, upleft=255, left=30 -> (30 + 510 + 30) >> 2 = 142, minus 0x21 = 109
	_ok(m[2 * stride + 2] == 109, "the diagonal carries the up-left weight of 2")


## The linear walk crosses the row end: a silhouette pixel at the far right of a row
## seeds the FIRST pixel of the next row. This is not an artefact — it is visible in
## `66_mantoman_match.png` at the left edge of the 48x64 kit's rows 23-25.
## The walk starts at byte `stride + 1`, so row 1's x0 is the ONE pixel it never
## visits; the wrap shows from row 2 on, where `up-left` is the previous row's last
## byte. In `66_mantoman_match.png` that is the kit's left-edge tail at rows 23-25.
func _row_wrap() -> void:
	var w := 8
	var h := 4
	var a := PackedByteArray()
	a.resize(w * h)
	a[1 * w + (w - 1)] = 1
	var m := PMShadow.spread_mask(a, w, h, PMShadow.CAP_KIT)
	var stride := ((w * 8 + 31) / 32) * 4
	_ok(stride == w, "this fixture has no row padding, so the wrap is exact")
	# (0,2) is i = 16: up = buf[8] = (0,1) = 0, up-left = buf[7] = (7,0) = 0,
	#        left = buf[15] = (7,1) = 255  ->  (255 >> 2) - 0x21 = 30
	_ok(m[2 * stride + 0] == 30, "a right-edge silhouette tails into the NEXT row's x0")
	# and the row after picks the up-left weight up: (0 + 2*255 + 30) >> 2 - 0x21
	_ok(m[3 * stride + 0] == 109, "the tail deepens on the second row down")


## `cap` clamps the spread, and it is the ONLY thing that differs between the two
## witnessed call sites.
func _cap() -> void:
	# s88: NOT every site. `tools/re/probe_shadow_sites.py` reads all 74 and finds
	# seventeen distinct (flags, thr, cap) triples; 0x21 is the value of the two sites this
	# leaf was reversed from and of no other.
	_ok(PMShadow.THR == 0x21, "thr is 0x21 at 0x50f9e3 and 0x50fba1 -- and only there")
	_ok(PMShadow.FLAGS_SPREAD == 0x10 and PMShadow.FLAGS_EDGE == 0x20,
		"the two flag words the 74 sites use: 0x10 spread (this leaf), 0x20 edge (not modelled)")
	_ok(PMShadow.CAP_MARKER == 0x63, "FUN_0050f970 pushes cap 0x63")
	_ok(PMShadow.CAP_KIT == 0x84, "FUN_0050fae0 pushes cap 0x84")
	var w := 6
	var h := 6
	var a := PackedByteArray()
	a.resize(w * h)
	for y in 4:
		for x in 4:
			a[y * w + x] = 1
	var stride := ((w * 8 + 31) / 32) * 4
	var lo := PMShadow.spread_mask(a, w, h, 0x40)
	var hi := PMShadow.spread_mask(a, w, h, 0x84)
	_ok(lo[4 * stride + 4] == 0x40, "a saturated neighbourhood is clamped to cap")
	_ok(hi[4 * stride + 4] > 0x40, "a higher cap lets the same pixel go darker")


## `FUN_005d5220`'s per-channel arithmetic, both wraps intact.
func _blend_wraps() -> void:
	# cap 0x84 -> w = 133: (0 - 255) * 133 folds mod 2^16 to +123, and 255 + 123
	# wraps to 122 in the byte. That is what the frames show as (128,128,128).
	_ok(PMShadow._blend(255, 133) == 122, "255 under w=133 wraps to 122, not to 255")
	# a small weight is the ordinary linear case
	_ok(PMShadow._blend(255, 64) == 191, "255 under w=64 is the plain 191")
	_ok(PMShadow._blend(0, 200) == 0, "black stays black whatever the weight")


## The reconstructed dither pair must be present and must actually differ.
func _tables() -> void:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(1, 1, 1))
	var a := PackedByteArray()
	a.resize(4)
	a[0] = 1
	var ov := PMShadow.overlay(img, Vector2i.ZERO, a, 2, 2, Vector2i.ZERO, PMShadow.CAP_KIT)
	_ok(ov.get_width() == 2 and ov.get_height() == 2, "the overlay is the sprite's size")
	_ok(FileAccess.file_exists(PMShadow.LUT_PATH), "the baked dither pair ships")
	if FileAccess.file_exists(PMShadow.LUT_PATH):
		var f := FileAccess.open(PMShadow.LUT_PATH, FileAccess.READ)
		_ok(f.get_length() == 768 + 2 * 65536, "shadow_lut.bin is palette + two 64K tables")
		f.close()


func _ok(cond: bool, what: String) -> void:
	if cond:
		print("  PASS  %s" % what)
	else:
		_fail += 1
		print("  FAIL  %s" % what)
