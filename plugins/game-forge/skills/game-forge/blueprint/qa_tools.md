# QA tools blueprint

Specs for every QA and build tool a forge game must write itself. There is no code to copy: each game writes these
tools fresh against its own engine. They are distilled from Shorelight's `tools/`, including where those tools
**passed while the game was broken**. Rule table: PLAN §7. Debug surface the tools rely on: `debug_hooks.md`.

## 0. Contract shared by every tool

- **Exit code is the verdict.** 0 = pass, 1 = fail, 2 = could not run. The last stdout line is
  `RESULT <tool> PASS|FAIL <passed>/<total> [<reason>]`, also written to `out/<tool>.summary`. Read results from that
  line, never from a `tail` of the log (Shorelight misread a boss suite that way).
- **Heartbeat.** Print a timestamped progress line at least every 30 s (`[seg 3/9] ch4:festival 41s`). The shared
  **no-output watchdog** kills any run that is silent for 90 s and prints the last step plus a state dump: scene stack,
  map, script busy, last 3 dialogue lines.
- **Fail on any runtime error**: console.error, pageerror, unhandled rejection, `G.lastError`, or a warn matching
  `/unknown|missing|not registered|undefined/`. The allowlist sits in one file, and each entry gives its reason.
- **Selectable scope.** `--only a,b`, `--from seg`, `--json FILE`, `--out DIR`. Re-run only what failed.
- **Browser tools take a slot from the governor** (`tools/forge/governor.sh -- <cmd>`; phase 00 copies the forge tools
  into the game repo as `tools/forge/`). They never launch Chromium on their own.
- **Shortcuts are declared.** Any assist (level, gear, flag, teleport, difficulty) is logged as `ASSIST <what>` and
  copied into the report. A run with assists can never be the gate run.
- **Tests encode the spec.** Every assertion that fixes a behaviour cites its source (screenplay beat id,
  requirements field, design doc). Never assert "what the game does now".
- Logs and artifacts go to `$SCRATCH` (defined in `docs/forge/env.md`) or `tools/*/out/` (git-ignored). Nothing a
  tool generates is hand-edited.

| # | Tool | File (suggested) | Runs | Budget | Gate |
|---|---|---|---|---|---|
| 1 | Load harness | `tools/test/load.js` | Node | ≤2 s | library |
| 2 | Validator | `tools/test/validate.js` | Node | ≤5 s | every commit, merge gate |
| 3 | Unit tests | `tools/test/unit.js` | Node | ≤10 s | every commit |
| 4 | e2e + chapter tests | `tools/test/e2e.js`, `chapters/chN.test.js` | browser | ≤15 min/chapter | builder done |
| 5 | Side-quest walkthroughs | `tools/test/sidequests/` | browser | ≤20 min/chapter | phase 8 |
| 6 | Full-chain test | `tools/test/full_chain.js` | browser | ≤90 min | phase 7/8, release |
| 7 | Battle bot | `js/engine/autobattle.js` (shared) | both | n/a | library |
| 8 | Boss simulator | `tools/sim/boss.js` | Node | ≤15 min total | per chapter |
| 9 | Economy simulator | `tools/sim/economy.js` | Node | ≤10 s | per chapter |
| 9b | Puzzle solver (no combat; replaces 8–9) | `tools/sim/solver.js` | Node | ≤60 s | per chapter |
| 10 | 3D sweep | `tools/r3d/sweep.js` | browser | ≤60 s/map, sharded | phase 8 |
| 11 | Music render | `tools/render_music.js` | browser | ≤30 s/track | phase 9 |
| 12 | Guide builder | `tools/guide/build_guide.js` | Node | ≤60 s (+shots) | phase 10 |
| 13 | Screenshot harness | `tools/forge/shoot.js` | browser | ≤10 s/shot | docs, answers |
| 14 | Packaging | `tools/package.sh` | shell | ≤3 min | phase 11 |
| 15 | Release gate | `tools/forge/release_gate.js` | browser | ≤5 min | G5 |

---

## 1. Load harness

**Purpose.** Run the real game scripts in a Node `vm`, in the canonical script order, with no browser, so the
validator, unit tests, sims and guide all see the same live registries and data.
**Inputs.** The canonical script list (parsed from `index.html` or a manifest; one source both the page and the
tools read). Options: `storage` (Map; share it to test reload), `search` (query string), `only`/`skip`/`extra`.
**Must provide.**
- Stubs for `window`, `document`, `localStorage`, timers and `Image`. The canvas 2D/WebGL context is a permissive
  Proxy: unknown methods are no-ops, and `measureText` returns plausible widths.
- **`document.currentScript` set per file.** Shorelight omitted it, so chapter-scoped i18n silently ran unscoped in Node.
- Errors are collected, never thrown: `{G, errors[], missing[], loaded[], run(code)}`.
- Skips the boot loop (`main.js`) and heavy binary blobs (the font).
- `loadChapter(n)` attributes every registration (map, item, troop, quest) to the file that made it. The guide and
  the validator need this.
