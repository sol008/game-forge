# mined_00 — timeline slice 2026-10-27 03:52 → 06:44 UTC (~2h50m)

Repo `/home/user/testProject`, game in `shorelight/`, branch `claude/magical-davinci-kp4fhq`. Main thread = "lead". A context compaction happened at 05:48 and the summary was cut off mid-sentence. Note that "U: [Image …]" lines at 04:55, 06:24, 06:26, 06:31 and 06:42 are not user uploads: they are images returned when the assistant Read its own screenshots.

## 1. Phases & outputs

| Time | Who | What |
|---|---|---|
| 03:52–03:58 | main | Env probe: `node -v`, CJK fonts, `/opt/pw-browsers`, Google Fonts reachable, `pip install fonttools brotli`. The assistant ran `git rm` on existing `test.java` files, then reverted it ("leave existing files alone"). |
| 03:58–04:01 | main | Engine groundwork: `index.html`, `css/style.css`, `js/core/{util,font,input,audio}.js` in `qiandeng/`. |
| 04:01–04:12 | main + user | Story pitch (3 options, A recommended). Psychedelic layer added, 8 zh title options, 8 en title options. Folder renamed 3 times: `qiandeng` → `biandeng` → `lantern-of-the-far-shore` → `shorelight`. **About 20 minutes of naming Q&A.** |
| 04:12–04:15 | main | `docs/STORY_BIBLE.md`, `js/gfx/registry.js` (shared art registry), `docs/CONTRACTS.md`. Resolution bumped to 1280×720, TILE 64. |
| 04:16–04:19 | 15 local agents | music, monsters ×2, portraits, backdrops, sprites, tiles, nature, buildings, interior, data/balance, story ch0-2/3-5/6-8, zh bible translation. |
| 04:23 | user interrupt | "Travel through all major places in Taiwan, culturally sound." The interrupt **killed some background agents**. |
| 04:26–04:34 | main + 20 agents | Bible rewritten (full-island route, "一年一渡", cultural-accuracy guide). CONTRACTS updated with regional ids, `docs/WRITERS_GUIDE.md` written. **Relaunched** 6 writers (by region), 13 art/music/data agents (adding monsters part 3 regional and regional architecture), and a zh bible re-sync agent. |
| 04:19–04:55 | main | Engine core, about 35 minutes: render, state, ui, scene, main, dialog, map, script (cutscene API), fx (weather, lighting, 靈視 overlay), battle (CTB), menu, shop, title, debug, quests stub, `maps/test.js` sandbox, worldmap, minigames (timing bar, mash, 山歌 duel, 擲筊), mapmech (guards, wind, push crates). TaskCreate list made at 04:40. |
| 04:50 | main | First headless smoke test with the scratchpad script `smoke.js` (URL params plus JSON action list). |
| 04:51–04:52 | main | `tools/build_font.py` (LXGW WenKai TC subset → `js/core/fontdata.js`, gitignored), `fonts/OFL.txt`, `Play Shorelight.command`, `electron-main.js`, `package.json`. |
| 04:53 | agent | QA test infrastructure (content validation, unit tests, e2e). |
| 04:59 | main | `docs/MAP_AUTHORING.md`, then `js/story/ending.js` and `js/story/story.js` (chapter chaining). |
| 05:00 | agent | Character design options sheet (v1). |
| 05:04–05:16 | main | Battle features the data relies on, boss auto-battle suite (`bosses.js`, `?auto`), audio fix. |
| 05:09–05:11 | main + agent | i18n: `js/core/i18n.js`, `tools/i18n/extract.js` (1,308 strings, `${}`→`%s`, coverage report), title-screen language option, dialogue paging. A translator agent did the UI and data strings. |
| 05:12–05:14 | 9 builder agents | `docs/BUILDER_BRIEF.md`, then builders for ch0, 3, 4, 5, 6, 7, 8, 9, 10. ch11+endings followed at 05:22 and ch1, ch2 at 05:33. **12 builders ran in parallel**, each writing its own playthrough test. |
| 05:16 | main | Bilingual `README.md`. |
| 05:21 | main | Final-battle engine features: per-turn scripts, mid-battle join/leave, HP floor broken only by finisher moves, buff inversion, photosensitivity setting (迷幻視覺強度). True-ending threshold set to 14 心燈. |
| 05:25 | main | Sprites integrated (78). Fixes for double shadow, NPC pre-render, English turn bar. |
| 05:36–05:40 | main | `screenshots/` folder (10 gameplay captures, 11 art sheets as JPEG, `README.md` index). 9 English layout fixes. |
| 05:41–05:43 | 7 agents | Design v1 rejected. `docs/design/DESIGN_BRIEF_V2.md` written and 7 concept-art v2 agents launched. |
| 05:43 | main | `npm view three/esbuild` → AskUserQuestion on 3D. The game pivots to **full 3D, cel-shaded, angled camera**. |
| 05:44–06:14 | main | `tools/build` esbuild bundle → `js/vendor/three.bundle.js` (classic script, works from `file://`). `js/r3d/{core,materials,models,mapview}.js` built and wired into render, saves and settings. Headless software GL was too slow, so an `r3lite` test mode was added. Also `docs/CONTRACTS_3D.md`, `tools/r3d/viewer.html`, `tools/r3d/shot.js`. |
| 06:07–06:10 | main | `docs/design/REFERENCES.md` (photo refs for 白芷 and 2 cats). New pets 芋圓/麻糬. Briefs sent to agents and corrected. |
| 06:15–06:18 | **11 cloud sessions** | characters, animals/pets, architecture A/B, nature, props A/B, monsters A/B, environment/atmosphere, battle 3D+VFX, each on an `r3d-*` branch. IDs saved to `docs/r3d_reports/TEAMS.txt`. A `send_later` check-in was set for +45 min. |
| 06:29 | user | "Running out of quota, one thing at a time." 17 TaskStops and 11 `interrupt_session` calls, trigger deleted. **The cloud sessions had pushed nothing, so about 20 minutes × 11 of work was lost.** |
| 06:31–06:44 | main, sequential | 白芷 sheet finished (age label fixed 17→19). User picked 02, which was applied: portraits baked from the design-sheet drawing (12 expressions plus blink) and the sprite updated. 星河 got 07 (portrait baked; a neck-scarf piece was added to the sprite renderer). 紅纓's sheet was rendered and her design doc generated; user picked 01, baking in progress. |

