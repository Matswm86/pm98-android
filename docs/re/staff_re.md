# Backroom Staff (EMPLE) — reverse-engineering notes + model

The STAFF screen is the Main Menu's EMPLE (empleados) icon. Until this session that icon
held the *interim* training screen (flagged since the training rollout); it now opens a
real staff screen with hire/sack, and training is nested under it (the trainer context).

## Faithful surface (strings scanned from MANAGER.EXE)

```
STAFF / Staff Wages / STAFF WAGES / STAFF AVAILABLE / CURRENT TRAINING STAFF / TRAINING STAFF
"1 member of staff" / " members of staff"
TRAINER / TRAINERS / Trainer        PHYSIO. / PHYSIOTHERAPIST / PHYSIOTHERAPISTS
SCOUT / SCOUTS                       YOUTH TEAM SCOUT / YOUTH SCOUT / SCOUTS YOUTH TEAM
YOUTH MANAGER / YOUTH TEAM MANAGER   ASSISTANT MANAGER / ASSISTANT
HIRE  (recursos\iconos\empleados\contratar.bmp / contratargente.bmp / contratarsacos.bmp)
SACK  (recursos\iconos\empleados\despedir.bmp)     billete.bmp (the wage / money icon)
emple3/emple6/emple7.bmp (role icons)              recursos\iconos\NIVELES\Entrenador0/1.bmp
YEARLY WAGE / MONTHLY WAGE / WAGE   CONTRACT / COMPENSATIONS OF CONTRACT
"Are you sure you want to sack him ?"
"The directors board will not let you sack this player."
"you have to have hired trainers."   "you need to hire an Assistant."
"This option is automatic in the Trainer level."   Options "Automatic contract renewal"
recursos\iconos\menuprincipal\emple{gris,on,off}.bmp   (the EMPLE menu icon states)
```

So PM98's staff are TRAINER(s), PHYSIOTHERAPIST(s), SCOUT(s), YOUTH TEAM SCOUT, YOUTH
MANAGER and an ASSISTANT MANAGER, hired from a pool (STAFF AVAILABLE) into the backroom,
paid STAFF WAGES, sacked for a contract COMPENSATION (with an "Are you sure ?" confirm and a
board veto on key staff). Higher "Trainer level" automates options (e.g. auto contract
renewal, automatic training).

## What we built (and what is ours vs PM98's)

PM98's staff EFFECTS + wages are **data-driven** (loaded from the save), like the
fee/finance models — nothing numeric to port. So the **surface** above is PM98's; the
**model** is ours, in `app/scripts/Staff.gd`. Scoped to the three roles with clean hooks
into the systems already built; a general transfer SCOUT and the ASSISTANT MANAGER
(automation) are deferred.

- **Roles + effects** (`Staff.gd`): each hired member has a role, a 1–5 **quality** and a
  yearly **wage** (wage = base + quality·step per role). The aggregate effect scales with
  the total quality in a role, clamped:
  - **TRAINER** → `training_factor` (1.0 → 1.5): speeds player development. Fed into
    `Training.train_week(..., dev_factor)` — applied to the *improvement* rate only, so a
    trainer never hastens a veteran's decline.
  - **PHYSIOTHERAPIST** → `physio_factor` (1.0 → 0.55): multiplies the injury risk down in
    `Availability.roll_match` (alongside the training-intensity multiplier).
  - **YOUTH COACH** → `youth_factor` (1.0 → 1.6): fed into `Youth.intake` (better crop) and
    `Youth.develop_week` (faster growth).
  - **No staff = factor 1.0 everywhere**, so training/injuries/youth keep their prior tuning
    — staff is pure upside, not a regression.
- **Career integration** (`Career`): a new career starts with **no staff** but a
  `staff_pool` of `STAFF_POOL_SIZE` (6) candidates (refreshed each season). `advance_week`
  applies the three factors and draws the weekly **STAFF WAGES** from cash. `hire_staff`
  moves a candidate pool→staff (guarded by `STAFF_MAX`=8 and affordability — the board won't
  fund a hire you can't pay); `sack_staff` moves him back and pays the **COMPENSATIONS OF
  CONTRACT** (`SACK_WEEKS`=8 weeks' wage) from cash. `staff`/`staff_pool`/`staff_seq` persist
  (candidate ids minted from `STAFF_ID_BASE`=800000); a pre-staff save loads no staff
  (effects = 1.0) and gets a pool at the next rollover.
- **Screen** (`app/scenes/StaffScreen.gd`): PM98 chrome, two sections — CURRENT STAFF (tap a
  member to SACK) and STAFF AVAILABLE (tap to HIRE) — with role, quality stars and yearly
  wage, plus a STAFF WAGES total and the live `+X% dev / −X% injuries / +X% youth` effect.
  Interactive like `MenuScreen`. **SACK is a two-tap confirm** ("Are you sure you want to
  sack him ?" → the row shows "SURE? SACK" until a second tap), since sacking costs money. A
  **TRAINING** button opens the training screen (the trainer context); RETURN → hub.

## Tests + verification

`app/tests/test_staff.gd` covers the unit model (candidate shape, wage monotonicity, the
three clamped factors + no role-bleed + no-staff-is-1.0, wage totals, sack cost) and the
Career integration (pool seeded, hire/sack with guards + compensation, the wage bill drawn
from cash exactly, a trainer developing the squad more than none over a season with the same
rng draws, persistence + legacy-save compat). Verified by a REAL render
(`PM98_STAFF_SHOT=1` under opengl3, `screens/staff.png`): a hired trainer/physio/youth coach
over an available pool, `£3,596/wk` reconciling with the three wages, and the live
`+5% dev / −25% injuries / +12% youth` effect readout.

## Automation roles — SCOUT + ASSISTANT MANAGER (T2 #10)
Two roles previously deferred are now hireable from the same pool (they show in CURRENT
STAFF / STAFF AVAILABLE with a role + quality + wage like the others; they carry no `_factor`
multiplier — their effect is a hook):
- **SCOUT** — `Career.scout_targets()` surfaces the best AFFORDABLE league targets, most able
  first, as many as his quality (1-5). A **SCOUT REPORT** entry appears on the transfer desk
  only when a scout is hired; tapping a target opens the bid screen.
- **ASSISTANT MANAGER** — at the season rollover (`advance_season`) he auto-renews an expiring
  player good enough to keep, so your stars don't walk for free unnoticed. His quality lowers
  the CA bar (`keep_ca = 75 - quality*3`: q5 keeps CA≥60, q1 keeps CA≥72); gated on
  affordability, same as the manual auto-renew flag.
Helpers: `Staff.has_scout/scout_quality/has_assistant/assistant_quality`. Test:
`app/tests/test_staff_roles.gd` (roles + wages, scout-report shape, assistant keeps an
expiring star vs a no-assistant control where he leaves). Verified by the `PM98_STAFF_SHOT`
render (Scout + Assistant Manager in the hired team) and a SCOUT REPORT GL capture.
