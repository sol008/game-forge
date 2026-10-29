# Mined slice 02: 2026-10-27 09:20 to 12:21 UTC (~3 h)

The integration and verification phase: the cloud 3D teams land and get merged, ch11 is finished, balance runs, English QA and Mac packaging happen, and the full-chain playthrough starts. Repo `/home/user/testProject/shorelight`, lead branch `claude/magical-davinci-kp4fhq`, cloud team branches `r3d-<team>`.

## 1. Phases & outputs (in order)

| Time | Output | Who |
|---|---|---|
| 09:25 | Merged **r3d-arch-coast** (22 assets / 37 models; 14 maps clean). Lead fixed 2 shared-code bugs in `js/r3d/models.js`, `js/r3d/mapview.js` | cloud, then main |
| 09:27 | ch11 test hang diagnosed, test killed (pid 2537) | main |
| 09:29-09:34 | ch11 EN translation done (game 99.9% EN); credits/punctuation i18n fixes | local subagent, then main |
| 09:32 | Party 3D costumes applied (4 sheets `docs/r3d_reports/cast/*_v2.png`) | local subagent |
| 09:33 | **Face pass + feminine 白芷** agent started (user yes) | local subagent, ~36 min |
| 09:34 | Merged **r3d-nature** (40 kinds x3 variants); lead wired `G.Nature3D.scatterGrass/update` into Map3D | cloud, then main |
| 09:37 | Merged **r3d-props-interior** (37 kinds); fixed `collectLights` to respect `o.rot3d` | cloud, then main |
| 09:39 | Merged **r3d-props-street** (32 kinds); 3 shared bugs fixed (variants, switch state, spirit fade) | cloud, then main |
| 09:41 | Merged **r3d-monsters-a** (26 creatures); forwarded boss `setPhase` API to battle team | cloud, then main |
| 09:45 | CPU at 2/4, so started **Mac packaging** and **English layout QA** agents | local subagents |
| 09:46 | Merged **r3d-arch-han** (25 types + 登高 tower) | cloud |
| 09:57 | Packaging done (~12 min): subset font 3,103 chars / 1.6 MB, `Play Shorelight.command`, Electron, `PLAYING.md`, 7.3 MB zip; Ctrl+F double-bind (fullscreen + auto-battle) fixed | local subagent, then main |
| 09:58 | Merged **r3d-monsters-b** (35 incl. bosses); lead wrote `scratchpad/mon_check.js` Playwright check: 61/61 art ids build, 0 errors | cloud, then main |
| 10:00 | Merged **r3d-animals**; renders showed off-model cats, so a polish pass was requested, plus 2 monster-B tidy items | cloud |
| 10:09 | Face pass delivered (~36 min) | local subagent |
| 10:14 | Merged **r3d-env** (water/sky/weather/vision FX); fixed FX.vision buffer not cleared (solid-rainbow overlay) in `js/gfx/fx.js` and set PCFShadowMap | cloud, then main |
| 10:18 | English layout QA done (~33 min): 29 overflow fixes, 14,418 lines fit in 4 lines or fewer, 54/54 unit tests | local subagent |
| 10:27 | ch11 passes both endings (segments ~13.5 min total); held follow-ups applied from `followups.md` | local subagent, then main |
| 10:28 | **Full chain playthrough** agent started (New Game to both endings) | local subagent |
| 10:40 | Balance ch0-10 done, `docs/BALANCE.md`, new `tools/test/lib/battlebot.js`; 400 sims/boss, target 86-94% first-try | local subagent |
| 11:00 | ch11 balance done; lead fixed `hpFloor` bug in `js/engine/battle.js` | local subagent, then main |
| 10:57-11:56 | Chain run: ch0 to ch7 in 26 min, then game over at ch8 (Lv25 vs 28 expected, 3 fighters). Re-ran `--from ch8 --assist` | local subagent |
| 12:08-12:13 | "Watch it play" attempt: Playwright video failed, stills sent instead | main |
| 12:17 | 4 new agents: playtest timer/stats page, Chinese proofread ch0-3 / ch4-7 / ch8-11 | local subagents |
| open | **r3d-battle** (last of 11 teams), 7 commits by 12:20, ETA 30-60 min | cloud |

Pattern: 10 of 11 cloud 3D teams merged within about 50 min (09:25 to 10:14). Each merge cost the lead 1-3 small shared-code fixes.

## 2. Decisions

**User:** face pass yes, plus "make 白芷 more feminine" (09:33). "Wait for the final build", no preview zip (09:58). Add both proofreading and a play-time clock, in parallel (12:16).

**Assistant, unprompted:** fixed shared 3D bugs itself in the lead files, not the teams. Accepted the teams' design calls (擂茶 bowl as the default mill stone, herb rack design). Ordered polish passes for the cats and 2 monsters after viewing renders. Rebalanced bosses to 86-94%. Raised ch11 bosses back after over-softening. Started packaging and English QA when CPU was idle. Chain run used a logged level assist after the ch8 failure. Recommended more story XP for ch5-8. Ruled out the video because 2 fps would misrepresent the game.

