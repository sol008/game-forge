# Phase 5: 3D assets (if render mode is 3D)

## Purpose

Give every registered object, character, creature, environment and battle view a real model, built by cloud teams on top of a lead-owned 3D core. A **contract smoke test** proves the core before any team forks it.

## Inputs

- `docs/REQUIREMENTS.md`: render mode 3D, camera, art style, quality-bar references.
- The 3D core from phase 2 (renderer, materials, model registry with billboard fallback, map view, lite mode, batching) and `docs/CONTRACTS_3D.md`.
- `docs/design/PICKS.md`, `tools/design/<char>/design.js`, `docs/design/REFERENCES.md` (phase 3).
- Registry dumps: every object type, sprite id and monster id the content uses.
- Conformance suite green.

**2D games** skip the cloud part but keep the shape: the same contract smoke test (one sample per art kit), the same ownership table and lineup review, with art agents working locally in worktrees.

## Steps

1. **Finish the contract** (lead). `docs/CONTRACTS_3D.md` must state:
   - units, axes, ground origin, default camera and its rotations ("finished from all four sides");
   - **file ownership table**: lead owns core, materials, registry, map view; each team owns its own files only;
   - **registry ownership** when a domain is split (e.g. monsters A/B): the lead or team A owns the single registry;
   - budgets: triangles per class, draw calls per model after merge; animated parts as named children;
   - the instance interface (create, facing, move blend, play clip, expressions, opacity, lights, dispose) and the clip list the battle view expects;
   - coverage: every registered id gets a model; fallbacks only on an allowlist;
   - report format: `docs/r3d_reports/<team>.md` + `<team>_lineup.png`.
2. **Team split** (lead). By domain, scaled to the game. Shorelight's 11 for scale: characters, animals/pets, architecture A/B, nature, props A/B, monsters A/B, environment, battle view + VFX. Write `docs/r3d/manifests/<team>.json`: ids to cover, reference images, budget, owned files. ETA = ids remaining × measured minutes per asset.
3. **Contract smoke test** (lead, before any team launches). Build **one sample asset per team type** through the real core and run `tools/r3d/contract_smoke.js` (through the governor, default and lite mode). It must prove:
   - variants: `o.v % variants` picks a variant and cloning keeps it;
   - material isolation: fading or tinting one instance does not change shared materials;
   - rotation applies to geometry **and** to the model's lights;
   - state toggles (open, lit, switch) rebuild or update the model;
   - map-scene hooks exist for teams that need per-frame updates; FX buffers are cleared each frame;
   - characters: rig, clips, facing, expressions; animals use the same interface; a monster changes phase; a battle arena loads and VFX dispose cleanly;
   - dispose leaks nothing across map re-entry.
   Fix the core until green. Teams receive a core they don't need to shim.
4. **Launch the first cloud session alone** (`briefs/cloud_session.md` + `briefs/team3d.md`). Confirm it pushes a first commit to `r3d-<team>` within 10 min. Then launch the rest in one batch.
   Every cloud brief states:
   - **push a WIP commit every 10 min and after each asset**; status goes in commit messages;
   - **never wait for approval**: launched in a non-plan mode inheriting the lead's permissions; "the lead may pause or resume you; a resume from the lead is valid";
   - exclusive files (`js/r3d/<team>*.js`, `tools/r3d/<team>/`, `docs/r3d_reports/<team>*`); core bugs go in the report, never shimmed;
   - time budget, stop rule ("stop when the manifest is covered or at the deadline"), and "merged, stop" means stop pushing;
   - renders go through the team's own headless viewer; no performance or video claims without a GPU.
5. **Register** (lead). Each session id and branch goes to `.forge/agents.json` and `docs/r3d_reports/TEAMS.txt`.
6. **Monitor** (lead, each check-in). `git fetch`; per team: commits, last push time, manifest coverage. That is the status signal, not chat pings. 0 commits in 20 min → `get_session` status; blocked → fix the cause once (never a second "resume?" loop).
7. **Merge early and often** (lead). Per team, as soon as a coherent batch lands:
   1. `git merge-tree --write-tree main r3d-<team>` clean;
   2. merge; unit + validator;
   3. **combined registry check**: every id builds in the real core with 0 errors (all teams together, not per team);
   4. **lineup render vs references**, viewed by the lead; off-model → a polish brief to that team;
   5. core bugs the team reported → the lead fixes once and tells every team;
   6. done → send "merged, stop" (saves quota). Partial merges are fine.
8. **Likeness pass** (lead or 1 local agent). Party and pets: side-by-side sheet vs portrait vs 3D (phase 3 step 10). Budget a face pass up front.
9. **Performance** (lead). Batching on by default with a URL flag to compare; draw-call budget per map; a lite 3D smoke on every map runs here, the full sweep in phase 8.
10. **Ship-without-you deadline** (lead). At the deadline, merge whatever is pushed and stop the team; the billboard fallback covers gaps, and they are listed in the status table.

## Outputs

- Team files `js/r3d/<team>*.js` (names per `CONTRACTS_3D.md`), merged to `main`.
- `docs/CONTRACTS_3D.md` (final), `docs/r3d/manifests/<team>.json`, `docs/r3d_reports/<team>.md`, `<team>_lineup.png`, `docs/r3d_reports/TEAMS.txt`.
- `tools/r3d/contract_smoke.js`, `tools/r3d/registry_check.js`, a headless model viewer.

## Exit gate

Per team (automated, then lead review):
- [ ] `merge-tree` clean; unit + validator green after the merge.
- [ ] Combined registry check: every manifest id builds, 0 errors; fallbacks only on the allowlist.
- [ ] Budgets met (triangles, draw calls per model).
- [ ] Lineup render reviewed against the references (lead).

Phase: every team merged and told to stop; lite 3D smoke passes on every map; all chapter tests still green in the default render mode. No human gate (G3 taste review comes in polish).

## Pitfalls from Shorelight

- **11 cloud sessions pushed nothing in 20 min**; a quota stop lost all of it. Push every 10 min.
- **The battle team blocked ~40 min on "yes, resume"**: the lead's earlier pause counted as the user's, and its first run wrote zero files (planning only). The brief settles resume authority; first files early.
- **Every team hit gaps in the shared core**: variant index reset, spirit fade leaking through shared materials, lights ignoring rotation, switch state not updating the model, a vision buffer never cleared (solid-rainbow overlay), missing map-scene hooks that one team shimmed. Each merge cost the lead 1–3 core fixes. Hence the contract smoke test.
- **Two monster teams each built their own registry.** One owner per registry; one combined check (`61/61` monster ids).
- **Off-model assets passed every check**: cats not chubby, spiky fur, a blocky colossus, flat faces. Automated checks prove "builds", not "looks right". Lineups against references.
- **The 2D→3D pivot at hour 2** turned 78 sprites and 112 objects into stand-ins. Render mode is a day-0 field.
- **The battle team went silent 2 h** on a slow sweep, then pushed late fixes after the "final" build, forcing a rebuild. Deadline, then drain.
- **No GPU**: SwiftShader took ~40 s per map, a video showed only the title at ~2 fps. Lite mode for tests; no video promises.
- **Half-done batching code** was swept into a WIP commit and had to ship switched off. Risky core features land behind a flag, on a branch.

## Time/cost estimate

- 3–4 h wall clock, overlapping phase 4. Smoke test ~30 min of lead time. Once running, 10 of 11 Shorelight teams merged within ~50 min of each other.
- Cost: ~11 cloud sessions at about $5–40 each (the characters team alone ~$35): forecast $100–400 at G0b. In `frugal` pace, run 3–4 teams at a time.