**CLI.** Library only. `node tools/test/load.js --eval "G.Data.items.potion"` for ad-hoc queries.
**Caught.** It is the base that lets every Node check run in ~1 s instead of a browser minute.

```js
// sketch: per-file attribution
for (const file of scriptList()) {
  ctx.document.currentScript = { src: file };
  const before = snapshotIds(ctx.G);
  try { vm.runInContext(read(file), ctx, { filename: file }); }
  catch (e) { env.errors.push({ file, error: e }); }
  for (const id of diffIds(before, ctx.G)) env.owner[id] = file;
}
```

## 2. Validator

**Purpose.** Static and semi-static content integrity: every reference, flag, item, path and string, before any
browser starts. **Errors fail. Warnings are kept at 0**; `--strict` (the default in the merge gate) fails on warnings.
**Inputs.** The load harness (real registries and a real `MapScene` for collision), a source scan of map and story
files, `content/flags.json` (declared dynamic patterns), the canon files `docs/canon/*.json` (`cast.json`,
`appearance_facts.json`, `timeline.json`, `collectibles.json`, `speakers.json`), and the scene cues
`docs/story/cues.json` (extracted from the screenplays' `<!-- cue: -->` lines by `tools/lint/screenplay.js`).
**CLI.** `node tools/test/validate.js [-v] [--json] [--strict] [--only cat,cat] [--extra fixture.js]`.
**Output.** `file:line  [cat]  id  message`, grouped by category, then a summary line. `--json` emits the issues plus
the **item-source graph** and the **reach graph**, which the guide and the economy sim consume.
**Budget.** ≤5 s for the whole game (Shorelight: ~1 s for 175 maps).
**Self-test.** `fixtures/bad_*.js` holds one deliberate violation per check. `unit.js` asserts each one is reported.
Adding a check means adding its fixture.

Checks, by category:

1. **load.** A listed script that is missing or throws is an error. A `js/**` file not listed is a warning.
   Duplicate keys in data literals (silent overwrite) are errors.
2. **Referential integrity.** Every id literal resolves: skills, items, enemies, troops, maps, warps (target exists,
   landing in bounds and walkable, not itself a warp), sprites, portraits, expressions, music, sfx, fx, particles,
   places, quests, status ids, elements, equip slot fits `who`. This covers data tables, map defs, script API calls
   and generic `key:'id'` literals. Enemy AI conditions are **probed on the real AI function** in two opposite states;
   a condition that is always or never true is reported.
3. **Flags, both ways.** Every flag read (`S.has`, `flags.x`, data `req`/`learn.flag`, `if:` getters) is set
   somewhere, and every flag set is read somewhere. The same applies to collectible ids (granted and checked by the
   ending), quest stages (advanced and tested) and vars. Collectible ids are derived from their quest ids and checked
   against the plan list `docs/canon/collectibles.json` both ways.
4. **No dynamic names.** A computed key (`'chN_pc_'+k`) is an **error** unless it matches a pattern declared in
   `flags.json` (`{"pattern":"ch4_pc_{k}","k":["a","b","c"]}`). The pattern then expands into concrete flags for check
   3. Shorelight instead treated every literal in such a file as "set", which hid real misses.
5. **Item-source graph.** Nodes are items. Edges come from: chest, shop (with the chapter it opens), drop (with
   rate), steal, quest reward, script `give`, craft/combine, starting gear. Each edge carries **the map plus the gate
   flag**, and is reachable only if its map is reachable (check 6). Rules:
   - every item has ≥1 reachable source, unless it is `noSource:'<reason>'`, and a `noSource` item that has a source is
     also flagged;
   - every **collection set** (quest needs N of a tag, or the true-ending collectible count) has ≥N distinct members,
     each reachable before the step that checks it;
   - the true ending is reachable with collectible count ≥ threshold, and the per-chapter counts match the bible.
6. **BFS reachability, as errors.** Build one graph per map from the real collision grid. Link maps through warps
   and `S.warp` literals, and BFS from New Game. Every exit, stair, chest, NPC, action event and quest target must be
   reachable on foot. Interaction counts from an orthogonal neighbour, or across a 1-tile counter.
   - Conditional terrain and warps (`if:`) are evaluated under each **declared story state** in
     `docs/states/chN.json`, a list of flag sets along the critical path, not just the initial state.
   - Unreachable is an error, not a warning.
   - `spirit:` content is checked with vision on.
7. **Discoverability.** Every interactable (action event, harvest object, hidden chest, clue tile) needs all of:
   - a **visible marker** (`glint`/`marker`/registered distinct art, never a decoration id also used elsewhere as
     scenery);
   - a **pointer**: an NPC line, a quest-log stage text, a `hint` getter or a guide note, linked by id;
   - a **hit area ≥2 tiles** (`w*h ≥ 2` or `hintR ≥ 1`).

   Every quest stage has `hint` metadata. Every one-way transition declares `pointOfNoReturn` listing the open quests
   and collectibles it closes.
8. **Multi-tile footprints.** Every object with `w>1||h>1` that is interactable must accept interaction from every
   footprint cell. Check it on the real engine by calling `findInteract` from each adjacent cell.
9. **i18n.** Every source-language string key has an entry in every target locale: the gate is **0 missing keys**
   (the coverage % is informational only). Templates keep the same placeholders. Puzzle and glyph keys carry
   `// i18n:puzzle` beside the key (from `[PUZZLE-LANG]` in the screenplay) and must have a translator note. Glossary
   terms follow `docs/i18n/GLOSSARY.md`.
   **Unique display names** across characters, items, skills, enemies and quests in every locale. Line-fit
   (measured) runs in e2e, not here.
10. **Lore lint.** Script descriptors are checked against `docs/canon/appearance_facts.json`; hair, eye, age and
    build words next to a cast name or alias fail. Speakers must be in `docs/canon/speakers.json`; pets marked
    `silent` may only `emote`. Dates and eras are checked against `docs/canon/timeline.json`.
11. **Scene cues.** Each `docs/story/cues.json` entry (`{scene, bgm, ambience, sfx}`, from a
    `<!-- cue: <scene-id> bgm=<id>|none ambience=<id>|none sfx=<ids> -->` line) is checked statically: every id
    exists, and the scene's map `bgm` or its `S.bgm` matches the cue (`null` only where the cue says `bgm=none`).
    The runtime check is `tools/test/spec_conformance.js` (§4). There is no other cue format.
12. **Engine support.** A data field that the engine never reads, or an item `special` with no implementation, is a
    warning. That means it fails under `--strict`.

```js
// sketch: reach + discoverability for one target
function checkTarget(t, reach, ptrIndex) {
  const where = `${t.map} ${t.x},${t.y}`;
  if (!reach.adjacent(t.map, t.x, t.y, t.state)) err('reach', `${t.kind} ${t.id} unreachable at ${where}`);
  if (t.kind !== 'interactable') return;
  if (!t.marker && !Art.isDistinct(t.art)) err('discover', `${t.id}: no marker/glint at ${where}`);
  if (!ptrIndex.has(t.id)) err('discover', `${t.id}: no NPC/quest-log/hint pointer`);
  if (t.w * t.h < 2 && !(t.hintR >= 1)) err('discover', `${t.id}: hit area < 2 tiles`);
}
```

**Caught.** Bad troop id restarting a battle every frame. Finale reading the wrong collectible ids for 4 stories. 39
(really 37) unobtainable items. A 7-item mushroom set with 5 that existed and 3 locked. The ch11 lighthouse stairs on
wall tiles. 扇貝殼 and 懷錶 on bare tiles. About 25 quests with no pointer. Carts and oars interactable from one
half. The silver-haired heroine and the talking cat. 芋圓 the cat vs 芋圓 the dessert. Untranslated helper lines.
Dynamic-flag noise hiding among 15 tolerated warnings.

## 3. Unit tests

**Purpose.** Fast tests of engine logic on the real engine code in a `vm`, independent of content.
**Inputs.** The load harness, plus `qa_*` fixtures (2 characters, ~10 skills and items, 1 quest, 1 troop) injected
into `G.Data`, so content churn never breaks them.
**Checks.**
- Party, inventory and save round-trips, including `storage` shared across a reload and save migration.
- Battle formulas through the real `damage/applyEffect/startTurn/aiCommand/flee`. Seeded `Math.random`.
- Level-up applies the QoL defaults (refill, message).
- Dialogue, menu and shop logic, pumped through the scene stack without rendering.
- The **conformance suite** (`conformance_suite.md`): awaited moves resolve, speed resets, draw isolation, null BGM,
  camera, input and HUD restored at script end, re-entering a map without reload, full-footprint interaction.
- The validator self-test (§2).
**CLI.** `node tools/test/unit.js [name-filter…]`. **Budget** ≤10 s. **Output** `N/M passed`, plus each failure's
assertion and stack.
**Caught.** A negative script `running` counter. Level-up with no refill (once that was specified). Interaction on
only one half of a footprint. Map re-entry leaving the footprint set stale.

## 4. e2e and chapter tests

**Purpose.** The real game in headless Chromium from `file://`: engine scenarios, sweeps of every map and every
troop, and one playthrough test per chapter, split into segments.
**Fixture.** `chapterStart(ch)` from `tools/test/lib/fixtures.js` is the **only** source of level, gear, items, party,
gold and flags at a chapter or segment start. It is derived from `G.Data.progression` plus the economy model's
**normal** player (§9). Any `ensureLevel`, `addExp`, `give` or `equip` inside a test body goes through a guard that
fails the run unless it is wrapped in `assist()` (logged, and never allowed in a gate run).
**Required paths.**
- **Real input.** Every flow has a path driven by `page.keyboard.press` (arrows, Z/Enter, Esc) with autoplay **off**:
  title → new game, one dialogue with a choice, menu panels, shop, save/load. Autoplay may speed up the rest.
- **Default render mode.** Each chapter runs at least once with the player's default renderer (3D-lite if 3D is the
  default). Faster modes are extra runs, not a substitute.
