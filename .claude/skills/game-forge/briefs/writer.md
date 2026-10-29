# Writer brief: {{DOC_KIND}} for {{UNITS}} — {{GAME}}

<!-- Lead: DOC_KIND = story bible section | screenplay. Several writers run in parallel by region or chapter group.
Send only after G0/G1 lock premise, setting/route, title, cast roster and render mode, and after the screenplay lint
`tools/lint/screenplay.js` exists. Fill every slot and delete this comment. -->

## Goal
Write {{DOC_KIND}} for {{UNITS}} so a builder can turn it into code with no questions. It must be canon-consistent,
culturally sound, and complete: every scene has a map, a sound cue, its encounters and its rewards.

## Read first
1. `{{REQUIREMENTS}}`: premise, tone, themes, setting and route scope, content limits, render mode, scope.
2. `{{BIBLE}}` (canon), especially cast voices, route, chapter beats and the cultural guide `{{CULTURE_GUIDE}}`.
3. `docs/canon/appearance_facts.json`, `docs/canon/timeline.json`, `{{NAME_INDEX}}`, `docs/i18n/GLOSSARY.md`.
4. `{{CONTRACTS}}` (map, sprite, music and monster ids) and `{{PROGRESSION_TABLE}}` (levels, gold, encounter levels).
5. Neighbouring writers' files, read-only, for hand-off flags: {{NEIGHBOUR_FILES}}.

## Files you own (exclusive)
- `{{OUT_DIR}}/{{UNIT_PREFIX}}*.md`. Nothing else.
- The bible, appearance facts, timeline and glossary belong to the lead. Put proposed changes in your report.
- If canon is wrong or blocks you, report it; never "fix" another writer's file.

## Screenplay format (one file per unit)
1. **Maps**: id (a unique snake_case place name such as `tamsui_fort`, no chapter prefix), a name in every language
   of `langs`, purpose, size in tiles, layout prose plus an ASCII sketch (exits, NPCs, chests, clue tiles, enemies,
   puzzles), time of day, lighting, particles, connections.
2. **Sound per scene**: one cue line per scene, `<!-- cue: <scene-id> bgm=<id>|none ambience=<id>|none sfx=<ids> -->`;
   `bgm=none` carries its reason in the prose. The lint extracts these to `docs/story/cues.json`, and
   `tools/test/spec_conformance.js` asserts them in game. No other cue format.
3. **NPCs**: id, sprite id, position, all dialogue, and every flag-dependent variant.
4. **Cutscenes** as numbered beats: `speaker(expression): line`, stage directions in [brackets], choices and branches,
   flags set (`flag: chN_snake_case`), items given, party joins and leaves, battles with rules (if the game has any).
5. **Side quests and collectibles** step by step: quest id `q_cN_<name>`, start pointer, a `hint` for every step,
   conditions, rewards. A collectible's id is derived from its quest id; it must be a row of
   `docs/canon/collectibles.json` (the plan list, owned by the lead).
6. **Shops, inns, chests, puzzles** with exact mechanics (state, inputs, solution, failure). Minigames with scoring.
7. **Encounters and bosses** (if any): per map, at levels from `{{PROGRESSION_TABLE}}`; boss gimmick and phases.
8. **Points of no return**: each one-way moment and what it makes missable.
9. **Names table**: every new map, character, item and quest with its name in every language of `langs`.

## Writing rules
- Voices come from the bible. {{SILENT_CHARS}} never speak: narration and emotes only.
- Appearance words (hair, eyes, build, clothing) come only from `docs/canon/appearance_facts.json`; dates only from
  `docs/canon/timeline.json`. Speakers come from `docs/canon/speakers.json`, cast facts from `docs/canon/cast.json`.
- Check every new name against `{{NAME_INDEX}}`; no clash with a character, item or skill.
- Culture: ground places, food, trades and festivals in fact. Sacred rites are witnessed only: ambience without
  melody, no minigames. Never invent rites for real peoples. Use dialect words only where you are sure of them; never
  pidgin. {{CONTENT_LIMITS}}.
- Dialogue lines ≤ {{MAX_LINE}} characters. Mark any puzzle that depends on {{SRC_LANG}} glyphs, puns or rhyme with
  `[PUZZLE-LANG]` so the translator can handle it.
- Use only ids that exist in `{{CONTRACTS}}`; name a fallback id when you want new art.

## Definition of done
1. `{{SCREENPLAY_LINT_CMD}}` (`tools/lint/screenplay.js`) passes: every scene has a map, a cue line, encounters and
   rewards.
2. `{{LORE_LINT_CMD}}` is clean: appearance facts, speaker whitelist, timeline, unique names.
3. Tests: none for you to run. Write for the default render mode ({{RENDER_MODE}}: camera, staging), and take levels
   and rewards from the canonical progression table, the same one the test fixtures use.
4. Strings: the Names table covers every name you introduce, in every language of `langs`. The two lints above are
   your validator.
5. Commit only your files to `{{BRANCH}}` in `{{WORKTREE}}`. Report, then **STOP**. The lead freezes and hashes the
   screenplay; after that, changes go through the lead only.

## Time budget and stop rule
Budget {{BUDGET_MIN}} min for {{UNITS}}. At 75 %: finish the open unit, start no new one. At 100 %: commit, report
PARTIAL with the missing sections listed, stop.

## Re-run scope
On lint failures, fix and re-lint only the failing units.

## Tools and hygiene
- You should need no browser. If you must view something, use `tools/forge/governor.sh -- <cmd>` only.
- Notes, drafts and logs go to `$SCRATCH/{{AGENT_ID}}/` (set in `docs/forge/env.md`), never the repo.
- Only cite APIs or ids you can show by file:line.

## Report format
```
STATUS: DONE | PARTIAL | BLOCKED        time: <used>/{{BUDGET_MIN}} min
Branch: {{BRANCH}} @ <sha>    Files: <paths>
Lint: screenplay <pass/fail>, lore <pass/fail>
Units: <id> — maps <n>, scenes <n>, side quests <n>, collectibles <n>, bosses <n>
Hand-off flags in/out: <flag> — <file:line>
New art or audio wanted (with fallback ids):
[PUZZLE-LANG] items:
Canon conflicts or proposed bible/timeline/glossary edits:
Backlog:
```

> **Shorelight lesson** (opening Shorelight itself: similar policy only).
> The setting changed to "all of Taiwan" after 15 agents had launched, and every writer was
> relaunched. Scripts called 白芷 silver-haired after her design was picked otherwise, and a cat spoke a line against
> the silent-pet rule; both rules existed only in prose. A screenplay revised mid-build forced a re-brief. A festival
> scene had no ambience cue, so a test asserted "no BGM" and locked the bug in.
