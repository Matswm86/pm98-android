# RE doc status index

Status: GENERATED — rebuild with `python3 tools/re/build_status_index.py`.

`docs/REMAINING.md` used to delegate per-screen truth to each doc's own `Status:`
line — and most docs do not carry one, so for most screens it pointed at nothing.
Since 2026-08-01 it delegates HERE instead: for every doc, the artefacts that can
CONFIRM it, each of them checkable, and none of them a sentence someone guessed.

* **137 docs**, 23 with a `Status:` line of their own.
* **37** are covered by a `diff_*_parity.py` render-diff gate — the
  strongest evidence here, since a gate compares the app to a captured frame.
* **67** have a headless `test_*.gd` suite; **95** cite MANAGER.EXE
  addresses, i.e. their claims are anchored in the binary and not only in frames.
* **29** name their proof directly on an `Evidence:` line — for the plans,
  audits and M5 session notes, whose evidence is a banked capture, an oracle
  runner or a witness directory rather than a screen gate. Every path on those
  lines is checked to exist by this script.
* **0** have none of the four. That is the audit's real backlog: not the
  missing sentence, the missing evidence.

`open` counts a doc's OWN gap flags (`un-RE'd`, `unwitnessed`, `declared`, `OURS`,
`inference`, ...). A high count is honesty, not debt — the docs that declare
nothing are the ones to distrust.

| doc | own Status: | gate | suite | scene | EXE addrs | evidence | open |
|---|---|---|---|---|---|---|---|
| `APP_VS_SPEC_AUDIT.md` | — | — | — | — | 42 | — | 10 |
| `AUDIT_COMPLETE_2026-07-26.md` | — | — | — | — | — | 3 path(s) | 6 |
| `AUDIT_season_playthrough_2026-07-25.md` | — | — | — | — | — | 3 path(s) | 2 |
| `EXACT_PORT_PLAN.md` | — | — | — | — | 166 | — | — |
| `M5_CLK47_WANDER_GAP_MARKS.md` | — | — | — | — | 3 | — | — |
| `M5_CLK9_CANDIDATE2_REFUTED.md` | — | — | — | — | 1 | — | — |
| `M5_DART209_POSDRIFT.md` | — | — | — | — | 10 | — | — |
| `M5_DIVERGENCE0_KICKOFF.md` | — | — | — | — | 4 | — | — |
| `M5_DIVERGENCE1_OPENPLAY_TRACE.md` | — | — | — | — | 1 | — | — |
| `M5_DIVERGENCE1_RNG_DESYNC.md` | — | — | — | — | 3 | — | — |
| `M5_DIVERGENCE1_SHOT_CONVERSION.md` | — | — | — | — | 6 | — | — |
| `M5_DIVERGENCE1_TRAJBUF_FIX.md` | — | — | — | — | 6 | — | — |
| `M5_DIVERGENCE2_PHASE6_STALL_FIX.md` | — | — | — | — | 2 | — | — |
| `M5_DIVERGENCE2_THREADB_REPLAY_RING.md` | — | — | — | — | — | 3 path(s) | — |
| `M5_DIVERGENCE_CLK12_INTERCEPT_CLAMP.md` | — | — | — | — | 1 | — | — |
| `M5_DIVERGENCE_CLK9_EXTRA_DRAW.md` | — | — | — | — | 1 | — | — |
| `M5_DIVERGENCE_CLK9_ROOT_FIX.md` | — | — | — | — | — | 3 path(s) | — |
| `M5_KICKOFF_ARM_TIMING_FIX.md` | — | — | — | — | 4 | — | — |
| `M5_KICKOFF_TAKER_WRONG_TEAM_ROOTFIX.md` | — | — | — | — | 2 | — | — |
| `M5_RECEIVER_ALIAS_165C_FIX.md` | — | — | — | — | 7 | — | — |
| `M5_S44_POSTSHOT_TRAJ_REBUILD.md` | — | — | — | — | 4 | — | — |
| `M5_S45_CTRL_MIRROR_DESIGNATION.md` | — | — | — | — | — | 3 path(s) | — |
| `M5_S46_CARRIER_DRAG_ROTATION.md` | — | — | — | — | 5 | — | — |
| `M5_S52_APPLY_PATH_DISASM.md` | — | — | — | — | — | 3 path(s) | 1 |
| `M5_S53_B1420_ARM_AND_STEER_ORDER.md` | — | — | — | — | 7 | 1 path(s) | — |
| `M5_S54_BALL_TRAJ_FIELDS.md` | — | — | — | — | 5 | 1 path(s) | — |
| `M5_S55_SAMPLING_PHASE_ARTEFACT.md` | — | — | — | — | — | 3 path(s) | — |
| `M5_S56_WIDE_FIELD_DIFF.md` | — | — | — | — | — | 3 path(s) | — |
| `M5_S57_SAMPLING_ANCHOR.md` | — | — | — | — | 13 | — | 1 |
| `M5_S58_FRONTIER_1032.md` | — | — | — | — | — | 3 path(s) | — |
| `M5_S59_FRONTIER_2836.md` | — | — | — | — | 9 | — | — |
| `M5_S85_WATCH_PLAYSTATE_FULLTIME.md` | yes | — | — | — | 12 | — | — |
| `M5_S86_ENGINE_THROUGHPUT.md` | yes | — | — | — | — | 6 path(s) | — |
| `M5_T1I9_B0040_INPUTS_PORTSIDE.md` | — | — | — | — | 1 | — | — |
| `M5_T1I9_FIRST_STEP_TARGET.md` | — | — | — | — | 1 | — | — |
| `M5_T1I9_KICKOFF_BALL_TRAJECTORY.md` | — | — | — | — | 1 | — | — |
| `M5_T1I9_STEER_TARGET_LOCALIZED.md` | — | — | — | — | 4 | — | — |
| `M5_T1MOVER_MIDPOINT_FIX.md` | — | — | — | — | 11 | — | — |
| `MATCH_TICK_DRIVER_MAP.md` | — | — | — | — | 62 | — | — |
| `PLAN_byte_exact_match_engine.md` | — | — | — | — | 12 | — | 1 |
| `PLAN_source-inventory-spec-audit.md` | — | — | — | — | — | 4 path(s) | 1 |
| `REFRUN_manutd_1997-98.md` | — | — | — | — | — | 2 path(s) | 1 |
| `REFRUN_manutd_1997-98_FINDINGS.md` | — | — | — | — | 1 | — | 8 |
| `SOURCE_INVENTORY.md` | — | — | — | — | — | 3 path(s) | 1 |
| `SPEC_BINDING.md` | — | — | — | — | — | 3 path(s) | 3 |
| `alert_box_re.md` | — | `diff_entry_parity.py` | — | `PMAlert.gd` | 4 | — | 2 |
| `android_packaging_re.md` | yes | — | — | — | — | 3 path(s) | — |
| `audio_re.md` | — | — | `test_audio.gd` | `AudioManager.gd` | — | — | — |
| `awards_screens_re.md` | — | — | `test_month_awards.gd` | — | — | — | — |
| `camera_motion_re.md` | yes | — | — | `Pm98Camera.gd` | 46 | 3 path(s) | — |
| `camera_re.md` | yes | — | — | `Pm98Camera.gd` | 10 | 3 path(s) | — |
| `channeltv_fee_re.md` | yes | — | `test_channeltv_screen.gd` | `ChannelTvScreen.gd` | 65 | 3 path(s) | 1 |
| `club_tactics_re.md` | — | — | — | — | 5 | — | 5 |
| `comp_result_screen_re.md` | — | — | `test_comp_result.gd` | `CompResultScreen.gd` | 7 | — | — |
| `contract_re.md` | — | — | `test_contract.gd`, `test_contract_warning.gd` | `Contract.gd` | — | — | 1 |
| `crests_re.md` | — | — | — | — | — | 3 path(s) | — |
| `cup_re.md` | — | `diff_cupdraw_parity.py`, `diff_supercup_parity.py` | `test_cup.gd`, `test_cup_draw_then_play.gd` | `Cup.gd`, `CupDrawScreen.gd` | — | — | — |
| `cupdraw_screen_re.md` | yes | `diff_cupdraw_parity.py` | `test_cupdraw_screen.gd` | `CupDrawScreen.gd` | 35 | — | 9 |
| `database_screen_re.md` | yes | — | `test_database_card_screen.gd`, `test_database_screen.gd` | `DataBaseCardScreen.gd`, `DataBaseScreen.gd` | 69 | — | 4 |
| `dbase_player_card_re.md` | — | `diff_dbase_card_parity.py` | — | — | — | — | 10 |
| `directiva_screen_re.md` | — | — | `test_directiva_screen.gd` | `DirectivaScreen.gd` | 5 | — | 1 |
| `euro_league_screen_re.md` | — | `diff_euroleague_parity.py`, `diff_finance_eurolabel_parity.py` | `test_euro_group_screen.gd`, `test_euro_stat_engine.gd` | `EuroGroupScreen.gd`, `EuroSupercupScreen.gd` | 22 | — | 6 |
| `euro_supercup_screen_re.md` | — | `diff_euroleague_parity.py`, `diff_finance_eurolabel_parity.py` | `test_euro_group_screen.gd`, `test_euro_stat_engine.gd` | `EuroGroupScreen.gd`, `EuroSupercupScreen.gd` | 7 | — | — |
| `europe_re.md` | — | — | `test_europe.gd` | — | 1 | — | — |
| `faces_re.md` | — | — | `test_faces.gd` | — | — | — | — |
| `ficha_card_re.md` | — | `diff_entry_parity.py` | — | — | — | — | 4 |
| `finance_constants.md` | — | `diff_finance_axis_parity.py`, `diff_finance_detail_parity.py` | `test_finance.gd`, `test_finance_control.gd` | `FinanceModel.gd`, `FinanceScreen.gd` | 42 | — | — |
| `finance_screen_re.md` | yes | `diff_finance_axis_parity.py`, `diff_finance_detail_parity.py` | `test_finance.gd`, `test_finance_control.gd` | `FinanceModel.gd`, `FinanceScreen.gd` | 38 | — | 5 |
| `fines_re.md` | yes | — | `test_fines.gd` | `Fines.gd`, `FinesScreen.gd` | 30 | — | 2 |
| `fixtures_screen_re.md` | — | `diff_fixtures_parity.py` | `test_fixtures_screen.gd` | `FixturesScreen.gd` | — | — | 3 |
| `goalscorers_screen_re.md` | — | — | `test_goalscorers_screen.gd` | `GoalScorersScreen.gd` | — | — | 4 |
| `hack_three_forwards.md` | — | `diff_options_parity.py` | — | — | 16 | — | 4 |
| `hack_unsackable.md` | — | `diff_options_parity.py` | — | — | 30 | 5 path(s) | 1 |
| `hub_circle_re.md` | — | `diff_hub_circle_parity.py` | — | — | 29 | 4 path(s) | — |
| `injuries_screen_re.md` | — | `diff_injuries_row_parity.py` | `test_injuries_screen.gd` | `InjuriesScreen.gd` | 21 | — | 2 |
| `injury_model_re.md` | — | — | — | — | 33 | — | — |
| `insurance_economy_re.md` | — | — | `test_insurance.gd`, `test_insurance_screen.gd` | `Insurance.gd`, `InsuranceScreen.gd` | 24 | — | 2 |
| `insurance_screen_re.md` | — | — | `test_insurance.gd`, `test_insurance_screen.gd` | `Insurance.gd`, `InsuranceScreen.gd` | — | — | 3 |
| `jug_render_spec.md` | — | — | `test_jug_render.gd` | `JugKit.gd`, `JugRender.gd` | 67 | — | — |
| `kit_palette_re.md` | yes | — | — | `JugKit.gd` | 5 | 5 path(s) | 2 |
| `knockout_views_re.md` | — | `diff_knockout_parity.py`, `diff_scout_offers_parity.py` | `test_knockout_bracket.gd`, `test_knockout_layout.gd` | `KnockoutScreen.gd` | 77 | — | 43 |
| `league_table_screen_re.md` | — | `diff_euroleague_parity.py` | `test_league_calendar.gd`, `test_league_screen.gd` | `LeagueTableScreen.gd` | — | — | 1 |
| `lineup_screen_re.md` | — | `diff_lineup_ban_parity.py` | `test_brief_lineup.gd`, `test_lineup_roll.gd` | `LineupRollScreen.gd`, `LineupScreen.gd` | 2 | — | 2 |
| `living_league_re.md` | — | — | `test_living_league.gd` | — | — | — | — |
| `make_offer_re.md` | — | `diff_entry_parity.py` | `test_make_offer_screen.gd`, `test_make_offer_seed.gd` | `MakeOfferScreen.gd` | — | — | 7 |
| `manager_career_re.md` | — | `diff_managerhistory_parity.py` | `test_manager.gd`, `test_manager_history_screen.gd` | `AudioManager.gd`, `Manager.gd` | — | — | — |
| `mantoman_screen_re.md` | yes | `diff_mantoman_parity.py` | `test_mantoman.gd` | `ManToManScreen.gd` | 29 | 4 path(s) | — |
| `match_engine_re.md` | yes | — | `test_live_match.gd`, `test_match_init.gd` | `MatchCommentary.gd`, `MatchEngine.gd` | 52 | — | — |
| `match_flow_re.md` | — | — | `test_live_match.gd`, `test_match_init.gd` | `MatchCommentary.gd`, `MatchEngine.gd` | — | — | 2 |
| `match_header_re.md` | — | — | `test_live_match.gd`, `test_match_init.gd` | `MatchCommentary.gd`, `MatchEngine.gd` | — | — | 2 |
| `match_view_re.md` | yes | — | `test_live_match.gd`, `test_match_init.gd` | `MatchCommentary.gd`, `MatchEngine.gd` | 31 | — | — |
| `matchday_flow_witness_re.md` | — | — | — | — | — | 2 path(s) | — |
| `menu_screen_re.md` | — | — | `test_menu_screen.gd` | `MenuScreen.gd` | 7 | — | — |
| `morale_re.md` | — | `diff_entry_parity.py` | `test_morale.gd` | `Morale.gd` | 1 | — | 3 |
| `news_screen_re.md` | — | `diff_news_parity.py` | `test_news_screen.gd` | `NewsScreen.gd` | — | — | — |
| `nivel_screen_re.md` | — | — | — | `NivelScreen.gd` | 7 | — | — |
| `ofertas_screen_re.md` | — | — | — | — | 17 | — | 3 |
| `offer_record_re.md` | — | `diff_offers_selection_parity.py`, `diff_scout_offers_parity.py` | `test_current_offers.gd`, `test_current_offers_screen.gd` | `CurrentOffersScreen.gd`, `MakeOfferScreen.gd` | 29 | — | 2 |
| `offers_map_re.md` | — | `diff_offers_selection_parity.py`, `diff_role_popup_parity.py` | `test_current_offers.gd`, `test_current_offers_screen.gd` | `CurrentOffersScreen.gd`, `MakeOfferScreen.gd` | — | — | 7 |
| `pcf5dat_re.md` | yes | — | — | — | 41 | 1 path(s) | 1 |
| `pitch_markings_re.md` | yes | — | `test_halfpitch.gd` | — | 10 | 3 path(s) | 1 |
| `pkf_format.md` | — | — | — | — | 2 | — | 1 |
| `player_info_re.md` | — | — | `test_player_actions.gd`, `test_player_build.gd` | `PlayerInfoScreen.gd`, `PlayersMonthScreen.gd` | 11 | — | 6 |
| `positions_re.md` | — | — | — | — | 8 | — | — |
| `pretemporada_screen_re.md` | — | — | — | — | 8 | — | 1 |
| `promanager_career_screens_re.md` | — | — | — | — | 25 | — | — |
| `renew_negotiation_re.md` | — | — | `test_player_info_renew.gd` | — | 4 | — | 1 |
| `results_screen_re.md` | — | — | `test_results_screen.gd` | `CompResultScreen.gd`, `MatchResultScreen.gd` | — | — | 3 |
| `retirement_re.md` | yes | — | `test_retirement.gd` | `Retirement.gd` | 79 | — | 4 |
| `rival_screen_re.md` | — | — | `test_rival_screen.gd` | `RivalScreen.gd` | 10 | — | 2 |
| `sack_path_re.md` | yes | — | `test_sacking.gd`, `test_unsackable.gd` | — | 61 | — | 4 |
| `savegame_dialog_re.md` | — | — | `test_savegame_dialog.gd` | `SaveGameDialog.gd` | — | — | 2 |
| `scout_screen_re.md` | — | `diff_scout_bar_parity.py`, `diff_scout_offers_parity.py` | `test_scout_bar.gd`, `test_scout_offer_route.gd` | `ScoutScreen.gd` | 27 | — | 5 |
| `season_end_sequence_re.md` | — | `diff_seasonend_year_parity.py` | `test_season_start_screen.gd`, `test_season_stat_store.gd` | `EndOfSeasonScreen.gd`, `PreseasonScreen.gd` | — | — | 1 |
| `season_stats_re.md` | yes | `diff_seasonend_year_parity.py` | `test_season_start_screen.gd`, `test_season_stat_store.gd` | `EndOfSeasonScreen.gd`, `PreseasonScreen.gd` | 63 | — | — |
| `seasonend_flow_re.md` | — | `diff_seasonend_year_parity.py` | — | — | 46 | — | — |
| `seleccion_screen_re.md` | — | — | — | `SeleccionScreen.gd` | 1 | — | 1 |
| `session_lineup_re.md` | — | — | — | — | 11 | — | 3 |
| `shadow_blit_re.md` | yes | `diff_hub_circle_parity.py`, `diff_knockout_parity.py` | `test_shadow_blit.gd` | `PMShadow.gd` | 30 | 5 path(s) | 2 |
| `squad_number_re.md` | — | — | `test_squad_screen.gd` | `SquadScreen.gd` | — | — | — |
| `squad_screen_re.md` | — | — | `test_squad_screen.gd` | `SquadScreen.gd` | 3 | — | 1 |
| `stadium_screen_re.md` | yes | — | `test_stadium_screen.gd`, `test_stadium_works.gd` | `StadiumScreen.gd` | 26 | — | 5 |
| `staff_re.md` | — | — | `test_staff.gd`, `test_staff_overlay.gd` | `Staff.gd`, `StaffHireOverlay.gd` | — | — | 4 |
| `stat_commit_cadence_re.md` | yes | `diff_statistics_parity.py` | `test_euro_stat_engine.gd`, `test_result_statistics.gd` | `Pm98StatMatch.gd`, `Pm98StatStore.gd` | 34 | — | — |
| `stat_match_engine_re.md` | — | `diff_statistics_parity.py` | `test_euro_stat_engine.gd`, `test_result_statistics.gd` | `Pm98StatMatch.gd`, `Pm98StatStore.gd` | 20 | — | — |
| `statistics_row_widget_re.md` | yes | `diff_statistics_parity.py` | `test_result_statistics.gd`, `test_statistics_screen.gd` | `StatisticsScreen.gd` | 54 | — | — |
| `statistics_screen_re.md` | — | `diff_statistics_parity.py` | `test_result_statistics.gd`, `test_statistics_screen.gd` | `StatisticsScreen.gd` | 6 | — | — |
| `tacticas_screen_re.md` | — | `diff_entry_parity.py` | — | — | 18 | — | 1 |
| `tactics_subscreens_re.md` | — | `diff_teamtactics_parity.py` | `test_predef_tactics_screen.gd`, `test_tactics.gd` | `PredefTacticsScreen.gd`, `Tactics.gd` | 23 | — | 4 |
| `team_offer_re.md` | — | `diff_entry_parity.py`, `diff_teamtactics_parity.py` | `test_positionteam.gd` | `TeamOfferScreen.gd`, `TeamTacticsScreen.gd` | — | — | — |
| `title_screen_re.md` | — | — | `test_title_screen.gd` | `TitleScreen.gd` | 5 | — | — |
| `training_screen_re.md` | — | — | `test_training.gd`, `test_training_exact.gd` | `Training.gd`, `TrainingScreen.gd` | 2 | — | 1 |
| `transfer_loop_live_re.md` | — | — | `test_transfer_screen.gd`, `test_transfers.gd` | `TransferMarket.gd`, `TransferScreen.gd` | 12 | — | 1 |
| `transfer_screen_re.md` | — | — | `test_transfer_screen.gd`, `test_transfers.gd` | `TransferMarket.gd`, `TransferScreen.gd` | 5 | — | 4 |
| `transfer_value_re.md` | — | — | `test_transfer_screen.gd`, `test_transfers.gd` | `TransferMarket.gd`, `TransferScreen.gd` | 12 | — | 2 |
| `wage_formula_re.md` | — | — | `test_wage_bills.gd` | — | — | — | 4 |
| `youth_re.md` | — | `diff_youth_parity.py` | `test_youth.gd`, `test_youth_caps.gd` | `Youth.gd`, `YouthScreen.gd` | 24 | — | 21 |
