# Phase 2: Engine

## Purpose

A single engine owner (the lead) writes the engine fresh from `blueprint/`, plus the game's contracts and QA skeleton. The **engine conformance suite passes before any content fan-out**.

## Inputs

- `docs/REQUIREMENTS.md` (render mode, platform, languages, reference policy), `docs/SYSTEMS.md`, `docs/STORY_BIBLE.md`.
- `blueprint/architecture.md`, `config_first.md`, `content_formats.md`, `conformance_suite.md`, `qa_tools.md`, `debug_hooks.md`.
- `docs/forge/env.md` (GPU or not; font availability).

## Steps

Runs in parallel with phase 1 writers and phase 3 designers. **Only the lead edits engine files**, in this phase and after it.

1. **Apply the reference policy** recorded in `REQUIREMENTS.md`.
   - *Similar*: clone `sol008/Shorelight` read-only into `$SCRATCH/ref/`, never into the game repo. Read the matching module, close it, write fresh code to this game's contracts. Note "referenced <module>" in the commit body. No copied files, no pasted blocks.
   - *Similar, but the clone fails* (`gh repo view sol008/Shorelight` errors, or `env.md` says unreachable): record `similar, reference unavailable → clean room` in `REQUIREMENTS.md` and continue clean room. Never block on it.
   - *Different*: clean room. Use `blueprint/` only; no agent brief mentions Shorelight's code.
2. **CONFIG first.** Write the config file (`blueprint/config_first.md`) before any engine module: title pair, slug, currency, stat names, gauge, elements and their chart, collectible name and threshold, signature mechanic, save-key prefix (`<slug>_`), default party, font face, level cap, equip slots. Cast names come from data, never typed into engine code.
3. **Core and engine layers** per `blueprint/architecture.md`, in order: util → render → input → audio → **i18n** → font → state/save → scene stack → dialog → script API → map → battle → menus → shop → minigames → play stats → debug. Rules while writing:
   - every module `G.X = G.X || {}`; no file redefines another's namespace;
   - every registry draw call is wrapped (`try/catch` → `warnOnce` → placeholder): one bad asset never kills the frame;
   - **hook registries** (battle intro/turn hooks, auto-battle fight hints, 3D arenas, VFX) instead of content monkey-patching the engine;
   - kit and content in separate files (music sequencer vs songs, sprite kit vs cast specs);
   - **i18n has a shared scope plus a per-chapter scope from day 0** (phase 6); chapter entries fill gaps and never override shared ones;
   - script end restores camera, input and HUD; interaction hit area = the object's full footprint.
