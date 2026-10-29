# Phase 7: Balance and economy

## Purpose

Make every boss winnable on the first try by a careful player who is at the level, gear and gold they *really* have at that point, while keeping the fight a real challenge. Prove it with numbers, not with tests that boost the party.

Four instruments:
- **Battle bot**: this is the in-game auto-battle, the AI the player gets. There is no separate, smarter test AI.
- **Boss simulator**: 300–400 first-try fights per boss. The target is 86–94%.
- **Normal-player economy simulator**: the level and gold the player has at each boss.
- **Chain test**: New Game onward with carried state, field encounters on, and no assists.

**No combat** (`CONFIG.battle` absent): the bot, boss simulator and economy simulator are replaced by the **puzzle solver** `tools/sim/solver.js`. It proves that every puzzle is solvable from `chapterStart(ch)` with only what the player has there, and that every step is hinted. The chain test still applies. See the non-combat path in step 1 and the exit gate.

**When.** Start as soon as 2 chapters pass their definition of done, and keep running for the rest of the build. Each chapter is gated on its own results. Do not wait for the whole game.

## Inputs

- `docs/REQUIREMENTS.md`: difficulty defaults, auto-battle styles, the level-up refill rule.
- Systems design from phase 1: XP and gold curve, element chart, collectible thresholds.
- The progression table in `docs/SYSTEMS.md`, which lives in code as `G.Data.progression`: the canonical level and gear table. It also feeds the `chapterStart(ch)` fixture in `tools/test/lib/fixtures.js`, so tests and sims share one table.
- Merged chapters (validator 0 errors, chapter test green), plus their screenplays for each boss's intended feel.
- `blueprint/qa_tools.md` (bot, sims, chain test specs); `rules/testing.md`.

## Steps

1. **Launch** (lead). Start 2 local agents with `briefs/balance.md`:
   - **A, "bosses"**: bot plus boss simulator. Needs no browser.
   - **B, "economy"**: economy simulator plus chain test. Needs 1 browser slot, taken through `tools/forge/governor.sh --`.

   **Non-combat path:** A, "solver", builds `tools/sim/solver.js` instead (steps 2–6 do not apply): for each chapter it searches from `chapterStart(ch)` over the real puzzle data and the items, flags and abilities reachable in that chapter, and reports per puzzle: solvable yes/no, the shortest solution, and any step whose required clue has no `hint`. B runs only the chain test (step 7).

   Each gets its own worktree and an exclusive file namespace: `tools/sim/*`, `tools/test/full_chain.js`, `docs/BALANCE.md`, `docs/qa/full_chain.md`. Register both with `tools/forge/agents.sh add`.
2. **Bot = player AI** (A). Build or upgrade the engine's auto-battle module. A owns it, handed over by the engine owner and recorded in the agent registry. Its policy, in priority order:
   1. revive;
   2. healer heals;
   3. heal item when the healer can't act first;
   4. MP item for the healer;
   5. cure;
   6. guard against telegraphed blows (only the member a warning names);
   7. reliable openers;
   8. ultimates and combos;
   9. otherwise the best expected damage.

   It reads only what the screen shows. Per-fight hints go in a registry keyed by enemy id, never in code that branches on cast names. It offers styles (safe, standard, bold) and an item toggle. Chapter tests and the chain load **this** module.
3. **Canonical state** (A). For each boss, record in `G.Data.progression`:
   - the story party at that point, with guests;
   - skills learned by then;
   - story gifts;
   - gear: the best item per slot from shops **reachable before the fight**;
   - the kit (heals, MP items, revives sold in those shops).

   `chapterStart(ch)` reads this table. Any ad-hoc level, gear or gold boost in a test fails the run.
