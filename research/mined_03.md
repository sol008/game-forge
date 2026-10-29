# Mined slice 03: 2026-10-27 12:21 to 21:23 UTC (v1.0 ship, first playtest bug wave)

## 1. Phases and outputs

| Time (UTC) | Work | Who | Duration |
|---|---|---|---|
| 12:21 | Answered "would this be a 1995 classic?" Verdict: cult hit. Gaps: unreviewed emotional scenes, procedural music, uneven voice. This answer *caused* the later music and scene-polish agents. | main | – |
| ≤12:32 | 3 Chinese proofreaders (ch0–3: 23 fixes, ch4–7: 15, ch8–11: 17, so **55**). Main thread then fixed the clear-cut continuity flags itself: 墨鴉 "decades" became 18 years, a new `baizhi_spirit` sprite via `base:` inheritance in `js/gfx/sprites.js`, 麻糬's red string removed, 陳伯 20 years, Luo tragedy "four years", Kaswal line made culture-safe. | 3 local agents + main | (started earlier) |
| 12:32 | **Real finale bug found by a proofreader, not by tests:** the ending checked the wrong IDs for 4 心燈 stories (ch7/8), so those players got generic lines instead of the payoff scenes. | proofreader | – |
| 13:12 | Play Stats page and playtest timer (pauses when hidden or idle, 3-min idle rewind, per-chapter and per-boss stats, Z copies the report). i18n coverage dipped to 89–90% while the agent added menu text; `tools/i18n/extract.js` changed to exclude painted calligraphy; 3D tombstone 民國 became 光緒. | local agent | – |
| 13:13 | **Full-chain playthrough** from New Game to both endings, ~50 min at test speed. It needed `--assist-from ch8`, which exposed the economy bug. | local agent (`chain.log`) | ~1h |
| 13:15–14:47 | Economy and level curve: modelled a "normal player" (explores, fights the encounters it meets, ~½ of side quests). Ch8 boss win rate went from 31% to 97%; affordable gear from 9–56% to 92–100%. Rewards changed on ~30 bosses and ~35 chests; **no boss stats changed**. Also fixed 七仙蕈 (only 5 of 6 mushrooms existed and 3 were locked; added 潮汐蕈) and stuck ch1/2 quests. Proof: `full_chain --from ch5 --encounters` with no assist. | local agent | 1.5h |
| 13:22 | Merged cloud branch `r3d-battle`: `git merge-tree` showed it clean, then 60/60 unit tests, 0 validation errors, and a Playwright render of a 3D battle (`scratchpad/video/b3d.js`). The cloud session was told to merge main back in. | main + cloud | – |
| 13:29–14:14 | Polished the 6 key emotional scenes: pacing, silence, music cues, callbacks. EN rewritten to match. | local agent | 45m |
| 13:29–14:32 | Signature music: one pentatonic motif across 4 themes, better 笛子/二胡/古箏 synthesis, click fix, loudness and loop checks. The composer **cannot hear audio**, so 30-s previews went to the user. | local agent | 1h |
| 13:29–16:33 | **3D-on sweep of all 175 maps.** All earlier tests had run with 3D OFF. SwiftShader took ~40 s per map; headless Chrome crashed on the ending maps; the agent then started a 2nd full pass (~2h) until the lead stopped it. Output: canopy fade, `docs/qa/sweep3d.md`. | local agent | 3h |
| 16:34–16:37 | Final build: `tools/package.sh -o dist`. Font gap check found 裪, used only in comments. Unzipped into `My Games 彼岸燈` (spaces and CJK in the path) and loaded in 2D and 3D. Wrote `docs/RELEASE_NOTES.md`, sent the zip, deleted the check-in trigger, told the cloud team to stop. | main | 3m |
| 16:38–17:05 | The cloud team pushed late fixes, so a re-merge and rebuild followed. The worker restarted at 17:02. **Font had 99 subset slices vs 101** because offline mode reused a stale font, so `tools/build_font.py` was re-run and v1.0 resent. | main | 27m |
| 18:56 | User playtest: ch2 camera stuck after eating the mushroom, footprints missing, and a request for a Chinese guide with charts. | user | – |
| 18:57–21:17 | Bug wave: **8 local helpers** (camera, footprints, 3 guide writers, final-boss 3D stall, soft-locks, plant instancing), then 2 moved to cloud, plus a points-of-no-return agent. | mixed | ~2.3h |
| 20:29 | Cloud `fix-wuxiang-3d`: the "final boss stall" was a **test lie** (see §3). It also added timeouts on every 3D battle await and a broken-3D test across 21 multi-phase bosses (62/62). | cloud | 1h17m |
| 20:48 | Guide 《彼岸燈 完全攻略》 delivered: self-contained HTML, data-driven via `tools/guide/build_guide.js`, 32 map shots, charts (level curve, boss HP, gold, stats, 五行, 心燈, coastline route map). It found **39 unobtainable items**. | 3 local agents | 1h50m |
| 21:11 / 21:17 | Footprint fix (per-leg sets, brightness, 麻糬 hint, 靈視 low warning). Camera fix (scene fix + engine guard that returns the camera when a script ends; 3 ch3 scenes had the same bug). | local agents | 2.2h each (≥15–27 min starved) |
| 21:19 | Zip rebuilt (15 MB, guide in `GUIDE/攻略.html`/`.md`). 3 new agents: harvestable mushroom sparkle, smart F-key auto-battle, place the 39 items. | main | – |
| 21:22 | Annotated maps (PIL over map tile data plus `tools/guide/shoot_maps.js`) to pinpoint the mushrooms. This corrected the assistant's earlier wrong directions. | main | 1m |

