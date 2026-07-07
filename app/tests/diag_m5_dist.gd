extends SceneTree
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
		var ctrl: Variant = b.get(0x40,null)
		var cs := ("p%d"%(ctrl as Dictionary).get(0x2c8,-1)) if ctrl is Dictionary else "-"
		# nearest player to ball across both teams
		var best := 1<<62; var who := "?"
		for ti in range(2):
			var pls: Array = (m["sim"][ti] as Dictionary).get("players",[])
			for pi in range(pls.size()):
				var p: Dictionary = pls[pi]
				var dx := Pm98Trig._i32(int(p.get(4,0)))-bx; var dy := Pm98Trig._i32(int(p.get(8,0)))-by
				var d := int(sqrt(float(dx*dx+dy*dy)))
				if d < best: best=d; who=("V" if ti==0 else "B")+str(pi)+" act=0x%x"%int(p.get(0x40,0))
		print("clk=%2d ball=(%d,%d) ctrl=%s  nearest=%s dist=%d (0x%x)"%[clk,bx,by,cs,who,best,best])
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