**Questions the assistant asked the user, and whether a template could have pre-answered them:**
- "Put a helper on a face pass?" Yes. Default rule: "visual fidelity gaps found in self-review: fix automatically up to N passes".
- "Preview zip now or wait for final?" Yes. Template field: `deliverable_cadence: final_only | previews`.
- "One more eyes/lips pass?" Partly. Default: keep iterating while the side-by-side diff is visible, then stop at a cap.
- "Upgrade F-key auto-battle to the smart AI?" (asked twice, never answered in slice) Yes. Default: "auto-battle must be able to clear normal-difficulty content".
- "Proofread pass / play-time clock?" Yes. Proofreading and a playtest telemetry page belong in the standard pipeline, not an opt-in.
- Battle view "needs your 'yes, resume' in its session" (09:20 to about 10:00) Yes. A cloud session should never be in a state where it needs human approval. Spawn it non-plan, auto mode, with a full brief.

## 3. Problems & lessons

| # | Problem | Root cause | Fix | RULE |
|---|---|---|---|---|
| P1 | ch11 test hung 8+ min after 「平安信」 step; helper sat on a 50-min timeout | 鯤 boss `hpFloor` sat just above the win threshold, so the fight could never end; test had no stall detector | Lead killed pid, sent the helper the evidence and a 30-min deadline; boss fixed | Test runners need a **no-output watchdog** (for example 90 s without log progress means fail with the last step). Never rely on long global timeouts. The same stop point in 2 runs means a real bug. |
| P2 | SendMessage to a busy helper is not read until its tool call returns | Helper was blocked in a long foreground wait | Killing the child process woke it | Helpers run long tests in the background and poll; the lead may kill a stalled child to deliver messages. |
| P3 | Battle view team idle ~40+ min waiting for user "yes, resume" | Cloud session paused for human approval (quota or plan gate) | User confirmed out of band | Spawn cloud sessions in a mode that never blocks on approval; the lead detects "0 commits in 20 min" and escalates once, clearly. |
| P4 | Shared-code bugs found by nearly every team: variant `o.v` reset, spirit fade on shared materials, lights ignoring `rot3d`, switch state not updating model, FX.vision buf not cleared, missing `MapScene.hooks()` (team shimmed it) | Contract (`docs/CONTRACTS_3D.md`) and the lead-owned core were incomplete when the teams forked | Lead patched each one at merge time | Before fan-out, run a **contract smoke test** with 1 sample asset per team type through core (variants, clone or material isolation, rotation, state toggles, hooks). Teams report core bugs and do not shim them. |
| P5 | Two monster teams each built their own registry | Parallel teams on one domain | Lead ran combined Playwright check `mon_check.js` (61/61) | When splitting a domain, the registry is owned by the lead or by team A; a combined integration check after each merge. |
| P6 | Cats and monsters "pass checks" but off-model (芋圓 not chubby, 麻糬 spiky fur, blocky colossus, thin mane) | Automated checks verify build and errors, not likeness | Lead rendered and compared against `REFERENCES.md` and sent a polish brief | Every art deliverable gets a **side-by-side render vs reference sheet** reviewed by the lead before "done". |
| P7 | 3D faces flat, ears too big, eyes weaker than portraits | Face system paints a flat texture | Face-pass agent | Same as P6; budget a face/likeness pass in the plan. |
| P8 | Ally falling counted as a boss win (夜玄, 無相 "won" while dying) | `hpFloor[tg.id]` returned `false` for allies; `false != null` is truthy | Guard `tg.side === 'enemy'` | Prefer explicit boolean checks; balance sims should assert "party alive at win". |
| P9 | Bosses 100% trivial except 石巨靈 11%; ch11 then 9-20% | No balance pass until late; auto-battle AI too dumb to be a proxy | Sim with `battlebot.js`, 400 fights per boss, retune to 86-94% | Build the balance simulator plus a player bot **early**; gate each chapter on a win-rate band. |
| P10 | Over-softening: earlier ch11 softening made 3 bosses trivial | Ad-hoc fixes to make tests pass | Rebalanced | Never tune difficulty to make a test pass; tests use the bot, and tuning goes through the sim. |
| P11 | Chain run game over at ch8; story-only party 2-5 levels under target | XP curve designed per chapter in isolation; chapter tests used presets | Logged assist; recommend more story XP for ch5-8 | Run the **chain test (New Game, no presets)** as soon as 2+ chapters exist; record level, gold and items at each boundary vs expected. |
| P12 | Chain agent had to fix its own script and restart (11:15) | New harness | Agent self-fixed | Keep a reusable chain harness in `tools/test/` from the start. |
| P14 | Video recording captured only the title screen; 3D at ~2 fps without a GPU | Debug URL jump didn't take effect in the recorder; headless has no GPU | Sent stills | Know that **no GPU means no video/perf claims**; provide a `?scene=` debug entry that is tested; don't promise video. |
| P15 | Stop hook fired 9 times; 27 "WIP snapshot" commits in 3 h | Helpers edit the shared working tree continuously; `stop-hook-git-check.sh` demands a clean tree | `for i in 1 2 3; git add -A; commit` loops | Helpers work in **worktrees or branches**; the lead merges logical commits. Or the hook ignores helper-owned paths. |
| P16 | Stray `tuneB.log` in repo root | Helper wrote logs to the repo | Moved to scratchpad | Briefs: "all logs and artifacts go to `$SCRATCH/<task>/`"; add `*.log` to `.gitignore`. |
| P17 | Late, duplicate status replies from teams after they had already merged | Async ping then reply lag | Ignored | Teams post status in commits; the lead reads `git log`. |
| P18 | Ch11 follow-ups (EN label 木 to "Wood", strike-through, long speaker name) couldn't be applied while the helper owned the file | File ownership | `followups.md` queue, applied at 10:27 | Keep a follow-up queue keyed by file owner; flush on handoff. Good pattern. |

