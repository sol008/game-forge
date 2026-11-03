# Phase 8: Pre-ship QA wave

## Purpose

This phase is **mandatory before the first playtest zip (G4).** Find the bugs that a player would hit and that green chapter tests walk past: soft-locks, unfindable items, silent missables, text bugs, overflow and spec drift.

The game is played the way a player plays it: real walking, real key presses, the default render mode, and no flag writes. Every finding becomes a fix plus a PASS/FAIL script or a validator rule.

## Inputs

- All chapters merged. Phase 7's chain test is green from New Game to every ending.
- Validator at **0 errors and 0 warnings**. Get warnings to 0 first, so that new ones stand out.
- Frozen screenplays (with their version hash), story bible, `docs/i18n/GLOSSARY.md`, `docs/canon/appearance_facts.json`, `docs/canon/timeline.json`, `docs/canon/collectibles.json`.
- The engine debug surface (`blueprint/debug_hooks.md`) and `blueprint/qa_tools.md`.
- `rules/testing.md`, `rules/discoverability.md`.

## Steps

1. **Prepare** (lead, 15 min, alone).
   - Write the shared side-quest driver `tools/test/sidequests/lib.js` **before fan-out**. It must:
     - walk BFS paths over real collision, one tile at a time, so that touch events fire;
     - press the real Z key in front of NPCs and objects;
     - wait for the script to be idle before any input;
     - detect any terminal state;
     - never write a quest flag, item, stage or variable.
   - Reserve one exclusive namespace per agent, for example `tools/test/sidequests/ch3_5/` and `docs/qa/sidequests_ch3-5.md`.
   - Check that `chapterStart(ch)` closes earlier chapters' content the way a real save does (`rules/testing.md` T2). Otherwise every session reads stale hint menus, recaps and warnings.
2. **Static checks** (lead, no browser, about 10 min). Run the validator's graph checks and keep the output as a hit list for step 3:
   - **Item-source graph.** Every item has a source: shop, chest, drop from a troop that is actually used, script give, or starting gear. A deliberate exception carries `noSource: '<reason>'`. Every collection quest's N items exist and can be reached. Debug start kits do not count as sources.
   - **BFS reachability.** From each map entry, every exit, stair, chest, NPC, quest target and warp destination is reachable on foot. A warp never lands on a wall or on another warp.
   - **Discoverability.** Every interactable has a visible marker or glint, an NPC or quest-log pointer, and a hit area of at least 2 tiles. Every quest step has `hint` metadata. Multi-tile objects work across their full footprint.
   - **Flags.** Every flag or id that is read is written somewhere, and the reverse. Dynamic flag names must use a declared pattern.
3. **Side-quest walkthroughs** (4 cloud sessions in parallel; briefs `briefs/qa_walkthrough.md` + `briefs/cloud_session.md`).
   - One session per **chapter range**, with ranges sized by **quest count**, so that each session fits in about 60 min. Each session's data fixes then stay inside its own chapters' files and merge cleanly.
   - Each session plays every side quest and collectible in its range, from the chapter start, like a player. For each quest, record:
     - how it starts;
     - its steps;
     - PASS/FAIL;
     - issues found and how they were fixed;
     - remaining concerns.
   - **Discoverability is a bug class.** A required step with no clue fails.
   - **No-guide pass.** Each unit is first played in `--no-guide` mode: in-game text only (dialogue, quest log, rumours, marks, party talk, stuck offers), no guide, code or screenplay. Record the lowest hint tier that was enough; tier 4 or none is a FAIL.
   - Walk into every point of no return, choose "not yet", and check that the player stays.
   - Spot-check visual clues in the default render mode.
   - Fix **data only**, in the session's own branch and its own chapters' files: clue lines, glints, hint tags, NPC pointers (with every translation), wider hit areas. Edit guide *fragments* only, never generated sections.
   - **Engine issues are report-only**: file:line, repro and a proposed patch in the report, never applied. Expect few unfindable items and several engine issues per session (one wave found 0 and about 5 each); the lead fixes those once, in step 10b.
   - Scripts print `PASS <quest>` or `FAIL <quest> — reason` and exit 1 on any failure. Every shortcut used (level boost, `stepOn` between beats) is printed as `[help]`.
   - Push a WIP commit every 10 min. Taste calls are decided by default and listed in the report; the lead rules on them while waiting.
4. **Full chain in the default render mode** (1 local agent, 1 browser slot).
   - Run phase 7's chain in the player's default mode (3D-lite if the game is 3D), from New Game to every ending, with no assist.
   - Add assertions:
     - after every cutscene, the player is on screen and the camera, input and HUD are restored;
     - re-entering a map without a reload rebuilds its state;
     - every collectible payoff scene fires.
   - Run both endings from a branch save.