4. **Boss simulator** (A). Run the **real battle engine headless**. Never re-implement the formulas, because a copy drifts from the engine. Requirements:
   - Each fight uses the exact options the chapter passes to its battle call, so every rule hook runs.
   - Fights with no rest in between are chained, with HP and MP carried over. A phase-2 row reports the win rate of the whole pair.
   - n = 300–400 per fight, fixed seed.
   - Report per fight: win %, KO % (at least one member fell), rounds, and a "2 levels lower" column.
   - Assert **"party alive at win"** on every win.
   ```
   for boss in bosses(ch):
     st = progression.state(boss)                 # level, party, gear, kit
     r  = runN(400, seed, () => realBattle(boss.opts, st, G.AutoBattle))
     assert r.wins.every(w => w.partyAlive > 0)
     row(boss, r.win, r.ko, r.rounds, runN(300, …, st.lv - 2).win)
   ```
5. **Economy simulator** (B). Model 3 players chapter by chapter, from the game's own data:
   - **Critical path.** BFS on real collision from each arrival warp to every exit and every story spot. A roaming enemy counts as met if the path passes within its chase range.
   - **Normal** (the target): fights every enemy met, ×1.3 for backtracking. Opens the chests near the path and the town chests. Does about half the side quests. Buys the kit, then the assumed gear, with its own gold.
   - **Minimal**: flees every field fight and does no side content.
   - **Thorough**: fights everything ×1.5 and does all side content.

   Output, at every boss: level vs the boss level, and the share of the assumed gear (by price) that each player can afford. Then feed each player's state back into the boss simulator (`--model normal|minimal|thorough`).
6. **Tune** (A and B together). Order of levers:
   1. boss and story-battle rewards (exp and gold);
   2. main-path chest gold;
   3. encounter exp per level band;
   4. shop prices;
   5. boss stats, last.

   Raise speed and damage together, and HP only a little: keep fights to 6–12 rounds. Never tune a boss so that a test passes. Outliers are below 60% (too hard) or above 97% with KOs in under 10% of fights (trivial). An exception, such as an empathy fight, needs one written reason.
7. **Chain test** (B, through the governor). Requirements:
   - Start from the real title screen with New Game, no debug preset, in the **default render mode**.
   - Carry all state across chapters.
   - Encounters on: the field fights the economy model says a player meets are fought or paid.
   - The party shops with its own gold.
   - A **firewall** blocks and logs every driver call that injects flags, items, gold, party or levels.
   - Write a boundary save at each chapter boundary; `--from chN` reloads it through the real load menu.
   - Watchdog: a progress line every 30 s; fail fast on any terminal state (game over, title, 3 min with no state change); dump the state on failure.

   Extend the run one chapter boundary at a time as chapters merge.
8. **Gate each chapter** (lead) when A and B report (see Exit gate). From then on, the chapter's merge command (phase 4 step 6) appends the fast balance check (n = 50, the chapter's bosses only; for non-combat games, the solver for that chapter), so any later merge that touches data, enemies, shops or puzzles is re-checked:
   ```
   FORGE_TEST_CMD="bash tools/test/run.sh --quick && tools/forge/governor.sh -- node tools/test/chapters/chN.test.js && bash tools/lint/freeze.sh --verify chN && bash tools/test/run.sh --balance chN" tools/forge/merge_gate.sh <branch>
   ```
   Never edit `tools/forge/merge_gate.sh` per game.
9. **Feel list** (A). Write the things a sim can't judge (boss speed, fight length, how tense the KO rate feels) to `docs/BALANCE.md` § "Needs a human playtest". Phase 10 copies the list into the release notes.

## Outputs

- `docs/BALANCE.md`. It holds:
  - the method;
  - a per-fight table (before and after values, win %, KO %, rounds, the −2 column, and each change);
  - per-chapter economy tables for the 3 players;
  - the levers used;
  - auto-battle results for each style and with items on and off;
  - the needs-a-human list.
