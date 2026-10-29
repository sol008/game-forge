# Phase 12: Playtest loop (G4)

## Purpose

The user plays the milestone zip and sends back two things:
- the in-game **Play Stats report**, copied with Z;
- their notes.

The forge then does, for each note:
1. answer questions at once;
2. triage;
3. fix in worktrees;
4. turn **every bug into a validator rule or a test**;
5. **commit each general lesson straight to `sol008/game-forge` main**, so the next game can't ship that class of bug.

The loop repeats until the user says "ship" (G5).

## Inputs

- The user's paste. The Play Stats report carries:
  - version and sha;
  - settings: render mode, language, difficulty, auto-battle style;
  - chapter, map and tile;
  - idle-aware play time per chapter and activity;
  - boss attempts.

  Notes may come in any language and with any amount of detail.
- The release's tag, `docs/RELEASE_NOTES.md` ("please check"), `docs/VERIFICATION.md`, `docs/BALANCE.md`.
- `tools/forge/shoot.js`, the guide's annotated maps, `tools/forge/governor.sh --prio -- <cmd>` (the priority lane for user-reported bugs).

## Steps

1. **Parse the report** (lead, about 2 min).
   - Check out the reported tag.
   - Take the repro settings and the location from the report. **Never ask a question the report answers**, such as "were you in 3D?".
   - With no report, reproduce in the default render mode, then in every other mode.
   - Compare boss attempts against `BALANCE.md`. More than 2 attempts at a boss the sim puts above 86% is a balance finding.
2. **Triage** (lead, about 5 min). Write one row per note in `docs/playtest/<date>.md`:

   | # | Note (user's words) | Class | Sev | Repro | Owner / worktree | Check added | Forge lesson |
   |---|---|---|---|---|---|---|---|

   The classes:
   - **bug**: fix it.
   - **discoverability**: add a pointer, and add a rule.
   - **balance/feel**: re-run the sims, then decide and disclose.
   - **taste**: apply the user's words, or the default.
   - **QoL**: accept it if it matches the QoL defaults in `docs/REQUIREMENTS.md`.
   - **question**: step 3.

   Severities run S1 (blocks progress) to S4 (cosmetic).
3. **Answer player questions now** (lead). Don't wait for the fixes.
   - **Language.** Reply in the language the question is written in. Quote in-game names exactly as the player's game language shows them.
   - **Spatial answers come from rendered, annotated maps. Never give directions from reading the code.**
     1. Render the map with `shoot.js`: no encounters, the bundled CJK font, labels from map data.
     2. Mark the exact tile(s) with their coordinates, the route from the nearest entrance or landmark, and any condition (time of day, spirit sight, a prior step).
     3. **Verify with BFS** that the target can be reached from the player's reported position in their current state.
     4. Send the image with at most 3 lines.
   - **Rules and minigames.** Answer from the guide's generated minigame section: scoring, best answers, and what is random. If the section is missing or wrong, that is a guide bug and gets a row.
   - **Every question is a discoverability signal.** Add a row: an in-game pointer (NPC line, glint, hint tag, quest-log text), plus a guide fix.
4. **Reproduce** (one helper per bug, in a worktree, through `tools/forge/governor.sh --prio --`).
   - Reproduce in the player's settings first, then in every render mode.
   - Write the repro as a **failing test that encodes the spec** (what should happen), never the current behaviour.
   - CPU-heavy 3D repros go to a cloud session (`briefs/cloud_session.md`).
5. **Fix** (same helper; as many in parallel as the governor allows; brief from `briefs/generic.md`).
   - Definition of done:
     - the new test passes and fails on the pre-fix sha;
     - validator 0 errors and 0 warnings;
     - the touched chapter tests pass in the default render mode;
     - every new line has an entry in every target language (none when `langs` = [source]);
     - guide fragments are updated if affected.
   - **Hunt siblings.** Grep every chapter for the same pattern.
   - Prefer an engine invariant to a per-scene patch.
   - Commit only after the tests finish.
6. **Make it a check** (helper). Each bug becomes a validator rule, a unit or e2e test, or an engine invariant with an assertion. Add it to `tools/test/` or `validate.js`, and record its id in the triage row.

   | Shorelight bug | Check it became |
   |---|---|
   | camera stuck after a cutscene | an engine guard restores camera, input and HUD at script end, plus a chain assertion that the player is on screen |
   | footprints gone on re-entry | a test that re-enters the same map without a reload |
   | shell on a bare tile | a discoverability rule over every `examine` event |
   | festival silence | a cue assertion from `cues.json` |
   | no refill on level-up | a unit test that empties MP, wins, and asserts full |
