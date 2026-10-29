# QA walkthrough brief: side content, {{RANGE}} — {{GAME}}

<!-- Lead: mandatory pre-ship phase, one session per chapter range (usually cloud, wrapped in cloud_session.md).
Create the shared harness `{{SHARED_HARNESS}}` BEFORE fan-out so no two sessions write the same helper.
FIX_MODE = report-only | fix-content. Fill every slot and delete this comment. -->

## Goal
Prove that every side quest, collectible and optional reward in {{RANGE}} can be **found, played and completed by a
real player**, and that nothing is lost without warning. Play as a player. Write a PASS/FAIL script per unit and a
report table. Discoverability failures are bugs, exactly like crashes.

## Read first
1. `{{SCREENPLAYS}}` for {{RANGE}}: the spec for each quest, its pointers and its rewards.
2. `{{QUEST_DATA}}`, `{{PONR_DATA}}` (points of no return), `docs/canon/collectibles.json` (the plan list; ids are
   derived from quest ids), and the ending thresholds.
3. `{{SHARED_HARNESS}}` (read-only): BFS walker, real-key input, player bot, terminal-state detector.
4. `{{DISCOVERABILITY_RULES}}`: marker or glint, pointer, hit area ≥ 2 tiles, `hint` per step.

## Files you own (exclusive namespace)
- `{{SIDEQUEST_DIR}}/{{RANGE}}/*`. Every new file, helpers included, goes inside it. Never create files outside it.
- `{{QA_REPORT}}`.
- FIX_MODE `{{FIX_MODE}}`. With fix-content you may edit only clue, hint, marker and pointer content in
  {{FIXABLE_FILES}}, adding target-language entries for each new line. Never touch the engine, the shared harness or other ranges.
- Engine or harness bugs: report them; don't patch them.

## How to play (hard rules)
- Start each script from `{{FIXTURE}}` at the start of its unit. That is the only jump allowed.
- **Never write quest flags, quest stages, items, gold or collectibles.** Read state only to assert.
- Move by **BFS walking** over walkable tiles to the target, never by teleport. An unreachable target is a FAIL.
- Interact with the **real interact key** (`{{INTERACT_KEY}}`) while facing the target. Wait for script idle first.
- Choices through the real menu. Battles, if any, through the player-facing bot `{{BOT}}`, never a dumber one.
- Buy through the shop UI. If you must simulate a purchase, assert the item is on that shelf at that price.
- Detect any terminal state (game over, title, no state change for {{STALL_S}} s) and fail fast with the last step.

## Check per quest or collectible
1. **Discoverable:** a pointer to its start (NPC line, quest-log entry, visible marker), and a clue for every step.
   A bare tile with no marker, an exact single-tile hit area or a hidden precondition = FAIL (discoverability).
2. **Completable:** starts, every stage advances, it completes, rewards arrive, the collectible counts, the log closes.
3. **Missable:** every one-way transition after its start lists it in the point-of-no-return warning, or it stays
   reachable afterwards. Permanently missable with no warning = FAIL (missable).
4. **Reachable:** BFS from every map entry to every exit, stair, chest and quest target in the range.
5. No page or console error, and `{{LAST_ERROR}}` stays null.

## Scripts
`{{SIDEQUEST_DIR}}/{{RANGE}}/<unit>.side.js`. Print one line per check, `PASS <id> ...` or `FAIL <id> <class>
<reason>`, then `SUMMARY <pass>/<total>`. Exit non-zero on any FAIL. Each script stays under 20 min.

## Definition of done
1. Every script PASS in **{{RENDER_MODE}}** using `{{FIXTURE}}`. If you ran in another mode for speed, spot-check every
   marker and glint in {{RENDER_MODE}} and say so.
2. `{{VALIDATE_CMD}}`: 0 errors, 0 new warnings. Every line you added has an entry in every target language (none
   when `langs` = [source]).
3. Report table complete, with every shortcut stated. Commit only your namespace (and fixes, if allowed) to
   `{{BRANCH}}`. Report, then **STOP**.
4. Design calls (add a warning? move a quest?) go in the report with your proposed default. The lead decides; don't wait.

## Time budget and stop rule
Budget {{BUDGET_MIN}} min. At 75 %: finish the open unit, report the rest unplayed. At 100 %: push, report PARTIAL.

## Re-run scope
After a fix, re-run only the failing script, then one final run of all your scripts.

## Cloud rules (when run as a cloud session)
- Push a WIP commit every 10 min and after each script. Status goes in the commit message:
  `[{{AGENT_ID}}] <pass>/<total> | <unit> | next: <x> | blockers: <none|...>`.
- Never wait for human approval. The lead may pause, resume or stop you. Ship-without-you: {{SHIP_WITHOUT_YOU_AT}}.

## Tools and hygiene
- Browser runs only via `tools/forge/governor.sh -- <cmd>`, with an explicit timeout ≥ 2× the expected run.
- Logs and screenshots go to `$SCRATCH/{{AGENT_ID}}/` (set in `docs/forge/env.md`), never the repo.
- Only report APIs you can show by file:line.

## Report format (`{{QA_REPORT}}`)
```
STATUS: DONE | PARTIAL | BLOCKED     time: <used>/{{BUDGET_MIN}} min     Branch: {{BRANCH}} @ <sha>
| Unit | Quest / collectible | Result | Discoverable | Missable warned | Fixed / proposed | Shortcut used |
Shortcuts used (every one, and why): debug start, simulated buys, render mode, bot battles, ...
Engine/harness bugs (unpatched): <file:line> | repro | expected | actual
Design calls proposed (with default):
Ending/collectible totals checked: <n> found vs <n> expected
```

> **Shorelight lesson** (opening Shorelight itself: similar policy only).
> Two QA branches both created `sidequests/lib.js`, so the merge conflicted and one became
> `lib68.js`. The ch11 lighthouse stairs sat on wall tiles; the finale was unreachable on foot, and the old chapter
> test had teleported past it. Items lay on bare tiles (扇貝殼, 懷錶), ~25 quests had no pointer, and ch5's 半邊井 心燈
> was permanently missable. The QA sessions used shortcuts that were only accepted because they were declared.