- **No teleport across the critical path.** `setPos`/`warp` is allowed only *within* a segment's start fixture. Between
  beats the driver walks a BFS path (using the same walker as §5) through the real collision and touch events.
- **Wait for idle.** Input is sent only when `G.Script.busy()===0` and no auto event is pending.
- **Terminal-state detection.** Each step returns one of `idle`, `gameover` (any game-over scene, including a
  chapter's custom one, which registers via `G.Engine.terminalScenes`), `title`, `ending`, `stuck` (script busy with
  nothing on screen for 15 game-seconds) or `stall` (no state hash change for N s). Anything but the expected state
  fails at once.
- **Segment hand-off.** A segment ends at its hand-off assertion (chapter increments, map changes). It never waits on
  past the end.
- **Spec assertions.** `tools/test/spec_conformance.js` asserts every `docs/story/cues.json` entry in game (required
  BGM, ambience and sfx per scene); the chapter test asserts encounter count and rewards. After every cutscene: the
  player is on screen and the camera follows.
- **Sweeps.** Every map loads, settles its entry event, talks to every NPC and fires every event one at a time. Every
  troop resolves in ≤900 game-seconds and returns to the map with no NaN. Every text box in every locale fits
  (measured), with a screenshot per screen per locale.
**CLI.** `node tools/test/e2e.js [--only] [--maps] [--troops N] [--render default|2d|lite]`;
`node tools/test/chapters/ch4.test.js [--from seg] [--only seg] [--shots]`.
**Output.** `out/e2e-report.json`, per-segment timings, and screenshots on failure only. Fast-forward (`ff`) runs
the game loop with a fixed dt; the watchdog is 90 s of real time without output.
**Budget.** Full chapter ≤15 min, segment ≤5 min, map sweep ≤10 min with workers.
**Caught.** Dialogue ignoring a real Z (autoplay passed). Boss tests passing at Lv36 vs an expected 28. ch8 `tide`
fought ungeared. Camera, decals and a double HUD broken in 3D only. Festival silence: a test that asserted "no BGM"
would now be a spec violation. Fake soft-locks from firing events mid-cutscene. A ch5 test waiting after its hand-off.
A 鯤 boss `hpFloor` loop that hung for 8+ min.

