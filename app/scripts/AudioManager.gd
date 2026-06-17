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

const _MUSIC_DB := -8.0   # the module theme sits under the UI
const _CROWD_DB := -10.0  # ambience bed, well under the event SFX

var _music: AudioStreamPlayer
var _crowd: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cur_music := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep playing across pauses
	_music = _mk(_MUSIC_DB)
	_crowd = _mk(_CROWD_DB)
	for _i in 6:
		_pool.append(_mk(0.0))


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
	p.volume_db = vol_db
	p.play()


## The UI confirm/select click (SONIDOS/SELEC8).
func ui_select() -> void:
	sfx("select")


func set_music_enabled(on: bool) -> void:
	music_enabled = on
	if not on:
		stop_music()


func set_sfx_enabled(on: bool) -> void:
	sfx_enabled = on
	if not on:
		stop_crowd()
