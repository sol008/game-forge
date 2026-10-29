# Phase 10: Docs

## Purpose

Ship the player-facing and reviewer-facing documents. All four are **always** made:

| Document | What it is |
|---|---|
| Strategy guide | Generated from game data. Every map is annotated; every minigame and puzzle is explained; it has charts wherever the data exists. |
| `PLAYING.md` | The player manual |
| `RELEASE_NOTES.md` | Notes for each build |
| `VERIFICATION.md` | What the tests prove and what they don't |

The rule: **nothing in a doc that the data already knows is typed by hand.** A number, count, location or answer comes from the data or from a rendered map, so the docs can't drift from the game.

## Inputs

- The merged game. Phase 8's static checks must be green: the item-source graph and the quest `hint` metadata feed the guide.
- `docs/BALANCE.md`: the economy simulator's level curves, boss levels, gold (combat games), or the solver's per-chapter results (non-combat games).
- `docs/qa/points_of_no_return.md` (missable boxes) and the side-quest reports (quest steps and clues).
- `docs/REQUIREMENTS.md`: guide language(s), tone, charts on or off, platform and launcher.
- `tools/forge/shoot.js`, the screenshot harness: no encounters, waits for state, bundled CJK font, labels from map data.
- `briefs/guide.md`.

## Steps

1. **Launch** (lead). Start once phase 8's static checks pass; this overlaps phases 8 and 9. 3 local agents with `briefs/guide.md`, each in a worktree:
   - **A, framework**: builder, map shots, charts, database, minigames. Owns `tools/guide/*` and `docs/guide/parts/`.
   - **B and C, chapter writers**, split by range. They own `docs/guide/chapters/chNN.md` for their chapters only.

   The lead writes `VERIFICATION.md`, because it knows what each suite really does.
2. **Builder** (A). `tools/guide/build_guide.js` works like this:
   - It loads the game data headlessly with the test loader.
   - It expands placeholders in the fragments: `<!-- table:id -->`, `<!-- chart:id -->`, `<!-- map:id -->`.
   - It emits a self-contained HTML file (inline images, charts with hover and a data table under each) and a Markdown copy.
   - Every database table is generated: items with their **source** column, gear, skills, enemies, shops, chests, quests, collectibles, bosses. The source column comes **from the validator's item-source graph**, the same code phase 8 runs.
   - Prose lives only in fragments. Generated sections are never edited by hand.
3. **Annotated maps** (A; browser slots through the governor). Shoot **every** map in `G.Maps`, interiors included, with `tools/guide/shoot_maps.js` (built on `shoot.js`). Annotate from map data:
   - exits, labelled with their destination;
   - NPCs, by name;
   - **clue tiles and quest targets**, labelled with the quest step;
   - chests, numbered as in the chapter tables. Spirit-only or hidden ones get a second colour; if a hidden layer exists, add a second "vision" image;
   - save points, shops, and point-of-no-return triggers;
   - coordinate ticks and a legend.

   Re-shoot only maps whose data hash changed.
4. **Minigames** (A). For every minigame *instance*, generate:
   - rules;
   - the scoring table, from data;
   - the win threshold;
   - **best answers**, computed by a solver over the data;
   - **randomness**: exactly what is random and what is fixed, and a mnemonic when the inputs are random;
   - retry rules;
   - what is lost by forfeiting.
5. **Charts** (A). Make only the charts whose data exists in this game; skip the rest without a placeholder. Candidates:
   - with combat (`CONFIG.battle`): level curve for the minimal, normal and thorough players against boss levels; boss HP; gold per chapter; growth per character; the element chart;
   - any genre: collectible distribution and the ending threshold; the whole route and a route map per chapter; puzzle count and solution length per chapter (from `tools/sim/solver.js`, if built).

   Every chart has an expandable data table.
6. **Chapter walkthroughs** (B, C, in parallel). Each chapter has:
   - an overview table (recommended level from BALANCE if the game has combat, party, maps, collectibles);
   - the numbered main path, with `<!-- map:id -->` at each new area;
   - side quests: how each starts, its steps, its reward, and the **in-game clue** for each step;
   - puzzles and minigames, which link to A's sections;
   - a "can't miss" box for every point of no return;
   - spoiler folds for twists.

   Writers never type a location from reading the code. They point at the annotated map.
