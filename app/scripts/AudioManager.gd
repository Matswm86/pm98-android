extends Node
## Central audio for PM98: the original ScreamTracker-3 menu theme (DINAMIC0) and the
## DATSIM match SFX, all extracted from the owned PKFs by tools/re/export_audio.py and
## committed as Ogg Vorbis under res://audio/. Autoloaded (see project.godot) so any
## screen can call it without holding a reference.
##
## Channels: one looping MUSIC player (menu theme), one looping CROWD player (match
## ambience bed), and a small round-robin POOL for overlapping one-shot SFX. Honours
## MANAGER.INI's MUSIC / SOUND ON-OFF switches (music_enabled / sfx_enabled).

const MUSIC_MENU := "res://audio/music/menu.ogg"
const CROWD := "res://audio/sfx/crowd.ogg"

# Keyed one-shots (verbatim from SFX/AMBIENTE.PKF + SONIDOS, see export_audio.py).
const SFX := {
	"select": "res://audio/sfx/select.ogg",
	"nav": "res://audio/sfx/nav.ogg",
	"whistle": "res://audio/sfx/whistle.ogg",
	"whistle_final": "res://audio/sfx/whistle_final.ogg",
	"goal": "res://audio/sfx/goal.ogg",
	"card_yellow": "res://audio/sfx/card_yellow.ogg",
	"card_red": "res://audio/sfx/card_red.ogg",
	"tackle": "res://audio/sfx/tackle.ogg",
	"post": "res://audio/sfx/post.ogg",
}

var music_enabled := true
var sfx_enabled := true
var music_volume := 100          # MANAGER.INI "MUSIC VOLUME" (0-100)
var sfx_volume := 100            # MANAGER.INI "SOUND VOLUME" (0-100)
var transitions_enabled := true  # MANAGER.INI "TRANSITIONS"
# MATCH OPTIONS view mode (WATCH/HIGHLIGHTS/BRIEF/RESULTS). The original stores the
# chosen presentation globally (MANAGER.INI); default BRIEF = the user's main play mode.
var match_view_mode := "brief"
# MATCH OPTIONS graphics/camera/sound sub-settings (the GRAPHICS/CAMERAS/SOUND tabs).
# Each configures PM98's 3D/positional engine or its match audio -- both absent from the
# source on hand -- so these are persisted (like MANAGER.INI) but honest no-ops at runtime
# (nothing to change). See app/scenes/MatchOptions.gd for the honesty note.
var gfx_sky := true
var gfx_boards := true
var gfx_shadows := true
var pitch_detail := "high"      # HIGH/MED/LOW/MIN
var stadium_detail := "high"    # HIGH/MED/LOW
var snd_fx := true
var snd_ambient := true
var snd_comments := true
var camera_mode := "static"     # static/auto/free
var lineups_on := true          # LINE-UPS: pre-match XI-vs-XI photo roll (live consumer)
var cheat_three_up_front := false   # port-only cheat, NOT a PM98 option — see set_three_up_front

const _SETTINGS := "user://settings.cfg"
const _MUSIC_DB := -8.0   # the module theme sits under the UI
const _CROWD_DB := -10.0  # ambience bed, well under the event SFX

var _music: AudioStreamPlayer
var _crowd: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cur_music := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep playing across pauses
	_load_settings()
	_music = _mk(_MUSIC_DB + _vol_off(music_volume))
	_crowd = _mk(_CROWD_DB + _vol_off(sfx_volume))
	for _i in 6:
		_pool.append(_mk(0.0))


## MANAGER.INI-style 0-100 volume as a dB offset (0 -> silence).
func _vol_off(v: int) -> float:
	return linear_to_db(maxf(v / 100.0, 0.0001))


func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(_SETTINGS) != OK:
		return
	music_enabled = bool(cf.get_value("audio", "music_enabled", music_enabled))
	sfx_enabled = bool(cf.get_value("audio", "sfx_enabled", sfx_enabled))
	music_volume = clampi(int(cf.get_value("audio", "music_volume", music_volume)), 0, 100)
	sfx_volume = clampi(int(cf.get_value("audio", "sfx_volume", sfx_volume)), 0, 100)
	transitions_enabled = bool(cf.get_value("ui", "transitions", transitions_enabled))
	match_view_mode = str(cf.get_value("match", "view_mode", match_view_mode))
	gfx_sky = bool(cf.get_value("match", "gfx_sky", gfx_sky))
	gfx_boards = bool(cf.get_value("match", "gfx_boards", gfx_boards))
	gfx_shadows = bool(cf.get_value("match", "gfx_shadows", gfx_shadows))
	pitch_detail = str(cf.get_value("match", "pitch_detail", pitch_detail))
	stadium_detail = str(cf.get_value("match", "stadium_detail", stadium_detail))
	snd_fx = bool(cf.get_value("match", "snd_fx", snd_fx))
	snd_ambient = bool(cf.get_value("match", "snd_ambient", snd_ambient))
	snd_comments = bool(cf.get_value("match", "snd_comments", snd_comments))
	camera_mode = str(cf.get_value("match", "camera_mode", camera_mode))
	lineups_on = bool(cf.get_value("match", "lineups", lineups_on))
	set_three_up_front(bool(cf.get_value("cheats", "three_up_front", cheat_three_up_front)))


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "music_enabled", music_enabled)
	cf.set_value("audio", "sfx_enabled", sfx_enabled)
	cf.set_value("audio", "music_volume", music_volume)
	cf.set_value("audio", "sfx_volume", sfx_volume)
	cf.set_value("ui", "transitions", transitions_enabled)
	cf.set_value("match", "view_mode", match_view_mode)
	cf.set_value("match", "gfx_sky", gfx_sky)
	cf.set_value("match", "gfx_boards", gfx_boards)
	cf.set_value("match", "gfx_shadows", gfx_shadows)
	cf.set_value("match", "pitch_detail", pitch_detail)
	cf.set_value("match", "stadium_detail", stadium_detail)
	cf.set_value("match", "snd_fx", snd_fx)
	cf.set_value("match", "snd_ambient", snd_ambient)
	cf.set_value("match", "snd_comments", snd_comments)
	cf.set_value("match", "camera_mode", camera_mode)
	cf.set_value("match", "lineups", lineups_on)
	cf.set_value("cheats", "three_up_front", cheat_three_up_front)
	cf.save(_SETTINGS)