7. **Commit the lesson to game-forge** (lead, right after the fix merges). `$FORGE` may be a read-only synced copy, so always edit a fresh clone of the source repo `sol008/game-forge` (attach it with add_repo if needed), on `main`, under `plugins/game-forge/skills/game-forge/` (`$SRC` below):
   - Add a row to `lessons.md`: incident → rule.
   - Put the rule itself where it acts: `rules/*.md`, the phase file's pitfalls, or the validator spec in `blueprint/qa_tools.md`.
   - Keep it generic, with the game named only as a labelled example. No secrets.
   - One lesson per commit:
   ```
   git clone --depth 1 https://github.com/sol008/game-forge "$SCRATCH/game-forge-src"
   SRC="$SCRATCH/game-forge-src/plugins/game-forge/skills/game-forge"
   $EDITOR "$SRC/lessons.md" "$SRC/rules/testing.md"     # or the phase / blueprint file
   git -C "$SCRATCH/game-forge-src" commit -am "lesson: re-entering a map rebuilds per-visit state (<game>)"
   git -C "$SCRATCH/game-forge-src" push origin main     # straight to main, as decided
   ```
   After pushing, tell the user once per batch that **the account-uploaded skill is now behind**. Rebuild the upload zip with `bash "$SCRATCH/game-forge-src/tools/package_skill.sh"` and send it (plugin users update with `/plugin update`).
   If a bug is purely game-specific, write "game-specific: <reason>" in the row instead.
   If the push to `sol008/game-forge` is denied, append the lesson to `docs/forge/lessons_for_forge.md` in the game repo instead, record "forge push denied" in the row, and list those lessons in the final report.
8. **Ship the batch** (lead). Merge with `tools/forge/merge_gate.sh` (the `FORGE_TEST_CMD` of phase 4 step 6, plus the new regression checks). When the batch is done, or an S1 is fixed, run **phase 11** as the next release candidate. The message maps each user note to its fix ("你說的 X → 已修正，並新增檢查 Y").
9. **Close the rows** (lead). Each row is closed with: the check id, the fix sha, the forge commit sha (or the reason), and the zip version that carries it.

## Outputs

- `docs/playtest/<date>.md`: the triage table, with every row closed.
- Regression tests and validator rules in `tools/test/`; engine invariants with their assertions.
- `docs/RELEASE_NOTES.md` § "Playtest changes" for the next version.
- Annotated answer images in the scratchpad (`answers/*.jpg`), sent to the user.
- Commits on `sol008/game-forge` main: `lessons.md`, `rules/`, `phases/`, `blueprint/`.

## Exit gate

Automated, per bug:
- [ ] A regression check exists, **fails on the pre-fix sha**, and passes on the fix.
- [ ] The validator still has 0 warnings.

Per batch:
- [ ] Every general lesson has a game-forge commit sha, or an entry in `docs/forge/lessons_for_forge.md` when the push was denied.
- [ ] Every spatial answer was sent as a rendered image.
- [ ] No S1 or S2 rows are open.
- [ ] Phase 11's release gate is green.

Human:
- [ ] **G5 "ship"** ends the loop.

## Pitfalls from Shorelight

- **The assistant's own retro:** "Your playtesting found most of the real problems… automated tests passed right over every one of them." That covered the camera, the footprints, the shell, the festival silence and the level-up refill. Each one is now a check.
- **The camera stuck after the mushroom (3D).** Every test ran with 3D off. The same never-released camera was in 3 more ch3 scenes, and it was fixed with an engine guard. Always hunt siblings.
- **Footprints went missing "sometimes".** They were built only on map entry, and the maze re-enters the same map without a reload. A planned 麻糬 hint had never been built.
- **扇貝殼 was unfindable.** It sat on one bare tile with a hidden precondition, and the guide left the condition out.
- **The festival was silent**, and a test asserted "no BGM", which locked the bug in.
- **Level-up didn't refill HP/MP**, and the HUD level went stale. The refill is now a QoL default.
- **Wrong directions.** The assistant said "the west edge"; the real spot was bottom-left. It had read the code. Then "I only found 1 place with mushroom", because 3 pickable clumps looked like 15 decorative ones. Rendered maps fixed both answers, and harvest markers fixed the cause.
- **Ad-hoc answer screenshots went wrong.** They caught a random battle, used the wrong street name, and had no CJK font. Hence `shoot.js` with labels from map data.
- **An avoidable question.** The assistant asked "were you in the forest, in 3D?". The report should carry settings and location.
- **Queue starvation.** The camera and footprint fixes took about 2.2 h each, mostly waiting 15–54 min in the browser queue. Hence the priority lane.
- **Fixes pushed before their tests finished** (ch3 and ch4). Commit only after green.
- **"Give me the latest zip."** Every fix batch ships through phase 11 with the zip attached.

## Time/cost estimate

- Answering a question: about 5 min, image included. Triage: about 5 min per report.
- A bug with the priority lane: about 15–60 min. In Shorelight the level-up refill took 11 min and 扇貝殼 took 5 min.
- A forge lesson commit: about 5 min.
- Release candidate: about 15 min (phase 11).
- Local, per round: 4–8 helpers × 1–2 h ≈ **4–16 agent-hours** (`tools/forge/cost_estimate.md` row 12).
- Cloud, per round: 0–2 overflow sessions for heavy 3D repros, **$0–80**.
