# Walkthrough frame -> screen manifest (2026-07-02 capture)

Status: GENERATED — rebuild with `python3 tools/re/build_walkthrough_manifest.py`.

Every frame is named by the taught pixel signatures in `tools/re/wine/screens.json`
(the wine auto-driver's own identifier), so a name here is a chrome match against
signatures learned from real frames of that screen — not a guess and not a caption.
This closes the `AUDIT_COMPLETE_2026-07-26.md` gap 'no frame->screen manifest'.

**636 frames at 640x480** (196 identified, 440 UNKNOWN), **2 at another size**.

An UNKNOWN run is not noise: it is either a screen the harness has never been
taught or a state no RE doc has claimed. Teach it with `autodrive.py learn` and
it disappears from this list.

## Frames per screen

| screen | frames |
|---|---|
| `UNKNOWN` | 440 |
| `hub` | 68 |
| `lineup_screen` | 19 |
| `full_time` | 16 |
| `match_options` | 15 |
| `team_offer` | 11 |
| `alert_box` | 10 |
| `half_time` | 9 |
| `finance_screen` | 8 |
| `results_league` | 6 |
| `cup_draw` | 6 |
| `select_level` | 5 |
| `enter_name` | 5 |
| `teams_in_championships` | 4 |
| `title` | 3 |
| `league_tables_final` | 3 |
| `news_extra` | 3 |
| `channel_tv` | 2 |
| `champion_card` | 2 |
| `prematch_lineups` | 1 |

## Not 640x480

| frame | size |
|---|---|
| `Screenshot_2026-07-02_16-24-28.png` | 1920x1080 |
| `Screenshot_2026-07-02_16-24-41.png` | 1920x1080 |

## Citation coverage

**182 of 636 frames are cited by at least one doc under `docs/`** (454 uncited). A frame is counted as cited when a doc names
its stem (`013_164406`) or its index behind a `frame` / `frames` / `witness` /
`run-3` lead-in. The uncited set is where new evidence is cheapest to find: it is
already captured, it is just unread.

## Every frame

| frame | screen | score | cited by |
|---|---|---|---|
| `001_154245.png` | title | 1.000 | — |
| `001_160008.png` | hub | 0.998 | `docs/re/hub_circle_re.md` |
| `001_164222.png` | hub | 0.998 | — |
| `002_154331.png` | UNKNOWN (best title 0.79) | 0.793 | `docs/re/nivel_screen_re.md` |
| `002_162343.png` | UNKNOWN (best match_options 0.07) | 0.075 | `docs/re/nivel_screen_re.md` |
| `002_164241.png` | hub | 0.998 | `docs/re/nivel_screen_re.md` |
| `003_154332.png` | select_level | 1.000 | `docs/re/nivel_screen_re.md` |
| `003_162345.png` | lineup_screen | 1.000 | `docs/re/nivel_screen_re.md` |
| `003_164344.png` | hub | 0.998 | `docs/re/nivel_screen_re.md` |
| `004_154334.png` | select_level | 1.000 | `docs/re/finance_screen_re.md` |
| `004_162346.png` | UNKNOWN (best lineup_screen 0.83) | 0.829 | `docs/re/finance_screen_re.md`, `docs/re/training_screen_re.md` |
| `004_164346.png` | finance_screen | 1.000 | `docs/re/finance_screen_re.md` |
| `005_154338.png` | select_level | 1.000 | `docs/re/nivel_screen_re.md`, `docs/re/savegame_dialog_re.md`, `docs/re/training_screen_re.md` |
| `005_162348.png` | UNKNOWN (best lineup_screen 0.83) | 0.829 | `docs/re/nivel_screen_re.md`, `docs/re/savegame_dialog_re.md`, `docs/re/training_screen_re.md` |
| `005_164347.png` | UNKNOWN (best finance_screen 0.94) | 0.939 | `docs/re/nivel_screen_re.md`, `docs/re/savegame_dialog_re.md`, `docs/re/training_screen_re.md` |
| `006_154340.png` | select_level | 1.000 | `docs/REMAINING.md`, `docs/re/finance_screen_re.md` |
| `006_162350.png` | UNKNOWN (best lineup_screen 0.83) | 0.829 | `docs/REMAINING.md`, `docs/re/finance_screen_re.md`, `docs/re/training_screen_re.md` |
| `006_164349.png` | UNKNOWN (best finance_screen 0.49) | 0.490 | `docs/REMAINING.md`, `docs/re/finance_screen_re.md` |
| `007_154343.png` | select_level | 1.000 | — |
| `007_162352.png` | UNKNOWN (best lineup_screen 0.83) | 0.829 | `docs/re/training_screen_re.md` |
| `007_164351.png` | UNKNOWN (best finance_screen 0.51) | 0.510 | — |
| `008_154345.png` | enter_name | 1.000 | `docs/re/offers_map_re.md`, `docs/re/pretemporada_screen_re.md`, `docs/re/seleccion_screen_re.md` |
| `008_162354.png` | UNKNOWN (best lineup_screen 0.83) | 0.829 | `docs/re/offers_map_re.md`, `docs/re/pretemporada_screen_re.md`, `docs/re/seleccion_screen_re.md`, `docs/re/training_screen_re.md` |
| `008_164357.png` | UNKNOWN (best finance_screen 0.55) | 0.547 | `docs/re/finance_screen_re.md`, `docs/re/offers_map_re.md`, `docs/re/pretemporada_screen_re.md`, `docs/re/seleccion_screen_re.md` |
| `009_154347.png` | enter_name | 1.000 | — |
| `009_162359.png` | UNKNOWN (best lineup_screen 0.83) | 0.829 | — |
| `009_164358.png` | UNKNOWN (best finance_screen 0.59) | 0.587 | — |
| `010_154349.png` | enter_name | 1.000 | `docs/re/match_header_re.md`, `docs/re/seleccion_screen_re.md`, `docs/re/training_screen_re.md` |
| `010_162401.png` | UNKNOWN (best lineup_screen 0.83) | 0.829 | `docs/re/match_header_re.md`, `docs/re/seleccion_screen_re.md`, `docs/re/training_screen_re.md` |
| `010_164400.png` | UNKNOWN (best finance_screen 0.59) | 0.587 | `docs/re/match_header_re.md`, `docs/re/seleccion_screen_re.md`, `docs/re/training_screen_re.md` |
| `011_154354.png` | enter_name | 1.000 | `docs/re/seleccion_screen_re.md` |
| `011_162408.png` | UNKNOWN (best lineup_screen 0.83) | 0.829 | `docs/re/seleccion_screen_re.md` |
| `011_164402.png` | UNKNOWN (best finance_screen 0.59) | 0.587 | `docs/re/seleccion_screen_re.md` |
| `012_154356.png` | enter_name | 1.000 | `docs/re/seleccion_screen_re.md` |
| `012_162410.png` | lineup_screen | 1.000 | `docs/re/seleccion_screen_re.md` |
| `012_164404.png` | UNKNOWN (best finance_screen 0.75) | 0.750 | `docs/re/finance_screen_re.md`, `docs/re/seleccion_screen_re.md` |
| `013_154358.png` | UNKNOWN (best preseason 0.89) | 0.893 | `docs/re/finance_screen_re.md`, `docs/re/pretemporada_screen_re.md` |
| `013_162412.png` | lineup_screen | 1.000 | `docs/re/finance_screen_re.md`, `docs/re/pretemporada_screen_re.md`, `docs/re/tacticas_screen_re.md` |
| `013_164406.png` | finance_screen | 1.000 | `docs/re/finance_screen_re.md`, `docs/re/pretemporada_screen_re.md` |
| `014_154400.png` | UNKNOWN (best preseason 0.89) | 0.893 | `docs/re/club_tactics_re.md`, `docs/re/tacticas_screen_re.md`, `docs/re/tactics_subscreens_re.md` |
| `014_162413.png` | UNKNOWN (best lineup_screen 0.85) | 0.847 | `docs/re/club_tactics_re.md`, `docs/re/match_header_re.md`, `docs/re/tacticas_screen_re.md`, `docs/re/tactics_subscreens_re.md` |
| `014_164407.png` | finance_screen | 1.000 | `docs/re/club_tactics_re.md`, `docs/re/finance_screen_re.md`, `docs/re/tacticas_screen_re.md`, `docs/re/tactics_subscreens_re.md` |
| `015_154401.png` | UNKNOWN (best preseason 0.89) | 0.893 | `docs/re/club_tactics_re.md`, `docs/re/morale_re.md`, `docs/re/offers_map_re.md`, `docs/re/pretemporada_screen_re.md`, `docs/re/rival_screen_re.md` |
| `015_162415.png` | UNKNOWN (best lineup_screen 0.81) | 0.811 | `docs/re/club_tactics_re.md`, `docs/re/match_header_re.md`, `docs/re/morale_re.md`, `docs/re/pretemporada_screen_re.md`, `docs/re/rival_screen_re.md`, `docs/re/tacticas_screen_re.md` |
| `015_164409.png` | hub | 0.998 | `docs/re/club_tactics_re.md`, `docs/re/morale_re.md`, `docs/re/pretemporada_screen_re.md`, `docs/re/rival_screen_re.md` |
| `016_154403.png` | UNKNOWN (best preseason 0.89) | 0.893 | `docs/re/offers_map_re.md` |
| `016_162419.png` | hub | 0.998 | — |
| `016_164411.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `017_154407.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `017_162421.png` | UNKNOWN (best match_options 0.07) | 0.075 | — |
| `017_164413.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `018_154409.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `018_162423.png` | UNKNOWN (best match_options 0.07) | 0.075 | — |
| `018_164415.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `019_154410.png` | UNKNOWN (best preseason 0.89) | 0.893 | `docs/re/dbase_player_card_re.md` |
| `019_162424.png` | UNKNOWN (best match_options 0.07) | 0.075 | `docs/re/dbase_player_card_re.md` |
| `019_164417.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | `docs/re/dbase_player_card_re.md` |
| `020_154412.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `020_162426.png` | UNKNOWN (best match_options 0.07) | 0.075 | — |
| `020_164419.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `021_154414.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `021_162428.png` | UNKNOWN (best match_options 0.07) | 0.075 | — |
| `021_164420.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `022_154416.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `022_162430.png` | UNKNOWN (best match_options 0.07) | 0.075 | — |
| `022_164422.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `023_154418.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `023_162432.png` | match_options | 0.993 | — |
| `023_164424.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `024_154419.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `024_162433.png` | match_options | 0.994 | — |
| `024_164426.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `025_154425.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `025_162435.png` | match_options | 0.994 | — |
| `025_164428.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `026_154427.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `026_162453.png` | match_options | 0.992 | — |
| `026_164429.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `027_154428.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `027_162457.png` | hub | 0.998 | — |
| `027_164431.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `028_154430.png` | UNKNOWN (best preseason 0.89) | 0.893 | — |
| `028_162459.png` | hub | 0.998 | — |
| `028_164433.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `029_154432.png` | teams_in_championships | 1.000 | — |
| `029_162501.png` | hub | 0.998 | — |
| `029_164435.png` | UNKNOWN (best hub 0.61) | 0.610 | — |
| `030_154434.png` | teams_in_championships | 1.000 | — |
| `030_162503.png` | hub | 0.998 | — |
| `030_164437.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `031_154436.png` | teams_in_championships | 1.000 | — |
| `031_162504.png` | hub | 0.998 | — |
| `031_164439.png` | UNKNOWN (best cup_draw 0.14) | 0.143 | — |
| `032_154438.png` | teams_in_championships | 1.000 | — |
| `032_162506.png` | hub | 0.998 | — |
| `032_164441.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `033_154439.png` | hub | 0.998 | — |
| `033_162508.png` | lineup_screen | 1.000 | — |
| `033_164442.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `034_154441.png` | hub | 0.998 | `docs/re/dbase_player_card_re.md`, `docs/re/injuries_screen_re.md`, `docs/re/insurance_economy_re.md` |
| `034_162510.png` | UNKNOWN (best lineup_screen 0.81) | 0.811 | `docs/re/dbase_player_card_re.md`, `docs/re/injuries_screen_re.md`, `docs/re/insurance_economy_re.md` |
| `034_164444.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | `docs/re/dbase_player_card_re.md`, `docs/re/injuries_screen_re.md`, `docs/re/insurance_economy_re.md` |
| `035_154443.png` | hub | 0.998 | — |
| `035_162522.png` | UNKNOWN (best lineup_screen 0.81) | 0.811 | — |
| `035_164446.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `036_154447.png` | hub | 0.998 | — |
| `036_162524.png` | UNKNOWN (best player_of_month 0.87) | 0.867 | — |
| `036_164448.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `037_154450.png` | hub | 0.998 | `docs/re/results_screen_re.md` |
| `037_162526.png` | UNKNOWN (best player_of_month 0.87) | 0.867 | — |
| `037_164450.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `038_154452.png` | results_league | 1.000 | `docs/re/results_screen_re.md` |
| `038_162528.png` | UNKNOWN (best player_of_month 0.87) | 0.867 | `docs/re/results_screen_re.md` |
| `038_164452.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | `docs/re/results_screen_re.md` |
| `039_154454.png` | results_league | 1.000 | `docs/re/results_screen_re.md` |
| `039_162530.png` | UNKNOWN (best lineup_screen 0.81) | 0.811 | `docs/re/injuries_screen_re.md` |
| `039_164454.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `040_154456.png` | results_league | 1.000 | — |
| `040_162531.png` | lineup_screen | 1.000 | `docs/re/match_header_re.md` |
| `040_164455.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `041_154458.png` | results_league | 1.000 | — |
| `041_162533.png` | lineup_screen | 1.000 | — |
| `041_164457.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `042_154459.png` | results_league | 1.000 | `docs/re/statistics_screen_re.md` |
| `042_162537.png` | UNKNOWN (best half_time 0.80) | 0.801 | `docs/re/statistics_screen_re.md` |
| `042_164459.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | `docs/re/statistics_screen_re.md` |
| `043_154501.png` | results_league | 1.000 | `docs/re/results_screen_re.md` |
| `043_162539.png` | UNKNOWN (best half_time 0.80) | 0.801 | — |
| `043_164501.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `044_154503.png` | hub | 0.998 | — |
| `044_162540.png` | UNKNOWN (best half_time 0.80) | 0.801 | `docs/re/statistics_screen_re.md` |
| `044_164503.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `045_154505.png` | league_tables_final | 0.972 | `docs/re/league_table_screen_re.md` |
| `045_162542.png` | UNKNOWN (best half_time 0.80) | 0.801 | `docs/re/league_table_screen_re.md` |
| `045_164505.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | `docs/re/league_table_screen_re.md` |
| `046_154507.png` | league_tables_final | 0.972 | `docs/re/league_table_screen_re.md` |
| `046_162544.png` | hub | 0.998 | — |
| `046_164507.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `047_154510.png` | UNKNOWN (best lineup_screen 0.70) | 0.700 | `docs/re/goalscorers_screen_re.md`, `docs/re/youth_re.md` |
| `047_162546.png` | hub | 0.998 | `docs/re/youth_re.md` |
| `047_164509.png` | UNKNOWN (best lineup_screen 0.74) | 0.744 | `docs/re/youth_re.md` |
| `048_154514.png` | UNKNOWN (best lineup_screen 0.70) | 0.700 | `docs/re/goalscorers_screen_re.md` |
| `048_162548.png` | UNKNOWN (best lineup_screen 0.81) | 0.811 | — |
| `048_164510.png` | UNKNOWN (best lineup_screen 0.74) | 0.744 | `docs/re/youth_re.md` |
| `049_154516.png` | league_tables_final | 0.972 | `docs/re/league_table_screen_re.md` |
| `049_162551.png` | hub | 0.998 | — |
| `049_164512.png` | UNKNOWN (best lineup_screen 0.74) | 0.744 | — |
| `050_154518.png` | hub | 0.998 | `docs/re/fixtures_screen_re.md` |
| `050_162553.png` | hub | 0.998 | `docs/re/fixtures_screen_re.md` |
| `050_164516.png` | UNKNOWN (best lineup_screen 0.74) | 0.744 | `docs/re/fixtures_screen_re.md` |
| `051_154519.png` | UNKNOWN (best full_time 0.70) | 0.698 | `docs/re/fixtures_screen_re.md` |
| `051_162604.png` | hub | 0.998 | `docs/re/fixtures_screen_re.md` |
| `051_164518.png` | UNKNOWN (best lineup_screen 0.74) | 0.744 | `docs/re/fixtures_screen_re.md` |
| `052_154521.png` | UNKNOWN (best full_time 0.70) | 0.698 | — |
| `052_162606.png` | UNKNOWN (best title 0.05) | 0.054 | — |
| `052_164520.png` | UNKNOWN (best lineup_screen 0.74) | 0.744 | — |
| `053_154523.png` | UNKNOWN (best full_time 0.70) | 0.698 | — |
| `053_162608.png` | UNKNOWN (best title 0.06) | 0.059 | — |
| `053_164521.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `054_154525.png` | UNKNOWN (best full_time 0.70) | 0.698 | — |
| `054_162610.png` | UNKNOWN (best title 0.06) | 0.059 | — |
| `054_164525.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `055_154527.png` | hub | 0.998 | `docs/re/fixtures_screen_re.md` |
| `055_162612.png` | prematch_lineups | 1.000 | — |
| `055_164527.png` | hub | 0.998 | — |
| `056_154529.png` | UNKNOWN (best player_of_month 0.70) | 0.698 | — |
| `056_162617.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `056_164529.png` | hub | 0.998 | — |
| `057_154530.png` | UNKNOWN (best player_of_month 0.70) | 0.698 | — |
| `057_162619.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `057_164531.png` | hub | 0.998 | — |
| `058_154532.png` | UNKNOWN (best player_of_month 0.70) | 0.698 | `docs/re/match_header_re.md` |
| `058_162622.png` | UNKNOWN (best hub 0.57) | 0.567 | `docs/re/match_header_re.md` |
| `058_164533.png` | hub | 0.998 | `docs/re/match_header_re.md` |
| `059_154536.png` | UNKNOWN (best hub 0.68) | 0.678 | — |
| `059_162624.png` | UNKNOWN (best hub 0.57) | 0.567 | — |
| `059_164534.png` | half_time | 1.000 | — |
| `060_154538.png` | UNKNOWN (best hub 0.68) | 0.678 | — |
| `060_162626.png` | UNKNOWN (best hub 0.57) | 0.567 | — |
| `060_164536.png` | half_time | 1.000 | — |
| `061_154539.png` | UNKNOWN (best player_of_month 0.70) | 0.698 | — |
| `061_162628.png` | UNKNOWN (best hub 0.57) | 0.567 | — |
| `061_164538.png` | half_time | 1.000 | — |
| `062_154541.png` | UNKNOWN (best lineup_screen 0.84) | 0.843 | `docs/re/dbase_player_card_re.md` |
| `062_162630.png` | UNKNOWN (best hub 0.57) | 0.567 | `docs/re/dbase_player_card_re.md` |
| `062_164540.png` | half_time | 1.000 | `docs/re/dbase_player_card_re.md` |
| `063_154543.png` | UNKNOWN (best lineup_screen 0.84) | 0.843 | — |
| `063_162631.png` | UNKNOWN (best hub 0.57) | 0.567 | — |
| `063_164542.png` | half_time | 1.000 | — |
| `064_154545.png` | UNKNOWN (best lineup_screen 0.84) | 0.843 | — |
| `064_162633.png` | UNKNOWN (best hub 0.57) | 0.567 | — |
| `064_164544.png` | full_time | 1.000 | — |
| `065_154547.png` | UNKNOWN (best player_of_month 0.70) | 0.698 | — |
| `065_162635.png` | UNKNOWN (best hub 0.57) | 0.567 | — |
| `065_164546.png` | full_time | 1.000 | — |
| `066_154548.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | `docs/re/finance_screen_re.md` |
| `066_162637.png` | UNKNOWN (best hub 0.57) | 0.567 | `docs/re/finance_screen_re.md` |
| `066_164547.png` | hub | 0.998 | `docs/re/finance_screen_re.md` |
| `067_154552.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `067_162639.png` | UNKNOWN (best hub 0.57) | 0.567 | — |
| `067_164549.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `068_154556.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `068_162640.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `068_164551.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `069_154557.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `069_162642.png` | UNKNOWN (best half_time 0.80) | 0.801 | `docs/re/statistics_screen_re.md` |
| `069_164558.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `070_154559.png` | UNKNOWN (best news_extra 0.24) | 0.245 | — |
| `070_162644.png` | UNKNOWN (best half_time 0.80) | 0.801 | — |
| `070_164610.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `071_154601.png` | UNKNOWN (best news_extra 0.24) | 0.245 | — |
| `071_162646.png` | UNKNOWN (best half_time 0.80) | 0.801 | — |
| `071_164611.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `072_154603.png` | UNKNOWN (best news_extra 0.24) | 0.245 | — |
| `072_162648.png` | UNKNOWN (best half_time 0.80) | 0.801 | — |
| `072_164617.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `073_154605.png` | UNKNOWN (best news_extra 0.24) | 0.245 | `docs/re/match_flow_re.md` |
| `073_162649.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | `docs/re/match_flow_re.md` |
| `073_164619.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | `docs/re/match_flow_re.md` |
| `074_154606.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `074_162651.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `074_164623.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `075_154608.png` | UNKNOWN (best player_of_month 0.70) | 0.698 | — |
| `075_162653.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `075_164624.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `076_154610.png` | hub | 0.998 | — |
| `076_162655.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `076_164626.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `077_154612.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | `docs/re/APP_VS_SPEC_AUDIT.md`, `docs/re/squad_number_re.md`, `docs/re/squad_screen_re.md`, `docs/re/transfer_loop_live_re.md` |
| `077_162657.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | `docs/re/squad_number_re.md`, `docs/re/squad_screen_re.md`, `docs/re/transfer_loop_live_re.md` |
| `077_164630.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | `docs/re/squad_number_re.md`, `docs/re/squad_screen_re.md`, `docs/re/transfer_loop_live_re.md` |
| `078_154614.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `078_162658.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `078_164632.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `079_154615.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `079_162700.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `079_164634.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `080_154617.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `080_162702.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `080_164636.png` | alert_box | 1.000 | — |
| `081_154619.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | `docs/re/club_tactics_re.md`, `docs/re/ficha_card_re.md`, `docs/re/morale_re.md`, `docs/re/player_info_re.md` |
| `081_162704.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | `docs/re/club_tactics_re.md`, `docs/re/ficha_card_re.md`, `docs/re/morale_re.md`, `docs/re/player_info_re.md` |
| `081_164637.png` | alert_box | 1.000 | `docs/re/club_tactics_re.md`, `docs/re/ficha_card_re.md`, `docs/re/morale_re.md`, `docs/re/player_info_re.md` |
| `082_154621.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `082_162706.png` | UNKNOWN (best cup_draw 0.09) | 0.095 | — |
| `082_164639.png` | hub | 0.998 | — |
| `083_154624.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `083_162707.png` | full_time | 1.000 | `docs/re/match_flow_re.md` |
| `083_164641.png` | hub | 0.998 | — |
| `084_154626.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | `docs/re/player_info_re.md` |
| `084_162709.png` | hub | 0.998 | — |
| `084_164643.png` | half_time | 1.000 | — |
| `085_154628.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | `docs/re/transfer_loop_live_re.md` |
| `085_162713.png` | hub | 0.998 | `docs/re/transfer_loop_live_re.md` |
| `085_164645.png` | full_time | 1.000 | `docs/re/transfer_loop_live_re.md` |
| `086_154630.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | `docs/re/APP_VS_SPEC_AUDIT.md`, `docs/re/team_offer_re.md` |
| `086_162715.png` | UNKNOWN (best match_options 0.09) | 0.089 | `docs/re/APP_VS_SPEC_AUDIT.md`, `docs/re/team_offer_re.md` |
| `086_164647.png` | team_offer | 1.000 | `docs/re/APP_VS_SPEC_AUDIT.md`, `docs/re/team_offer_re.md` |
| `087_154632.png` | UNKNOWN (best lineup_screen 0.74) | 0.744 | `docs/re/youth_re.md` |
| `087_162717.png` | match_options | 0.994 | `docs/re/youth_re.md` |
| `087_164648.png` | team_offer | 1.000 | `docs/re/team_offer_re.md`, `docs/re/youth_re.md` |
| `088_154633.png` | UNKNOWN (best lineup_screen 0.74) | 0.744 | `docs/re/youth_re.md` |
| `088_162718.png` | match_options | 0.978 | — |
| `088_164650.png` | team_offer | 1.000 | `docs/re/team_offer_re.md` |
| `089_154635.png` | UNKNOWN (best lineup_screen 0.74) | 0.744 | `docs/re/youth_re.md` |
| `089_162720.png` | match_options | 0.983 | — |
| `089_164652.png` | team_offer | 1.000 | `docs/re/team_offer_re.md` |
| `090_154637.png` | UNKNOWN (best player_of_month 0.73) | 0.728 | — |
| `090_162722.png` | match_options | 0.988 | — |
| `090_164654.png` | team_offer | 1.000 | `docs/re/team_offer_re.md` |
| `091_154639.png` | hub | 0.998 | — |
| `091_162726.png` | UNKNOWN (best match_options 0.82) | 0.823 | — |
| `091_164656.png` | team_offer | 1.000 | `docs/re/team_offer_re.md` |
| `092_154641.png` | UNKNOWN (best hub 0.69) | 0.686 | — |
| `092_162727.png` | UNKNOWN (best match_options 0.82) | 0.819 | — |
| `092_164658.png` | team_offer | 1.000 | — |
| `093_154642.png` | UNKNOWN (best hub 0.69) | 0.686 | `docs/re/team_offer_re.md` |
| `093_162729.png` | UNKNOWN (best match_options 0.82) | 0.818 | `docs/re/team_offer_re.md` |
| `093_164659.png` | alert_box | 1.000 | `docs/re/alert_box_re.md`, `docs/re/team_offer_re.md` |
| `094_154646.png` | UNKNOWN (best player_of_month 0.35) | 0.350 | — |
| `094_162731.png` | UNKNOWN (best match_options 0.94) | 0.940 | — |
| `094_164701.png` | hub | 0.998 | — |
| `095_154648.png` | UNKNOWN (best player_of_month 0.35) | 0.350 | `docs/re/staff_re.md` |
| `095_162733.png` | UNKNOWN (best match_options 0.81) | 0.812 | `docs/re/staff_re.md` |
| `095_164703.png` | hub | 0.998 | `docs/re/staff_re.md` |
| `096_154650.png` | UNKNOWN (best player_of_month 0.37) | 0.366 | — |
| `096_162735.png` | UNKNOWN (best match_options 0.82) | 0.823 | — |
| `096_164705.png` | hub | 0.998 | — |
| `097_154651.png` | UNKNOWN (best player_of_month 0.37) | 0.366 | `docs/re/transfer_screen_re.md` |
| `097_162736.png` | UNKNOWN (best match_options 0.81) | 0.812 | `docs/re/transfer_screen_re.md` |
| `097_164707.png` | UNKNOWN (best player_of_month 0.70) | 0.698 | `docs/re/transfer_screen_re.md` |
| `098_154653.png` | UNKNOWN (best player_of_month 0.37) | 0.366 | — |
| `098_162738.png` | UNKNOWN (best match_options 0.82) | 0.818 | — |
| `098_164709.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | `docs/re/offers_map_re.md` |
| `099_154655.png` | UNKNOWN (best player_of_month 0.37) | 0.366 | — |
| `099_162742.png` | UNKNOWN (best match_options 0.81) | 0.814 | — |
| `099_164711.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | `docs/re/offers_map_re.md` |
| `100_154657.png` | UNKNOWN (best player_of_month 0.37) | 0.366 | `docs/re/offers_map_re.md`, `docs/re/scout_screen_re.md`, `docs/re/staff_re.md` |
| `100_162745.png` | UNKNOWN (best match_options 0.94) | 0.940 | `docs/re/offers_map_re.md`, `docs/re/staff_re.md` |
| `100_164712.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | `docs/re/make_offer_re.md`, `docs/re/offers_map_re.md`, `docs/re/staff_re.md` |
| `101_154659.png` | UNKNOWN (best player_of_month 0.37) | 0.366 | `docs/re/make_offer_re.md` |
| `101_162747.png` | UNKNOWN (best match_options 0.95) | 0.952 | `docs/re/make_offer_re.md` |
| `101_164714.png` | UNKNOWN (best news_extra 0.24) | 0.241 | `docs/re/make_offer_re.md` |
| `102_154700.png` | UNKNOWN (best player_of_month 0.37) | 0.366 | — |
| `102_162749.png` | hub | 0.998 | — |
| `102_164716.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `103_154702.png` | UNKNOWN (best player_of_month 0.37) | 0.366 | `docs/re/staff_re.md` |
| `103_162751.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | `docs/re/staff_re.md` |
| `103_164718.png` | UNKNOWN (best news_extra 0.24) | 0.241 | `docs/re/staff_re.md` |
| `104_154704.png` | UNKNOWN (best player_of_month 0.37) | 0.366 | — |
| `104_162753.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `104_164720.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `105_154706.png` | UNKNOWN (best player_of_month 0.37) | 0.366 | — |
| `105_162754.png` | UNKNOWN (best cup_draw 0.13) | 0.133 | — |
| `105_164722.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `106_154708.png` | UNKNOWN (best player_of_month 0.34) | 0.343 | — |
| `106_162756.png` | UNKNOWN (best player_of_month 0.18) | 0.181 | — |
| `106_164724.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `107_154709.png` | UNKNOWN (best player_of_month 0.43) | 0.426 | — |
| `107_162758.png` | UNKNOWN (best player_of_month 0.18) | 0.181 | — |
| `107_164725.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `108_154711.png` | UNKNOWN (best player_of_month 0.43) | 0.426 | — |
| `108_162800.png` | UNKNOWN (best finance_screen 0.06) | 0.057 | — |
| `108_164727.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `109_154715.png` | UNKNOWN (best player_of_month 0.43) | 0.426 | — |
| `109_162802.png` | UNKNOWN (best finance_screen 0.07) | 0.072 | — |
| `109_164729.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `110_154717.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | `docs/re/staff_re.md` |
| `110_162804.png` | UNKNOWN (best finance_screen 0.13) | 0.131 | `docs/re/staff_re.md` |
| `110_164731.png` | UNKNOWN (best news_extra 0.24) | 0.241 | `docs/re/staff_re.md` |
| `111_154718.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | — |
| `111_162805.png` | UNKNOWN (best finance_screen 0.21) | 0.206 | — |
| `111_164733.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `112_154720.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | — |
| `112_162807.png` | UNKNOWN (best finance_screen 0.31) | 0.312 | — |
| `112_164735.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `113_154722.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | `docs/re/staff_re.md` |
| `113_162809.png` | UNKNOWN (best finance_screen 0.19) | 0.192 | `docs/re/staff_re.md` |
| `113_164736.png` | UNKNOWN (best news_extra 0.24) | 0.241 | `docs/re/staff_re.md` |
| `114_154724.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | `docs/re/staff_re.md` |
| `114_162811.png` | UNKNOWN (best finance_screen 0.14) | 0.135 | `docs/re/staff_re.md` |
| `114_164738.png` | UNKNOWN (best news_extra 0.24) | 0.241 | `docs/re/staff_re.md` |
| `115_154726.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | `docs/re/staff_re.md` |
| `115_162813.png` | UNKNOWN (best finance_screen 0.07) | 0.070 | `docs/re/staff_re.md` |
| `115_164740.png` | UNKNOWN (best news_extra 0.24) | 0.241 | `docs/re/staff_re.md` |
| `116_154727.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | — |
| `116_162814.png` | UNKNOWN (best finance_screen 0.13) | 0.128 | — |
| `116_164742.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `117_154729.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | — |
| `117_162816.png` | UNKNOWN (best finance_screen 0.12) | 0.124 | — |
| `117_164744.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `118_154731.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | — |
| `118_162818.png` | UNKNOWN (best player_of_month 0.07) | 0.074 | — |
| `118_164746.png` | UNKNOWN (best news_extra 0.24) | 0.241 | — |
| `119_154733.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | — |
| `119_162820.png` | UNKNOWN (best results_league 0.10) | 0.103 | — |
| `119_164747.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | `docs/re/offers_map_re.md` |
| `120_154734.png` | UNKNOWN (best player_of_month 0.44) | 0.441 | — |
| `120_162822.png` | UNKNOWN (best finance_screen 0.06) | 0.057 | — |
| `120_164749.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `121_154736.png` | UNKNOWN (best hub 0.69) | 0.686 | `docs/re/APP_VS_SPEC_AUDIT.md`, `docs/re/staff_re.md` |
| `121_162824.png` | UNKNOWN (best finance_screen 0.06) | 0.061 | `docs/re/APP_VS_SPEC_AUDIT.md`, `docs/re/staff_re.md` |
| `121_164751.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | `docs/re/APP_VS_SPEC_AUDIT.md`, `docs/re/staff_re.md` |
| `122_154740.png` | UNKNOWN (best hub 0.69) | 0.686 | — |
| `122_162825.png` | UNKNOWN (best news_extra 0.10) | 0.099 | — |
| `122_164753.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `123_154742.png` | hub | 0.998 | — |
| `123_162827.png` | UNKNOWN (best finance_screen 0.42) | 0.421 | — |
| `123_164755.png` | UNKNOWN (best news_extra 0.25) | 0.248 | — |
| `124_154744.png` | UNKNOWN (best hub 0.69) | 0.686 | — |
| `124_162829.png` | UNKNOWN (best finance_screen 0.24) | 0.238 | — |
| `124_164757.png` | UNKNOWN (best news_extra 0.25) | 0.248 | — |
| `125_154745.png` | UNKNOWN (best hub 0.69) | 0.686 | — |
| `125_162831.png` | UNKNOWN (best finance_screen 0.47) | 0.472 | — |
| `125_164759.png` | UNKNOWN (best player_of_month 0.22) | 0.224 | — |
| `126_154747.png` | UNKNOWN (best hub 0.69) | 0.686 | — |
| `126_162833.png` | UNKNOWN (best finance_screen 0.47) | 0.472 | — |
| `126_164800.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `127_154749.png` | hub | 0.998 | — |
| `127_162834.png` | UNKNOWN (best finance_screen 0.34) | 0.341 | — |
| `127_164802.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `128_154751.png` | lineup_screen | 1.000 | `docs/re/lineup_screen_re.md`, `docs/re/match_header_re.md`, `docs/re/morale_re.md` |
| `128_162836.png` | UNKNOWN (best select_level 0.31) | 0.310 | `docs/re/lineup_screen_re.md`, `docs/re/morale_re.md` |
| `128_164804.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | `docs/re/lineup_screen_re.md`, `docs/re/morale_re.md` |
| `129_154753.png` | lineup_screen | 1.000 | — |
| `129_162838.png` | UNKNOWN (best finance_screen 0.13) | 0.133 | — |
| `129_164806.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `130_154758.png` | lineup_screen | 1.000 | — |
| `130_162840.png` | UNKNOWN (best finance_screen 0.34) | 0.345 | — |
| `130_164808.png` | UNKNOWN (best news_extra 0.24) | 0.245 | — |
| `131_154800.png` | lineup_screen | 1.000 | — |
| `131_162842.png` | UNKNOWN (best finance_screen 0.45) | 0.451 | — |
| `131_164810.png` | UNKNOWN (best news_extra 0.24) | 0.245 | — |
| `132_154802.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `132_162844.png` | UNKNOWN (best finance_screen 0.45) | 0.448 | — |
| `132_164812.png` | UNKNOWN (best news_extra 0.24) | 0.245 | — |
| `133_154803.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `133_162845.png` | UNKNOWN (best finance_screen 0.47) | 0.472 | — |
| `133_164813.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `134_154805.png` | UNKNOWN (best player_of_month 0.27) | 0.266 | — |
| `134_162847.png` | UNKNOWN (best finance_screen 0.46) | 0.459 | — |
| `134_164815.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `135_154807.png` | UNKNOWN (best cup_draw 0.07) | 0.072 | — |
| `135_162849.png` | UNKNOWN (best select_level 0.28) | 0.276 | — |
| `135_164817.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `136_154809.png` | lineup_screen | 1.000 | — |
| `136_162851.png` | UNKNOWN (best finance_screen 0.12) | 0.120 | — |
| `136_164819.png` | UNKNOWN (best news_extra 0.23) | 0.235 | — |
| `137_154812.png` | hub | 0.998 | — |
| `137_162853.png` | UNKNOWN (best results_league 0.09) | 0.086 | — |
| `137_164821.png` | UNKNOWN (best news_extra 0.23) | 0.235 | — |
| `138_154814.png` | UNKNOWN (best lineup_screen 0.85) | 0.847 | `docs/re/match_header_re.md` |
| `138_162855.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `138_164823.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `139_154818.png` | UNKNOWN (best lineup_screen 0.85) | 0.847 | — |
| `139_162856.png` | UNKNOWN (best finance_screen 0.10) | 0.105 | — |
| `139_164824.png` | UNKNOWN (best lineup_screen 0.84) | 0.839 | — |
| `140_154820.png` | UNKNOWN (best cup_draw 0.20) | 0.203 | `docs/re/tactics_subscreens_re.md` |
| `140_162858.png` | UNKNOWN (best finance_screen 0.18) | 0.179 | `docs/re/tactics_subscreens_re.md` |
| `140_164826.png` | hub | 0.998 | `docs/re/tactics_subscreens_re.md` |
| `141_154821.png` | UNKNOWN (best cup_draw 0.20) | 0.203 | — |
| `141_162900.png` | UNKNOWN (best finance_screen 0.10) | 0.105 | — |
| `141_164828.png` | half_time | 1.000 | — |
| `142_154825.png` | UNKNOWN (best cup_draw 0.20) | 0.203 | `docs/re/tactics_subscreens_re.md` |
| `142_162902.png` | UNKNOWN (best results_league 0.10) | 0.103 | `docs/re/tactics_subscreens_re.md` |
| `142_164830.png` | full_time | 1.000 | `docs/re/tactics_subscreens_re.md` |
| `143_154828.png` | UNKNOWN (best cup_draw 0.20) | 0.203 | — |
| `143_162904.png` | UNKNOWN (best finance_screen 0.06) | 0.061 | — |
| `143_164832.png` | cup_draw | 0.989 | — |
| `144_154830.png` | UNKNOWN (best lineup_screen 0.85) | 0.847 | — |
| `144_162905.png` | UNKNOWN (best finance_screen 0.07) | 0.070 | — |
| `144_164834.png` | cup_draw | 0.989 | — |
| `145_154836.png` | lineup_screen | 1.000 | — |
| `145_162907.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `145_164836.png` | cup_draw | 0.989 | — |
| `146_154837.png` | lineup_screen | 1.000 | — |
| `146_162909.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `146_164837.png` | cup_draw | 0.997 | — |
| `147_154839.png` | UNKNOWN (best half_time 0.80) | 0.801 | `docs/re/statistics_screen_re.md` |
| `147_162911.png` | UNKNOWN (best finance_screen 0.09) | 0.093 | — |
| `147_164839.png` | cup_draw | 1.000 | — |
| `148_154843.png` | UNKNOWN (best half_time 0.80) | 0.801 | — |
| `148_162913.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `148_164909.png` | cup_draw | 1.000 | — |
| `149_154845.png` | UNKNOWN (best half_time 0.80) | 0.801 | — |
| `149_162915.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `149_164911.png` | alert_box | 1.000 | `docs/re/alert_box_re.md` |
| `150_154846.png` | hub | 0.998 | — |
| `150_162916.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `150_164913.png` | team_offer | 1.000 | — |
| `151_154848.png` | UNKNOWN (best lineup_screen 0.81) | 0.811 | — |
| `151_162918.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `151_164914.png` | team_offer | 1.000 | — |
| `152_154852.png` | UNKNOWN (best lineup_screen 0.81) | 0.811 | `docs/re/PLAN_byte_exact_match_engine.md` |
| `152_162920.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | `docs/re/PLAN_byte_exact_match_engine.md` |
| `152_164916.png` | team_offer | 1.000 | `docs/re/PLAN_byte_exact_match_engine.md` |
| `153_154854.png` | hub | 0.998 | — |
| `153_162922.png` | UNKNOWN (best finance_screen 0.37) | 0.368 | — |
| `153_164920.png` | team_offer | 1.000 | — |
| `154_154856.png` | hub | 0.998 | — |
| `154_162924.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `154_164922.png` | alert_box | 1.000 | — |
| `155_154857.png` | news_extra | 1.000 | `docs/re/lineup_screen_re.md`, `docs/re/morale_re.md`, `docs/re/news_screen_re.md` |
| `155_162931.png` | lineup_screen | 1.000 | `docs/re/lineup_screen_re.md`, `docs/re/match_header_re.md`, `docs/re/morale_re.md` |
| `155_164924.png` | hub | 0.998 | `docs/re/lineup_screen_re.md`, `docs/re/morale_re.md` |
| `156_154859.png` | news_extra | 1.000 | `docs/re/news_screen_re.md` |
| `156_162933.png` | lineup_screen | 1.000 | — |
| `156_164926.png` | hub | 0.998 | — |
| `157_154901.png` | news_extra | 1.000 | `docs/re/news_screen_re.md` |
| `157_162934.png` | lineup_screen | 1.000 | — |
| `157_164927.png` | finance_screen | 1.000 | — |
| `158_154905.png` | UNKNOWN (best player_of_month 0.53) | 0.531 | `docs/re/news_screen_re.md` |
| `158_162936.png` | lineup_screen | 1.000 | — |
| `158_164931.png` | UNKNOWN (best finance_screen 0.55) | 0.550 | — |
| `159_154906.png` | hub | 0.998 | — |
| `159_162938.png` | lineup_screen | 1.000 | — |
| `159_164935.png` | UNKNOWN (best finance_screen 0.55) | 0.550 | — |
| `160_154908.png` | finance_screen | 1.000 | `docs/re/PLAN_byte_exact_match_engine.md` |
| `160_162940.png` | lineup_screen | 1.000 | `docs/re/PLAN_byte_exact_match_engine.md` |
| `160_164937.png` | hub | 0.998 | `docs/re/PLAN_byte_exact_match_engine.md` |
| `161_154910.png` | finance_screen | 1.000 | — |
| `161_162942.png` | UNKNOWN (best finance_screen 0.52) | 0.524 | — |
| `162_154912.png` | finance_screen | 1.000 | — |
| `162_162944.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `163_154914.png` | finance_screen | 1.000 | `docs/re/PLAN_byte_exact_match_engine.md` |
| `163_162946.png` | UNKNOWN (best finance_screen 0.12) | 0.118 | `docs/re/PLAN_byte_exact_match_engine.md` |
| `164_154915.png` | hub | 0.998 | — |
| `164_162948.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `165_154917.png` | hub | 0.998 | — |
| `165_162949.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `166_154919.png` | UNKNOWN (best hub 0.58) | 0.575 | — |
| `166_162951.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `167_154921.png` | UNKNOWN (best hub 0.58) | 0.575 | `docs/re/directiva_screen_re.md`, `docs/re/promanager_career_screens_re.md` |
| `167_162953.png` | UNKNOWN (best finance_screen 0.08) | 0.080 | `docs/re/directiva_screen_re.md`, `docs/re/promanager_career_screens_re.md` |
| `168_154923.png` | UNKNOWN (best hub 0.58) | 0.575 | `docs/re/directiva_screen_re.md` |
| `168_162955.png` | UNKNOWN (best finance_screen 0.06) | 0.057 | — |
| `169_154924.png` | UNKNOWN (best hub 0.58) | 0.575 | `docs/re/directiva_screen_re.md` |
| `169_162957.png` | UNKNOWN (best finance_screen 0.06) | 0.063 | — |
| `170_154926.png` | hub | 0.998 | `docs/re/stadium_screen_re.md` |
| `170_162959.png` | UNKNOWN (best finance_screen 0.18) | 0.181 | — |
| `171_154928.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `171_163001.png` | UNKNOWN (best finance_screen 0.06) | 0.063 | — |
| `172_154930.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | `docs/re/stadium_screen_re.md` |
| `172_163003.png` | UNKNOWN (best finance_screen 0.06) | 0.063 | `docs/re/stadium_screen_re.md` |
| `173_154935.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | `docs/re/stadium_screen_re.md` |
| `173_163005.png` | UNKNOWN (best finance_screen 0.06) | 0.061 | `docs/re/stadium_screen_re.md` |
| `174_154939.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `174_163007.png` | UNKNOWN (best finance_screen 0.41) | 0.410 | — |
| `175_154941.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | `docs/re/stadium_screen_re.md` |
| `175_163009.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `176_154943.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `176_163011.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `177_154948.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `177_163013.png` | UNKNOWN (best finance_screen 0.06) | 0.063 | — |
| `178_154950.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `178_163015.png` | UNKNOWN (best player_of_month 0.18) | 0.179 | — |
| `179_154952.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `179_163017.png` | UNKNOWN (best player_of_month 0.07) | 0.069 | — |
| `180_154953.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `180_163018.png` | UNKNOWN (best finance_screen 0.06) | 0.059 | — |
| `181_154955.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `181_163020.png` | UNKNOWN (best finance_screen 0.06) | 0.059 | — |
| `182_154957.png` | alert_box | 1.000 | — |
| `182_163022.png` | UNKNOWN (best finance_screen 0.19) | 0.187 | — |
| `183_155003.png` | hub | 0.998 | — |
| `183_163024.png` | UNKNOWN (best finance_screen 0.06) | 0.063 | — |
| `184_155004.png` | UNKNOWN (best lineup_screen 0.81) | 0.807 | — |
| `184_163026.png` | UNKNOWN (best results_league 0.16) | 0.155 | — |
| `185_155006.png` | hub | 0.998 | — |
| `185_163028.png` | UNKNOWN (best finance_screen 0.07) | 0.067 | — |
| `186_155008.png` | hub | 0.998 | — |
| `186_163030.png` | UNKNOWN (best results_league 0.09) | 0.086 | — |
| `187_155010.png` | hub | 0.998 | — |
| `187_163031.png` | UNKNOWN (best results_league 0.14) | 0.138 | — |
| `188_155014.png` | UNKNOWN (best match_options 0.07) | 0.075 | — |
| `188_163033.png` | UNKNOWN (best finance_screen 0.06) | 0.063 | — |
| `189_155015.png` | match_options | 0.996 | — |
| `189_163035.png` | UNKNOWN (best results_league 0.09) | 0.086 | — |
| `190_155019.png` | match_options | 0.995 | — |
| `190_163037.png` | UNKNOWN (best finance_screen 0.47) | 0.467 | — |
| `191_155021.png` | match_options | 0.996 | — |
| `191_163039.png` | UNKNOWN (best finance_screen 0.48) | 0.478 | — |
| `192_155023.png` | match_options | 0.994 | — |
| `192_163041.png` | UNKNOWN (best finance_screen 0.46) | 0.461 | — |
| `193_155024.png` | match_options | 0.972 | — |
| `193_163043.png` | UNKNOWN (best results_league 0.28) | 0.276 | — |
| `194_155026.png` | hub | 0.998 | — |
| `194_163044.png` | UNKNOWN (best player_of_month 0.06) | 0.059 | — |
| `195_155028.png` | half_time | 1.000 | — |
| `195_163046.png` | UNKNOWN (best finance_screen 0.05) | 0.053 | — |
| `196_155032.png` | half_time | 1.000 | — |
| `196_163048.png` | UNKNOWN (best finance_screen 0.07) | 0.072 | — |
| `197_155033.png` | full_time | 1.000 | — |
| `197_163050.png` | UNKNOWN (best finance_screen 0.05) | 0.048 | — |
| `198_155035.png` | full_time | 1.000 | — |
| `198_163052.png` | UNKNOWN (best finance_screen 0.37) | 0.366 | — |
| `199_155037.png` | full_time | 1.000 | — |
| `199_163054.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `200_155039.png` | full_time | 1.000 | — |
| `200_163056.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `201_155041.png` | full_time | 1.000 | — |
| `201_163057.png` | UNKNOWN (best finance_screen 0.07) | 0.074 | — |
| `202_155043.png` | channel_tv | 1.000 | — |
| `202_163059.png` | UNKNOWN (best player_of_month 0.18) | 0.179 | — |
| `203_155044.png` | channel_tv | 1.000 | — |
| `203_163101.png` | UNKNOWN (best player_of_month 0.18) | 0.179 | — |
| `204_155050.png` | UNKNOWN (best match_options 0.04) | 0.037 | — |
| `204_163103.png` | UNKNOWN (best finance_screen 0.05) | 0.048 | — |
| `205_155052.png` | alert_box | 1.000 | — |
| `205_163105.png` | UNKNOWN (best finance_screen 0.06) | 0.055 | — |
| `206_155053.png` | alert_box | 1.000 | — |
| `206_163107.png` | UNKNOWN (best finance_screen 0.05) | 0.048 | — |
| `207_155055.png` | hub | 0.998 | — |
| `207_163108.png` | UNKNOWN (best finance_screen 0.06) | 0.065 | — |
| `208_155057.png` | UNKNOWN (best match_options 0.09) | 0.086 | — |
| `208_163110.png` | UNKNOWN (best finance_screen 0.05) | 0.048 | — |
| `209_155059.png` | match_options | 0.994 | — |
| `209_163112.png` | UNKNOWN (best finance_screen 0.05) | 0.051 | — |
| `210_155101.png` | match_options | 0.990 | — |
| `210_163114.png` | UNKNOWN (best finance_screen 0.05) | 0.048 | — |
| `211_155103.png` | hub | 0.998 | — |
| `211_163116.png` | UNKNOWN (best finance_screen 0.08) | 0.084 | — |
| `212_155104.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `212_163118.png` | UNKNOWN (best finance_screen 0.05) | 0.053 | — |
| `213_155106.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `213_163120.png` | UNKNOWN (best finance_screen 0.05) | 0.053 | — |
| `214_155108.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `214_163121.png` | UNKNOWN (best finance_screen 0.05) | 0.048 | — |
| `215_155110.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `215_163123.png` | UNKNOWN (best finance_screen 0.05) | 0.048 | — |
| `216_155112.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `216_163125.png` | UNKNOWN (best finance_screen 0.05) | 0.048 | — |
| `217_155113.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `217_163127.png` | UNKNOWN (best finance_screen 0.05) | 0.048 | — |
| `218_155115.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `218_163129.png` | UNKNOWN (best team_offer 0.08) | 0.084 | — |
| `219_155117.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `219_163131.png` | UNKNOWN (best finance_screen 0.07) | 0.074 | — |
| `220_155119.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `220_163133.png` | UNKNOWN (best finance_screen 0.07) | 0.069 | — |
| `221_155121.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `221_163134.png` | UNKNOWN (best select_level 0.05) | 0.052 | — |
| `222_155122.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `222_163136.png` | UNKNOWN (best results_league 0.17) | 0.172 | — |
| `223_155124.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `223_163138.png` | UNKNOWN (best finance_screen 0.06) | 0.063 | — |
| `224_155126.png` | UNKNOWN (best cup_draw 0.08) | 0.080 | — |
| `224_163140.png` | UNKNOWN (best results_league 0.24) | 0.241 | — |
| `225_155128.png` | UNKNOWN (best cup_draw 0.08) | 0.077 | — |
| `225_163142.png` | UNKNOWN (best finance_screen 0.15) | 0.147 | — |
| `226_155130.png` | UNKNOWN (best cup_draw 0.08) | 0.080 | — |
| `226_163144.png` | UNKNOWN (best finance_screen 0.30) | 0.305 | — |
| `227_155131.png` | full_time | 1.000 | — |
| `227_163146.png` | UNKNOWN (best player_of_month 0.07) | 0.069 | — |
| `228_155133.png` | full_time | 1.000 | — |
| `228_163147.png` | UNKNOWN (best finance_screen 0.14) | 0.145 | — |
| `229_155135.png` | full_time | 1.000 | — |
| `229_163149.png` | UNKNOWN (best cup_draw 0.09) | 0.092 | — |
| `230_155137.png` | full_time | 1.000 | — |
| `230_163151.png` | UNKNOWN (best match_options 0.10) | 0.097 | — |
| `231_155139.png` | full_time | 1.000 | — |
| `231_163153.png` | alert_box | 1.000 | — |
| `232_155141.png` | full_time | 1.000 | — |
| `232_163155.png` | title | 1.000 | — |
| `233_155142.png` | champion_card | 1.000 | — |
| `233_163157.png` | title | 1.000 | — |
| `234_155144.png` | champion_card | 1.000 | — |
| `235_155148.png` | UNKNOWN (best results_euroleague 0.67) | 0.673 | — |
| `236_155150.png` | hub | 0.998 | — |
| `237_155151.png` | hub | 0.998 | — |
| `238_155153.png` | hub | 0.998 | — |
| `239_155155.png` | hub | 0.998 | — |
| `240_155157.png` | hub | 0.998 | — |
| `241_155159.png` | hub | 0.998 | — |
| `242_155200.png` | alert_box | 1.000 | — |
| `243_155202.png` | hub | 0.998 | — |
