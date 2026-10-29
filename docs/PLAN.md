# game-forge: plan for building a full game from requirements with minimal handholding

Status: **DRAFT v2.** Updated with your answers to 5 rounds of multiple-choice questions; the decisions are recorded in §12. Nothing gets built until this plan is approved.
Evidence base, in the forge scratch notes:
- all 76 user messages from the Shorelight session;
- a condensed timeline of the 2-day build (2,364 events), mined in 5 slices for phases, decisions, problems and handholding;
- a survey of the Shorelight codebase.

---

## 0. Goal and benchmark

**Goal.** You hand over one filled-in requirements document. The forge then builds the game to "Shorelight level":
- story;
- engine;
- every chapter;
- 3D;
- two languages;
- balance;
- QA;
- a strategy guide;
- a Mac or Chrome package.

It asks you only at a few fixed checkpoints, where your taste or your money is genuinely needed.

**What "Shorelight level" means (the benchmark bar):**

| Area | Shorelight v1.0 (Oct 29) |
|---|---|
| Scope | 12 chapters (prologue to finale), 175 maps, 2 endings, 28 心燈 side stories (the true ending needs 14) |
| Content | 498 items (all obtainable), 452 skills, 191 enemies, 313 troops, 45 quests, 36 bosses tuned to 86–94% first-try win |
| Code | ~150k lines of game JS, ~42k lines of tools, 437 commits |
| Presentation | Full 3D (cel-shaded, rigged characters, 61 monsters, 41 battle arenas) with a 2D fallback; procedural soundtrack (46 tracks, 4 signature themes) |
| Languages | Traditional Chinese original plus American English (99.9%), with layout checked so every line fits its box |
| Quality gates | Unit tests 64; content validator at 0 errors; per-chapter playthrough tests; side-quest scripts for every chapter; full New Game → both endings chain test; 3D sweep of all 175 maps; boss simulator; economy simulator |
| Player docs | 《完全攻略》 guide (HTML+MD, generated from game data, charts, map shots); PLAYING.md; release notes |
| Ship | A ~15 MB zip that runs offline on Mac (launcher + bundled CJK font) or Chrome |

**Benchmark test for the forge itself (decided):**
1. **Mini dry run** first: a **brand-new game**, its genre settled at intake, with 2 chapters or the equivalent. This measures your touches, wall-clock time and cost.
2. Then **you decide** whether to do a full Shorelight-size build.

The full build must reach the bar above with:
- **≤ 8 human touches**, all of them in the "needs you" class (§2). Shorelight took 76 messages, about 45 of them avoidable.
- **0 playtest bugs of a class already listed in §7.** Every bug you found by hand in Shorelight becomes an automated check.
- A known cost estimate before it starts, and a cost report at the end.

---

## 1. What went wrong last time, and the fix for each

The 5 timeline slices found ~115 problems. Nearly all fall into 10 classes:

