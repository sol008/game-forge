# Phase 4: Chapter build

## Purpose

Turn each frozen screenplay into playable, tested content: one builder per chapter, each in its own worktree, each stopping at a written definition of done. The lead merges only green branches.

## Inputs

Hard preconditions (checked by the lead before the first launch):
- Conformance suite green at `main` HEAD (phase 2 exit gate). **No builder starts before this.**
- `docs/story/FREEZE.md` hashes match the screenplay files.
- `docs/MAP_AUTHORING.md`, `docs/BUILDER_BRIEF.md`, `docs/CONTRACTS.md`, the sample chapter and its test.
- `tools/test/lib/fixtures.js` with `chapterStart(ch)`; validator; i18n extractor with `--stub`.
- Shared test helpers already exist (`tools/test/lib/*`). Builders never create shared helpers.

## Steps

1. **Plan the wave** (lead). One work package per chapter (split a chapter > ~2,000 screenplay lines into two packages by map group, each with its own file). Register every package with `tools/forge/agents.sh add <id> <task> <branch> <log> <eta>` (put the chapter and worktree in the task text, e.g. `ch5 build ../wt/ch5`).
2. **Worktrees** (lead). `git worktree add ../wt/chN -b build/chN` per package. Exclusive namespace per builder:
   - `js/maps/chN_<slug>.js` (maps, quests, chapter-local data prefixed `cN_*`, `t_cN_*`);
   - `tools/test/chapters/chN.test.js`;
   - the chapter's i18n stub file(s), written by the extractor only;
   - scratch output in `$SCRATCH/chN/`.
   Never: engine files, shared data files, other chapters, `index.html` (the lead pre-registers chapter files).
3. **Canary** (when there are ≥ 6 chapters). Launch the first 2 builders; after their first test run (~20 min), fold any brief or engine fixes into `BUILDER_BRIEF.md`, then launch the rest.
4. **Launch builders** (local agents, `briefs/builder.md` + `docs/BUILDER_BRIEF.md`). Up to ~11 at once; writing is CPU-light, but **every browser test runs through `tools/forge/governor.sh -- …`** (slots = nproc − 1), so tests queue instead of thrashing. Each brief states:
   - chapter, screenplay path and **frozen hash**; owned files; time budget (90 min);
   - **definition of done** (below), then commit on own branch, report, **stop**; extra ideas go to the report's backlog;
   - re-run scope: only the failing segment (`--from`, `--only`);
   - "report only APIs you can show by file:line"; engine bugs reported in the fixed format, never patched;
   - long tests run in the background and are polled, so lead messages get through.
5. **Builder definition of done** (in every brief):
   - [ ] every map, NPC, beat, side quest, shop, chest, puzzle and boss in the screenplay is implemented, or listed as "not implemented: why";
   - [ ] validator: 0 errors, 0 warnings in own files;
   - [ ] chapter test PASS **in the default render mode** (lite variant allowed), started from `chapterStart(ch)`; any ad-hoc level, gear or gold boost fails the run;
   - [ ] the test includes a **real key-press** path (dialogue and one interaction with autoplay off), waits for script idle before input, never teleports across the critical path, asserts the hand-off to the next chapter and ends there;
   - [ ] the `<!-- cue: -->` assertions for this chapter (`docs/story/cues.json`, checked by `tools/test/spec_conformance.js`) pass;
   - [ ] every side quest exercised; every collectible awarded through the engine API with its derived id (`<collectibleId>_<quest suffix>`, e.g. `q_c3_bell` → `ember_c3_bell`), never hand-typed; the validator checks it against `docs/canon/collectibles.json`;
   - [ ] every quest step has `hint` metadata; every interactable has a marker and a hit area of ≥ 2 tiles;
   - [ ] every one-way transition uses the point-of-no-return API;
   - [ ] every map screenshotted (via `shoot.js` through the governor) and viewed;
   - [ ] i18n stubs regenerated for the chapter: an entry in every target language (none when `langs` = [source]); display text is whole static literals;
   - [ ] screenplay hash re-checked at done.
   Sketch of the fixture rule the test uses:
   ```js
   const st = chapterStart(5);                 // level, party, gear, kit from G.Data.progression
   await game.load(`?debug&startch=5&fixture=${st.id}`);
   game.forbid(['setLevel', 'giveGold', 'giveItem', 'setFlag']);  // throws if a test calls them
   await game.waitIdle();
   await game.pressKey('z');                   // real input path, autoplay off
   ```
