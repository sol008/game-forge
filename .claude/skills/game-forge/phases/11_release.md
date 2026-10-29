# Phase 11: Freeze and release

## Purpose

Turn the merged tree into one tested zip (and, for a hosted platform, a deployed build) and put it in the user's hands. Nothing may change underneath the build:
1. freeze;
2. drain **all** agents (**Release milestone only**);
3. merge (Release only);
4. regenerate the derived assets;
5. package;
6. deploy, if the platform is hosted;
7. pass the release gate;
8. send.

**Zips go out only at milestones:**

| Milestone | When | Gate before it |
|---|---|---|
| First playable | The first chapters (ch0–1, or the first two) are merged | Phase 4 per-chapter gates for those chapters + New Game reaches the last merged chapter's hand-off with no debug flags. Balance or solver numbers and the full chain are **not** required. |
| After the QA wave | Phase 8 exit gate green | Phase 8 + 9 + 10 gates |
| Release | After the G4 fix loop, when the user says "ship" (G5) | Everything above + phase 12 regressions |

A batch of playtest fixes is shipped as the next release candidate, through this same phase. There are no ad-hoc preview zips in between.

**Drain only for Release.** For First playable and After the QA wave, freeze `main` at a sha (`git worktree add "$SCRATCH/rel" <sha>`) and package from that worktree. Skip steps 2–4: agents keep working on their branches, and the merge loop to `main` goes on. Steps 5–10 run in the frozen worktree; its derived-asset commit goes on branch `release/vX.Y.Z` and is merged back through `tools/forge/merge_gate.sh` after sending. For Release, run every step on `main`.

## Inputs

- The green branches of every agent, and the follow-ups queue (`followups.md`).
- `tools/package.sh`, the font builder, `tools/i18n/extract.js`, `tools/guide/build_guide.js`.
- `tools/forge/merge_gate.sh`, `tools/forge/release_gate.js`, `tools/forge/governor.sh`, `tools/forge/agents.sh`.
- `docs/REQUIREMENTS.md`: platform(s) and hosting target, render modes, languages, launcher, zip-size budget.

## Steps

All steps are done by the **lead, alone**. There is no parallelism in this phase, on purpose.

1. **Announce the freeze.** Post one status row: "FREEZE at `<sha>`, `<time>`, `<milestone>`". At First playable and After QA that is all: work goes on, and the build uses the frozen sha. At Release, from now on no new work package starts; disable any scheduled task that would launch agents, and keep the check-in.
2. **Drain local agents** (Release only). For each registry entry:
   - it finishes its current unit and commits on its own branch, or it is stopped;
   - uncommitted work stays on its branch or is discarded, and either way is listed;
   - nothing is swept into main.

   Then close each entry that is still running with `tools/forge/agents.sh done <id> stopped` and `tools/forge/agents.sh set <id> note drained`. (`drained` is a note, not a status.)
3. **Drain cloud sessions** (Release only).
   1. Send each one: "Freeze. Push your final commit now, then stop. Nothing pushed after `<time+10 min>` ships in this build."
   2. A session counts as drained when its status is idle or complete **and** its branch head has not moved for 5 min.
   3. After 15 min, ship without the session; its later work waits for the next milestone.
   4. Record each branch's final sha, then `tools/forge/agents.sh done <id> stopped` with note "drained".
4. **Merge** (Release only). For each drained branch, run `tools/forge/merge_gate.sh <branch>` with that branch's `FORGE_TEST_CMD` (phase 4 step 6):
   - `git merge-tree --write-tree` pre-check;
   - merge;
   - `run.sh --quick` (validator, unit, conformance);
   - that branch's own scripts.

   Then apply the `followups.md` queue. A red branch is left out and listed; never fix forward during a freeze.
5. **Verify the merged tree.**
   - Run `tools/test/run.sh`: validator, unit, e2e smoke.
   - Run `build_guide.js --check` and `full_chain.js --check` (the drivers compile).
   - At the QA and release milestones, re-check the phase 8 gate predicates as well. They are all static or fast.
6. **Regenerate derived assets. Always, and never from a cache.**
   - **i18n**: run extract, and check coverage against the requirement.
   - **Font subset**: always rebuild; never fall back to a committed font file. Build from every on-screen string in every language. Scan string literals and dictionaries, not comments. Then assert:
     - 0 missing glyphs;
     - the slice or file count matches the fresh build;
     - the font hash differs from the last release whenever the text changed.
   - **Guide**: rebuild the HTML and Markdown, and re-shoot only maps whose data hash changed.
   - **Vendor bundles**, if their source changed. Version stamp in the title or about screen.
   - Commit as `release: regenerate derived assets vX.Y.Z`.
7. **Package.** `tools/package.sh -o "$SCRATCH/dist"` builds `<Slug>-<ver>-<date>.zip`. It contains:
   - only the files the entry page references;
   - the launcher(s) with the executable bit kept;
   - `PLAYING.md`, `GUIDE/` (HTML and MD), licences, the font licence.

   No tools, tests, logs or design sources. Check the size against the budget.

   **7b. Deploy (hosted platform only).** Deploy the packaged folder to the hosting target in `docs/REQUIREMENTS.md`: GitHub Pages from a separate public deploy repo, Netlify, or an itch.io upload that the user does. Record the URL. Never deploy from the game repo itself (it stays private).