5. **3D sweep** (if 3D; 1 local agent, or a cloud session when CPU is short; `briefs/cloud_session.md`).
   - Load every map in the default mode, lite settings.
   - Record for each map: build time, draw calls, triangles, console errors, `warnOnce` keys, billboard fallbacks, NaN bounds and placement outliers.
   - Produce a screenshot contact sheet. Darkness-heuristic flags get a visual look before they count: small rooms in a large black frame and title cards read as "dark".
   - Load the injected-Inf-emitter map and assert no black rectangle (`blueprint/architecture.md` §2.5).
   - **Time budget and stop rule:** one full pass, then re-run only the failures plus 10 spot-checks. Cap the agent's browser slots (e.g. 2). When the agent fixes something, it **reports the fix at once**, then re-sweeps only the affected maps.
6. **Point-of-no-return audit** (1 local agent; `rules/discoverability.md` D6).
   - List every one-way transition: chapter ends, one-way travel, map-edge exits that end a quest early, bosses that move the story on, NPCs who leave after a flag, choices that lose an item or a collectible.
   - Every one calls the shared warning and **declares its `sets`** (flags, vars, next chapter). Audit every call site: one without `sets` checks nothing and stays silent.
   - The warning names exactly what closes: entries whose `closedIf` turns true under `sets` and that are available now. It gives where each one is, counts unlit collectibles without spoiling them, and offers go on / not yet / save first.
   - Every losing choice gets an NPC hint line just before it and a confirmation.
   - Test each prompt both ways, and for both errors: an open entry that closes is named; an entry still doable later, or not yet open, is not.
7. **Proofreading** (3 local agents by chapter range; `briefs/proofread.md`; CPU-light, so they backfill idle cores). In the source language, check:
   - typos and wrong script variants;
   - terms against the glossary;
   - voice;
   - continuity against the bible, timeline and appearance facts;
   - anachronisms;
   - **logic**: payoff scenes that check the wrong ids.

   A fix to source text also updates its translation and any test that quotes it. Clear-cut flags are fixed directly; taste flags are decided by the lead by default and listed.
8. **Layout check** (1 local agent per translated language; `briefs/translator.md` for terms).
   - Measure every string against its box in every locale, and screenshot every screen in every language.
   - **Fix overflow in the UI code** with fit, wrap and shrink helpers. Never shorten strings.
   - Run a pixel-diff regression of the source-language screens.
