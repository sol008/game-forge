# Builder brief: {{UNIT}} — {{GAME}}

<!-- Lead: one builder per chapter/level, one worktree each. Fill every slot and delete this comment;
`grep -n '{{' brief` must then print nothing. Send only after the engine conformance suite is green and the
screenplay is frozen. -->

## Goal
Build {{UNIT}} ({{UNIT_KIND}}) as playable content, exactly as the frozen screenplay `{{SCREENPLAY}}` (hash
`{{SCREENPLAY_HASH}}`) says: every map, NPC and line, cutscene beat, choice, side quest, collectible, shop, chest,
puzzle, encounter, boss and sound cue. Enter via `{{ENTRY_API}}`; hand off to {{NEXT_UNIT}} via `{{HANDOFF_API}}`.

## Read first (in order)
1. `{{REQUIREMENTS}}`: render mode, QoL defaults, languages.
2. `{{MAP_AUTHORING}}`, `{{CONTRACTS}}`: map format, script API, art/audio ids. Binding.
3. `{{SCREENPLAY}}`. If `{{HASH_CMD}}` does not print `{{SCREENPLAY_HASH}}`, stop and report: never build on a moving spec.
4. `{{BIBLE}}`, `docs/canon/appearance_facts.json`, `docs/canon/collectibles.json` (the plan list),
   `docs/i18n/GLOSSARY.md`, `docs/story/cues.json`, `{{PROGRESSION_TABLE}}`.
5. The engine source of every API you call: {{ENGINE_FILES}}. Neighbouring units are read-only (hand-off flags).

## Files you own (exclusive)
- `{{UNIT_FILE}}`, `{{UNIT_TEST}}`, `{{STUB_FILES}}` (one per target language, none when `langs` = [source]; keys
  only, value `{{STUB_MARK}}` until the translator pass).
- New ids follow the id grammar (`blueprint/content_formats.md` §0): flags `chN_*`; items, skills, enemies `cN_*`;
  troops `t_cN_*`; quests `q_cN_*`. Map ids are unique snake_case place names (`tamsui_fort`), no chapter prefix;
  the validator checks them game-wide.
- Never edit anything else: engine, shared data, other units, tools, shared test helpers.
- Missing data (an item, a troop): define it in your unit file under your `cN_` prefix, in the shared format.
- Engine or shared bug: do not patch it and do not hide a workaround. Report it (format below) and build the rest.
  The lead fixes it once for every builder and broadcasts.

## Build rules
- Display text in {{SRC_LANG}} as whole static strings; no sentences assembled from fragments or variables. A line
  the screenplay tags `[PUZZLE-LANG]` gets `// i18n:puzzle` beside its key.
- Use only registered art/audio ids. Grep the registry before you use one; never invent an id.
- Every interactable has a visible marker or glint, a pointer (NPC line or quest-log hint) and a hit area of ≥ 2
  tiles. Multi-tile objects are interactable across their full footprint. Every quest step has `hint` metadata.
- Every one-way transition is declared with `{{PONR_API}}` and lists the side content it makes missable.
- Every script ends with camera, input and HUD restored, and the player on screen.
- No dynamic flag names unless the pattern is declared in `{{FLAG_REGISTRY}}`. Collectibles go through
  `{{COLLECTIBLE_API}}`, never a bare flag; their ids are derived from the quest id (`q_c3_bell` → `ember_c3_bell`),
  never typed, and each one must match a row of `docs/canon/collectibles.json`. Names are unique across characters,
  items and skills.

## Test (`{{UNIT_TEST}}`)
- Every session starts from `{{FIXTURE}}`. Never set level, gear, items, gold or flags by hand; ad-hoc boosts fail.
- The critical path uses real input: `{{INTERACT_KEY}}` presses through at least one full dialogue, one choice and one
  battle, if any. Autoplay may cover the rest. Wait for script idle before every input.
- No teleport across the critical path. Walk it. A warp is allowed only to set up a side quest; comment why.
- Assert every side quest, collectible and the hand-off. Fail fast on: page or console error, `{{LAST_ERROR}}`,
  missing-art warning, or any terminal state (game over, title, no state change for {{STALL_S}} s).
- Sound cues come from the screenplay's `<!-- cue: -->` lines, extracted to `docs/story/cues.json`;
  `tools/test/spec_conformance.js` asserts them (BGM or ambience id per scene, required silence). Make it pass; turn
  the other scene notes into assertions in your test. A test encodes the spec, never current behaviour.
- Re-enter at least one map without a reload and assert it still works.
- Screenshot each map once to scratch and LOOK at it: blocked doors, hidden actors, unreachable areas, lighting.

## Definition of done
1. `{{UNIT_TEST_CMD}}` PASS in **{{RENDER_MODE}}** (the player's default) using `{{FIXTURE}}`, plus one smoke pass in
   {{OTHER_RENDER_MODE}} if the game has one.
2. `{{VALIDATE_CMD}}`: 0 errors, 0 new warnings (reachability, item sources, flags read/written, discoverability).
3. `{{I18N_CMD}}`: every new {{SRC_LANG}} key has an entry in every target language (none when `langs` = [source]),
   real or stub.
4. Commit only your owned paths (`git add <paths>`, never `-A`) to `{{BRANCH}}` in `{{WORKTREE}}`.
5. Report, then **STOP**. Polish ideas go in the report's Backlog, not into code.

## Time budget and stop rule
Budget {{BUDGET_MIN}} min. At 75 %: no new work, fix failures only. At 100 %: commit what is green, report PARTIAL,
stop. The same failure at the same step twice is a real bug: report it, don't loop on it.

## Re-run scope
After a fix, re-run only the failing segment (`{{SEGMENT_FLAG}}`), then one final full run. Never re-run green runs
"to be sure".

## Tools and hygiene
- Browser tests only through `tools/forge/governor.sh -- <cmd>` (the forge tools live in `tools/forge/`). Never launch
  a browser yourself. Run long tests in
  the background and poll the log.
- Logs, screenshots, scratch scripts go to `$SCRATCH/{{AGENT_ID}}/` (set in `docs/forge/env.md`), never the repo.
- Only report APIs you can show by file:line. Grep before you claim.

## Report format
```
STATUS: DONE | PARTIAL | BLOCKED        time: <used>/{{BUDGET_MIN}} min
Branch: {{BRANCH}} @ <sha>              Screenplay hash: {{SCREENPLAY_HASH}}
Test: {{UNIT_TEST_CMD}} → <n/n PASS> in {{RENDER_MODE}} (log: $SCRATCH/{{AGENT_ID}}/<file>)
Validator: <errors>/<warnings>          target-language keys: <present>/<total>
Maps: <ids>    Quests/collectibles: <ids>    Data added: <ids>
APIs relied on: <name> — <file:line>
Engine/shared bugs (unpatched): <file:line> | repro | expected | actual
Spec parts not built, and why:
Shortcuts in tests (warps, autoplay spans):
Backlog:
```

> **Shorelight lesson** (opening Shorelight itself: similar policy only).
> The ch1 builder passed 6/6, then polished for 30 more minutes and broke its own green run;
> it had no definition of done. Boss tests passed only because tests set the party to Lv36 instead of the expected
> ~28. Every test ran with 3D off while 3D was the default, so the player found the camera bug. Four builders each
> worked around the same engine bug (an awaited move that never resolved) instead of reporting it once.
