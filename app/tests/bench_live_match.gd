extends SceneTree
## Measure the POSITIONAL engine's OUTER-FRAME THROUGHPUT, because that number — not a
## per-match total — is what decides whether a WATCHED match plays at the rate the original
## plays it.
##
## `MatchSimulador._step_live` asks for `delta * ENGINE_FPS` frames a render tick
## (`ENGINE_FPS = 60`), so the view keeps real time iff the engine sustains **60 outer
## frames a second**. Below that the clock falls behind (the view degrades gracefully, it
## does not hang — `MAX_FRAMES_PER_TICK` caps the catch-up), so the interesting figure is
## the ratio to 60, per platform.
##
## Usage: godot4 --headless --path app --script res://tests/bench_live_match.gd
##        PM98_BENCH_FRAMES=3000 to shorten; default runs to full time.

func _init() -> void:
	var want := int(OS.get_environment("PM98_BENCH_FRAMES")) if \
		OS.has_environment("PM98_BENCH_FRAMES") else 0
	var live := Pm98LiveMatch.create(40, 42, 1)
	if live == null or live.match_state.is_empty():
		push_error("BENCH: no live match")
		quit(1)
		return
	var t0 := Time.get_ticks_usec()
	var frames := 0
	var marks: Array = []
	while not live.over and (want == 0 or frames < want):
		var n := live.advance(500)
		if n == 0:
			break
		frames += n
		if frames % 5000 == 0:
			var el := (Time.get_ticks_usec() - t0) / 1e6
			marks.append("  %6d frames  %7.1fs  %6.1f fps  clk=%d min=%d" % [
				frames, el, frames / maxf(el, 1e-6), int(live.match_state.get(0x450, 0)),
				live.minute()])
	var elapsed := (Time.get_ticks_usec() - t0) / 1e6
	for m in marks:
		print(m)
	var fps := frames / maxf(elapsed, 1e-6)
	print("BENCH live-match: %d frames in %.1f s = %.1f outer-fps (need %.0f for real time)" % [
		frames, elapsed, fps, MatchSimulador.ENGINE_FPS])
	print("  ratio to real time: %.2fx   full match (18500 f) would take %.1f s" % [
		fps / MatchSimulador.ENGINE_FPS, 18500.0 / maxf(fps, 1e-6)])
	print("  final: %d-%d  minute=%d  over=%s" % [live.score[0], live.score[1],
		live.minute(), live.over])
	if Pm98Driver.prof_on:
		print(Pm98Driver.prof_report())
	quit(0)