9. **Screenplay conformance** (1 local agent).
   - Audit `docs/story/cues.json` (extracted by `tools/lint/screenplay.js` from the screenplays' `<!-- cue: -->` lines). Every entry needs a passing assertion in `tools/test/spec_conformance.js` in the **default render mode**: entering scene X plays BGM or ambience Y; "no melody" rules; no minigame on sacred content; the rewards and encounters each scene lists. Add any that phase 4 missed.
   - **Pose audit.** Grep every screenplay for "lies", "collapses", "asleep", "kneels", "sits", "slumps" (and their translations). Each needs an `S.pose` at that beat, screenshotted in 2D and 3D: in 3D the figure lies along the bed, head on the pillow.
   - **Transitions.** Every chapter boundary shows its card after the fade-out (the chain's transition frames, C21).
   - Grep the tests for assertions of absence ("no BGM", "no item") that the spec doesn't state, and delete them.
   - A test encodes the spec, never the current behaviour. If code and spec disagree, the code is wrong unless the lead changes the spec and records it.
10. **Merge** (lead, as each branch lands).
    - Run `FORGE_TEST_CMD="bash tools/test/run.sh --quick && <that range's side scripts, each through tools/forge/governor.sh -->" tools/forge/merge_gate.sh <branch>`: `merge-tree` pre-check, then validator, unit and conformance, then the side scripts.
    - Send the cloud session "merged, stop, don't push further", then `tools/forge/agents.sh done <id> merged`.
    - Re-run the merged scripts locally in the background, with a timeout of at least 2× the expected time.
    - A failure under load is re-run alone, then on a worktree of the last good commit, before it counts as a regression (`rules/testing.md` T10).
10b. **Engine fixes** (after all ranges merge). Group the reported engine issues **by engine area**, not by range, and fan out one fix agent per area on its own branch, e.g. points of no return; hint venues and party talk; marks and tags. Each applies the reported patches after checking them by file:line. Then re-run **all** side-quest tests, not only the reporters': a point-of-no-return change ripples into many tests.
11. **Milestone build** (lead). Freeze `main` at a sha and run phase 11 for the **"after QA wave"** milestone: package from that sha, pass the release gate, send the zip. **No drain:** agents keep working on their branches.

## Outputs

- `docs/qa/sidequests_chA-B.md` (one per range) and `tools/test/sidequests/chA_B/*.side.js`.
- `docs/qa/full_chain.md`: a new default-render-mode run section.
- `docs/qa/sweep3d.md` + `docs/qa/sweep3d_contact.jpg`.
- `docs/qa/points_of_no_return.md`: a table with point, trigger, `sets`, what it closes and what the game does; a choice-hints table; how to add a new one.
- `docs/qa/proofread_chA-B.md`; `docs/qa/layout_<lang>.md` + before and after shots.
- `docs/qa/screenplay_conformance.md`, plus the assertions in the chapter tests.
- `docs/qa/item_sources.md`, `docs/qa/reachability.md`, `docs/qa/discoverability.md` (validator output, regenerated).

## Exit gate

All automated. Phase 11 refuses to package unless each holds:
- [ ] Every side script and chapter test PASSes, and every `[help]` is listed in the report.
- [ ] 0 unobtainable items, apart from `noSource` items that state a reason.
- [ ] Every collection set is complete and reachable.
- [ ] 0 unreachable targets.
- [ ] 0 discoverability violations; every quest has a complete guidance record; the no-guide pass solves every unit at hint tier 3 or lower.
- [ ] 0 flags read but never set.
- [ ] Every one-way exit and point of no return declares `sets` and warns about exactly what it closes (no over- or under-warning); both choices are tested.
- [ ] Every entry with hints has a reachable hint venue while it is open (D11); every collectible has the shared in-world cue (D1).
- [ ] All side-quest tests re-run green after the engine fixes of step 10b.
- [ ] Validator 0 errors and 0 warnings. 0 missing i18n keys (coverage % is informational). 0 measured overflows.
- [ ] Every screenplay cue assertion passes.
- [ ] Chain test in the default render mode: PASS to every ending.
- [ ] 3D sweep: 0 errors, NaN 0, 0 fallbacks except the explicit allowlist in `docs/qa/sweep3d.md`.

Human gate: none. G4 follows the QA-wave zip.

## Pitfalls from Shorelight

- **ch11 lighthouse stairs.** On every floor the up-stairs sat on a wall tile, so a walking player could never reach the finale. The chapter test **teleported** past it. Only the cloud walkthrough found it. Hence the BFS check and the no-teleport rule.
- **More soft-locks the tests missed.** The ch9 sand bridge collapsed mid-dialogue and stranded the party. The ch5 半邊井 collectible could be lost for good. ~25 quests had no pointer. Items sat on bare tiles: 懷錶, 扇貝殼, ch9 log pages, ch10 招魂 spots and oar, 3 mushrooms.
- **Half-interactable objects.** 2-tile carts and oars only worked from one half.
- **QA came only after the player tripped.** It started after the user reported the 扇貝殼, and after v1.0 had shipped. It is a pre-ship phase now.
- **A test locked in a bug.** The ch4 test asserted "festival night: no BGM", while the screenplay asked for ambience, so the silence bug was frozen in place. Screenplay conformance prevents this.
- **The finale checked the wrong ids** for 4 collectible stories. A proofreader caught it, not a test. Hence the flag read/write rule and the payoff assertions.
- **Two QA branches both created `sidequests/lib.js`.** One had to be renamed `lib68.js`. Shared helpers come first, then namespaces are reserved.
- **A hand-edited guide table** (ch10 chests) conflicted between two branches.
- **Fake soft-locks.** A test fired events while the opening cutscene ran. Wait for the script to be idle.
- **A suite killed by a timeout.** The ch11 side suite died at the 30-min background limit (it needs 33 min). Set timeouts to at least 2× and split suites to under 20 min.
- **A sweep with no stop rule** started a needless second full 2-hour pass under software GL.
- **A verification sweep outran its fix.** The root fix landed in the first hour; the full every-map screenshot sweep on a loaded 4-CPU machine took hours more. Report the fix first, then verify only the affected maps.
- **False "dark map" flags.** The darkness heuristic flagged small rooms in a large black frame and title cards. Triage flags by eye before filing them.
- **Hidden warnings.** 15 old validator warnings (dynamic flag names) hid new ones.
- **Warnings that named too much, then too little.** "Everything open in this area" named quests still doable later, so players learn to click past. "Only what the call site passes" lost content silently. Simulating the declared `sets` against each `closedIf` fixed both; call sites that declared no `sets` stayed silent until audited.
- **Stale party talk.** Companions kept repeating a quest's discovery rumour after it had started, which read as broken. Talk follows the current stage.
- **Unreachable hint venues.** A one-way area had no hint vendor, and a vendor showing only its top 3 targets hid the missable ones. Hence a venue per area, urgency ranking and at least about 6 targets.
- **Noisy debug starts.** Chapter starts left earlier chapters' quests open, so hint menus, recaps and warnings listed stale entries.
- **Load flakes.** Chapter tests under load failed at a different step each run and passed alone. Re-run alone, then diff against the last good build.

## Time/cost estimate

- Wall clock: about **2 h**. Shorelight's cloud ranges took 47, 61, 65 and 108 min; size the largest one down.
- Cloud: 4 walkthrough sessions (47–108 min each): **$20–160** (`tools/forge/cost_estimate.md` row 8). An optional cloud sweep session (one more C, $5–40) comes out of the 25% contingency.
- Local: 4–6 agents × ~2 h ≈ **8–12 agent-hours**. Proofreading and layout are CPU-light.
- Lead: about 1 h of merging and design calls.
