extends SceneTree
# Proves M5 div#1 root cause: the ball's predicted-trajectory buffer (ball+0x114..0x1d4,
# 16 vec3 written by FUN_0058fda0) is NEVER populated in the port -> _grid9490_build reads
# all-zero slots -> gate-4 catch zone tests rot(-p.pos,-facing) for every row. Dumps, per tick
# clk 5-14: whether ball has key 0x114 (slot 0), raw slots 0 and 2, and the built grid[0]/grid[2]
# for the ball's nearest player.
const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
func _init() -> void: _run(); quit(0)
func _run() -> void:
	var dump: Dictionary = _lj(STRUCT_JSON)
	var throwaway := MatchEngine.Pm98Rng.new(1)
	var m := Pm98Match.build_match(throwaway)
	Pm98CollBuilder.populate_posts(m)
	for k in (dump["match"] as Dictionary): m[_hx(k)] = int((dump["match"] as Dictionary)[k])
	var session := {}
	for k in (dump["session"] as Dictionary):
		if k == "_va": continue
		session[_hx(k)] = int((dump["session"] as Dictionary)[k])
	m[0x468] = session
	var ball: Dictionary = m["ball"]; var teams: Array = m["sim"]; var built := [[],[]]
	for ti in range(2):
		var own: Dictionary = teams[ti]; var opp: Dictionary = teams[1-ti]
		for src in ((dump["players"] as Array)[ti] as Array):
			built[ti].append(_lp(src as Dictionary, own, opp, m, ball))
	for ti in range(2): _lh(teams[ti] as Dictionary, (dump["team_headers"] as Array)[ti] as Dictionary, built[ti] as Array, ti, m)
	var rng := MatchEngine.Pm98Rng.new(0); rng.state = FRAME0_SEED
	var b: Dictionary = m["ball"]
	var t := 0
	while t < 45:
		Pm98Driver.tick(m, rng); t += 1
		var clk := int(m.get(0x450,0))
		if clk < 5 or clk > 14: continue
		var bx := Pm98Trig._i32(int(b.get(4,0))); var by := Pm98Trig._i32(int(b.get(8,0)))
		# find nearest player to ball
		var best := 1<<62; var np: Dictionary = {}
		for ti in range(2):
			var pls: Array = (m["sim"][ti] as Dictionary).get("players",[])
			for pi in range(pls.size()):
				var p: Dictionary = pls[pi]
				var dx := Pm98Trig._i32(int(p.get(4,0)))-bx; var dy := Pm98Trig._i32(int(p.get(8,0)))-by
				var d := int(sqrt(float(dx*dx+dy*dy)))
				if d < best: best=d; np=p
		var has114 = b.has(0x114)
		var s0x = int(b.get(0x114,-999)); var s0y = int(b.get(0x118,-999)); var s0z = int(b.get(0x11c,-999))
		var s2x = int(b.get(0x114+24,-999))
		var grid: Array = Pm98Movement._grid9490_build(np)
		var g0: Array = grid[0]; var g2: Array = grid[2]
		var catch0 = (int(g0[2]) <= 0x1e665) and (abs(int(g0[1])) <= 0x8000) and (abs(Pm98Trig._i32(int(g0[0])-0x4ccc)) <= 0x4ccb)
		print("clk=%2d ball=(%d,%d) buf.has0x114=%s slot0=(%d,%d,%d) slot2.x=%d | grid0=(%d,%d,%d) inCatch=%s | ctrl=%s"%[
			clk,bx,by,str(has114),s0x,s0y,s0z,s2x, int(g0[0]),int(g0[1]),int(g0[2]),str(catch0),
			("p%d"%(b.get(0x40) as Dictionary).get(0x2c8,-1)) if b.get(0x40) is Dictionary else "-"])
func _lp(src,own,opp,m,ball):
	var p := {}
	for k in (src["dwords"] as Dictionary): p[_hx(k)]=int((src["dwords"] as Dictionary)[k])
	for k in src:
		if k=="dwords" or k=="_va": continue
		p[_hx(k)]=int(src[k])
	p[0x184]=own;p[0x188]=opp;p[0x18c]=m;p[0x190]=ball; return p
func _lh(team,hdr,players,ti,m):
	team[0x0]=players;team[0x4]=players.size();team["players"]=players;team[0x8]=ti;team[0x138]=m
	team[0xc]=int(hdr["score_0xc"]);team[0x168]=int(hdr["active_idx_0x168"])
	var act:Array=hdr["active_table"]
	for s in range(act.size()): team[0x4f+s]=players[int(act[s])] if (act[s] is float or act[s] is int) else 0
	var rol:Array=hdr["role_table"]
	for k in range(rol.size()): team[0x5b+k]=players[int(rol[k])] if (rol[k] is float or rol[k] is int) else 0
	var sh:Array=hdr["squad_header"]
	for k in range(sh.size()): team[0xbf+k]=int(sh[k])
	team[0x2e0]=int(hdr["0x2e0"]);team[0x2ec]=int(hdr["0x2ec"]);team[0x2ed]=int(hdr["0x2ed"]);team[0x20c]=int(hdr["0x20c"])
func _hx(k): return (k as String).hex_to_int()
func _lj(path) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return {}
	var r = JSON.parse_string(f.get_as_text())
	return r if r is Dictionary else {}