```js
// sketch: fixture guard
const ALLOWED = new Set(['talk', 'walk', 'press', 'wait']);
page.exposeFunction('__qaMutate', (kind, detail) => {
  if (ALLOWED.has(kind)) return;
  if (!ctx.assisting) throw new Error(`state injection '${kind}' outside fixture: ${detail}`);
  report.assists.push({ seg: ctx.seg, kind, detail });
});
```

## 5. Side-quest walkthrough harness

**Purpose.** Play every side quest and collectible of a chapter **as a player**, proving it can be completed,
found and not missed by accident. It is mandatory before the first ship.
**Inputs.** `chapterStart(ch)` plus `docs/qa/sidequests_chN.md` (the expected steps and windows).
**Rules.**
- It **never writes** quest state, flags, items, vars or stages. A firewall on `page.evaluate` blocks it (§4 guard).
- **Walking.** BFS over the live collision (`G.mapScene.blocked`), stepping one tile at a time through the engine's
  step function, so touch events and warps fire. It avoids warp and touch cells unless they are the goal.
- **Interacting.** Face the target and press the real interact key. Resolution goes through the engine's
  `findInteract`, which is exactly what a player hits.
- **Finding.** Before interacting, the script records the pointer it followed: NPC line id, quest-log text or marker.
  A step that needs knowledge with no pointer fails as `UNDISCOVERABLE`.
- **Missables.** It walks to each point of no return with the quest still open and asserts that the warning names it
  and where it is, and offers "save first".
- **No-guide mode** (`--no-guide`). The agent plays from **in-game text only**: dialogue, quest log, rumours, marks,
  party talk and stuck offers; never the guide, code or screenplay. For each unit it records the **lowest hint tier**
  that was enough (0 = none). Tier 4, or no tier, is `UNDISCOVERABLE`.
- No level raise before bosses. It uses the fixture and the shared bot (§7).
**CLI.** `node tools/test/sidequests/ch3.side.js [quest-filter] [--shots] [--render lite]`.
**Output.** One line per quest, `PASS q_x 4/4 steps 38s` or `FAIL q_x step 3: <reason>`, plus a report table in
`docs/qa/sidequests_chN.md`. **Budget** ≤20 min per chapter file; split any file that runs longer.
**Shared lib.** `sidequests/lib.js` is created by the lead **before** fan-out. Per-range scripts live in their own
namespace (`sidequests/ch6_8/`), which avoids the `lib.js` vs `lib68.js` fork.
**Caught.** The ch11 lighthouse soft-lock, the ch9 sand bridge stranding the party, the ch5 半邊井 collectible
missable with no warning, and about 25 pointerless quests. All were found only by the post-ship cloud QA.

## 6. Full-chain test