Asset counts at about 05:25: 4 party members, 248 skills, 148 items, 113 enemies, 170 troops, 61 monsters, 21 portraits × 12 expressions, 112 objects, 45 interior props, 51 terrain types, 41 backdrops, 78 sprites, 46 music pieces, 13 screenplay files.

## 2. Decisions

**User decided:**
- Story option A.
- Add psychedelics (mushroom, DMT, ayahuasca).
- Rejected the title 千燈劍緣. Set the title to 彼岸燈 with English title Shorelight, and an English (not pinyin) folder slug.
- Ancient Taiwan and 九份, then the whole island with cultural soundness.
- Screenshots go in the repo.
- Design v1 rejected: 10 industry-standard, culturally sound designs per character.
- Story cast gets 1 design each and party members get 10. This arrived as a "scope change from the client", probably via AskUserQuestion.
- 3D cel-shaded with an angled camera, at a "2026 standard".
- Photo references: 白芷's face and hair, two real cats. Both cats are new pets and 糰子 stays.
- Quota: serial work.
- Finish 白芷 first.
- Picks: 白芷 02, 星河 07, 紅纓 01.

**Assistant decided:**
- Folder layout `js/core|gfx|engine|data|maps|story`.
- 1280×720 at 64px tiles.
- CTB battle with 五行 elements.
- 心燈 drives the ending, with the threshold at 14.
- A fictional mountain tribe, so no invented rites are attributed to real peoples.
- Bundled font, `.command` launcher, optional Electron.
- Bilingual zh/en with an extraction tool.
- Photosensitivity setting.
- Cloud sessions for 3D because the machine has 4 CPUs.
- Image-baked portraits from the design-sheet code.
- Treat "every single character" as all 13 named cast (130 designs).
- Recorded the user's reference pets as replacing 糰子. This was wrong and later corrected.