8. **Release gate.** Run `tools/forge/release_gate.js` on the zip, with **one mode per render mode × language**. It unzips into a temp path with spaces and CJK characters (the check that mattered for the Mac launcher), boots with no debug flags, presses through title → New Game, and fails on any page error, console error, failed or network request, or failed assertion. Use the game's own settings key and fields (`docs/CONTRACTS.md`). Example for a 2D/3D game in zh + en:
   ```
   unzip -p "$zip" '*.command' | bash -n                       # Mac launchers parse (if any)
   tools/forge/governor.sh -- node tools/forge/release_gate.js "$zip" \
     --modes 2d_zh,3d_zh,2d_en,3d_en --settings-key <slug>_settings \
     --settings '2d_zh={"render3d":false,"lang":"zh"}' --settings '3d_zh={"render3d":true,"lang":"zh"}' \
     --settings '2d_en={"render3d":false,"lang":"en"}' --settings '3d_en={"render3d":true,"lang":"en"}' \
     --press 'wait:1500,KeyZ,KeyZ,wait:3000' \
     --assert 'G.Scenes.top().sceneName==="MapScene"' \
     --assert 'document.fonts.check("16px "+G.CONFIG.font.face)' \
     --out "$SCRATCH/rg/shots" > "$SCRATCH/rg/report.json"
   sha256sum "$zip" >> "$SCRATCH/rg/gate.txt"
   ```
   A 2D, English-only game uses `--modes 2d_en`; a game with a lite 3D mode adds `3dlite_<lang>` modes with `--query '3dlite_<lang>=<lite flag>'`. **Hosted:** after step 7b, run the same command with `--url <URL>` in place of the zip (same-origin requests are allowed) and save its report as `report_url.json`. Both must pass.
9. **Look.** The lead opens every gate screenshot before sending. Check: text rendered in the bundled font, the HUD drawn once, the player visible, the right language.
10. **Publish and send.**
    1. Update the version's section in `docs/RELEASE_NOTES.md`.
    2. Append a row to `docs/forge/releases.md`: version, sha, zip sha256, size, gate result.
    3. Tag `vX.Y.Z` on the packaged sha, then push the tag and `main` (Release) or `release/vX.Y.Z` (milestones).
    4. Send **one** message: the zip attached, its path, a 5-line changelog, and "what to try". The "try" list is taken from the release notes' "please check" section.
11. **Unfreeze.** Re-enable the scheduled tasks. Resume the backlog, or enter phase 12.

## Outputs

- `$SCRATCH/dist/<Slug>-<ver>-<date>.zip`, sent to the user. Never commit zips.
- Committed derived assets: the font subset, the guide outputs, i18n reports.
- `docs/RELEASE_NOTES.md` (one section per build) and `docs/forge/releases.md` (the release log).
- Git tag `vX.Y.Z` on the packaged sha.
- `$SCRATCH/rg/shots/*.png`, `report.json` (+ `report_url.json` when hosted) and `gate.txt`.
- Hosted platform: the deployed URL, recorded in `docs/forge/releases.md`.

## Exit gate

Automated:
- [ ] `release_gate.js` green in every mode (render mode × language) on the zip, and on the URL when hosted.
- [ ] 0 page errors, 0 console errors, 0 network requests (same-origin only for the URL).
- [ ] Font coverage 100%, from a freshly rebuilt subset.
- [ ] Release only: every registry entry is in a terminal status (`done`, `merged`, or `stopped` with note "drained").
- [ ] Release only: no remote branch head has moved since its recorded final sha (`git ls-remote` check, run right before sending).
- [ ] The packaged sha equals the tagged sha (the frozen sha plus its derived-asset commit at milestones). `run.sh` is green on that sha.

Human:
- [ ] **G5 "ship"**, for the final release only. The first playable and the after-QA builds are sent without asking.

## Pitfalls from Shorelight

- **A cloud team pushed after the "final" build.** The battle-view team pushed fixes after v1.0 was packaged and sent. The re-merge and rebuild took 27 min, and v1.0 had to be sent again. So, at Release: freeze, drain, *then* build, with a ls-remote check right before sending. Earlier milestones build from a frozen sha instead, so nobody is stopped mid-build.
- **The rebuild shipped a stale font.** Offline packaging reused a cached subset: 99 slices against 101. Derived assets are always regenerated, and their coverage is asserted.
- **A glyph check flagged a character that wasn't on screen.** The gap check flagged 裪, which appeared only in code comments. Scan on-screen strings, not source files.
- **Packaging found a real bug.** Ctrl+F was bound twice, to fullscreen and to auto-battle. Boot the packaged build with real input, not only the dev tree.
- **The CJK path with spaces** (`My Games 彼岸燈`) was the check that mattered for the Mac launcher. Keep it in the gate.
- **The worker restarted mid-rebuild.** The release log and the registry let the lead resume without guessing.
- **The user had to ask for the zip.** "Do you have a latest version with all the fixes?" and "give me the latest zip". Always attach the zip and its path at every milestone.
- **Packaging was deferred until the text was final,** because the font subset depends on the text. That was correct, and it is why packaging lives in this phase.
- **A WIP snapshot of the shared tree shipped a half-built feature.** It had to go out switched off. Only drained, gated branches reach main.

## Time/cost estimate

- About **15 min** when the drain is clean: Shorelight's final build and gate took 3 min; its first packaging pass took ~12 min.
- Add 15 min for each straggling cloud session, up to the deadline.
- The release gate takes about 1–2 min per mode (render × language) under software GL; double it when hosted (zip and URL).
- Local: lead only, about 0.25 agent-hours (`tools/forge/cost_estimate.md` row 11).
- Cloud: $0. No agents, no cloud sessions.