| # | Class (examples) | Cost last time | Forge fix |
|---|---|---|---|
| 1 | **Requirements locked late**: setting changed to all-Taiwan after 15 agents launched; the 2D→3D pivot came at hour 2; title or folder renamed 3×; cast roster changed (糰子 built then cut) | Agents relaunched; the 2D art pipeline mostly thrown away | Requirements gate (§3) locks premise, setting/route, title, cast roster and render mode **before any fan-out** |
| 2 | **Tests that lied** (most damaging):<br>• autoplay hid broken real key presses<br>• boss tests passed only because the test raised the party's level<br>• everything was tested with 3D off although 3D is the default<br>• the ch11 lighthouse soft-lock was teleported past<br>• a "boss stall" was really the dumb AI losing<br>• a test asserted "no BGM", which locked in a bug | You found the camera, footprints, shell, silence and level-up bugs by hand | Testing rules (§7): real input, canonical level and gear fixtures, default render mode, no teleport on the critical path, tests written from the spec |
| 3 | **Discoverability**: items on bare tiles (扇貝殼, 懷錶, 3 mushrooms…), ~25 quests with no pointer, missable content with no warning | Your reports, then 4 cloud QA sessions after shipping | Discoverability validator plus a **mandatory pre-ship side-quest walkthrough** (§5 phase 8) |
| 4 | **No resource governor**: ~30 workers on 4 CPUs (load 19–26); tests 2–3× slower; queue starvation 15–54 min | Your "is it stuck / are we using full CPU?" messages | Resource governor and auto-backfill from day 0 (§6) |
| 5 | **Shared working tree**: 40+ stop-hook commit nags, 27+ "WIP snapshot" commits, half-done work swept into commits, one helper breaking another's test | Noise, risk, a half-built feature had to be shipped switched off | One git worktree or branch per agent; the lead merges only green branches (§6) |
| 6 | **Balance and economy too late**: the ch8 chain run was unwinnable; 39 items had no source; over-softened bosses | 3+ hours of rework | Battle bot, boss simulator, economy simulator and chain test start once 2 chapters exist; each chapter gated on a win-rate band (§5 phase 7) |
| 7 | **Silent or blocked agents**: cloud sessions pushed nothing for 20 min and lost all work on a quota stop; a cloud team blocked ~40 min on "yes, resume"; a 2-hour duplicate sweep | Lost work and money | Cloud briefs: push every 10 min, never wait for approval, time budget and stop rule; watchdog (§6) |
| 8 | **No budget awareness**: hit the monthly limit twice; forced back to one task at a time | Your billing intervention, lost momentum | Budget field in requirements, cost forecast per phase, checkpoint before the limit (§6) |
| 9 | **Engine bugs found during content work**: every chapter builder hit the same engine bugs and patched around them; every 3D team hit gaps in the shared 3D core | Duplicate workarounds, merge fixes | Engine conformance tests and a contract smoke test **before** fan-out; a single engine owner (§5 phase 2) |
| 10 | **Answers and docs out of step with the game**: wrong directions to the grove, guide count 39 vs real 37, guide missing maps, clues and minigame answers | Your 剝皮寮 / 柿霜 / 山歌 questions | The guide is generated from game data only and covers every map, clue and minigame; spatial answers always come from rendered, annotated maps |

---

## 2. Human checkpoints: the only times the forge stops for you

Everything else follows **decide and disclose**: make the call, note it in the next status report, and let you override it later.

| Gate | When | What you do | Default if you're away |
|---|---|---|---|
| **G0 Requirements** | Minute 0 | Fill in or confirm the requirements template (§3); create the empty private repo and give Claude access; set the budget | Can't proceed; this is the one hard block |
| **G0b Cost estimate** | Right after G0 | The forge estimates cost per phase (local agents, cloud sessions) and asks whether you want to set a cap. **No cap by default.** | Proceed with no cap, reporting spend in every status table |
| **G1 Pitch** (only if your requirements have no premise) | ~30 min | Pick 1 of 3 story pitches and title pairs (zh/en), all in **one** message | Recommended pitch after 2 h |
| **G2 Design gallery** | ~2–3 h | Pick a design per party member and pet from **one** gallery page (a pilot sheet is checked against the quality bar first). Work continues meanwhile; only the final baking waits | Waits (picks are yours) |
| **G3 Taste review** (non-blocking) | During polish | Listen to the music previews and read the key scenes; your notes go into the fix loop | Ship as is |
| **Milestone builds** | First playable, after the QA wave, at release | Play the zip if you like (it is sent automatically) | — |
| **G4 Playtest** | First full build | Play; send the 遊玩統計 report with Z-copy, plus bug notes | — |
| **G5 Release** | After the fix loop | Say "ship" | — |

**Never** a reason to stop: "should I continue?", "start the next one?", "want a preview zip?", "upgrade auto-battle?", continuity nits, minor-name clashes, propagating a cut you already made.

---

## 3. Requirements template (filled in once, at G0)

Every question the assistant had to ask during Shorelight is pre-answered by a field here.

**Intake runs as multiple-choice questions** (like the rounds that produced this plan). The forge then writes the filled template to `docs/REQUIREMENTS.md` in the game repo.

**Required:** the intake must ask these and has no default:
- **languages**;
- **render mode (2D/3D)**;
- **target platform**.

**Defaults when not asked:**
- pace **balanced**;
- reports every **15 min**;
- builds at **phase milestones**;
- taste review **non-blocking**;
- design picks via **one gallery**;
- premise: if you give none, **3 pitches**.

The fields:

- **Identity:**
  - title (zh and en);
  - repo slug;
  - private repo `owner/name`, created empty with Claude access granted.