4. **3D layer** (if render mode is 3D): core renderer, materials, model registry with billboard fallback, map view, a **lite mode** for headless tests (`?r3lite`-style), batching on by default with a URL flag to compare. Vendor the 3D library once as a classic script that runs from `file://`.
4b. **Audio cue stubs.** Build the music sequencer and ambience player. Then give every cue id in `docs/story/cues.json` (extracted from the screenplays' `<!-- cue: -->` lines) a playable placeholder: a simple track, or an ambience bed for "no music, ambience only" scenes. Phase 4's screenplay-conformance assertions (e.g. "this scene plays cue X") then hold from day one. Real compositions arrive in phase 9; the cue ids never change. *(Shorelight: the festival scene's ambience was never built, and a test asserted the silence.)*
5. **Debug surface** (`blueprint/debug_hooks.md`): jump to map, chapter or battle; autoplay; set flags; lite 3D; no encounters; `scriptIdle()`; terminal-state probe. Tests never need to teleport across a critical path.
6. **Game contracts** (lead writes; builders and teams read):
   - `docs/CONTRACTS.md`: art, audio and data ids and formats; battle formulas; **who owns shadows, outlines, HUD**;
   - `docs/MAP_AUTHORING.md`: map format, script API, points of no return, hint metadata, id namespaces;
   - `docs/BUILDER_BRIEF.md`: this game's supplement to `briefs/builder.md`: system invariants up front (e.g. "award a collectible only through `S.collect(id)`; ids from `collectibles.json`"), namespaces, the sample chapter to copy from;
   - `docs/CONTRACTS_3D.md` (if 3D): units, axes, camera, ownership table, budgets, instance interface.
7. **QA skeleton** (`blueprint/qa_tools.md`): `tools/test/load.js` (Node loader), `validate.js` (referential integrity, flag set/read, item sources, BFS reachability, discoverability, i18n coverage, unique names, lore lint), `unit.js`, `e2e.js`, `spec_conformance.js` (asserts `docs/story/cues.json` in game), `run.sh`, and `tools/test/lib/fixtures.js` with `chapterStart(ch)` built from the `SYSTEMS.md` progression table.
   - `tools/test/run.sh --quick` = validator + unit + conformance; non-zero exit on any FAIL. It is the base of every merge: `FORGE_TEST_CMD="bash tools/test/run.sh --quick && tools/forge/governor.sh -- node tools/test/chapters/chN.test.js && bash tools/lint/freeze.sh --verify chN" tools/forge/merge_gate.sh build/chN`.
   - **Shared build tools**, written now because phase 4 needs them for stubs and the first playable zip:
     - `tools/i18n/extract.js` (spec in `phases/06_localization.md` step 1): `--stub chN`, `--missing`, coverage report, puzzle keys marked by `// i18n:puzzle`;
     - `tools/package.sh [-o DIR]` (`blueprint/qa_tools.md` §14): always regenerates derived assets, never falls back to a committed font;
     - `tools/build_font.py` (`blueprint/architecture.md`): font subset from every display string, fontTools, base64 parts;
     - `tools/render_music.js` stub (`blueprint/qa_tools.md` §11): renders the placeholder cues offline and prints peak/loudness; phase 9 completes it.
   Every browser test:
   - runs through `tools/forge/governor.sh -- <cmd>`;
   - defaults to the **player's default render mode** (lite variant for speed, never "off");
   - has a 90-s no-output watchdog and detects any terminal state;
   - writes a PASS/FAIL summary line to a file.
8. **Conformance suite** (`tools/test/conformance/`, spec `blueprint/conformance_suite.md`). At minimum:
   - awaited moves resolve (including followers); move speed resets after a move;
   - draw isolation: one draw call cannot corrupt the next one's transform or state;
   - `bgm: null` is silence without warnings, including after a battle;
   - camera, input and HUD are restored at script end; the player is on screen after every cutscene;
   - re-entering a map without a reload rebuilds per-entry state;
   - dialogue advances on a **real key press** with autoplay off, exactly one page per press;
   - full-footprint interaction for multi-tile objects;
   - terminal-state detection (every game-over variant, title, no state change for N s).
   Run it in the default render mode and in the fallback mode. Sketch of one case:
   ```js
   test('script end releases camera', async (g) => {
     await g.load('?debug&map=sandbox&autoplay=0');
     await g.run(async S => { await S.camera(5, 5); });   // script never releases it
     await g.waitIdle();
     assert(g.eval(() => G.Cam.follow === 'player'), 'camera returned to player');
     assert(g.eval(() => G.isOnScreen(G.player)), 'player visible');
   });
   ```
9. **Sandbox + sample chapter.** A sandbox map and a one-chapter sample that uses every content feature: quest with hints, collectible, point of no return, shop, chest, boss with hooks, a minigame, a multi-tile object, a `[PUZZLE-LANG]` puzzle (its key tagged `// i18n:puzzle`). Its chapter test (real key-press path, `chapterStart`) is the template builders copy.
10. **Screen smoke.** Open every menu and screen in every language; fail on any console error.
11. **Platform spike.** Boot the sandbox from `file://` (and the launcher, if the platform needs one) inside a path with spaces and non-ASCII characters. Packaging itself is phase 11.
12. **After fan-out: engine bug intake.** Builders and teams report engine bugs in a fixed format (file:line, repro URL, expected vs actual) and never patch the engine. The lead fixes once, adds a conformance case, and broadcasts "fixed in <sha>; workarounds optional".

## Outputs

- Engine files per `blueprint/architecture.md` (config, core, engine, gfx registry, optional 3D layer), `index.html`, entry script.
- `docs/CONTRACTS.md`, `docs/MAP_AUTHORING.md`, `docs/BUILDER_BRIEF.md`, `docs/CONTRACTS_3D.md` (if 3D).
- `tools/test/{load,validate,unit,e2e,spec_conformance}.js`, `tools/test/run.sh` (with `--quick`), `tools/test/lib/fixtures.js`, `tools/test/conformance/*`.
- `tools/i18n/extract.js`, `tools/package.sh`, `tools/build_font.py`, `tools/render_music.js` (stub).
- Sandbox map, sample chapter and its test.

## Exit gate

Automated (all must hold before phase 4 launches a single builder):
- [ ] Conformance suite green in the default render mode **and** the fallback mode.
- [ ] Sample chapter test PASS, including the real key-press path.
- [ ] Validator 0 errors, 0 warnings; unit tests green; screen smoke green in every language.
- [ ] Vocabulary leak check: no config value (title, currency, stat names, cast ids) appears as a literal in engine files.
- [ ] Platform spike boots from a path with spaces and non-ASCII characters.
- [ ] `bash tools/package.sh -o "$SCRATCH/dist"` builds a zip of the sandbox with a freshly built font; `extract.js --stub` and `render_music.js --json` run without error.

No human gate.

## Pitfalls from Shorelight

- **Engine bugs found by content builders.** An awaited follower move never fired `onArrive`, freezing cutscenes in ch5, 6, 7 and 8; each builder wrote its own workaround. Also: a `move` speed leak, a monster draw corrupting every later draw (missing save/restore), `bgm: null` warnings after battles. All are now conformance cases.
- **Dialogue ignored real Z presses** (`pressed('ok')` consumed twice). Autoplay tests passed; a builder found it.
- **Camera stuck after a cutscene** (`S.camera` never released in the mushroom scene and 3 ch3 scenes). The player found it. Fixed by an engine guard at script end.
- **Footprints missing on re-entry**: per-entry state built only on a fresh load.
- **Carts and oars interactable from one half only**: the engine used the nominal tile.
- **`new UI().List(...)` crashed the menu on open**; **`G.Mapx = {}` in two files** clobbered each other; a script counter went negative; **one art exception blanked the whole frame**.
- **Vocabulary baked into ~10 engine files** (currency 文, 生命/真氣, 劍意, 心燈, cast ids in debug/title/dialog). Chapters wrapped `G.Battle.start` to add intros. Hence CONFIG first and hook registries.
- **Headless software WebGL was too slow**, so every test ran 3D off while 3D was the default; HUD drawn twice, broken decals and the camera bug shipped. Hence the lite mode, never "off".
- **Ctrl+F bound twice** (fullscreen and auto-battle). Keep one input map in config.

## Time/cost estimate

- ~1 h of lead time for the core and contracts; +30 min with a 3D layer; conformance and sample chapter ~30 min. Overlaps phases 1 and 3.
- Cost: lead only.
