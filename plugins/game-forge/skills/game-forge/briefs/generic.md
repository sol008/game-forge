# Helper brief: {{TASK_KIND}}, {{SCOPE}} — {{GAME}}

<!-- Lead: for any helper with no role brief of its own. TASK_KIND = polish (scenes, music, likeness, perf; phase 9) |
pnr-audit (points of no return) | chain (full-chain test) | fix (one bug, phase 12). Keep the matching block under
"Kind rules" and delete the others. Wrap in cloud_session.md when it runs in the cloud. Fill every slot and delete
this comment; `grep -n '{{' brief` must then print nothing. -->

## Goal
{{ONE_LINE_GOAL}} for {{SCOPE}}. Done means the definition of done below holds, not "it looks better".

## Read first
1. `{{REQUIREMENTS}}`: render mode, languages, QoL defaults, and the fields this task touches.
2. The spec you work against: {{SPEC_FILES}} (screenplays and `docs/story/cues.json`, design picks, the bug row, or
   `docs/qa/points_of_no_return.md`).
3. The code you call or change: {{CODE_FILES}}. Read it before you claim how it works.
4. Canon you must not contradict: `{{BIBLE}}`, `docs/canon/*.json`, `docs/i18n/GLOSSARY.md`.

## Files you own (exclusive)
- {{OWNED_PATHS}}. Nothing else.
- Never edit the engine, shared data, the shared test helpers or another agent's files unless they are listed above.
  Engine or shared bugs outside your paths: report them with file:line; don't patch around them.
- Flags, item and quest ids and the order of story beats stay as they are unless this brief says otherwise.

## Kind rules
**polish.** Work only on {{SCOPE}} (key scenes, tracks, likeness targets or perf maps). Pass cap: {{PASS_CAP}}. A
changed music cue is changed in the screenplay's `<!-- cue: -->` line and `docs/story/cues.json` too. Loudness: peak
≤ −1 dBFS, integrated −20 ±3 LUFS-ish as `tools/render_music.js` measures it. Every rewritten line gets new
translations.

**pnr-audit.** For every one-way transition in {{SCOPE}}: it calls the point-of-no-return API, it is catalogued in
`docs/qa/points_of_no_return.md`, and walking to it with each open quest and unfound collectible shows a warning that
names the quest and counts the collectibles. Fix the catalogue; report missing calls in game code to the lead, or fix
them if {{OWNED_PATHS}} includes that file.

**chain.** Run `{{CHAIN_CMD}}` from New Game, default difficulty, **default render mode**, encounters on, no assists.
At each boundary, compare with the progression table: within ±1 level at each boss, gear affordability ≥ 90 %. Save
and reload once (`--reload-at`). A game without combat runs `tools/sim/solver.js` first; the chain still applies.
You report; you don't tune.

**fix.** One bug: `{{BUG_ID}}`. First write a failing test that encodes the spec, then fix it. Grep every unit for
the same pattern (siblings) and fix those in your paths. Prefer an engine invariant to a per-scene patch if the
engine is yours. Then make it a check: a validator rule, a unit or e2e test, or an engine assertion.

## Definition of done
1. Tests: {{TEST_CMDS}} pass in **{{RENDER_MODE}}** using the canonical fixture `{{FIXTURE}}`. For fix: the new test
   passes now and fails on the pre-fix sha.
2. `{{VALIDATE_CMD}}`: 0 errors, 0 warnings.
3. `{{I18N_CMD}}`: every line you added or changed has an entry in every target language (none when `langs` =
   [source]); 0 missing keys.
4. Guide fragments updated if your change affects them; otherwise say "guide: not affected".
5. Commit only your owned paths (`git add <paths>`, never `-A`) to `{{BRANCH}}` in `{{WORKTREE}}`. Report, then
   **STOP**.

## Time budget and stop rule
Budget {{BUDGET_MIN}} min. At 75 %: finish the open item, start no new one. At 100 %: commit what is green, report
PARTIAL with what is left. The same failure at the same step twice is a real bug: report it, don't loop on it.
Report a fix **as soon as it is made** (sha + what changed), then verify only what it touched, within the budget.

## Re-run scope
After a change, re-run only the tests that cover it (failing segment, changed track, touched map), then one final run
of {{TEST_CMDS}}. Never re-run green work "to be sure", and never start a second full pass.

## Tools and hygiene
- Every browser or headless-GL run goes only through `tools/forge/governor.sh -- <cmd>` (`--prio` for user-reported
  bugs only), with an explicit timeout. Run long jobs in the background and poll the log.
- Logs, renders and scratch scripts go to `$SCRATCH/{{AGENT_ID}}/` (`$SCRATCH` is set in `docs/forge/env.md`), never
  the repo. Read results from the `RESULT` summary line, never a truncated tail.
- Only report APIs you can show by file:line. Grep before you claim.

## Report format
```
STATUS: DONE | PARTIAL | BLOCKED        time: <used>/{{BUDGET_MIN}} min
Kind: {{TASK_KIND}}    Scope: {{SCOPE}}    Branch: {{BRANCH}} @ <sha>
Done: <item> — <what changed> — <file:line>
Tests: <cmd> → <PASS n/n> in {{RENDER_MODE}} (log: $SCRATCH/{{AGENT_ID}}/<file>)
Validator: <errors>/<warnings>          i18n missing keys: <n>
New check added (fix only): <test or rule id> — <file:line>
Siblings found (fix) / boundaries (chain) / pnrs (pnr-audit): <list>
Engine/shared bugs (unpatched): <file:line> | repro | expected | actual
Backlog:
```

> **Shorelight lesson** (opening Shorelight itself: similar policy only).
> The ch1 builder had no definition of done, polished for 30 more minutes and broke its own green run. The 3D sweep
> helper started a needless 2-hour second full pass until the lead stopped it. Four builders each worked around the
> same engine bug instead of reporting it once.
