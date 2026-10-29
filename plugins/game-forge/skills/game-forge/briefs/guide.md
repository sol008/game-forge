# Guide brief: strategy guide, {{SECTIONS}} — {{GAME}}

<!-- Lead: the guide is always a deliverable. One agent owns the framework (builder + templates); others write unit
sections. Start after content freeze for the units covered. Fill every slot and delete this comment. -->

## Goal
Write the {{GUIDE_LANGS}} strategy guide for {{SECTIONS}}: a walkthrough a stuck player can trust. Everything
countable or spatial is **generated from game data**. Every map is annotated, every clue is located, every minigame
is explained, and every missable is warned.

## Read first
1. `{{REQUIREMENTS}}` (guide language, tone, charts) and `{{GUIDE_SPEC}}` (structure, placeholder syntax).
2. `{{GUIDE_BUILDER}}`: how `<!-- table:<name> -->`, `<!-- chart:<name> -->` and `<!-- map:<id> -->` placeholders
   expand.
3. Game data: {{DATA_FILES}}; quests, points of no return, collectibles, shops; the validator's item-source graph.
4. `{{SCREENPLAYS}}` for {{SECTIONS}}: intent and tone only. Data wins where they disagree; report the mismatch.

## Files you own (exclusive)
- `{{GUIDE_DIR}}/{{SECTION_PREFIX}}*.md` (prose), `{{GUIDE_IMG_DIR}}/{{SECTION_PREFIX}}*`.
- Framework owner only: `{{GUIDE_BUILDER}}`, `{{GUIDE_TEMPLATES}}`. Framework owner: {{FRAMEWORK_OWNER}}.
- Never hand-edit generated sections or outputs. Never edit game files: unobtainable items, missing hints or wrong
  data are game bugs. Report them.

## Content rules
- Counts, lists, tables, stats, prices, drop rates and item sources come from placeholders, never typed by hand.
  The unobtainable-item count must equal the validator's.
- **Every map** gets an annotated image from `tools/forge/shoot.js` (`?debug&noenemies=1`, `--wait-for`,
  `--font-from-page`): exits, named places, NPCs, chests, clue tiles, quest targets. Labels come from map data
  (`--labels-eval`).
- Spatial directions only from rendered images, never from reading code.
- **Every quest step**: where to go, who or what points there, the reward. Every missable step sits in a
  "Missable" box built from the point-of-no-return data.
- **Every minigame**: rules, scoring, win threshold, best answers, and what is random (say "randomized" plainly).
- Spoilers are marked; puzzle answers sit after the hint.
- Charts are generated from data, and only those whose data exists (level curve, boss HP, gold and element chart
  need battles; a game without combat charts collectibles, puzzles and route only).

## Definition of done
1. `{{GUIDE_BUILD_CMD}}`: 0 missing images, 0 unexpanded placeholders, 0 unobtainable items (or the exact validator
   list, flagged as game bugs), and every quest step has a pointer.
2. Tests: map shots are taken in **{{RENDER_MODE}}** from the canonical fixture `{{FIXTURE}}` state for each section;
   the built HTML renders headless with 0 console errors.
3. `{{VALIDATE_CMD}}` clean (the guide reads it; it must not change it). Every language in {{GUIDE_LANGS}} builds
   and passes the same checks.
4. Commit only your owned paths to `{{BRANCH}}` in `{{WORKTREE}}`. Report, then **STOP**.

## Time budget and stop rule
Budget {{BUDGET_MIN}} min. At 75 %: finish the open section, start none. At 100 %: commit, report PARTIAL with the
missing sections. Never fill a gap by guessing at game data.

## Re-run scope
Re-shoot only the maps that changed or failed; rebuild only your sections, then one full build.

## Tools and hygiene
- Map shots and HTML render checks run only through `tools/forge/governor.sh -- <cmd>`.
- Raw shots, data dumps and logs go to `$SCRATCH/{{AGENT_ID}}/` (set in `docs/forge/env.md`). Only curated images
  go in `{{GUIDE_IMG_DIR}}`.
- Only report data APIs you can show by file:line.

## Report format
```
STATUS: DONE | PARTIAL | BLOCKED        time: <used>/{{BUDGET_MIN}} min
Branch: {{BRANCH}} @ <sha>    Sections: <ids>
Build: maps <shot>/<total>, quests with pointer <n>/<n>, minigames documented <n>/<n>, placeholders unexpanded 0
Game bugs found (not fixed): <file:line> | unobtainable item / missing hint / data vs screenplay mismatch
Data APIs relied on: <name> — <file:line>
Backlog:
```

> **Shorelight lesson** (opening Shorelight itself: similar policy only).
> The guide's own count said 39 unobtainable items; the strict validator scan found 37. The lead
> gave wrong in-game directions to the mushroom grove from reading code; only the annotated map was right. After
> release the player still had to ask where 剝皮寮 was, where 柿霜's footprints were, and what the 山歌 answers were.
> Two agents hand-edited the same chest table, and the merge conflicted.