**Purpose.** One continuous game, from New Game on the real title screen to **every** ending, carrying all state. It
is the integration and balance acceptance gate.
**Rules.**
- No `?debug` presets. Default difficulty, **default render mode** (lite allowed), and **encounters on**: the field
  fights the economy sim's normal player meets are fought. It uses the shared bot (§7). There is **no level floor**
  at chapter starts; Shorelight's chain still raised the party to the expected start level.
- Reuse the chapter drivers' critical-path functions through a **state firewall**. Calls that would inject flags,
  items, gear, gold, party or levels are blocked and logged as `assumed state`. `--assist[-from chN]` exists for
  diagnosis only and marks the run `ASSISTED` (not a gate pass).
- Shopping uses the gold actually carried, bought the way the economy model buys.
- **Boundary record** at each chapter start and boss: level per member, gold, item counts, gear, collectibles,
  against the economy model's normal-player row. A level more than ±1 off at a boss, or gear affordability below
  90 %, is a FAIL.
- **Transition frames.** At every chapter boundary it samples frames from the fade-out to the next map and asserts
  the chapter card was visible (non-black text pixels). A black screen where a card belongs is a FAIL (C21).
- **No combat** (`CONFIG.battle` absent): the chain still applies; it replays every puzzle and the critical path.
- **Save/reload mid-run.** At `--reload-at chN` it saves through the real save menu, opens a fresh page, loads
  through the title menu, and continues. Each ending branch replays from a save made before the finale.
- Terminal-state detection and the 90 s watchdog, as in §4. Fail fast on game over.
**CLI.** `node tools/test/full_chain.js [--from chN] [--to chN] [--reload-at chN] [--render lite] [--assist-from chN]`.
`--from` resumes from the boundary save `saves/chNN.json`.
**Output.** `out/chain/chain.log` with `[boundary] ch5 Lv 18/18/17 gold 2,140 items …` lines, `report.json`
(assists, deltas, times), and a screenshot per boundary. **Budget** ≤90 min (Shorelight: 60–90 min). Run it as soon
as 2 chapters exist, then continuously.
**Caught.** The ch8 game over: the story-only party was 2–5 levels low, with 2k gold against 14k of gear. Chapter tests
never saw it because each started from its own preset.

## 7. Battle bot

**Purpose.** One battle policy, used by the player's auto-battle key, the e2e, chapter, side-quest and chain tests,
and the boss simulator.
**Spec.** It **is** the player-facing auto-battle module (`G.AutoBattle.command(scene, unit, settings)`), with the
player's settings (style 保守/標準/積極, items on/off). Tests load the same file. They never use a private, smarter or
dumber copy: Shorelight kept a separate test bot, and its "final boss stall" was the weaker in-game AI losing.
- Policy order: revive → heal in danger (skill, then item) → MP for the healer → cure a disabled healer → guard on a
  telegraphed big hit (enemy wind-up, charge flag, warning text) → opening buffs and debuffs in boss fights →
  ultimate or combo → best expected damage (element cycle, weak/resist, hit and crit) with an MP cost.
- Per-fight hints come from a **registry** (`G.AutoBattle.registerFight(id, hints)`), never from enemy ids hard-coded
  in the engine.
- It must clear normal content at `chapterStart` level (asserted by the troop sweep, §4).
**Caught.** The "final boss stall" was the dumb AI losing and sitting on game over. Auto-battle bosses had a 37 %
average win rate before the AI was upgraded and 94.5 % after.

## 8. Boss simulator

**Purpose.** The win rate of every boss and scripted fight on the first try, at the state each player model really
has there.
**Inputs.** The load harness running the **real** battle scene headless (timers, tweens, dialogue resolved at once),
chapter battle hooks through the hook registry (no eval injection into chapter closures), `content/fights.json`
(fight id → `S.battle` options), and the economy model (§9) for level, gear and kit per model.
**Checks.** 300–400 seeded trials per fight with the shared bot. First-try win rate in the requirements band
(Shorelight: 86–94 %); at `--lv -2` it stays above the floor. **Party alive at win** (an ally KO must never count as a
boss win). Reaching the turn cap counts as a loss.
**CLI.** `node tools/sim/boss.js [--only ids] [--ch N] [--n 400] [--model normal|minimal|thorough] [--lv ±k] [--json]`.
**Output.** A table of fight, model, Lv, win %, median turns, deaths, and items used; FAIL rows are out of band.
`docs/BALANCE.md` tables are generated from `--json`. **Budget** ≤15 min for every boss on 1 CPU.
**Rule.** Tune difficulty only through this sim, never to make a test pass.
**Caught.** Bosses sitting at 100 % trivial except one at 11 %, ch11 at 9–20 %. Over-softened ch11 bosses. 夜玄 and
無相 "won" while the party was dying (the `false != null` bug).

## 9. Economy simulator

