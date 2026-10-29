# Balance brief: {{UNITS}} — {{GAME}}

<!-- Lead: start once 2 units exist; runs continuously. Freeze the numeric fields of TUNABLE_FILES for other agents
while this runs. No combat (`CONFIG.battle` absent): the goal becomes "every puzzle solvable from `chapterStart`, every
step hinted" with `tools/sim/solver.js` as SIM_CMD and no ECON_CMD; the chain test still applies. Fill every slot and
delete this comment. -->

## Goal
Every boss and scripted fight in {{UNITS}} is won on the **first try** {{WIN_BAND}} of the time (e.g. 86–94 %) by a
normal player at the level, gear and items they really have there. Gear in each shop is affordable on arrival. The
chain test reaches each unit boundary with encounters on and **no assists**.

## Read first
1. `{{REQUIREMENTS}}` (difficulty, QoL defaults) and `{{SYSTEMS_DESIGN}}` (XP and gold curve, elements, stats).
2. `{{PROGRESSION_TABLE}}` and the canonical fixture `{{FIXTURE}}`: expected level, gear, items and gold per boundary.
3. The battle engine you simulate: {{BATTLE_FILES}}. Each unit's fight rules and hooks: {{UNIT_FILES}}.
4. `{{BOT}}`: the player-facing auto-battle AI. The sim uses it, never a dumber one.

## Files you own (exclusive)
- `{{BALANCE_DOC}}`, `tools/sim/*` (`boss.js`, `economy.js`; `solver.js` when there is no combat).
- Numeric fields only (enemy stats, rewards, XP, gold, prices, drop tables) in {{TUNABLE_FILES}}. No text, flags,
  scripts or ids. Any renamed or new item needs an entry in every target language (none when `langs` = [source]).
- Engine bugs (a fight that can't end, a wrong win check): report them with file:line; don't patch the engine.

## Method
- **Boss sim:** `{{SIM_CMD}}`, {{SIMS_PER_BOSS}} fights per boss, run through the real battle code and every fight's
  own rule hooks. Chain fights with no rest between them (HP and MP carry over).
- **Player model:** level, gear and kit from `{{FIXTURE}}`; gear = the best per slot from shops reachable before the
  fight. Also measure at fixture − 2 levels.
- **Economy sim:** `{{ECON_CMD}}`. A normal player explores, fights the encounters met (~{{ENCOUNTER_RATE}}) and does
  about half the side quests. Record level, gold and gear at every boundary against the table.
- **Chain test:** `{{CHAIN_CMD}}`, New Game onward, encounters on, no assists. It's the integration gate.
- Fix the economy first (XP, gold, rewards, prices), boss stats second. One change at a time; re-sim only the
  affected fights.
- Never tune a fight to make a test pass. Assert the party is alive at every win. A fight with no result after
  {{MAX_TURNS}} turns is a bug (bot or design): report which.

## Definition of done
1. Every fight in {{UNITS}} within {{WIN_BAND}} at the fixture level, and still winnable at fixture − 2. A normal
   player is within ±1 level of the table at each boss, and gear affordability is ≥ 90 %.
2. Tests: `{{CHAIN_CMD}}` reaches every boundary in {{UNITS}} in **{{RENDER_MODE}}** with no assist, starting from
   `{{FIXTURE}}`; `{{UNIT_TESTS}}` pass; the unit tests of every file you touched still pass.
3. `{{VALIDATE_CMD}}`: 0 errors, 0 new warnings (item sources, shop references). Target-language entries present
   for any rename.
4. `{{BALANCE_DOC}}` has a table per fight (level, win % before → after, what changed) and a table per boundary
   (expected vs simulated level, gold, gear).
5. Commit only your owned paths to `{{BRANCH}}` in `{{WORKTREE}}`. Report, then **STOP**.

## Time budget and stop rule
Budget {{BUDGET_MIN}} min per pass. At 75 %: stop tuning, run the final sims. At 100 %: commit the in-band part,
report PARTIAL with the out-of-band fights.

## Re-run scope
Re-sim only the fights and boundaries your last change affects; one full sim and chain run at the end.

## Tools and hygiene
- Headless sims run in Node. Any browser run (chain test) goes only through `tools/forge/governor.sh -- <cmd>`.
- Sim outputs and logs go to `$SCRATCH/{{AGENT_ID}}/` (`$SCRATCH` is set in `docs/forge/env.md`). Write results to
  a file and grep the summary line; never read results off a truncated tail.
- Only report APIs you can show by file:line.

## Report format
```
STATUS: DONE | PARTIAL | BLOCKED        time: <used>/{{BUDGET_MIN}} min
Branch: {{BRANCH}} @ <sha>
| Fight | Unit | Lv | Win % before | Win % after | Win % at Lv−2 | Change |
| Boundary | Lv exp/sim | Gold exp/sim | Gear affordable % |
Chain: {{CHAIN_CMD}} → reached <boundary> unassisted (log: $SCRATCH/{{AGENT_ID}}/<file>)
Engine/bot bugs (unpatched): <file:line> | repro | expected | actual
Design notes for the lead (e.g. end-game gold slack):
Backlog:
```

> **Shorelight lesson** (opening Shorelight itself: similar policy only).
> Boss tests passed because the test set the party to Lv36 against an expected ~28. The chain run
> then hit game over at ch8: 2k gold against 14k of gear. Fixing rewards and XP alone, with no boss stat changed, took
> the ch8 boss from 31 % to 97 %. Earlier ad-hoc softening had made three ch11 bosses trivial. A "final boss stall"
> turned out to be a dumb test AI losing and sitting on a game-over screen.
