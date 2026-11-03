# Testing rules: no test may lie

In Shorelight, every bug the player found by hand had passed the automated tests:
- the camera stuck after a cutscene;
- missing footprints in the maze;
- a scallop shell nobody could find;
- a silent festival;
- level-up without a refill.

These rules exist so that can't happen again. Each one names the incident behind it.

| # | Rule | Shorelight incident |
|---|---|---|
| T1 | Every e2e flow has a **real key-press** path. Autoplay or debug hooks can never be the only coverage. | Dialogue ignored real Z presses, yet autoplay tests passed |
| T2 | Level, gear and items come from one canonical **`chapterStart(ch)` fixture**, and ad-hoc boosts fail the run. Balance claims come only from the simulators. The fixture also **closes earlier chapters' content the way a real save does** (their story flags set, their missables closed), so hint menus, recaps and warnings read as a player sees them. | Boss tests passed at Lv36 vs an expected 28; the ch8 `tide` test fought ungeared; debug chapter starts left earlier chapters' quests open, so no-guide QA read noisy hint menus, recaps and warnings |
| T3 | Each chapter runs at least once in the **player's default render mode** (e.g. 3D). | All tests ran 3D-off; camera bug, decals and HUD broke in 3D |
| T4 | **No teleport across the critical path.** Walk it, or prove it with BFS reachability. | ch11 lighthouse stairs sat on wall tiles; the test teleported past them |
| T5 | The harness detects **any terminal state** (every game-over variant, title, no state change for N s) and fails fast. A no-output watchdog of 90 s runs on every test. | "Final boss stall" was the dumb AI losing on a custom game-over screen; a boss with an unreachable HP floor hung a test for 8+ min |
| T6 | The test AI **is** the player-facing auto-battle AI. | The F-key auto-battle lost bosses that the test bot won |
| T7 | Drivers **wait for script idle** before sending input. | Fake "soft-locks": the test fired events mid-cutscene |
| T8 | **Re-entering a map without a reload** is a test case. | Footprints were built only on map entry |
| T9 | Tests **encode the spec** (screenplay, requirements), never current behaviour. Derive audio and scene assertions from the screenplay's notes. | A test asserted "festival night: no BGM", locking in a silence the screenplay forbade |
| T10 | A failing test on the base branch is root-caused within the hour. "Flaky" is not a cause. The same stop point twice means a real bug. Under load, browser tests fail at timing-sensitive steps, a different step each run: **re-run the test alone** before filing it, and run it on a **worktree of the last good commit** to separate a regression from a flake. | ch8 `tide` failed on base for hours before the cause (no gear) was found; during a parallel QA wave, chapter tests failed at a different step each run and passed alone |
| T11 | **Full chain** (New Game → every ending, encounters on, **no assists**, save reloaded mid-run) is the release gate, and it starts once 2 chapters exist. | The chain run found ch8 unwinnable only at hour 7 |
| T12 | Read results from a **summary line in a file** (PASS/FAIL counts), never from a truncated tail. | Boss suite results misread from `tail` |
| T13 | Tests may use shortcuts (debug maps, simulated shop buys) only if the report **lists each shortcut**. At least one no-shortcut chain run per release. | Side-quest QA used flags and level boosts in places |
| T14 | Keep validator warnings at **0**, so a new one stands out. False positives get suppressed by a declared pattern. | Dynamic flag names (`'ch4_pc_'+k`) hid among 15 old warnings |
| T15 | Visual checks use the **real flow**, never forced state. | A forced victory page hid the stale HUD level after a level-up |
| T16 | Long suites are split so none exceeds 20 min; background timeouts are ≥2× the expected time. | A ch9–11 suite was killed at the 30-min background limit |
| T17 | Every puzzle and stateful interactable is **screenshotted in every render mode, in each state** (unsolved, partly solved, solved), and its state is drawn by the model itself, not by a 2D overlay. After the solve, the story chain that follows (scene, flags, objective, next trigger) is played in the default render mode. | Ch5 mirror puzzle: 3D hid the mirror cloths and facings, and the screens lay flat |

## Before any fan-out
The engine conformance suite (`blueprint/conformance_suite.md`) is green. Every chapter builder hit the same engine bugs and wrote six different workarounds.

## Merges
Use `tools/forge/merge_gate.sh <branch>`:
1. a `merge-tree` pre-check;
2. merge;
3. unit + validator + the merged area's tests;
4. abort on red.

Never merge red. Never force-push.