**Purpose.** The level, gold, gear and consumables each player model has at every boss and chapter boundary. This
model is what the fixtures, the boss sim and the chain test agree on.
**Inputs.** Story battle order per chapter (`content/story_path.json`), maps and the reach graph (§2), roaming
enemies (chase range plus wander radius against the critical path), step encounters, chests, shops by chapter, and
side-quest rewards.
**Models.**
- **normal**: fights every enemy met ×1.3 (backtracking), chests within 10 steps of the path, ½ of side quests.
- **minimal**: flees everything, chests within 4 steps, no side quests.
- **thorough**: fights every enemy ×1.5, every chest, every quest.
Spending is the same for all: restock the kit first, then the best gear gain per coin.
**Checks.** Per boss: model level ≥ design level − 1; normal's gear coverage ≥90 %; minimal still wins at ≥ the
floor rate (fed to §8); gold never negative.
**CLI.** `node tools/sim/economy.js [--maps] [--schedule] [--json out.json] [--diff normal]`.
**Output.** Per-chapter table, `model.json` (the input for fixtures, the boss sim and the chain), and the encounter
schedule the chain test pays. **Budget** ≤10 s.
**Caught.** The ch8 economy: 31 % → 97 % win and gear affordability 9–56 % → 92–100 %, fixed through rewards alone.

## 9b. Puzzle solver (games without combat)

**Purpose.** For a game with no `CONFIG.battle`, it replaces §8 and §9 in phase 7: every puzzle and gate on the
critical path is solvable from `chapterStart(ch)`, and every step is hinted.
**Inputs.** The load harness, the reach graph (§2), puzzle definitions with their state, inputs and solution (as the
screenplay specifies them), and quest `hint`s.
**Checks.** A search over the puzzle's real state machine finds a solution from the fixture state; the solution only
uses items and knowledge reachable before it; every step a solution needs has a pointer (hint, NPC line, marker);
`// i18n:puzzle` keys still solve in every language.
**CLI.** `node tools/sim/solver.js [--ch N] [--only ids] [--json]`. **Budget** ≤60 s.

## 10. 3D sweep