**Questions the assistant asked, and whether a template could pre-answer them:**

| Question | Pre-answerable? |
|---|---|
| Story A/B/C | Partly. The template needs a premise/tone/theme slot. Otherwise it is an inherent taste pick, and should be done as one batched question before any build work. |
| zh title options (twice), en title options | Yes: a `title_zh`, `title_en`, `slug` slot. Default the folder to a neutral `game/` so renames never matter. |
| "Every character = 13 or 5?" | Yes: default "party = N options, story cast = 1 final design". |
| 3D decisions (AskUserQuestion) | Yes: a template slot for `render: 2D/3D`, `camera`, `art style (toon/painterly)`, `quality bar reference`. |
| Design picks per character | No. This is necessary taste, but it could be batched. |
| "Should I start with 1 (chapters)?", "start on 星河 / 紅纓 next?" | Yes. Use a priority order in the requirements plus a rule: proceed on the stated default without asking. |
| "Message 11 cloud sessions to push their work?" | Avoidable with a mandatory push cadence. |

## 3. Problems & lessons

1. **Requirements churn after fan-out** (04:23, setting pivot after 15 agents had launched). The user interrupt also killed agents, so 20 agents were relaunched, about 15 minutes lost. **RULE:** lock premise, setting/route, cultural scope, title and render mode (2D/3D) in a requirements gate before any fan-out. Treat a user interrupt as possibly killing in-flight agents: check them with ListAgents.
2. **Late 2D→3D pivot** (05:43). The whole 2D art pipeline (78 sprites, 112 objects, tiles) became "stand-ins", and 11 3D teams were spawned. **RULE:** 2D vs 3D is a day-0 required field.
3. **Folder renamed 3 times in 12 minutes.** **RULE:** use a neutral working directory, or ask for slug and title together.
4. **Dialogue didn't advance on real Z presses.** `I.pressed('ok')` was consumed twice in `DialogScene.update`. The autoplay tests passed anyway (*a test that lied*). The ch0 builder agent found it. Fixed with a single `adv` evaluation, and QA was told to add `page.keyboard.press` e2e tests with autoplay off. **RULE:** every e2e flow must include a real-input path. Autoplay or debug hooks cannot be the only coverage.
5. **`new UI().List(...)`** parsed as `(new UI()).List`, so the menu crashed on open (05:01). **RULE:** always run a smoke test that opens every menu and screen. Lint for `new X().Y(` patterns.
6. **`G.Mapx = {}` declared in two files** clobbered each other (04:50). **RULE:** every module uses `G.X = G.X || {}`, and the contract says so.
7. **`running--` went negative** in script.js; fixed with `Math.max(0, …)`.
8. **One art function's exception broke the whole frame.** Fixed with `warnOnce` plus fallbacks (05:16). **RULE:** wrap every registry draw call in try/catch and draw a placeholder.
9. **Enemy with a bad troop id** restarted a failing battle every frame. **RULE:** a content validator checks referential integrity of ids before runtime.
10. **Boss suite results misread** because `tail` cut the output (05:15). **RULE:** write results to a file and grep a PASS/FAIL summary line. Never infer from a tail.
11. **Boss fights (夜玄, final) didn't end within the time limit**, and the suite was slow on an overloaded machine. **RULE:** cap auto-battle turns, add a speed multiplier, and run on a dedicated runner.
12. **An agent hallucinated an API.** The tile agent reported `G.Tiles.warm`, which didn't exist. **RULE:** the lead greps for every API an agent claims before relying on it, and briefs require "only report APIs you can show by line number".
13. **Screenplay revised after its builder started** (ch0), so a SendMessage told the builder to re-read it. **RULE:** freeze the screenplay before the build, with a version hash in the brief.
14. **心燈 awarded via flags only**, so it didn't count toward the ending. The lead had to message the ch7/ch8 builders. **RULE:** put game-system invariants in BUILDER_BRIEF up front, and have the validator count lanterns per chapter against the bible.
15. **Outdated chapter refs in `characters.js`**, flagged by a writer. The prologue dream drops coins and items against the screenplay. **RULE:** a validator diffs screenplay rules against data (loot tables per map).
16. **Nine English layout overflows** in titles, settings, battle target text and the turn bar. There was also a text-baseline bug that hit Chinese too. The world map's south tip ran off screen. **RULE:** run an automated overflow check (measureText against box width) for every locale, and screenshot every screen in both languages.
17. **Double shadow on battle sprites.** **RULE:** contracts must say who owns shadows.
18. **Headless software WebGL was very slow, and 4 CPUs were overloaded by about 20 agents** (06:01–06:05). Fixed with the `r3lite` low-quality test mode. **RULE:** check `nproc` before fan-out, cap local agents at about 2× cores, give 3D tests a lite path, and run heavy render work in cloud sessions.
19. **Cloud sessions pushed nothing in 20 minutes**, so all 11 sessions' work was lost on the quota stop. **RULE:** cloud briefs say "push a WIP commit to your branch every ~10 min and after each asset".
20. **Quota exhaustion** at about 2.5 hours, with 17 local agents plus 11 cloud sessions running. **RULE:** set a quota budget per phase, fan out in stages, and when the remaining budget is low, switch to serial and save work first.
21. **Design v1 judged "really bad"** because of a shared face template. **RULE:** design brief requirements are no shared templates, a historical/cultural basis per design, a silhouette check, and the lead self-reviewing against a reference bar before sending. Show the first sheet before scaling to all characters.
22. **The in-game portrait didn't match the picked design** because it used an old generic face template, and edits had no visible effect. Fixed by baking portraits from the design-sheet drawing code (`image portrait support`). **RULE:** in-game assets are generated from the same source as the approved concept: a single source of truth.
23. **Sheet age label (17) contradicted the bible (19).** **RULE:** sheets pull metadata from the bible and data, not free text.
24. **Sprite renderer lacked a scarf piece** for 星河's signature item. **RULE:** a concept-to-sprite checklist of signature items.
25. **Misread references**: the assistant assumed the cat photos replaced 糰子, then corrected and re-briefed 2 agents. **RULE:** when ambiguous, default to additive, or confirm in the same reply.
26. **Stray screenshots committed** to the repo. **RULE:** scratch outputs go outside the repo, and `screenshots/` is a curated, explicit copy.
27. **Stop-hook commit nags:** about 12 times, the hook demanded commits because background agents were mid-write, which produced many "WIP snapshot" commits. **RULE:** agents work in worktrees or own-branches and commit their own files, and the lead merges on finish.

