# Phase 9: Polish

## Purpose

Lift the game from "works" to "lands". Four tracks:
- the key emotional scenes;
- a signature score;
- characters that look like the designs the user picked;
- 3D that runs within budget.

This phase runs **alongside phase 8**. The agent cannot hear audio and cannot judge feel, so music previews and key-scene excerpts go to the user as a **non-blocking taste gate (G3)**. Work never waits for the reply.

## Inputs

- Frozen screenplays and `docs/story/cues.json`. The lead picks 5–8 **key scenes** from the bible's beat sheet (first meeting, first loss, a revelation, a sacrifice, every ending) and lists them at the top of `docs/qa/scenes.md`.
- `docs/REQUIREMENTS.md`: music style, signature motif, whether G3 is wanted, quality-bar reference.
- Design picks and their sheets (`docs/design/PICKS.md`), the reference notes (`docs/design/REFERENCES.md`), `docs/canon/appearance_facts.json`.
- `docs/qa/sweep3d.md` from phase 8 (draw calls and triangles per map).
- The music sequencer, plus `tools/render_music.js` for offline render and measurement.

## Steps

1. **Launch** (lead). Start 3–4 agents, each in its own worktree, using the brief template in `rules/orchestration.md`:
   - **scenes**: local, no CPU load.
   - **music**: local; it needs a browser slot only while rendering.
   - **likeness**: local, render-heavy. Move it to the cloud if load is above target.
   - **perf**: a cloud session (`briefs/cloud_session.md`), because A/B sweeps are CPU-heavy.

   Each brief carries a time budget and a pass cap.
2. **Key scenes** (scenes agent). For each listed scene, polish:
   - pacing: waits and beats;
   - **silence**: drop the music before the line that matters;
   - music cues: which theme, and where;
   - callbacks: earlier lines, objects or places;
   - camera and emotes.

   Constraints:
   - Never change flags, items, quest ids or the order of beats.
   - Rewrite each translation to match the new feel, not word for word.
   - A changed music cue is changed in `docs/story/cues.json` too, with the screenplay version bumped in `docs/story/FREEZE.md`.
   - The scene's chapter test still passes, and its cue assertions still hold.
   - Write before and after notes in `docs/qa/scenes.md`.
3. **Signature music** (music agent).
   1. Write one leitmotif, 2 bars. Carry it across 3–4 signature themes: title, the heroine or main bond, the ritual or quest theme, the ending.
   2. Vary it by mode, inversion or instrument, never by a new tune. The ending pays off the title by changing mode.
   3. Write `docs/MUSIC.md`: notation conventions, the motif, each theme's form, and where each one plays.

   The agent can't hear, so it **works from theory plus measurement**. Render offline through the real audio graph, then check:
   - peak below −3 dBFS;
   - RMS within ±1.5 dB of the median background track;
   - loop seam: sample jump ≤ the p99.9 step, and RMS matched on both sides;
   - no clicks, and polyphony under the cap.

   Ambience for sacred scenes follows the screenplay: drones and textures, **no melody**.
4. **G3 previews** (music agent → lead → user). Render a 30-s preview of each signature theme (mp3 or ogg, under 1 MB) and send it in **one** message, together with the key-scene excerpts. Give each item one line saying what it should evoke, and ask for notes in plain words. Then carry on. Notes that arrive go into the fix loop like playtest notes (phase 12).
5. **Face and likeness pass** (likeness agent).
   - For every party member, pet and boss, render the in-game model (or sprite) **side by side** with its approved sheet and reference photos, from the same angle.
   - Fix by priority: face (eyes, mouth, ears, proportions), hair, silhouette, signature items (scarf, hairpin, weapon).
   - Re-run the appearance-facts lint over all scripts.
   - **Cap at 2 passes per character.** Remaining gaps are listed for G4.
   - The lead looks at every final side-by-side render before calling it done.