**Purpose.** Every map with the 3D renderer on: it builds, draws, has no errors, and stays within the draw-call
budget.
**Inputs.** The map list from the registry. Party and flags come from `chapterStart(chapterOf(map))`, not a
hard-coded query string with cast names. Lite mode (`?r3lite`: half resolution, no shadows or post) under SwiftShader.
**Checks (fail on any threshold; Shorelight's sweep only reported).** Build time; draw calls ≤ the requirements
budget (Shorelight median 79; the worst map at ~490 was a finding); triangles; console errors and `warnOnce` keys = 0;
**billboard fallbacks** (object or actor with no 3D model) = 0, except an explicit allowlist in `docs/qa/sweep3d.md`;
placement outliers (props in walls or floating). Batching is on; `--ab` compares against `?nobatch`.
**Darkness flags are triage, not failures.** A "too dark" heuristic also flags small rooms inside a large black
frame and title cards; a human or agent looks at each flagged shot before it becomes a bug. A large **pure-black
rectangle** in a lit scene is different: it is the HDR NaN/Inf blackout (`architecture.md` §2.5), which SwiftShader
won't reproduce, so the sweep also loads one test map with an injected Inf emitter and asserts no black block.
**CLI.** `node tools/r3d/sweep.js --out DIR [--resume] [--shard i/n] [--only map,map] [--ab]`.
**Output.** `DIR/<map>.json`, a JPEG of the 3D layer, a contact sheet, and `docs/qa/sweep3d.md`.
**Budget.** ≤60 s per map. Shard across cloud sessions (175 maps took ~2 h on one CPU). Re-run only failures, plus 10
spot checks. Never a full second pass. **To verify a fix**, sweep only the maps the fix touches (`--only`), never
every map: a full every-map screenshot sweep on a loaded 4-CPU machine ran for hours after the root fix had landed
in the first hour.
**Caught.** Every 3D-only bug that 2D tests missed: decals, spirit lights, the double HUD, the canopy fade, ending
maps crashing headless Chrome.

## 11. Music render and analysis

**Purpose.** Objective checks on procedural music the agent cannot hear, plus previews for the human (G3).
**Inputs.** The song table, rendered offline in headless Chromium through the game's own sequencer and master chain
at the default music volume.
**Checks (fail, not just print; Shorelight's tool only printed).** Integrated K-weighted loudness −20 ±3 LUFS-ish
(as this tool measures it); peak ≤ −1 dBFS. **Loop seam**: the sample jump at the
cut ≤ the signal's 99.9th-percentile step, a low periodic error into the next loop, and RMS either side within 1.5 dB.
Peak polyphony ≤ the voice budget. Every BGM id used by maps, troops or scripts exists, and every song is used.
**CLI.** `node tools/render_music.js [--ids a,b] [--loops 2] [--wav] [--preview 30 --from id=sec] [--json]`.
**Output.** A per-song table, `out_music/<id>.wav` (one seamless loop), and `<id>_preview.mp3/ogg` sent to the human.
**Budget** ≤30 s per track.
**Caught.** Loop clicks and level jumps between tracks. With the cue check in §2/§4, the festival-silence class too.

## 12. Guide builder

**Purpose.** The player strategy guide, **generated from game data**. Hand-written prose fragments hold
placeholders; tables, counts and charts are never typed by hand.
**Inputs.** `docs/guide/parts/*.md` and `chapters/chNN.md` fragments, the load harness (per-chapter attribution),
validator `--json` (**item-source graph**, reach graph, quest hints), sim JSON (balance tables), map shots (§13),
and `minigames.json` (each minigame's scoring, answers or seed rules, exported by the minigame module itself).
**Placeholders.** `<!-- chart:<name> -->` (level curve, boss HP, gold, element cycle, collectibles, route),
`<!-- table:<name> -->` (`shops:chN`, `chests:chN`, `bosses:chN`, `enemies:chN`, `items:type`, `quests:chN`,
`minigame:ID`, `missables:chN`) and `<!-- map:<id> -->` (the annotated shot, §13). They expand to SVG or HTML tables,
and to Markdown tables in the `.md` output. Chart only what has data: a game without combat has no level curve, boss
HP or element chart.
**Checks (build fails).** An unknown placeholder; a missing image; a chapter with no fragment (a stub is generated
and listed); item counts that differ from the validator's graph (the guide never recomputes them). **Every map has
an annotated image**, every quest step its pointer text, every minigame a section, and every point of no return a
「不可錯過」-style box.
**CLI.** `node tools/guide/build_guide.js [--no-inline] [--dump] [--check]`.
**Output.** A self-contained `guide_<lang>.html` (inline images, ≤10 MB), `guide_<lang>.md` plus `img/`, and
`.data.json`. **Budget** ≤60 s, plus shots.
**Caught.** Guide said 39 unobtainable items when there were 37. The ch10 chest table conflicted with a hand edit. No
image for `hakka_road`, so the 柿霜 footprints went unfound. Questions about the 剝皮寮 location and the 山歌 answers
and directions.

## 13. Screenshot harness (`shoot.js`)

**Purpose.** Deterministic stills for the guide, galleries, release notes and answers to spatial questions. It also
covers whole-map annotated renders (Shorelight's `shoot_maps.js` numbered chests only).
The tool is the shared `tools/forge/shoot.js`; the game supplies the state through its debug surface
(`debug_hooks.md`).
**Rules.**
- No encounters: load `?debug&map=<id>&noenemies=1` (or set it with `--eval-before`), so no battle photobombs a shot.
- `--wait-for <predicate>` polls game state; never fixed sleeps. Wait for the scene, then 2 settled frames.
- Labels are drawn with the **game's bundled CJK font** (`--font-from-page`), not a system default.
- **Every label comes from map data** through `--labels-eval`: exits (`→ <target map name>`), NPC names, chest
  numbers matching the guide table, clue tiles, quest targets and the player start. Never type a place name by hand.
- Whole-map render: the game's debug surface frames the whole map at a fixed scale (lighting off unless `light`),
  called with `--eval-before`; size `--viewport` to fit. Per-shot state comes from `flags=`, `vision` and `x/y` in the
  URL.
- Render mode is selectable (`render=2d|3d`). The 2D whole map is the default for annotation.
**CLI** (the tool's own usage):
```
node tools/forge/shoot.js --url URL|PATH [--out FILE.png] [--viewport 1280x720]
     [--storage KEY=JSON ...] [--init JS ...] [--eval-before JS ...]
     [--wait-for JS-PREDICATE] [--timeout MS] [--press KEYS] [--wait MS] [--selector CSS]
     [--title TEXT] [--label "x,y,text" ...] [--labels FILE.json] [--labels-eval JS]
     [--font FILE | --font-b64 BASE64|@FILE | --font-from-page JS] [--label-size PX] [--strict]
```
A typical map shot:
```
tools/forge/governor.sh -- node tools/forge/shoot.js --url "index.html?debug&map=harbor&noenemies=1" \
  --wait-for "G.Debug.idleNow()" --labels-eval "<labels from map data>" --font-from-page "<bundled font data>" \
  --out "$SCRATCH/shots/harbor.png"
```
**Output.** A PNG, plus a JSON summary on stdout. The guide builder compresses each image to ≤120 KB. Exit 1 if
loading or `--wait-for` fails (or on page errors with `--strict`). **Budget** ≤10 s per shot.
**Caught.** A random battle in a shot. The victory screen already closed. Tofu boxes in labels. The wrong street name
on a label. Wrong in-game directions from reading code.

## 14. Packaging

**Purpose.** A clean, offline, distributable zip containing exactly what the game needs.
**Steps.**
1. **Regenerate derived assets, always.** Font subset, guide and the 3D bundle if its sources changed. There is
   **no** silent fallback to a committed copy: a regeneration failure fails the build. Shorelight's `--offline`
   reused a stale font with 99 of 101 slices.
2. Copy **only referenced files**: everything the script manifest and `index.html` reference, plus the launcher,
   PLAYING, LICENSES, font license and the guide. A missing reference is an error. Unreferenced `js/**`, `tools/`,
   docs and design sources are never copied.
3. **Glyph-coverage assertion.** Collect every display string from every locale, using the i18n extractor plus data
   names, and fail on any code point the bundled font lacks, unless it is allowlisted with a reason (emoji drawn by
   the system font). Characters that appear only in code comments are excluded by the extractor, not the allowlist.
4. Normalise permissions (the launcher stays executable), drop OS junk, and write the zip with unix modes.
**CLI.** `bash tools/package.sh [-o DIR]`. **Output** `dist/<Title>-<ver>-<yyyymmdd>.zip`, plus a manifest (file
list, sizes, font glyph count and slice count, git sha). **Budget** ≤3 min.
**Caught.** The stale font (99 vs 101 slices). 裪 appearing only in a comment. Packaging run before the text was final.

## 15. Release gate (`tools/forge/release_gate.js`)

**Purpose.** Prove the shipped zip (or the hosted build), not the repo, works the way a player opens it.
**What the tool does.** It unzips into a temp path with **spaces and CJK** characters, then for each mode loads the
entry over `file://` with a clean profile, applies that mode's `--settings` (merged into `localStorage[--settings-key]`
before page scripts run) and `--query`, waits, presses the `--press` keys, evaluates every `--assert`, and screenshots
to `<out>/release_<mode>.png`. Any page error, `console.error`, failed request, network request, crash or failed
assert is an error. With `--url URL` it loads a hosted build instead of a zip (same-origin requests allowed).
**Modes.** One mode per (render × language), e.g. `2d_zh,3d_zh,2d_en,3d_en`; each sets its render mode and language
through `--settings`.
**Around it (the lead).** Freeze first: for the Release milestone no agent is running; for other milestones package
from a frozen `main` sha. The tree is clean. Build (§14), run the gate, look at every screenshot, diff the zip manifest
against the previous release, and attach `validate --strict`, `unit` and this commit's chain summary.
**CLI** (the tool's own usage):
```
node tools/forge/release_gate.js <zip> | --url URL  [--modes 2d,3d] [--out DIR] [--entry index.html]
     [--settings-key KEY --settings MODE=JSON ...] [--query MODE=QS ...]
     [--wait MS] [--press KEYS] [--eval JS ...] [--assert JS ...] [--ignore REGEX ...]
     [--viewport 1280x720] [--timeout MS] [--allow-net] [--keep] [--browser-arg ARG ...]
```
A typical run (New Game with real keys, map control reached, the bundled font loaded):
```
tools/forge/governor.sh -- node tools/forge/release_gate.js "$zip" --modes 2d_zh,3d_zh,2d_en,3d_en \
  --settings-key <id>_settings --settings '2d_zh={"render3d":false,"lang":"zh"}' … \
  --press 'wait:1500,KeyZ,KeyZ,wait:3000' --assert 'G.Scenes.top().sceneName==="MapScene"' \
  --assert 'document.fonts.check("16px "+G.CONFIG.font.face)' --out "$SCRATCH/release"
```
Save and reload are proven by the chain run's `--reload-at` (§6), not by this tool.
**Output.** One JSON report on stdout and a screenshot per mode. Exit 0 pass, 1 errors, 2 usage or setup problem.
**Budget** ≤5 min.
**Caught.** Path-with-spaces and CJK-path bugs in the launcher, a missing bundled font, and late cloud pushes after a
"final" build.

---

## Tests that lied: checklist

Before trusting any green run, confirm each item. Every "no" is a lie waiting to happen.

- [ ] A **real key-press** path exists for this flow; autoplay or debug hooks are not the only coverage.
- [ ] Level, gear, items and gold came from `chapterStart(ch)`. The run log shows **0 ASSIST lines**.
- [ ] It ran in the **player's default render mode** at least once (3D-lite counts; 2D-only does not).
- [ ] **No teleport** across any critical-path step. Walking used real collision and touch events.
- [ ] The driver **waited for script idle** before every input.
- [ ] **Any terminal state** (custom game over, title, ending, stall) fails fast. The 90 s watchdog was armed.
- [ ] The battle AI is the **player-facing auto-battle**, at the player's settings, not a test-only bot.
- [ ] Assertions cite the **spec** (screenplay beat, requirement), not observed behaviour. No "no BGM" style asserts.
- [ ] A boss "win" required the **party alive**.
- [ ] The test **never wrote** quest state, flags or items (side quests and chain).
- [ ] Encounters were **on**, with **no difficulty easing** beyond the requirements default (chain).
- [ ] **Re-entry without reload** and **save → reload** were exercised.
- [ ] Validator warnings are **0** (`--strict`), with no new allowlist entries without a reason.
- [ ] Counts in the docs came from the **validator graph**, not a separate heuristic.
- [ ] Derived assets were **regenerated** in this build, and glyph coverage passed.
- [ ] The result came from the `RESULT` summary line, not a truncated tail.
- [ ] The same stop point in 2 runs was treated as a **real bug**, not flakiness.
- [ ] Shortcuts the run used are listed in its report and in `VERIFICATION.md` (what is proven and what is not).