- **Genre and model:**
  - genre (仙俠 JRPG…);
  - combat style (CTB, turn-based…);
  - element system;
  - stat names (生命/真氣);
  - currency (文).
- **Premise and tone:**
  - premise;
  - themes (e.g. psychedelic visions);
  - tone;
  - inspirations (PAL95);
  - "must be better than…";
  - content limits.
- **Setting:**
  - era and place;
  - **route / geography scope** (e.g. "all major places in Taiwan");
  - cultural-accuracy bar;
  - sacred-content rule (witness only).
- **Cast:**
  - party size;
  - pets;
  - roster lock;
  - reference photos folder;
  - design options per party member (default 10);
  - story cast (default 1 design each);
  - pick mode (`ask` / `auto-recommend`).
- **Scope:**
  - chapter count;
  - target play time;
  - endings and their conditions;
  - side-content density;
  - collectibles.
- **Presentation:**
  - **render mode** (2D / 3D);
  - camera;
  - art style;
  - quality bar reference;
  - resolution.
- **Audio:** music style; signature motif; whether a human review is wanted (G3).
- **Languages:** original language and translations; puzzle-translation policy.
- **Platform:** Mac / Chrome / Windows; offline; launcher.
- **Difficulty and QoL defaults (on unless switched off):**
  - level-up refills HP/MP;
  - auto-save;
  - smart auto-battle that can clear normal content;
  - 2× speed;
  - point-of-no-return warnings;
  - harvest markers;
  - 靈視 hints;
  - photosensitivity setting.
- **Deliverables:**
  - strategy guide (language, charts, annotated maps);
  - player manual;
  - release notes;
  - screenshots;
  - Play Stats page.
- **Process:**
  - budget cap (USD) and quota mode (`max-speed` / `balanced` / `frugal`);
  - deadline;
  - report cadence (default 15 min);
  - deliverable cadence (`final-only` / `previews`);
  - priority order if something must give.

---

## 4. What we build (the forge itself)

1. **`game-forge` skill.** The playbook: phases, gates, rules, agent brief templates, the status and check-in loop. Lives at `.claude/skills/game-forge/` in a `game-forge` repo.
2. **Engine blueprint (no code template; decided).** Each game writes its own engine fresh. The forge carries the *design knowledge* (§9):
   - architecture;
   - module contracts;
   - the content formats;
   - the **engine conformance suite as a spec**;
   - the specs of every QA tool (validator checks, side-quest harness, chain test, simulators, guide builder, packaging).

   **Reference policy (decided):** at intake the forge judges how similar the new game is to Shorelight.
   - **Similar** (e.g. an RPG): agents may **read Shorelight's code as reference, then write fresh**.
   - **Different**: **clean room**. Agents work from the blueprint only and never open Shorelight's code.
3. **Forge tools**, made permanent instead of scratch scripts:
   - `governor.sh`: browser and CPU slots, and the overflow-to-cloud rule;
   - `agents.json` registry plus a `status.sh` summary;
   - a watchdog: no log growth or commits for N min raises an alert, and the queue alerts after a 5-min wait;
   - a check-in prompt template;
   - a cloud-session brief template;
   - a merge-gate script;
   - a release-gate script (build, unzip, boot in 2D and 3D, screenshot);
   - a screenshot harness (no encounters, wait-for-state, bundled CJK font, labels taken from map data).