6. **3D performance** (perf session, if the game is 3D).
   - Set budgets from the sweep: worst map ≤ 2.5× the median draw calls, and an absolute cap from `docs/REQUIREMENTS.md` (default 250 calls, 400k triangles).
   - Fixes, cheapest first:
     1. **instanced batching** of repeated static models per ground chunk;
     2. field LOD for far NPCs;
     3. merged static meshes.
   - Ship batching **on by default** with a URL flag (`?nobatch`) to compare.
   - Prove it with an A/B sweep: same ids, same pixels within tolerance, 0 new errors, and a draw-call table before and after.
   - Without a GPU, report draw calls, triangles and CPU frame ms only. **Never** make fps or "smooth" claims, and never send a video.
7. **Merge** (lead). Run `forge-tools/merge_gate.sh`, then the affected chapter tests in the default render mode. Perf work merges only after its A/B sweep is clean. A risky half-finished feature stays on its branch and is never swept into a WIP commit.

## Outputs

- Polished scene scripts in the chapter files, and their translations; `docs/qa/scenes.md`.
- Signature themes in the song table; `docs/MUSIC.md` with a measurement table (peak, RMS, Δ vs median, seam).
- Previews in the scratchpad (`music/previews/*.mp3`), sent to the user. They are not committed.
- `docs/qa/likeness.md` plus side-by-side PNGs in `docs/r3d_reports/cast/`.
- The batching module and its flag; `docs/qa/sweep3d.md` § Batching (A/B table).

## Exit gate

Automated:
- [ ] Draw-call and triangle budgets met on every map (a sweep with batching on).
- [ ] A/B sweep: 0 new errors and matching node ids.
- [ ] Every signature and ambient track: no clipping, RMS in band, loop seams pass.
- [ ] Chapter tests for the touched scenes are green in the default render mode. Screenplay cue assertions pass. Translation coverage has not dropped.
- [ ] Appearance-facts lint: 0 conflicts.

Lead review:
- [ ] Every side-by-side likeness render has been seen.

Human (non-blocking):
- [ ] G3 previews and excerpts **sent**. A reply is not required to continue.

## Pitfalls from Shorelight

- **"Would this be a 1995 classic?"** The assistant's own answer named three gaps: unreviewed emotional scenes, procedural-sounding music and uneven voice. Only then were scene and music polish started. Now they are standard tracks.
- **The composer agent cannot hear.** 30-s previews went to the user, and only theory plus measurement backed the agent's choices. Say so up front, and send previews proactively.
- **Festival night was silent.** The screenplay asked for ambience, and the code had none. When ambience was added, the new track measured 6 dB under the others and had to be raised. Loudness is a gate, not a taste call.
- **Models that pass checks but look wrong.** The cats were off-model while every automated check passed: 芋圓 not chubby, 麻糬 with spiky fur. So were a blocky colossus and a thin mane. Hence the side-by-side render review.
- **Flat 3D faces.** Faces were flat, ears too big and eyes weaker than the portraits. That took a 36-min face pass. Budget for it.
- **The user had to ask** for a "more feminine" heroine. Self-review against the picked sheet should catch most of this first.
- **A batching feature swept into a WIP commit half-done.** A stopped agent left batching code in a shared-tree WIP snapshot, so it had to ship opt-in. A later cloud A/B took the worst map from 494 to 64 draw calls (the worst across all maps went from 494 to 204), and batching then became the default.
- **"Watch it play" failed.** Headless video ran at about 2 fps and captured only the title screen. Without a GPU, send stills and numbers.
- **Stale descriptions.** Scripts described the heroine as silver-haired after a different design was picked. Re-run the appearance-facts lint after every look change.

## Time/cost estimate

- Wall clock: about **1.5 h**, overlapping phase 8.
- Shorelight actuals: scenes 45 min; music about 1 h; face pass about 36 min per round; perf about 1–2 h in the cloud.
- Cost: 1 cloud session for perf ($10–40), plus 3 local agents of about 1 h each.