7. **`PLAYING.md`** (agent A, at the end). Write it in every shipped language. Contents:
   - per-platform launch, including OS security prompts (Gatekeeper "Open Anyway");
   - a controls table **generated from the input bindings**;
   - auto-battle styles, taken from the engine's style table (if the game has combat);
   - language switching;
   - render modes and the low-spec path;
   - where saves live (browsers don't share them);
   - **the Play Stats page, and "press Z to copy the report and paste it to Claude"**;
   - troubleshooting.
8. **`docs/RELEASE_NOTES.md`** (lead). One section per build:
   - how to play;
   - what's in it;
   - quality work, with numbers;
   - bugs fixed;
   - "please check in your playtest", seeded from `BALANCE.md` § Needs a human playtest and from the G3 notes;
   - known open items.

   Remove an item from the notes once it is fixed.
9. **`docs/VERIFICATION.md`** (lead). One row per suite:

   | Suite | Drives | Proves | Shortcuts it takes | Does **not** prove |
   |---|---|---|---|---|
   | chapter tests | real keys + autoplay, `chapterStart` fixture | story flow, flags | `stepOn` between beats | balance at carried state |

   Then a section on what no automated check can judge: writing quality, music, feel, real-GPU performance, real hardware and OS.
10. **Sample** (lead). When the first chapter builds, attach that chapter's rendered page to the next status table. Don't make it a separate question.
11. **Feed back.** Whatever the guide build finds goes to the lead as a phase 8 bug, not into a guide footnote: an item with no source, a quest step with no clue, a map that is unreachable.

## Outputs

- `tools/guide/build_guide.js`, `tools/guide/shoot_maps.js`, `tools/guide/charts.js`.
- `docs/guide/parts/*.md` (preface, intro and systems, characters, minigames, endings, database, charts) and `docs/guide/chapters/chNN.md`.
- `docs/guide/img/map_<id>.jpg` (+ `_vision.jpg`), one per map. Plus `docs/guide/guide_<lang>.html` and `.md`, which phase 11 regenerates.
- `PLAYING.md` (repo root), `docs/RELEASE_NOTES.md`, `docs/VERIFICATION.md`.

## Exit gate

Automated, by `build_guide.js --check`:
- [ ] **0 missing images**, and every map id has an annotated image.
- [ ] **0 unobtainable items.** The item counts match the validator's.
- [ ] **Every quest step has a pointer**, and every collectible is listed with its source and its missable window.
- [ ] Every minigame instance has scoring, best answers and a randomness statement.
- [ ] Every chart placed renders with data; no chart for data the game lacks. 0 broken links.
- [ ] Regenerating produces **no diff**, so nothing generated was hand-edited.
- [ ] The controls in `PLAYING.md` match the bindings.
- [ ] `VERIFICATION.md` lists every suite in `tools/test/`.
- [ ] `RELEASE_NOTES.md` has a section for this version.

Human gate: none. The guide ships in the zip.

## Pitfalls from Shorelight

- **The guide was not a planned deliverable.** The user asked for it only during the playtest ("a comprehensive game guide in chinese with graphs"). It is now always made.
- **Two different counts.** The guide's loose scan reported 39 unobtainable items; the strict scan found 37. One source of truth: the validator graph.
- **Most maps had no image.** The guide shipped **34 map images for 175 maps**. That led to "where is 剝皮寮" and "where is 柿霜上的四爪腳印", whose hakka_road map had no image at all.
- **Minigame answers were missing.** The 山歌 answers were there but the arrow directions were not, so the user asked twice. State the randomness explicitly.
- **Wrong directions.** The assistant said "west edge"; the real spot was bottom-left. It had answered from reading code. Only rendered, annotated maps count.
- **A hand-edited table.** The ch10 chest table was edited by both the item-placement agent and QA, and the branches conflicted.
- **Guide prose drifted from the game.** It called the 7th mushroom a "spare" and said there was "one shy lamp"; there were two. QA had to correct both.
- **"How did it test dialogues and fights?"** The user had to ask, and the answer was given ad hoc in chat. It belongs in `VERIFICATION.md`.
- **The guide found real bugs.** Its build surfaced 39 sourceless items, which were placed afterwards. Route these findings back to QA.

## Time/cost estimate

- Wall clock: about **1.5 h**, overlapping phases 8–9. Shorelight took 1 h 50 min with 3 agents, without full map coverage.
- Map shots: about 3–5 s per map in 2D, through 1 browser slot. 175 maps is about 15 min.
- Local: 3 agents × ~1.5 h ≈ **4.5 agent-hours** (`tools/forge/cost_estimate.md` row 10).
- Cloud: $0.
