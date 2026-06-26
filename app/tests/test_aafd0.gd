extends SceneTree
## Oracle-backed parity test for FUN_005aafd0 (the non-controller possession tail, the last settle leaf):
## Pm98Movement.possession_tail_aafd0 reproduces the REAL binary's field writes, rng draw sequence, and
## return-low-byte bit-for-bit.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_aafd0.gd
##
## ORACLE = the REAL FUN_005aafd0 entered at 0x5aafd0 (ECX=p, char param_2=1 as a cdecl arg), with the
## cos/atan LUT + faithful _ftol injected and FUN_005ec250 traced: tools/re/run_aafd0_oracle.sh ->
## specs/aafd0_oracle.txt. Each `AAFD0 <name> EAX=<v> draws=<n> | 0xADDR=<unsigned LE> ...` row is rebuilt
## as identical p/ball/gs/carrier/stats Dicts; we assert every written field, the final LCG state (==> the
## draw count + order), and the return low byte. Distances are axis-aligned so int(sqrt) == the x87 ftol.

const SEED := 0x4d2

var _fail := 0
var _pass := 0

# name -> fixture cfg (mirrors run_aafd0_oracle.sh FIX rows). Offsets default 0.
var _fix := {
	"bvf_near":     {"b174": 0x8000, "tier": 1, "s384": 50, "s390": 50},
	"bvf_far":      {"b174": 0x30000, "tier": 1, "s384": 80, "p68": 0x4000, "s390": 40},
	"bvf_bigp68":   {"b174": 0x30000, "tier": 1, "s384": 40, "p68": 0x9000, "s390": 30},
	"bvt":          {"bteam": 5, "carrier": true, "car2bc": 1, "carAct": 0x1e, "carx": 0x10000, "carvx": 0x1000,
		"tier": 1, "s384": 60, "p68": 0x4000, "s390": 50},
	"gate_ballz":   {"b174": 0x8000, "ballz": 0x3333, "tier": 1, "s384": 50},
	"gate_caroff":  {"b174": 0x8000, "carrier": true, "car2bc": 0, "tier": 1, "s384": 50},
	"gate_engaged": {"b174": 0x8000, "engaged": true, "tier": 1, "s384": 50},
	"gate_heading": {"b178": 0x30000, "tier": 1, "s384": 50},
	"gate_far":     {"b174": 0x40000, "tier": 1, "s384": 50},
}

# oracle abs-addr -> [object, field-off, bytes].  "AC" = the carrier-ref special case.
var _addr := {
	"0x230020": ["p", 0x20, 4], "0x230024": ["p", 0x24, 4], "0x230028": ["p", 0x28, 4],
	"0x230080": ["p", 0x80, 4], "0x230084": ["p", 0x84, 4], "0x230066": ["p", 0x66, 2],
	"0x230094": ["p", 0x94, 4], "0x230098": ["p", 0x98, 4], "0x23009c": ["p", 0x9c, 4],
	"0x2300ac": ["AC", 0xac, 4], "0x230060": ["p", 0x60, 1], "0x230062": ["p", 0x62, 1],
	"0x2d0090": ["stats", 0x90, 4],
}


func _init() -> void:
	var o := _load("aafd0_oracle.txt")
	if o.is_empty():
		_ok(false, "aafd0 oracle empty (run tools/re/run_aafd0_oracle.sh)")
	else:
		for name in _fix:
			if o.has(name):
				_run(name, o[name])
			else:
				_ok(false, name + ": missing from aafd0 oracle")
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


func _s32(v: int) -> int:
	return v - 0x100000000 if v >= 0x80000000 else v


# Parse the oracle into name -> {eax:int, draws:int, rng:int, fields:{addr:unsigned}}.
func _load(fname: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path(fname), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("AAFD0 "):
			continue
		var head := line.split("|", false)
		var parts := head[0].split(" ", false)            # AAFD0 <name> EAX=.. draws=..
		var name := parts[1]
		var row := {"eax": 0, "draws": 0, "rng": 0, "fields": {}}
		for tok in parts:
			if tok.begins_with("EAX="):
				row["eax"] = _s32(int(tok.substr(4)))
			elif tok.begins_with("draws="):
				row["draws"] = int(tok.substr(6))
		if head.size() > 1:
			for tok in head[1].split(" ", false):
				var eq := tok.find("=")
				if eq > 0 and tok.begins_with("0x"):
					var addr := tok.substr(0, eq)
					var val := int(tok.substr(eq + 1))
					if addr == "0x6d3184":
						row["rng"] = val
					else:
						row["fields"][addr] = val
		out[name] = row
	return out


func _run(name: String, want: Dictionary) -> void:
	var cfg: Dictionary = _fix[name]
	var stats := {}
	var m := {0x180a: 0}
	var gs := {0x31c: int(cfg.get("tier", 0))}
	var ball := {0x54: int(cfg.get("bteam", 0)), 0xc: int(cfg.get("ballz", 0)),
		0x174: int(cfg.get("b174", 0)), 0x178: int(cfg.get("b178", 0)), 0x17c: int(cfg.get("b17c", 0))}
	var p := {
		0x190: ball, 0x18c: m, 0x184: gs, 0x3b8: stats,
		0x4: 0, 0x8: 0, 0xc: 0, 0x2b8: 0, 0x34: 0,
		0x384: int(cfg.get("s384", 0)), 0x68: int(cfg.get("p68", 0)), 0x390: int(cfg.get("s390", 0))}
	var carrier := {}
	if cfg.get("carrier", false):
		carrier = {0x2bc: int(cfg.get("car2bc", 0)), 0x40: int(cfg.get("carAct", 0)),
			0x4: int(cfg.get("carx", 0)), 0x8: 0, 0xc: 0,
			0x20: int(cfg.get("carvx", 0)), 0x24: 0, 0x28: 0}
		ball[0x40] = carrier
	if cfg.get("engaged", false):
		ball[0x4c] = p

	var rng = MatchEngine.Pm98Rng.new(SEED)
	var ret := Pm98Movement.possession_tail_aafd0(p, 1, rng)

	_ok((ret & 0xff) == (int(want["eax"]) & 0xff),
		"aafd0/%s ret low byte: got %d want %d" % [name, ret & 0xff, int(want["eax"]) & 0xff])
	_ok(rng.state == int(want["rng"]),
		"aafd0/%s rng state (draws=%d): got %d want %d" % [name, int(want["draws"]), rng.state, int(want["rng"])])

	var objs := {"p": p, "stats": stats}
	for addr in _addr:
		var spec: Array = _addr[addr]
		var exp: int = int(want["fields"].get(addr, 0))
		if spec[0] == "AC":
			if exp == 0:
				_ok(int(p.get(0xac, 0)) == 0, "aafd0/%s p+0xac: want 0 got %s" % [name, str(p.get(0xac, 0))])
			else:
				_ok(p.get(0xac, null) is Dictionary and is_same(p.get(0xac), carrier),
					"aafd0/%s p+0xac: want carrier ref" % name)
			continue
		var obj: Dictionary = objs[spec[0]]
		var got := int(obj.get(spec[1], 0))
		var mask := 0xffff if int(spec[2]) == 2 else 0xffffffff
		_ok((got & mask) == exp, "aafd0/%s %s+0x%x: got %d want %d" % [name, spec[0], int(spec[1]), got & mask, exp])