4. **Reference game.** Shorelight (`sol008/Shorelight`) is the worked example. Its docs (story bible, screenplays, BALANCE.md, docs/qa/*) show "what good looks like". Its code may be read only under the reference policy above.

---

## 5. Pipeline: phases, parallelism, exit gates

Times are for a Shorelight-size game on a 4-CPU container plus cloud overflow. Phases overlap where noted.

| # | Phase | Who / parallelism | Exit gate (automated unless marked) | Est. |
|---|---|---|---|---|
| 0 | **Setup**: probe the environment (nproc, GPU, fonts, Playwright); private repo; budget; governor; registry; check-in loop armed | Lead | Repo pushable; `status.sh` works | 15 min |
| 1 | **Pre-production**: story bible (zh+en); route; cast; cultural guide; screenplays per chapter (**frozen, with a version hash**); appearance-facts file; glossary; systems design (combat, 五行, XP/gold curve, collectibles, ending thresholds); sound notes per scene | Lead + 4–6 writer agents by region | **G1**; screenplay lint: every scene has map, BGM/ambience cue, encounters, rewards; lore lint | 1.5 h |
| 2 | **Engine from the blueprint** (fresh code; Shorelight read as reference only if the game is similar): CONTRACTS / MAP_AUTHORING / BUILDER_BRIEF written for this game; **engine conformance suite** (awaited moves, camera release at script end, draw isolation, null BGM, re-entry without reload, real key-press dialogue, full-footprint interaction) | Lead (single engine owner) | Conformance suite green **before fan-out** | 1 h |
| 3 | **Art and design**: pilot sheet → self-review vs quality bar → 10 options per party member → **G2 gallery** → bake the in-game assets from the *same source* as the approved sheet → signature-item checklist | Design agents (CPU-light) in parallel with phase 2 | Side-by-side render vs sheet reviewed by the lead | 2–3 h |
| 4 | **Chapter build**: one builder per chapter, each in **its own worktree**, BUILDER_BRIEF with a definition of done (validator clean + chapter test green, in the default render mode, using canonical level/gear fixtures) | Up to ~11 local agents; browser tests through the governor | Per chapter: test PASS, validator 0 errors, en strings stubbed | 1–2 h |
| 5 | **3D assets** (if 3D): contract smoke test with 1 sample asset per team type first; then cloud teams by domain (characters, animals, architecture A/B, nature, props A/B, monsters A/B, environment, battle) | ~11 cloud sessions | Each team: lineup render vs references, `merge-tree` clean, combined registry check | 3–4 h (overlaps 4) |
| 6 | **Localization**: shared + per-chapter dictionaries from day 0; glossary; puzzle keys flagged; units ≤1,200 lines | ~6 local agents (CPU-light; backfills idle CPU) | Coverage ≥99.9%; layout check: every line fits its box in every language | 30 min |
| 7 | **Balance and economy** (starts when 2 chapters exist): battle bot = player-facing AI; boss sim (300–400 fights per boss, target 86–94%); normal-player economy sim; **chain test with encounters and no assists** | 2 agents, continuous | Per chapter: win-rate band and gear affordability; chain test reaches the next chapter boundary unassisted | continuous |
| 8 | **Pre-ship QA wave** (mandatory, before G4):<br>• full chain in the default render mode<br>• 3D sweep of every map (lite)<br>• **side-quest walkthrough per chapter range** (cloud ×4: play as a player, discoverability, missables, PASS/FAIL scripts)<br>• point-of-no-return audit<br>• zh proofread ×3<br>• en layout check<br>• screenplay conformance (audio cues, scene rules)<br>• item-source graph<br>• BFS reachability | 4 cloud + 4–6 local | All scripts PASS; 0 unobtainable items; 0 unreachable targets; every missable warned | 2 h |
| 9 | **Polish**: key emotional scenes, signature music (previews to you, G3), face and likeness pass, 3D performance (instanced batching on by default) | 3–4 agents | Draw-call budget; loop seams OK; loudness within the band | 1.5 h (overlaps 8) |
| 10 | **Docs**: guide generated from data, with **every map annotated** (exits, NPCs, clue tiles, chests), every minigame documented (scoring, best answers, randomness), charts; PLAYING.md; RELEASE_NOTES; **VERIFICATION.md** (what the tests prove and what they don't) | 3 agents | Guide build: 0 missing images, 0 unobtainable items, every quest step has a pointer | 1.5 h (overlaps 8–9) |
| 11 | **Freeze and release**: stop and drain *all* agents, merge, regenerate derived assets (font subset, guide), package, unzip into a CJK path with spaces, boot in 2D and 3D, send the zip | Lead | Release-gate script green | 15 min |
| 12 | **Playtest loop (G4)**: you play and paste the Play Stats report and notes; triage → fix in worktrees → **every bug becomes a validator rule or test**, and its general lesson is committed to game-forge → new zip at the next milestone | Lead + helpers | Regression test added per bug | ongoing |

**Expected total:** about 12–16 h of wall clock to the first playable zip. Shorelight took about 13 h to v1.0, but needed about 45 avoidable interventions. Then the playtest loop runs.

---

## 6. Orchestration rules (the "minimal handholding" machinery)

- **Pace modes** (default **balanced**, as decided):
  - **balanced**: local agents up to the governor limit; cloud sessions only for heavy 3D and the QA walkthrough wave.
  - **max-speed**: overflow anything to cloud.
  - **frugal**: mostly serial.
- **Resource governor.**
  - Browser slots are about nproc − 1, and no agent may launch a browser outside `governor.sh`.
  - Keep load around cores − 0.5. If the backlog isn't empty and load is under target, auto-start the next work package.
  - CPU-heavy work (3D, sweeps, long suites) overflows to cloud sessions.
  - Queue rules: priority lane for user-reported bugs; maximum hold time per job; config re-read on each poll.
- **Isolation.**
  - Each local agent works in its own git worktree or branch and commits its own files.
  - The lead merges only green branches, after a `merge-tree` pre-check.
  - No blanket `git add -A` WIP commits. Logs and artifacts go to the scratchpad only (`*.log` is in .gitignore).
- **Registry and status.**
  - Every launch is written to `agents.json`: id, task, branch, log, ETA.
  - A `send_later` check-in every 15 min posts **one table** with each agent's state, ETA, CPU load, spend so far and blockers, then commits, pushes and re-arms.
  - No-op checks stay silent.
- **Watchdog.**
  - Any agent with no log growth or commits for 20 min, or a test with no output for 90 s, is investigated and fixed by the lead *before* you'd notice.
  - The same stop point twice means a real bug.
- **Cloud lifecycle.**
  - Launch with a full brief, in a mode that never blocks on approval; the brief says the lead may pause or resume it.
  - The team pushes a WIP commit every 10 min and after each asset, and posts status in commit messages.
  - It has a time budget and a stop rule.
  - The lead merges early, then sends "merged, stop".
  - Set a "ship without you" deadline.
- **Briefs** (template): goal; files owned (with an **exclusive new-file namespace**); definition of done; time budget; re-run scope ("only failures"); "only report APIs you can show by line number"; report engine bugs, don't patch the engine.
- **Budget.**
  - Forecast cost per phase at G0b (cloud sessions cost about $5–40 each). Ask whether you want a cap; there is none by default.
  - Warn at 70% of the cap. At 90%, checkpoint everything and drop to serial work.
  - Never hit the limit mid-write.
- **Communication.**
  - The status table is the only routine message.
  - Always attach the current zip and its path at release.
  - Answer in your language.
  - Spatial questions get annotated, rendered maps, never directions from reading the code.
- **Compaction safety.** The registry, `followups.md` and the plan file are the memory. After a context reset, re-read them instead of mining transcripts.

---

## 7. Validator and test rules: every bug class becomes a check

| Rule | Catches (Shorelight example) |
|---|---|
| Every e2e flow includes a **real key-press** path (autoplay can't be the only coverage) | Dialogue ignored Z |
| Tests take level, gear and items from one canonical `chapterStart(ch)` fixture; ad-hoc boosts fail the run | Boss tests passed at Lv36 vs 28; ch8 `tide` ungeared |
| Every chapter runs at least once in the **player's default render mode** | Camera bug, decals, HUD drawn twice in 3D |
| **No teleport across the critical path**; BFS reachability from each entry to every exit, stair, chest and quest target | ch11 lighthouse stairs on walls |
| Harness detects *any* terminal state (game over, title, no state change for N s) and fails fast; the test AI is the player-facing AI | "Final boss stall" that wasn't |
| Test drivers wait for the script to be idle before sending input | Fake "soft-locks" |
| Engine invariants: script end restores camera, input and HUD; after every cutscene the player is on screen | Camera stuck after the mushroom |
| Re-entering the same map without a reload is a test case | Footprints missing in the maze |
| **Discoverability:** every interactable has a visible marker or glint, a quest-log or NPC pointer, and a hit area of ≥2 tiles; every quest step has `hint` metadata | 扇貝殼, 懷錶, 風穴石耳, ~25 quests |
| Every one-way transition lists open side quests and asks first | ch5 半邊井, ch3 soldiers, ch4 認輸 |
| Item-source graph: every item has a source; every collection quest's N items exist and can be reached | 39 unobtainable items; 七仙蕈 impossible |
| Every flag or id read somewhere is written somewhere (and the reverse); no dynamic flag names unless a pattern is declared | Finale checked wrong 心燈 ids |
| **Spec conformance:** screenplay sound and scene notes become assertions; a test encodes the spec, never current behaviour | Festival silence locked in by a "no BGM" test |
| Lore lint: appearance facts vs script descriptors; a speaker whitelist (silent pets can't talk); one timeline file | Silver-haired 白芷 lines; a talking cat |
| Unique names across characters, items and skills | 芋圓 cat vs 芋圓 dessert |
| Every zh key has an en entry; every line fits its box (measured) | Untranslated helper lines; 29 overflows |
| Multi-tile objects are interactable across their full footprint | ch9 carts, ch10 oars |
| Package step regenerates derived assets and checks glyph coverage | Stale font (99 vs 101 slices) |
| Warnings kept at 0, so new ones stand out | Dynamic-flag false positives hid in 15 old warnings |

---

## 8. Design defaults learned from playtesting

- **Level-up** fully refills HP/MP for the character who levels up, and the screen says so.
- **Harvest markers:** interactables look different from decoration (glint and tag).
- Smart **auto-battle** that clears normal content (styles: 保守/標準/積極; item toggle).
- **Point-of-no-return** prompt naming exactly what you'd lose.
- Hidden or spirit-only finds still get an NPC hint, and a no-spirit-sight hint where it makes sense.
- **Sacred content** is witnessed only: ambience without melody, no minigames.
- **Play Stats page:** an idle-aware clock and a Z-copy report, the channel for playtest feedback.
- 3D **batching** on by default, with a URL flag to compare.

---

## 9. Engine blueprint (replaces a code template)

You chose **no code template**, so every game writes its engine fresh. The forge carries the *design* instead, written as `blueprint/` docs. Each doc is derived from the Shorelight codebase survey (`research/repo_survey.md`), keeps what worked, and fixes the coupling problems that survey found.

| Blueprint doc | Contents |
|---|---|
| `architecture.md` | **Layers:**<br>• core: util, render, input, audio, i18n, font, state/save<br>• engine: scene stack, dialog, script API, map, battle, menus, shop, minigames, play stats, debug<br>• gfx registry<br>• optional 3D layer: core, materials, models registry, batching, map view, env, battle view, vfx<br><br>**Conventions:** classic scripts on one global, no network, offline from `file://`, and a script order every tool can read. |
| `config_first.md` | Design lessons from Shorelight's leaks:<br>• **all game vocabulary goes in one `CONFIG` from day 1**: title, currency, stat names, gauge, element system, collectible and its threshold, vision mechanic, save-key prefix, default party, font<br>• cast names are generated from data, never typed into engine code<br>• **hook registries** (battle intro/turn hooks, auto-battle tactics, 3D arenas, VFX ultimates) instead of chapters monkey-patching the engine<br>• **kit and content kept in separate files** (music sequencer vs songs, sprite kit vs cast specs, enemy helpers vs rosters) |
| `content_formats.md` | Map definition, script API, quests and collectibles, items, skills, enemies and troops, i18n scoping (shared + per-chapter, never overriding), and points of no return. All taken from what worked in Shorelight. |
| `conformance_suite.md` | The engine tests that must pass **before** content fan-out:<br>• awaited moves resolve<br>• speed resets after a move<br>• draw isolation<br>• null BGM<br>• camera, input and HUD restored at script end<br>• re-entering a map without a reload<br>• real key-press dialogue<br>• full-footprint interaction<br>• terminal-state detection |
| `qa_tools.md` | Specs, not code, for:<br>• **validator**: referential integrity; flag set/read; item-source graph; BFS reachability; discoverability; i18n coverage; unique names; lore lint<br>• unit tests<br>• e2e and chapter tests with fixtures<br>• side-quest walkthrough harness (BFS walking, real Z key, never writes flags)<br>• full-chain test (encounters on, no assists)<br>• battle bot, boss simulator and economy simulator<br>• 3D sweep<br>• music render and loudness check<br>• guide builder (generated from data; annotated maps; minigames)<br>• packaging with font subsetting<br>• release gate |
| `debug_hooks.md` | The URL/debug surface every test relies on: jump to a map, chapter or battle; autoplay; set flags; lite 3D. It is designed in from the start so tests never need to teleport across the critical path. |

**Reference policy.** At intake, the forge rates the new game's similarity to Shorelight:
- **similar:** agents may *read* Shorelight's code for the matching module, then write fresh;
- **different:** clean room, blueprint only.

The decision and its reason go in `docs/REQUIREMENTS.md`.

---

## 10. Repo layout (`sol008/game-forge`)

```
game-forge/
├─ .claude/skills/game-forge/
│  ├─ SKILL.md                      entry point: when to use, phases, gates, rules (short; links below)
│  ├─ intake.md                     multiple-choice intake script: required fields, defaults
│  ├─ requirements_template.md      §3
│  ├─ phases/00_setup.md … 12_playtest.md    steps, briefs, exit gates per phase
│  ├─ briefs/                       builder, writer, translator, 3D team, QA walkthrough, balance, guide, proofread, cloud session
│  ├─ rules/                        testing.md, discoverability.md, orchestration.md, budget.md, communication.md
│  ├─ lessons.md                    §1 and §7, with Shorelight examples
│  └─ status_table.md               check-in format
├─ blueprint/                       §9 engine and QA-tool design docs
├─ forge-tools/                     governor.sh, status.sh, agents registry, watchdog, merge_gate.sh,
│                                    release_gate.sh, shoot.js (screenshot harness), cost_estimate.md
├─ research/                        evidence behind this plan (timeline mining, repo survey, user messages)
└─ docs/PLAN.md                     this file
```

Using it for a new game: start a session with **`sol008/game-forge` + the new game's empty private repo**, then say "build a game". The skill runs the intake questions, then the phases.

---

## 11. How we build and prove the forge

| Step | What | How | Est. |
|---|---|---|---|
| 1 | Skill + rules + intake + briefs | Lead writes SKILL.md and rules; 3 agents draft phases and briefs in parallel from `research/` | 2 h |
| 2 | Blueprint docs | 3 agents (architecture + config, content formats + conformance, QA tools), each grounded in Shorelight code with file:line evidence | 2 h (parallel with 1) |
| 3 | Forge tools | Governor, status, watchdog, gates and screenshot harness, made generic and tested on Shorelight itself (e.g. the release gate must pass on Shorelight's zip) | 1 h |
| 4 | Self-review | A fresh agent with **no** context reads only `game-forge` and lists what is ambiguous or missing for building a new game; fix the gaps | 30 min |
| 5 | **Mini dry run** | New session: game-forge + a new empty private repo. Run intake (multiple choice) → cost estimate → build → milestone zips. Count your touches, hours and spend | 4–8 h |
| 6 | Retro | Every surprise in the dry run becomes a rule or tool fix, committed straight to game-forge main (as decided); then you decide on the full-size run | 30 min |

---

## 12. Decisions

**Decided (5 multiple-choice rounds):**

| Topic | Decision |
|---|---|
| Forge home | `sol008/game-forge` (private) |
| Engine reuse | **No code template, playbook only.** Similar games may read Shorelight as reference and write fresh; otherwise clean room. The agent decides and records why. |
| Forge tools | Ship orchestration scripts (governor, status, watchdog, gates, screenshots) |
| Benchmark | Mini dry run first, then decide; a **brand-new game**, genre settled at intake |
| Mini requirements | You, through multiple-choice intake |
| Story | You may write the premise; if not, pick from 3 pitches |
| Design picks | One gallery, you pick |
| Budget | No cap; the forge estimates first and asks whether you want one |
| Pace | Balanced |
| Status reports | Every 15 min (one table, silent when nothing changed) |
| Builds | At phase milestones |
| Taste review | Non-blocking previews |
| Languages / render mode / platform | Always asked at intake (no default) |
| Shorelight | Keep fixing your playtest reports; each fix also becomes a forge rule |
| Blueprint depth | Design docs + short illustrative code sketches; no Shorelight files copied |
| Self-improvement | After each game, the forge **commits new lessons and rules straight to game-forge main** |
| Strategy guide | **Always** a default deliverable (generated from data, annotated maps, minigames explained) |
| Start | Build the forge **after you approve this plan** |
| testProject | Delete the game branches. **Blocked:** the session's git proxy refuses branch deletion (403), so delete them on GitHub's branches page |

**Still open:** your review of this plan. Send notes, or say go.