## 2. Decisions

**User:** start more subagents (13:28); "max speed, as much parallel as needed" (18:59); bug triage and guide request (18:56); confirmed 3D and the forest location (18:58); implicitly approved the three open items by asking for the "latest version" (21:18).

**Assistant (autonomous):** resolved all clear-cut continuity flags; fixed the economy via rewards rather than boss stats; the true ending requires side content (14/28 心燈); started music and scene polish from its own critique; stopped waiting for the silent cloud battle team ("its core is in"); cut the sweep's 2nd pass; moved 2 local agents to cloud when load hit ~19; batching made opt-in (`?batch`); split the guide among 3 writers; started the points-of-no-return agent from the guide's findings; added the 3rd browser slot; decided 1 and 2 by default ("if you don't reply").

**Asked user, never answered (defaults applied):**
- 雲歸 貧道 vs 我; duplicate minor names (阿德/阿財/阿海伯, 阿順伯/阿義); 白芷 hairpin vs comb; 念念 timeline; Hakka 着/著; 陳伯 and 紅纓's family. *Template could pre-answer:* "Continuity: lead resolves with the stated default; minor-name collisions are renamed automatically; dialect orthography follows the MOE dictionary."
- Gold surplus of 20–30k at the end: taste, but a template field "target end-game gold slack" would answer it.
- Music "please listen": **necessary human**.
- F-key auto-battle upgrade: *pre-answerable* ("auto-battle must clear normal content using the same AI as tests").
- 39 unobtainable items: *pre-answerable* (a validator rule: every item has a source, or the build fails).
- Mushroom sparkle: *pre-answerable* (UX rule: interactables are visually distinct from decoration).
- Camera-bug clarification (forest? 3D?): *avoidable*. Reproduce in all render modes by default, and the Play Stats report should embed settings and location.
- Guide style and publish link: optional; a template "doc tone/format" answers it.

## 3. Problems and lessons