6. **Merge loop** (lead, continuous). For each builder reporting FINISHED:
   ```
   FORGE_TEST_CMD="bash tools/test/run.sh --quick && tools/forge/governor.sh -- node tools/test/chapters/chN.test.js && bash tools/lint/freeze.sh --verify chN" tools/forge/merge_gate.sh build/chN
   ```
   That is `merge-tree` pre-check → merge → `run.sh --quick` (validator, unit, conformance) + that chapter's test (through the governor) + the screenplay hash check → roll back on red. Once phase 7 gates the chapter, append `&& bash tools/test/run.sh --balance chN`. Never merge red; never `git add -A` on the lead tree.
7. **Engine bugs** (lead). Fix once in the engine, add a conformance case, broadcast "fixed in <sha>; workarounds optional" to every builder.
8. **Canon changes mid-build** (lead). A cut, a pick, a renamed item: send **one** standard change brief to all builders (cut list, locked looks, new ids). Propagate cuts without asking the user. Late screenplay edits: bump `FREEZE.md`, send the diff to that builder only.
9. **Follow-ups** (lead). Fixes for files a builder still owns go to `docs/forge/followups.md` keyed by owner; flush on hand-off.
10. **Watchdog and backfill** (lead, every check-in).
    - No log growth or commit for 20 min → read the log tail and test progress; a stalled child process may be killed so the agent wakes.
    - The same stop point in two runs is a real bug, not a flake.
    - Load under target with backlog → start the next package: translation of merged chapters (phase 6), balance once 2 chapters merged (phase 7, `briefs/balance.md`).
11. **First playable** (lead). When chapters 0–1 (or the first two) are merged and New Game reaches the last merged chapter's hand-off: freeze `main` at a sha, package from it and run the release gate (phase 11, First playable milestone), then send the zip automatically. **No drain:** builders keep working on their branches.

## Outputs

- `js/maps/chN_<slug>.js` per chapter (maps, quests, chapter-local data).
- `tools/test/chapters/chN.test.js` per chapter.
- i18n stub entries per chapter (filled in phase 6).
- Curated `screenshots/chN/` (lead copies chosen shots; raw shots stay in `$SCRATCH`).
- Updated registry (`tools/forge/agents.sh`; snapshot in `docs/forge/AGENTS.md` at each check-in), `docs/forge/followups.md`.

## Exit gate

Per chapter (automated, enforced by `tools/forge/merge_gate.sh` with the `FORGE_TEST_CMD` above):
- [ ] Chapter test PASS in the default render mode, from `chapterStart(ch)`, with the real key-press path.
- [ ] Validator 0 errors, 0 warnings; screenplay hash unchanged since launch (or re-briefed).
- [ ] i18n stubs present for every new display string, in every target language.

Phase (all chapters merged): full validator clean on `main`; every chapter test green on `main`; first-playable zip sent. No human gate.

## Pitfalls from Shorelight

- **12 builders + ~12 headless browsers on 4 CPUs**: load ~26, every test 2–3× slower. A test-slot queue closed 10 chapters in ~1 h.
- **No definition of done**: the ch1 builder polished for 30 min after 6/6 passed. Commit, report, stop.
- **Builders patched around engine bugs** (the `onArrive` freeze hit ch5–8); six workarounds, then a central fix.
- **Boss tests passed only because tests raised the party level** (ch8 at Lv36 vs ~28); the ch8 `tide` test fought ungeared. Hence `chapterStart` and the forbid list.
- **Every chapter tested with 3D off** while 3D was the default: chapter decals, overlays and a doubled HUD broke only in 3D.
- **The ch11 lighthouse stairs sat on wall tiles**; the test teleported past every floor, so the finale was unreachable on foot.
- **Fake soft-locks**: tests fired events during opening cutscenes. Wait for script idle.
- **ch5's test kept waiting after handing off to ch6.** Hand-off ends the segment.
- **Collectibles via flags only** didn't count toward the ending; the lead had to message two builders.
- **Shared working tree**: 40+ stop-hook nags, 27+ "WIP snapshot" commits; one helper's half-built sparkle code broke another's ch11 test.
- **ch11 test hung 8+ min** on a boss that could never end; results misread from a truncated `tail`. Watchdog + summary line in a file.
- **An agent reported `G.Tiles.warm`**, an API that didn't exist. File:line or it didn't happen.
- **Untranslated lines** (4 each in ch3, 7, 9) from a helper whose done criteria lacked i18n.

## Time/cost estimate

- 1–2 h wall clock with the governor. A chapter's full test takes 10–15 min alone on the machine; finishing a chapter took 30–90 min, mostly test → fix → re-run the failing segment.
- Local: about 1–2 agent-hours per chapter (11 chapters ≈ 11–22 agent-hours), up to ~11 agents at once (`tools/forge/cost_estimate.md` row 4).
- Cloud: $0 in the G0b forecast. In `max-speed` pace, CPU-heavy re-runs may overflow to cloud; that comes out of the 25% contingency.