## THREE UP FRONT — the port of MANAGER_HACK.EXE (docs/re/hack_three_forwards.md).
## Not a PM98 setting: the original has no such option, so it lives in its own `cheats`
## block and never appears on a screen the render-diff covers. Default OFF, and OFF is
## bit-identical to stock (proven in the PCode emulator against the real bytes).
func set_three_up_front(on: bool, persist := false) -> void:
	cheat_three_up_front = on
	Pm98StatMatch.cheat_three_up_front = on
	if persist:
		save_settings()


## Persist the chosen MATCH OPTIONS view mode (WATCH/HIGHLIGHTS/BRIEF/RESULTS).
func set_match_view_mode(mode: String) -> void:
	match_view_mode = mode
	save_settings()


## The MATCH OPTIONS graphics/camera/sound sub-settings as a dict (for the dialog).
func match_settings() -> Dictionary:
	return {
		"gfx_sky": gfx_sky, "gfx_boards": gfx_boards, "gfx_shadows": gfx_shadows,
		"pitch_detail": pitch_detail, "stadium_detail": stadium_detail,
		"snd_fx": snd_fx, "snd_ambient": snd_ambient, "snd_comments": snd_comments,
		"camera_mode": camera_mode, "lineups": lineups_on,
	}


## Persist the MATCH OPTIONS sub-settings block (honest no-ops; see MatchOptions.gd).
func set_match_settings(d: Dictionary) -> void:
	if d.has("gfx_sky"): gfx_sky = bool(d["gfx_sky"])
	if d.has("gfx_boards"): gfx_boards = bool(d["gfx_boards"])
	if d.has("gfx_shadows"): gfx_shadows = bool(d["gfx_shadows"])
	if d.has("pitch_detail"): pitch_detail = str(d["pitch_detail"])
	if d.has("stadium_detail"): stadium_detail = str(d["stadium_detail"])
	if d.has("snd_fx"): snd_fx = bool(d["snd_fx"])
	if d.has("snd_ambient"): snd_ambient = bool(d["snd_ambient"])
	if d.has("snd_comments"): snd_comments = bool(d["snd_comments"])
	if d.has("camera_mode"): camera_mode = str(d["camera_mode"])
	if d.has("lineups"): lineups_on = bool(d["lineups"])
	save_settings()


func set_music_volume(v: int) -> void:
	music_volume = clampi(v, 0, 100)
	if _music != null:
		_music.volume_db = _MUSIC_DB + _vol_off(music_volume)
	save_settings()


func set_sfx_volume(v: int) -> void:
	sfx_volume = clampi(v, 0, 100)
	if _crowd != null:
		_crowd.volume_db = _CROWD_DB + _vol_off(sfx_volume)
	save_settings()


func set_transitions(on: bool) -> void:
	transitions_enabled = on
	save_settings()


func _mk(db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = db
	add_child(p)
	return p


## Load a stream and force it to loop (Ogg imports default to loop=off).
func _load_looped(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: missing %s" % path)
		return null
	var s: AudioStream = load(path)
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	return s


## Start the looping menu theme. Idempotent: a no-op if it is already the playing track.
func play_music(path := MUSIC_MENU) -> void:
	if not music_enabled:
		return
	if _cur_music == path and _music.playing:
		return
	var s := _load_looped(path)
	if s == null:
		return
	_music.stream = s
	_cur_music = path
	_music.play()


func stop_music() -> void:
	_music.stop()
	_cur_music = ""


## Looping crowd bed for the match (separate channel from the music).
func play_crowd() -> void:
	if not sfx_enabled:
		return
	var s := _load_looped(CROWD)
	if s == null:
		return
	_crowd.stream = s
	_crowd.play()


func stop_crowd() -> void:
	_crowd.stop()


## Fire a one-shot SFX by key (in SFX) or by direct res:// path. Round-robins the pool
## so overlapping events (e.g. a goal roar over the crowd) don't cut each other off.
func sfx(key: String, vol_db := 0.0) -> void:
	if not sfx_enabled:
		return
	var path: String = SFX.get(key, key)
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: missing sfx %s" % path)
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = load(path)
	p.volume_db = vol_db + _vol_off(sfx_volume)
	p.play()


## The UI confirm/select click (SONIDOS/SELEC8).
func ui_select() -> void:
	sfx("select")


func set_music_enabled(on: bool) -> void:
	music_enabled = on
	if not on:
		stop_music()
	elif _cur_music != "":
		play_music(_cur_music)
	save_settings()


func set_sfx_enabled(on: bool) -> void:
	sfx_enabled = on
	if not on:
		stop_crowd()
	save_settings()