## 4. Process patterns

**Worked:**
- **Contracts first:** `registry.js`, `CONTRACTS.md`, `WRITERS_GUIDE.md`, `MAP_AUTHORING.md`, `BUILDER_BRIEF.md`, `ART_NOTES.md` and `CONTRACTS_3D.md` let 12 builders and 13 artists work on disjoint files.
- **Lead builds the engine while agents make content**, with the lead integrating each report.
- **Debug URL params** (`?debug&map=&party=&lv=&battle=&auto&chapter&flags`) plus a `smoke.js` that takes JSON actions gave fast visual checks. The lead looked at every screenshot.
- **Preview HTML per art module**, so each sheet renders standalone.
- **SendMessage to running agents** for mid-flight corrections. Each was queued to deliver at the agent's next tool round.
- **Builder agents as QA:** the ch0 builder found the core input bug.
- **Cloud sessions for CPU-heavy 3D**: the first one was launched alone to confirm it worked, then the other 10.
- **Sequential design application** gave fast, high-quality iterations of about 5–7 minutes per character.

**Failed:**
- Fan-out before requirements were locked.
- No push cadence for cloud sessions.
- No quota awareness.
- About 30 concurrent workers on 4 CPUs.
- Status reports were long. Progress reports were frequent here, but the user still had to ask about screenshots.