- `docs/qa/full_chain.md`: per-boundary level, gold, key items and collectibles; boss level vs BALANCE; every help logged; run history.
- `tools/sim/boss.js`, `tools/sim/economy.js`, `tools/sim/fights.js` (the per-fight hints registry), `tools/test/full_chain.js`. Non-combat games: `tools/sim/solver.js` instead of the three sims.
- `run.sh --balance chN` wired to the sims (or the solver).
- The engine auto-battle module, plus its unit tests (item rules; a warning that names one member).
- Boundary saves in the scratchpad (`chain/saves/chNN.json`). Never commit them.

## Exit gate

Per chapter, all automated (combat games; non-combat games use the solver gate below plus the chain test):
- [ ] Every boss is at **86–94%** at its canonical state (n ≥ 300), or has a written exception.
- [ ] 0 wins with a dead party.
- [ ] Normal player: within **±1 level** of each boss's level, and affords **≥ 90%** of the assumed gear by price.
- [ ] Minimal player: **≥ 60%** first-try win on every boss.
- [ ] In-game auto-battle, standard style, normal player's state: mean **≥ 90%**, no boss under 70%. Field troops: 100% wins with 0 items used.
- [ ] Chain test: from the previous boundary save to this chapter's boundary, with encounters, **no assist**, 0 wipes, 0 page or console errors. Boundary checks hold:
  - the chapter number goes up by exactly 1;
  - no NaN or unknown ids;
  - the previous chapter's main quest is done.

Non-combat games, per chapter:
- [ ] Solver: every puzzle solvable from `chapterStart(ch)`; every required step has a `hint`; 0 dead ends.
- [ ] Chain test as above (the boundary checks hold; no assist).

Whole game, before phase 8:
- [ ] The chain runs New Game → every ending with no assist.

No human gate. Feel goes to G4 through the needs-a-human list.

## Pitfalls from Shorelight

- **Tests that lied about balance.** Boss tests passed only because each test levelled the party (ch8 at Lv36 against an expected ~28). Once the boost was removed, the ch3 ambush wiped a Lv11 party 2 times in 3.
- **Balance ran late.** It started only after all 12 chapters existed. At that point every boss was at 100% (trivial) except 石巨靈 at 11%. Several bosses the builders had softened had to be raised again.
- **The ch8 wall.** The chain run hit game over at 潮怨・百手. The carried party had 1,983 gold against 14,400 of assumed gear. The cause was gold, not level. The fix changed rewards on ~30 bosses and ~35 chests and **no boss stats**, and took the ch8 boss from 31% to 97%.
- **The F-key auto-battle was dumber than the test bot.** Its mean boss win rate was 37% against the bot's 94%. A "final boss stall" reported in 3D was really this AI losing and sitting on a custom game-over screen the harness didn't recognise.
- **A fallen ally counted as a boss win.** A floor check returned `false` rather than null for party members, so 無相 phase 2 "won" 92% of fights while the party was dying. Hence the party-alive assertion.
- **A boss that could never end.** 鯤's HP floor sat above its win threshold, and the ch11 test hung 8+ min on a 50-min timeout. Hence the no-output watchdog.
- **Rewards left unpaid.** Two bosses that end by script never paid rewards, because the battle call lacked the rewards option.
- **A hard-coded chapter floor.** The ch8 entry level floor was hard-coded to 25 while the table said 27. Every chapter test started from a debug preset, so none of them saw it.
- **A re-implemented sim.** The first simulator copied the damage formulas and resisted magic with the attacker's stat instead of the target's. That hid the boss that nearly one-shot the hero. Use the real engine.

## Time/cost estimate

- First full pass for 2 chapters: about 1.5 h for agent A and 1.5 h for agent B.
- Each later chapter: about 20–40 min.
- A full boss sweep (36 bosses × 400 fights): about 10–20 min of CPU in Node, with no browser.
- Chain test: about 4–5 min per chapter at test speed. The full game took ~50 min in Shorelight.
- Local: 2 agents running in the background for the whole build, ~4–6 h each ≈ **8–12 agent-hours** (`tools/forge/cost_estimate.md` row 7). Forecast that at G0b, scaled to the game as the worksheet says (a 2-chapter mini is roughly 1/5 of it).
- Cloud: $0.