| # | Problem | Root cause | Fix | RULE |
|---|---|---|---|---|
| P1 | Finale used wrong 心燈 IDs for 4 stories | Cross-chapter IDs hand-typed; no test asserted payoff scenes fire | Proofreader caught it | Validator: every flag/ID read anywhere must be written somewhere (and the reverse). Ending tests assert each 心燈 payoff triggers. |
| P2 | Story-only path is unwinnable from ch8 (2k gold vs 14k gear; bosses 1–4 levels over) | Bosses retuned to end-of-area level while levels came from chapter-start presets; the test runner skipped random fights | Normal-player sim plus reward rebalance | Balance against a **simulated player economy** (XP/gold curve) from the start; the full-chain test runs with encounters and no assists as the release gate. |
| P3 | 七仙蕈 quest impossible (5 of 6 exist, 3 locked) | Collectible sets not validated | Added 潮汐蕈 | Validator: every collection quest's N items exist and are reachable. |
| P4 | 39 items unobtainable | Data authored apart from placement | Placement agent | Same validator: item → source map. |
| P5 | Every test ran with 3D OFF; 3D is the player's default | Speed (SwiftShader ~2 fps) | 175-map 3D sweep; user still hit 3D-only bugs | **Test in the player's default config**; keep a fast "3D-lite" smoke for every map in CI. |
| P6 | "Final boss stalls in 3D" (15 min) | **Test lied:** F-key auto-battle AI loses, then sits on Game Over; the harness didn't recognise ch7's custom Game Over and waited | Smart AI in tests; timeouts on all 3D awaits; broken-3D test | Harness must detect *any* terminal state (game over, title, stall with no state change for N s) and fail fast. Never use a dumber AI than the player-facing one. |
| P7 | "Soft-locks" on 4 maps | **Test lied:** test fired events while the opening cutscene ran, so 2 scripts ran at once | Test waits for script idle | Test drivers must await `scriptIdle` before input; impossible-for-player states are test bugs. |
| P8 | Camera stuck after the mushroom (user-found) | `grove25` `S.camera(15,8)` never released; same in 3 ch3 scenes | Scene fix plus an engine guard that auto-returns the camera at script end | Engine invariants over per-scene discipline: script end restores camera, input and HUD. Add an "after every cutscene the player is on screen" assertion to the chain test. |
| P9 | Footprints missing "sometimes" | Per-leg footprint set built only on map entry; the maze re-enters the same map without reload. 3D brightness random. Planned 麻糬 hint never built | Rebuild on leg change, fixed brightness, hint, low-靈視 warnings | Re-entry without reload is a test case. Design-doc features need a checklist test ("planned but never built"). |
| P10 | 3D sweep: browser crash, then a needless 2nd full 2h pass | Agent brief had no budget or stop condition | Lead: re-run failed maps plus 10 spot-checks | Briefs state a time budget, re-run scope ("only failures"), and a done-definition. |
| P11 | Load ~19 on 4 CPUs with 8 helpers | Each helper launched headless Chrome freely | `withbrowser.sh` 2-slot semaphore; 2 jobs moved to cloud | A resource governor exists **before** fan-out: browser slots = f(cores); monitor `uptime`; overflow goes to cloud. |
| P12 | 4 jobs starved 15–54 min in the queue | One 3D `e2e.js --workers 2` held a slot 43 min; FIFO with no priority; waiters read the slot count at start, so they never saw slot 3 | Killed the hog, added a slot, killed waiters and asked them to retry | Queue has a max hold time, a priority lane for user-reported bugs, re-reads config each poll, and reports waits > 5 min to the lead. |
| P13 | TaskStop mid-work left half-done batching code in a WIP auto-commit | Stop-hook "commit everything" loop (`git add -A` WIP snapshots) captures other agents' partial edits | Batch3D made opt-in (`?batch`) | Agents work on branches/worktrees and commit atomically; the main thread's WIP snapshot never sweeps agent files; risky features ship behind a default-off flag. |
| P14 | Rebuild shipped a stale font (99 vs 101 slices) | `package.sh` offline mode reused a cached font | Re-ran `build_font.py` | Package step always regenerates derived assets and asserts glyph coverage against all on-screen text. |
| P15 | Late cloud push after "final" build, so a rebuild was needed | Shipped before stopping and draining remote teams | Merge plus rebuild | Freeze: stop all agents, merge, *then* build. |
| P16 | Assistant gave wrong in-game directions (west edge vs bottom-left) | Answered from code reading | Rendered annotated map | Answer spatial questions from rendered map images with overlays. |
| P17 | Player found only 1 of 3 harvest spots | 3 pickable clumps identical to 15 decorative ones | Sparkle and marker agent | UX lint: interactables are distinct. |
| P18 | Content was missable with no warning (ch3 soldiers, ch4 認輸, ch5 inn) | No point-of-no-return audit | Warning dialog listing open quests; `docs/qa/points_of_no_return.md` | Every one-way transition checks open side quests. |
| P19 | Music cannot be verified by the agent | No audio perception | Theory and measurements, previews to user | Mark as human-review gate early; send previews proactively. |
| P20 | Cloud battle team silent 2h on a slow sweep | Software rendering; no heartbeat | Lead stopped waiting | Cloud briefs require a status push every 30 min; the lead sets a "ship without you" deadline. |

## 4. Process patterns

