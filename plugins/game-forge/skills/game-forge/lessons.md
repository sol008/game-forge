# Lessons from Shorelight (and later games)

Each lesson: **what happened → rule** (the file holding the rule).
Add new lessons at the bottom of the matching section after every game, and commit them to `sol008/game-forge` main.

## Requirements and scope
- Setting changed to "all of Taiwan" after 15 agents launched; some agents were killed by the interrupt and 20 were relaunched → **lock requirements before fan-out** (intake.md). A user interrupt may kill in-flight agents: check them with ListAgents.
- 2D→3D pivot at hour 2; the 2D art pipeline mostly thrown away → **render mode is a required intake field**.
- Folder renamed 3× in 12 min for naming → **slug fixed at setup**; use a neutral folder until the title is locked.
- A third pet was built in full, then cut 6 min later when two new cats arrived; ~800 lines rewritten → **lock the cast roster**; when cast is added, ask "keep or cut overlapping cast?".
- "Every character" read as 13 designs when it meant 5 → default: party gets N options, story cast 1.
- Reference photos read as "replace" when the user meant "add" → **default to additive**, or confirm in the same message.

## Testing (see rules/testing.md)
- Autoplay hid dialogue that ignored real key presses → T1.
- Boss tests passed at Lv36 vs 28; ch8 unwinnable in the chain run → T2, T11.
- Every test ran 3D-off while the player used 3D; camera bug, decals and HUD broke in 3D → T3.
- ch11 lighthouse stairs on walls, hidden by a teleporting test → T4.
- "Final boss stall" was the auto-battle losing on a custom game-over screen → T5, T6.
- Fake soft-locks from a test firing input mid-cutscene → T7.
- Footprints built only on map entry → T8.
- A test asserted "no BGM" and locked in a silence the screenplay forbade → T9.
- Results misread from a truncated `tail` → T12.
- A forced victory page hid a stale HUD level → T15.
- A suite was killed at the 30-min background limit → T16.

## Content and discoverability (see rules/discoverability.md)
- Scallop shell on a bare tile with a hidden precondition; the player never found it → D1, D2, D8.
- 39 items had no source; a 7-mushroom quest had only 5 mushrooms (3 locked) → item-source graph in the validator.
- The finale checked the wrong 心燈 ids for 4 stories; a proofreader caught it, not the tests → flag/id read-write integrity.
- 半邊井 心燈 lost forever behind a strip the player could skip → D5, D6.
- About 25 quests had no pointer to their next step → D4.
- 2-tile carts and oars were usable from one half only → D3; full-footprint interaction in the engine.
- Text described 白芷 as silver-haired after her design was picked otherwise → appearance-facts file + lore lint.
- A cat (silent by design) had a line → speaker whitelist lint.
- 芋圓 was both a cat and a dessert → unique-name lint.
- The camera was held by a cutscene and never released → engine invariant: script end restores camera, input and HUD.
- Guidance was added quest by quest after the build (log notes here, a hint line there) and the retrofit cost a whole day → **guidance is a system planned from day 0**: one record per quest (where, when, closes-at, rumour, 4 graded hints, area) that every guidance UI reads, a validator rule, points of no return that name what they close and where and offer save-first, and a no-guide QA pass that records the lowest hint tier needed (D6, D9, D10).

## Systems and balance
- Bosses trivial until a late pass, then over-softened to make tests pass → simulator with the player bot, target band 86–94%, never tune to pass a test.
- Level-up didn't refill HP/真氣; the player was stuck without skills → **QoL default: level-up refill**.
- Auto-battle couldn't beat bosses → the player-facing AI must clear normal content and is the test AI.
- Economy: story-only path broke at ch8 (2k gold vs 14k gear) → normal-player economy sim from 2 chapters on.
- An ally falling counted as a boss win (`false != null`) → explicit boolean checks; sims assert "party alive at win".

