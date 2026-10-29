# Phase 11: Freeze and release

## Purpose

Turn the merged tree into one tested zip and put it in the user's hands. Nothing may change underneath the build:
1. freeze;
2. drain **all** agents;
3. merge;
4. regenerate the derived assets;
5. package;
6. pass the release gate;
7. send.

**Zips go out only at milestones:**

| Milestone | When | Gate before it |
|---|---|---|
| First playable | Every chapter chains from New Game to an ending | Phase 4 per-chapter gates + phase 7 chain |
| After the QA wave | Phase 8 exit gate green | Phase 8 + 9 + 10 gates |
| Release | After the G4 fix loop, when the user says "ship" (G5) | Everything above + phase 12 regressions |

A batch of playtest fixes is shipped as the next release candidate, through this same phase. There are no ad-hoc preview zips in between.

## Inputs

- The green branches of every agent, and the follow-ups queue (`followups.md`).
- `tools/package.sh`, the font builder, `tools/i18n/extract.js`, `tools/guide/build_guide.js`.
- `forge-tools/merge_gate.sh`, `forge-tools/release_gate.sh`.
- `docs/REQUIREMENTS.md`: platform(s), render modes, languages, launcher, zip-size budget.

## Steps

All steps are done by the **lead, alone**. There is no parallelism in this phase, on purpose.

1. **Announce the freeze.** Post one status row: "FREEZE at `<sha>`, `<time>`". From now on, no new work package starts. Disable any scheduled task that would launch agents; keep the check-in.
2. **Drain local agents.** For each registry entry:
   - it finishes its current unit and commits on its own branch, or it is stopped;
   - uncommitted work stays on its branch or is discarded, and either way is listed;
   - nothing is swept into main.

   Then mark each entry `drained`.
3. **Drain cloud sessions.**
   1. Send each one: "Freeze. Push your final commit now, then stop. Nothing pushed after `<time+10 min>` ships in this build."
   2. A session counts as drained when its status is idle or complete **and** its branch head has not moved for 5 min.
   3. After 15 min, ship without the session; its later work waits for the next milestone.
   4. Record each branch's final sha.
4. **Merge.** For each drained branch, run `merge_gate.sh <branch>`:
   - `git merge-tree --write-tree` pre-check;
   - merge;
   - unit tests and validator;
   - that branch's own scripts.

   Then apply the `followups.md` queue. A red branch is left out and listed; never fix forward during a freeze.
5. **Verify the merged tree.**
   - Run `tools/test/run.sh`: validator, unit, e2e smoke.
   - Run `build_guide.js --check` and `full_chain.js --check` (the drivers compile).
   - At the QA and release milestones, re-check the phase 8 gate predicates as well. They are all static or fast.
6. **Regenerate derived assets. Always, and never from a cache.**
   - **i18n**: run extract, and check coverage against the requirement.
   - **Font subset**: rebuild from every on-screen string in every language. Scan string literals and dictionaries, not comments. Then assert:
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
8. **Release gate.** Run `forge-tools/release_gate.sh <zip>`:
   ```
   dir="$SCRATCH/rg/My Games <title_zh>"          # CJK + spaces on purpose
   unzip -q "$zip" -d "$dir"; bash -n "$dir"/*.command
   for mode in 2d 3d 3d-lite; do for lang in $LANGS; do
     boot "file://$dir/index.html" --mode $mode --lang $lang   # no debug flags
     press Z → title → New Game → first map; open menu
     assert pageErrors==0 && consoleErrors==0 && failedRequests==0
     assert fontProbe uses bundled face; audio context running
     shot "$SCRATCH/rg/shots/${mode}_${lang}.png"
   done; done
   sha256sum "$zip" >> "$SCRATCH/rg/gate.txt"
   ```
9. **Look.** The lead opens every gate screenshot before sending. Check: text rendered in the bundled font, the HUD drawn once, the player visible, the right language.
10. **Publish and send.**
    1. Update the version's section in `docs/RELEASE_NOTES.md`.
    2. Append a row to `docs/forge/releases.md`: version, sha, zip sha256, size, gate result.
    3. Tag `vX.Y.Z`, then push main and the tag.
    4. Send **one** message: the zip attached, its path, a 5-line changelog, and "what to try". The "try" list is taken from the release notes' "please check" section.
11. **Unfreeze.** Re-enable the scheduled tasks. Resume the backlog, or enter phase 12.

## Outputs

- `$SCRATCH/dist/<Slug>-<ver>-<date>.zip`, sent to the user. Never commit zips.
- Committed derived assets: the font subset, the guide outputs, i18n reports.
- `docs/RELEASE_NOTES.md` (one section per build) and `docs/forge/releases.md` (the release log).
- Git tag `vX.Y.Z` on the packaged sha.
- `$SCRATCH/rg/shots/*.png` and `gate.txt`.

## Exit gate

Automated:
- [ ] `release_gate.sh` green in every render mode × every language.
- [ ] 0 page errors, 0 console errors, 0 network requests.
- [ ] Font coverage 100%.
- [ ] Every registry entry is `drained`.
- [ ] No remote branch head has moved since its recorded final sha (`git ls-remote` check, run right before sending).
- [ ] The packaged sha equals the tagged sha. `run.sh` is green on that sha.

Human:
- [ ] **G5 "ship"**, for the final release only. The first playable and the after-QA builds are sent without asking.

## Pitfalls from Shorelight

- **A cloud team pushed after the "final" build.** The battle-view team pushed fixes after v1.0 was packaged and sent. The re-merge and rebuild took 27 min, and v1.0 had to be sent again. So: freeze, drain, *then* build, with a ls-remote check right before sending.
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
- The release gate takes about 1–2 min per mode × language under software GL.
- Cost: lead only. No agents, no cloud sessions.