**Worked**
- Chapter-range proofreaders with the lead resolving flags: fast, and they found a real logic bug.
- Full-chain New Game to endings test as the integration gate.
- Merges: a `git merge-tree --write-tree` pre-check, then unit, validate and a visual render.
- Cloud sessions for CPU-heavy isolated work on their own branches (`fix-wuxiang-3d`, `perf-batch3d`, `r3d-battle`).
- Guide as framework plus 2 chapter writers, with the lead relaying conventions (`<!-- chart:route_chN -->` placeholders expanded from live data).
- Cross-agent hint relay (soft-lock agent to camera agent). Downstream agents (the guide) surfaced upstream bugs.
- `send_later` check-ins every 15–20 min, posted as tables, with a checklist prompt (check, report, commit, re-arm).
- Release QA: unzip into a CJK path with spaces, load 2D and 3D, font coverage.

**Failed**
- Parallelism with no resource budget (P11, P12); briefs with no time or scope limits (P10).
- Waiting on a silent remote team; shipping before draining agents (P15).
- Stop-hook WIP snapshots: 5 nags in this slice, noisy history, captured partial work.
- Bug fixes took ~2h, largely from queue starvation and slow 3D reproduction.

## 5. Handholding

| Time | Intervention | Class | Removal |
|---|---|---|---|
| 13:28 | "feel free to start subagents" | avoidable | Standing policy: fill capacity up to the governor limit |
| 18:56 | Playtest bugs (camera, footprints) | necessary-human (playtest), but the bugs were avoidable | P5/P8/P9 rules: 3D default-config chain test with an on-screen-player assertion |
| 18:56 | Guide request | avoidable | The template lists a strategy guide as a standard deliverable |
| 18:58 | Answered clarifying question | avoidable | Reproduce in all modes; stats report carries settings and location |
| 18:59 | "max speed" | avoidable | Default speed policy in the requirements |
| 19:10 | "fully using the machine?" | avoidable | Auto load monitor plus cloud overflow, reported in each check-in |
| 19:37 | "show me ch2 guide" | semi-necessary (review) | Proactively send a sample section when the first fragment lands |
| 20:35 | "check if stuck" | avoidable | Watchdog: queue wait > 5 min or no commits or log growth for 20 min triggers an alert and the lead acts |
| 21:14 / 21:21 | Mushroom location questions | necessary-human (UX feedback); answer quality avoidable | Annotated map in the guide; distinct interactables |
| 21:18 | "latest version with all fixes?" | avoidable | Auto-ship a tested zip after each batch of fixes merges |
| 12:21, 12:29, 19:12, 19:39 (×5 total) | Stop-hook commit nags | avoidable | Commit and push before ending every turn |

## 6. Tools, scripts, docs

- `scratchpad/withbrowser.sh`: shared headless-browser semaphore (2, later 3 slots, `.browser_slot*` lock files).
- `scratchpad/chain/chain.log` plus the full-chain runner (`--assist-from chN`, `--from ch5 --encounters`).
- `tools/test/load.js` (node loader of game data for ad-hoc queries), `e2e.js` (`--3d --r3lite --workers N`), unit tests (60, then 61, then 62), content validator.
- `tools/i18n/extract.js --missing` producing `tools/i18n/out/ui.missing.json` (EN coverage %).
- `tools/package.sh -o <dir>`, `tools/build_font.py` (CJK subset font), `docs/RELEASE_NOTES.md`.
- `docs/qa/sweep3d.md` (draw calls per map, median 79, sugarcane_night ~490), `docs/qa/points_of_no_return.md`, `docs/r3d_reports/battle.md`.
- `tools/guide/build_guide.js` (data-driven HTML/MD guide with chart placeholders), `tools/guide/shoot_maps.js` (map screenshots, `map:vision`), `docs/guide/chapters/chNN.md`, `docs/guide/img/`, `docs/guide/.data.json`, `docs/guide/guide_zh.html`, shipped as `GUIDE/攻略.html` and `GUIDE/攻略.md`.
- `js/r3d/batch.js` (`G.Batch3D`, opt-in `?batch`); engine camera-restore guard in `js/engine/script.js`, `map.js` and `js/r3d/mapview.js`; `baizhi_spirit` sprite.
- Ad-hoc Playwright checks (`scratchpad/video/spr.js`, `b3d.js`, `guideview/ch2pdf.js`) and PIL annotated maps (`scratchpad/harvest_map/`).