## 5. Handholding (user interventions in this slice)

| Time | Intervention | Class | Removal |
|---|---|---|---|
| 04:03 | Story A plus psychedelics, title rejected | taste | Requirements: premise, themes, title |
| 04:04 | Ancient Taiwan, 九份, 彼岸燈 | taste | Requirements: setting |
| 04:07 | Interrupt: no pinyin folder | avoidable | Neutral slug rule |
| 04:08–04:09 | English title options, then "Shorelight" | taste | Requirements: en title |
| 04:23 | Interrupt: whole-Taiwan route, culturally sound | avoidable (late requirement) | Template: geographic scope, cultural-accuracy bar |
| 05:36 | "No screenshots in repo" | avoidable | Default: maintain `screenshots/` and per-chapter captures |
| 05:41 | Designs "really bad" | partly taste, mostly avoidable | Quality bar, self-critique, pilot sheet |
| 05:43 | 3D answers, plus photo refs | necessary input | Template: render mode, art refs folder |
| ~06:10 | Clarification: 糰子 stays, both cats new | avoidable | Additive-default or confirm rule |
| 06:29 | Quota: serial work | avoidable | Budget and staged fan-out |
| 06:31 | "Is 白芷 main? finish first" | partly necessary (priority) | Priority list in requirements |
| 06:33, 06:43 | Picks 02 and 01 | necessary taste | Batch all picks in one gallery |
| 06:38, 06:42 | "yes work on that" / "sure keep going" | avoidable | Rule: don't ask permission to continue a stated plan |
| ×12 | Stop-hook commit nags | avoidable | Agent worktrees and self-commit |

## 6. Tools, scripts, docs created

**Docs** (in `shorelight/docs/`):
- `STORY_BIBLE.md` / `STORY_BIBLE_zh.md`: world, cast, route, cultural guide.
- `CONTRACTS.md`: art and audio ids and APIs.
- `WRITERS_GUIDE.md`
- `MAP_AUTHORING.md`: map and script DSL for builders.
- `ART_NOTES.md`: placement rules from art agents.
- `BUILDER_BRIEF.md`
- `design/DESIGN_BRIEF_V2.md`
- `design/REFERENCES.md`: binding photo-ref notes; the photos themselves are not stored.
- `design/v2/*_sheet.png` + `*.md`, and a picks record.
- `CONTRACTS_3D.md`
- `r3d_reports/TEAMS.txt`: cloud session IDs.
- `story/*.md`: 13 screenplays.

**Code and tools:**
- `js/gfx/registry.js`: shared plug-in point for all art.
- `js/engine/debug.js`: URL-param test harness, autoplay, auto-battle.
- `tools/build_font.py`: CJK font subset to base64.
- `tools/i18n/extract.js`: string extraction and coverage; output `tools/i18n/out/` is gitignored.
- `js/i18n/en_*.js`
- `tools/preview_*.html`: per-module art sheets.
- `tools/build/`: esbuild bundling of three r186 into `js/vendor/three.bundle.js`.
- `tools/r3d/viewer.html` + `shot.js`: 3D asset viewer and screenshots.
- `js/r3d/*`: 3D map view.
- `Play Shorelight.command`, `electron-main.js`, `package.json`: Mac launch.
- `screenshots/` + `README.md`
- Scratchpad (not in repo): `smoke.js`, `preview.js`, `bosses.js`, `lead/shots/`.