## 4. Process patterns

**Worked**
- **Cloud fan-out of 11 asset teams** on `r3d-*` branches, sharing `docs/CONTRACTS_3D.md`. Each team writes `docs/r3d_reports/<team>.md` plus a lineup PNG. Merge flow: `git merge-tree` precheck (always CLEAN, 0 conflicts), then merge, patch core, and tell the team "you're done, stop" to save quota.
- **Lead-owned core:** teams flag core bugs and the lead fixes each once for everyone. This is fast, but it is also the cause of P4.
- **CPU-aware scheduling:** check `uptime`, and add jobs when load is under the core count. Load went from 2/4 to about 7.
- **15-min `send_later` check-ins** with a fixed checklist: check jobs, post a status table, commit, re-arm.
- **Stall triage** from log mtime and the last log line.
- **Final-build gate list** kept in `followups.md`.
- **Honest report** of what the tests prove and what they can't.
- **Split text work by chapter range** (proofreading ch0-3/4-7/8-11), with a rule that a zh fix also updates its en entry and any test that quotes it.

**Failed or weak**
- **Broadcast status pings** got few ETAs back. Commit counts and last-push time were the better signal.
- **WIP commit spam** (P15).
- **A cloud session blocked on approval** (P3).
- **Balance and chain tests ran too late.**

## 5. Handholding in this slice

| Time | User message | Class | Removal |
|---|---|---|---|
| 09:20 | "progress for each 3d team and eta?" | avoidable | Auto progress table every 15 min from the start (came at 09:31), with ETA derived from asset counts in each team's manifest. |
| 09:26 | "is Build Ch11 + endings task still running?" | avoidable | Stall watchdog (P1) plus a proactive "stuck" alert. |
| 09:33 | face pass yes + feminine 白芷 | necessary-human (taste) for "more feminine"; the pass itself is avoidable (P6 rule) | — |
| 09:45 | "are we using full CPU?" | avoidable | Scheduler rule: keep load at about cores minus 0.5; auto-pull from the backlog. |
| 09:58 | "wait for the final build" | avoidable | Template: deliverable cadence. |
| (out of band) | "yes, resume" in the battle session | avoidable | P3. |
| 12:08 | "can I watch it play?" | semi-necessary (user curiosity) | Pre-generate a stills gallery or highlight reel per chapter in the build report. |
| 12:14 | "how did it test dialogues and fights?" | avoidable | A standard VERIFICATION.md (what is proven, what is not) shipped with each build. |
| 12:16 | "add both, in parallel" | avoidable | Proofreading and playtest telemetry are default pipeline stages. |
| 12:19 | "how much longer battle view?" | avoidable | Per-team ETA in the periodic table. |

About 9 of 11 interventions were avoidable. The genuine-taste one was "more feminine 白芷".

## 6. Tools, scripts and docs created or used

- `docs/r3d_reports/<team>.md` + `*_lineup.png`, `cast/<hero>_v2.png`, `env/*.png`: team reports and renders.
- `js/r3d/{models,mapview,core}.js`: lead-owned 3D core; `G.Nature3D`, `G.Mon3D`, `G.Env3D` modules from the teams.
- `tools/r3d/animals/shot.js` + `view.html`: per-team headless render tool (query `ids=,zoom=,w=,h=`).
- `scratchpad/mon_check.js`: Playwright combined-registry check (61 art ids).
- `tools/i18n/extract.js`: i18n coverage report.
- `tools/test/lib/battlebot.js`: smart player bot (heal/revive/items/guard telegraphs/hints).
- Boss balance simulator (400 fights per boss) and `docs/BALANCE.md`.
- Chain playthrough harness (logs `scratchpad/chain/chain.log`, `[boundary] chN entry` lines, `--from chN --assist`).
- `tools/package.sh`, `Play Shorelight.command`, `PLAYING.md` (bilingual), `LICENSES.txt`, subset font, zip `scratchpad/dist/Shorelight-1.0.0-20261027.zip`.
- `scratchpad/followups.md`: deferred fixes plus the final-build gate list.
- In progress: Play Stats page (遊玩統計) with a "Copy report" button; proofreading reports.
