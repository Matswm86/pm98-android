class_name PMTouch
## Shared TOUCH-INPUT helpers for the phone build. Input layer ONLY — nothing here
## draws a pixel, so every parity gate is untouched. The original is a mouse game;
## on a phone its 11-15 px scroll steppers are below any finger, so list screens
## add drag-to-scroll ON TOP of the original's own steppers (which keep working).
## BrowseScreen carried this pattern first; this class is that pattern extracted
## so the reversed screens can share it instead of re-implementing it.
##
## Contract per screen (see BrowseScreen for the reference wiring):
##   * on press:   drag.press(design_y, over_the_list)
##   * on motion:  var dy := drag.update(design_y)   -> scroll by -dy (design px)
##   * on release: if drag.release(): return         -> the gesture was a scroll,
##                 NOT a tap; the screen's tap dispatch must not fire.
## Screens that scroll in whole ROWS feed `update()` through `take_rows()` so a
## finger tracks the list 1:1 at any row pitch.

## Design px of travel before a touch stops being a tap and becomes a scroll.
## BrowseScreen's own constant, shared: 6 px at 640x480 is ~2.5 mm on a 5" panel.
const DRAG_SLOP := 6.0

## Extra design px of forgiveness around a small tap target (scroll steppers,
## spin arrows). Input-side only — the art never changes. 5 px keeps the grown
## rects of a stepper pair (always >= 11 px apart) from overlapping.
const HIT_SLOP := 5.0


## True when `p` lands in `r` grown by HIT_SLOP on every side. Use ONLY for
## targets smaller than a finger (steppers); big buttons keep exact rects.
static func near(r: Rect2, p: Vector2, slop: float = HIT_SLOP) -> bool:
	return r.grow(slop).has_point(p)


## One finger's vertical drag state. All coordinates are DESIGN px (after the
## screen's own _to_design), so slop and row math are resolution-independent.
class Drag:
	var down := false     # a press is being tracked
	var armed := false    # ... and it started over the scrollable list
	var moved := false    # travel exceeded DRAG_SLOP -> this gesture is a scroll
	var _last_y := 0.0
	var _start_y := 0.0
	var _row_accum := 0.0   # un-consumed travel for row-stepped screens

	func press(y: float, over_list: bool) -> void:
		down = true
		armed = over_list
		moved = false
		_last_y = y
		_start_y = y
		_row_accum = 0.0

	## Feed a motion event; returns the design-px delta since the last call
	## (0.0 until the press is armed and slop is exceeded). The caller scrolls
	## its content by the NEGATIVE of this (finger down -> list up).
	func update(y: float) -> float:
		if not down or not armed:
			return 0.0
		if not moved:
			if absf(y - _start_y) <= DRAG_SLOP:
				return 0.0
			moved = true
			_last_y = y      # swallow the slop so the list doesn't jump
			return 0.0
		var dy := y - _last_y
		_last_y = y
		return dy

	## Convert a motion delta into whole rows at `pitch` design px per row,
	## carrying the remainder so slow drags still accumulate. Returns rows to
	## ADD to the scroll offset (finger down -> negative -> earlier rows).
	func take_rows(y: float, pitch: float) -> int:
		_row_accum += update(y)
		if pitch <= 0.0:
			return 0
		var rows := int(_row_accum / pitch)
		_row_accum -= rows * pitch
		return -rows

	## Close the gesture. True -> it was a scroll (or a stray duplicate release):
	## the screen must NOT run its tap dispatch.
	func release() -> bool:
		if not down:
			return true
		var was_scroll := moved
		down = false
		armed = false
		moved = false
		return was_scroll