## Engine and rendering (see blueprint/architecture.md §2.5, §5)
- A chapter ended on a black screen and its chapter card never showed: the global fade was drawn over every scene → `overFade` scenes, fade drawn beneath the first one; a transition test samples frames at every chapter boundary (C21).
- Screen-sized pure-black rectangles in 3D: one NaN/Inf pixel (Inf specular in a half-float target, `pow` of a negative base, `smoothstep` with edge0 > edge1) smeared by bloom; SwiftShader never showed it → sanitize pass before bloom, defined shader math, verify with an injected Inf emitter. GTAO drew black boxes around lights → sprites and non-depth-writing transparents stay out of its G-buffer.
- Heads spun in held poses: look-at added rotation on bones three.js hadn't rewritten because their keyframe value hadn't changed → reset bones every frame before additive rotations; clamp yaw/pitch, ease back, no look-at while lying (C22).
- A 2D sprite lay in bed while the 3D figure stood in it → explicit `S.pose` that both views draw, cleared on walk; audit every "lies/collapses/asleep/kneels" stage direction.

## Orchestration (see rules/orchestration.md)
- ~30 workers on 4 CPUs; tests 2–3× slower → governor from day 0.
- Queue starvation of 15–54 min (a hog held a slot 43 min; waiters never saw a new slot) → max hold time, re-read config each poll, priority lane.
- 40+ commit nags; WIP snapshots swept in half-done agent work → worktrees per agent, no blanket commits.
- 11 cloud sessions pushed nothing in 20 min, so all their work was lost at a quota stop → push every 10 min.
- A cloud team waited ~40 min for "yes, resume" → never block on approval; the lead may resume.
- A 3D sweep agent started a needless 2-hour second pass → time budget and stop rule in every brief.
- A ch1 builder polished for 30 min after passing → definition of done: commit, report, stop.
- Every chapter builder patched around the same engine bugs → conformance suite before fan-out; one engine owner.
- Every 3D team found gaps in the shared core at merge → contract smoke test with one sample asset per team type.
- Two monster teams each built a registry → split domains with an explicit registry owner.
- After context compaction, agent ids had to be recovered by grepping transcripts → agent registry.
- An agent claimed an API that didn't exist (`G.Tiles.warm`) → verify by file:line.
- Two parallel branches both created `sidequests/lib.js` → exclusive new-file namespaces.
- A full every-map screenshot sweep on a loaded 4-CPU machine ran for hours after the root fix had landed in the first hour → time-box verification, cap browser slots per agent, report the fix as soon as it is made, then verify only the affected maps. Darkness-heuristic flags need a visual look: small rooms in a black frame and title cards read as "dark".

## Art and audio
- Design v1 judged "really bad" (shared face template) → pilot sheet vs quality bar first, culturally grounded options, no shared templates.
- In-game portrait didn't match the picked design → bake in-game assets from the same source as the approved sheet.
- Sheet age label (17) contradicted the bible (19) → sheets pull metadata from data.
- 3D cats and monsters passed checks but were off-model → side-by-side render vs reference before "done".
- The agent cannot hear audio → measure (loudness, loop seams), send previews, mark music as a human taste gate.
- Sacred-ceremony scene: no melody may be imitated → ambience only, as the screenplay says (see T9).

- Shorelight ch5 mirror puzzle: in 3D the map's 2D overlay became a flat floor decal. The mirror cloths and ／＼ facings were hidden under the 3D stands, and the folding screens lay flat on the floor. The empty lamp seat that starts the puzzle was invisible too, so the player set every mirror right and the hall stayed dark. The puzzle was solvable but unreadable → **puzzle state lives on the model** (a live `state` the 3D layer re-reads), never only in a 2D overlay; screenshot every puzzle in every render mode, in its unsolved, partly-solved and solved states (T17).

## Release
- A rebuild shipped a stale font (99 vs 101 subset slices) → package step regenerates derived assets and checks glyph coverage.
- A cloud team pushed fixes after the "final" build → freeze and drain all agents before building.
- Release check: unzip into a path with spaces and CJK, boot every render mode → `tools/forge/release_gate.js`.
- The game sat in a public scratch repo for 2 days → a new private repo per game, at intake.
- The GitHub integration cannot create repos (403) and the git proxy cannot delete branches (403) → ask the user; never work around a policy denial.

## Player docs
- "Where is 剝皮寮?", "where are the frost footprints?", "what are the 山歌 answers?" → the guide annotates every map (exits, NPCs, clues) and documents every minigame (scoring, answers, randomness).
- Wrong directions given from reading code → spatial answers only from rendered, annotated maps.
